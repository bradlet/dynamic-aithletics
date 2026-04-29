//
//  GoogleSheetsSyncCoordinator.swift
//  Hybrid AIthletics
//
//  Orchestrates the Google Sheets sync feature: owns the user-facing
//  enable/disable state, debounces mutation-triggered syncs, and bridges
//  SwiftData (to read workouts + AppConfiguration) to the network-only
//  `GoogleSheetsAPI` layer.
//
//  Single coordinator instance lives in App scope and is exposed via
//  `@Environment(\.googleSheetsSync)`. Views never touch the API directly.
//

import Foundation
import Observation
import SwiftData

/// Lifecycle state for the Google Sheets sync feature, surfaced to the
/// History tab toolbar so it can show a status indicator.
enum GoogleSheetsSyncStatus: Equatable {
    /// No sync in flight; either disabled, or last sync succeeded long enough
    /// ago that we don't surface a visible state.
    case idle
    /// A sync is currently uploading.
    case syncing
    /// The last sync completed successfully at the given time.
    case success(Date)
    /// The last sync failed with the given user-facing reason. Mutation hooks
    /// will retry on next change.
    case failed(String)
    /// Sync is enabled in `AppConfiguration` but no OAuth token exists on
    /// this device (e.g. the user enabled on another device). The user must
    /// sign in via the menu before syncs can run.
    case needsAuth
}

/// Debounce + state coordinator for Google Sheets sync. `@Observable` so the
/// History tab toolbar can react to status changes for the failure indicator.
@MainActor
@Observable
final class GoogleSheetsSyncCoordinator {

    // MARK: - Public state

    /// Latest sync lifecycle state. Drives the History tab status indicator.
    private(set) var status: GoogleSheetsSyncStatus = .idle

    /// Whether the user has enabled sync. Mirrors
    /// `AppConfiguration.googleSheetsSyncEnabled`. Updated by `attach`,
    /// `enable`, and `disable`.
    private(set) var isEnabled: Bool = false

    /// The spreadsheet ID written to. `nil` until the first `enable` succeeds.
    private(set) var spreadsheetID: String?

    // MARK: - Dependencies

    private let api: GoogleSheetsAPI
    private weak var modelContainer: ModelContainer?
    private var debounceTask: Task<Void, Never>?

    /// Title used when creating a new spreadsheet on first enable.
    private static let spreadsheetTitle = "Hybrid AIthletics"

    /// Debounce window for mutation-triggered syncs. Mutation hooks call
    /// `requestSync()`; the actual upload fires this many seconds after the
    /// most recent call. Tunable in tests.
    let debounceSeconds: UInt64

    // MARK: - Init

    init(api: GoogleSheetsAPI, debounceSeconds: UInt64 = 10) {
        self.api = api
        self.debounceSeconds = debounceSeconds
    }

    // MARK: - Lifecycle

    /// Wires the coordinator to the app's model container and restores
    /// state from `AppConfiguration`. Attempts a silent OAuth restore so
    /// the next mutation can sync without prompting.
    /// Must be called once during app startup before any view consumes
    /// the coordinator's published state.
    func attach(modelContainer: ModelContainer) async {
        self.modelContainer = modelContainer
        readPersistedState(from: modelContainer)
        if isEnabled {
            let restored = await api.restoreAuthorizationIfPossible()
            status = restored ? .idle : .needsAuth
        } else {
            status = .idle
        }
    }

    // MARK: - User-driven actions

    /// Confirmed enable flow: present OAuth, request scope, create a fresh
    /// spreadsheet, persist state, and run an initial full sync.
    /// Throws on cancellation, denied scope, or API failure. Caller is
    /// responsible for showing an error to the user; status is also
    /// updated for the status indicator.
    func enable() async throws {
        guard let modelContainer else { throw GoogleSheetsSyncError.notAttached }
        status = .syncing
        do {
            try await api.authorize()
            let id = try await api.createSpreadsheet(title: Self.spreadsheetTitle)

            persistSyncState(enabled: true, spreadsheetID: id, in: modelContainer)
            isEnabled = true
            spreadsheetID = id

            let rows = try fetchAndEncodeRows(container: modelContainer)
            try await api.overwriteSheet(spreadsheetId: id, rows: rows)
            status = .success(Date())
        } catch {
            status = .failed(error.localizedDescription)
            throw error
        }
    }

    /// Re-authorize on a device where sync is already enabled in
    /// `AppConfiguration` (e.g. CloudKit-synced from another device) but no
    /// OAuth token exists locally. Presents OAuth, then runs an immediate
    /// sync to the existing spreadsheet. Throws on auth failure.
    func reauthorize() async throws {
        guard isEnabled, spreadsheetID != nil else {
            throw GoogleSheetsSyncError.notAuthorized
        }
        status = .syncing
        do {
            try await api.authorize()
            await syncNow()
        } catch {
            status = .failed(error.localizedDescription)
            throw error
        }
    }

