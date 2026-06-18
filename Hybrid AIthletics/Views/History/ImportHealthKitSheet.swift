//
//  ImportHealthKitSheet.swift
//  Hybrid AIthletics
//
//  Sheet presented from the History tab menu to import workouts from
//  Apple Health. Requests read authorization on appear, loads the most
//  recent workouts via `HealthKitImportService`, lets the user multi-
//  select with SwiftUI's native `EditMode`, and commits the selection
//  to SwiftData on confirmation (with dedup against `externalID`).
//

import SwiftUI
import SwiftData
import HealthKit

/// How many days of history to pull from HealthKit by default.
private let importLookbackDays: TimeInterval = 30
/// Upper bound on the number of workouts the sheet will display.
private let importFetchLimit: Int = 60

/// Sheet that lists recent Apple Health workouts and lets the user import
/// selected ones into the app's SwiftData store.
struct ImportHealthKitSheet: View {
    @Environment(\.healthKitImport) private var service
    @Environment(\.modelContext) private var modelContext
    @Environment(\.useMetricUnits) private var useMetricUnits
    @Environment(\.dismiss) private var dismiss
    @Environment(\.googleSheetsSync) private var sheetsSync

    @State private var loadState: LoadState = .loading
    @State private var selection = Set<String>()
    @State private var importBanner: String?

    /// Loading lifecycle for the HealthKit fetch.
    private enum LoadState {
        case loading
        case loaded([HealthKitWorkout])
        case empty
        case error(String)
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Import from Apple Health")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button {
                            commitImport()
                        } label: {
                            Label("Import \(selection.count)", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(selection.isEmpty ? Color.secondary : Color.green)
                        }
                        .disabled(selection.isEmpty || !isLoaded)
                    }
                }
                .task { await load() }
        }
    }

    // MARK: - Content switch

    @ViewBuilder
    private var content: some View {
        switch loadState {
        case .loading:
            ProgressView("Loading workouts from Apple Health")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .loaded(let workouts):
            loadedList(workouts: workouts)
        case .empty:
            ContentUnavailableView(
                "No recent workouts",
                systemImage: "heart.slash",
                description: Text("No workouts found in the last \(Int(importLookbackDays)) days. If this is unexpected, check Settings → Health → Data Access & Devices to confirm Hybrid AIthletics has read access.")
            )
        case .error(let message):
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.orange)
                Text("Could not load workouts")
                    .font(.headline)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button("Try Again") {
                    Task { await load() }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func loadedList(workouts: [HealthKitWorkout]) -> some View {
        List(workouts, selection: $selection) { workout in
            ImportHealthKitRow(workout: workout, useMetricUnits: useMetricUnits)
                .tag(workout.id)
        }
        .environment(\.editMode, .constant(.active))
        .overlay(alignment: .bottom) {
            if let banner = importBanner {
                Text(banner)
                    .font(.footnote)
                    .padding(8)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
                    .padding()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private var isLoaded: Bool {
        if case .loaded = loadState { return true }
        return false
    }

    // MARK: - Actions

    /// Requests authorization and fetches the most recent workouts.
    private func load() async {
        loadState = .loading
        do {
            try await service.requestAuthorization()
            let since = Date().addingTimeInterval(-importLookbackDays * 86400)
            let workouts = try await service.fetchRecentWorkouts(
                since: since,
                limit: importFetchLimit
            )
            if workouts.isEmpty {
                loadState = .empty
            } else {
                loadState = .loaded(workouts)
            }
        } catch {
            loadState = .error(error.localizedDescription)
        }
    }

    /// Transforms the selected DTOs into completed `Exercise` records,
    /// filtering out any whose `externalID` already exists in SwiftData, and
    /// persists them.
    private func commitImport() {
        guard case .loaded(let workouts) = loadState else { return }
        let selected = workouts.filter { selection.contains($0.id) }

        // Dedup against any recorded exercise already carrying an externalID.
        let existingIDs = fetchExistingExternalIDs()
        let deduped = selected.filter { !existingIDs.contains($0.id) }
        let skippedCount = selected.count - deduped.count

        for dto in deduped {
            let exercise = HealthKitWorkoutMapper.toExercise(dto)
            modelContext.insert(exercise)
        }
        do {
            try modelContext.save()
        } catch {
            importBanner = "Saved partial import: \(error.localizedDescription)"
            return
        }

        if skippedCount > 0 && deduped.isEmpty {
            // Everything was already imported — report and stay on screen.
            importBanner = "All selected workouts were already imported."
            return
        }

        // Batch imports skip the per-mutation debounce and sync once after
        // every selected row has been inserted. Fire-and-forget; UI proceeds.
        Task { await sheetsSync.syncNow() }
        dismiss()
    }

    /// Snapshots the set of all recorded-workout `externalID` values currently
    /// in SwiftData so the commit step can skip anything that's already been
    /// imported. The `externalID` lives inside the nested `workout` Codable
    /// value, which can't be reached from a `#Predicate`, so we fetch all
    /// exercises and collect in memory.
    private func fetchExistingExternalIDs() -> Set<String> {
        let descriptor = FetchDescriptor<Exercise>()
        guard let exercises = try? modelContext.fetch(descriptor) else { return [] }
        return Set(exercises.compactMap { $0.workout?.externalID })
    }
}

/// Single row in the HealthKit import list.
private struct ImportHealthKitRow: View {
    let workout: HealthKitWorkout
    let useMetricUnits: Bool

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        let exerciseType = HealthKitWorkoutMapper.exerciseType(for: workout.activityType)
        HStack(spacing: 12) {
            Image(systemName: exerciseType.systemImage)
                .font(.title2)
                .foregroundStyle(exerciseType.color)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(exerciseType.rawValue)
                    .font(.headline)
                Text(Self.dateFormatter.string(from: workout.startDate))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    Text(Int(workout.duration).formattedDuration)
                    if let miles = workout.distanceMiles, miles > 0 {
                        Text("•")
                        Text(miles.formattedDistance(metric: useMetricUnits))
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    ImportHealthKitSheet()
        .modelContainer(ModelContainerFactory.makePreviewContainer())
}