    /// Disable flow: cancel any pending debounced sync, sign out, clear
    /// `AppConfiguration` fields. The Google sheet itself is left alone in
    /// the user's Drive — disabling is local-only.
    func disable() {
        debounceTask?.cancel()
        debounceTask = nil
        api.signOut()
        if let modelContainer {
            persistSyncState(enabled: false, spreadsheetID: "", in: modelContainer)
        }
        isEnabled = false
        spreadsheetID = nil
        status = .idle
    }

    // MARK: - Mutation hooks

    /// Call from every workout add/edit/delete site. Schedules a sync for
    /// `debounceSeconds` from now. Repeated calls within the window collapse
    /// into a single upload.
    func requestSync() {
        guard isEnabled, spreadsheetID != nil else { return }
        debounceTask?.cancel()
        // Surface the pending state immediately so the History tab can show
        // the yellow toolbar dot + "syncing…" indicator during the debounce
        // window, not just once the upload starts.
        status = .syncing
        debounceTask = Task { [weak self] in
            guard let self else { return }
            let nanos = self.debounceSeconds * 1_000_000_000
            try? await Task.sleep(nanoseconds: nanos)
            if Task.isCancelled { return }
            // Drop the self-reference *before* the upload: a subsequent
            // `requestSync()` from a mutation site during the upload must
            // not cancel this task (URLSession would throw CancellationError
            // mid-flight). It can schedule a fresh debounce instead.
            self.debounceTask = nil
            await self.performSync()
        }
    }

    /// Sync immediately, bypassing debounce. Used by batch-import flows
    /// (CSV / HealthKit) that already group their inserts and want a single
    /// post-batch upload. Also used to flush a pending debounce on app
    /// backgrounding or retry.
    func syncNow() async {
        // Cancelling here only meaningfully affects *direct* callers (batch
        // imports, retry button). The debounce task clears its own
        // `debounceTask` reference before invoking `performSync`, so a
        // debounce-fired sync never cancels itself here.
        debounceTask?.cancel()
        debounceTask = nil
        await performSync()
    }

    /// Shared upload path used by both the debounce task and direct
    /// `syncNow()` callers. Does not touch `debounceTask` so it's safe to
    /// invoke from inside the debounce task without self-cancelling.
    private func performSync() async {
        guard isEnabled, let id = spreadsheetID, let modelContainer else { return }
        guard api.isAuthorized else {
            status = .needsAuth
            return
        }
        status = .syncing
        do {
            let rows = try fetchAndEncodeRows(container: modelContainer)
            try await api.overwriteSheet(spreadsheetId: id, rows: rows)
            // Re-check enablement after the network await: `disable()` may
            // have flipped the flag while the upload was in flight, in
            // which case overwriting `.idle` with `.success` would surface
            // a confusing post-disable success indicator.
            guard isEnabled else { return }
            status = .success(Date())
        } catch {
            guard isEnabled else { return }
            status = .failed(error.localizedDescription)
        }
    }

    // MARK: - Internals

    /// Reads workouts + unit preference from SwiftData and produces the row
    /// matrix for the Sheets API. Pure read; never mutates the context.
    private func fetchAndEncodeRows(container: ModelContainer) throws -> [[String]] {
        let context = ModelContext(container)
        let configDescriptor = FetchDescriptor<AppConfiguration>()
        let useMetric = (try? context.fetch(configDescriptor).first?.useMetricUnits) ?? false
        let workoutDescriptor = FetchDescriptor<Workout>(sortBy: [SortDescriptor(\.date)])
        let workouts = try context.fetch(workoutDescriptor)
        let unit: WorkoutCSVDistanceUnit = useMetric ? .kilometers : .miles
        return WorkoutCSV.rows(workouts: workouts, unit: unit)
    }

    /// Pulls `googleSheetsSyncEnabled` and `googleSheetsSpreadsheetID` from
    /// the singleton `AppConfiguration` into local state.
    private func readPersistedState(from container: ModelContainer) {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<AppConfiguration>()
        guard let config = try? context.fetch(descriptor).first else { return }
        isEnabled = config.googleSheetsSyncEnabled
        let storedID = config.googleSheetsSpreadsheetID
        spreadsheetID = storedID.isEmpty ? nil : storedID
    }

    private func persistSyncState(enabled: Bool, spreadsheetID: String, in container: ModelContainer) {
        let context = ModelContext(container)
        let config = AppConfiguration.current(in: context)
        config.googleSheetsSyncEnabled = enabled
        config.googleSheetsSpreadsheetID = spreadsheetID
        try? context.save()
    }
}
