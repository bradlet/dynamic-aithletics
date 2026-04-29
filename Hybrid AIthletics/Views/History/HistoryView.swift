//
//  HistoryView.swift
//  Hybrid AIthletics
//
//  Container view for the History tab. Shows summary stats,
//  a monthly calendar, and a paginated list of all recorded workouts.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// The History tab combining summary statistics, a monthly calendar, and a workout log.
struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.useMetricUnits) private var useMetricUnits
    @Environment(\.googleSheetsSync) private var sheetsSync

    @Query(sort: \Workout.date, order: .reverse) private var allWorkouts: [Workout]
    @State private var selectedMonth: Date = Date()

    /// Drives `WorkoutListView` to jump to a specific workout's page and
    /// highlight it briefly. A new request (fresh `id`) is constructed on
    /// every calendar day tap so repeat taps still fire the observer.
    @State private var navigationRequest: WorkoutNavigationRequest?

    // MARK: CSV Import/Export state

    @State private var exportDocument: WorkoutCSVDocument?
    @State private var isExporterPresented = false
    @State private var isImporterPresented = false
    @State private var isPreImportSheetPresented = false
    @State private var pendingImport: PendingImport?
    @State private var importUnit: WorkoutCSVDistanceUnit = .miles
    @State private var errorMessage: String?

    // MARK: HealthKit Import state

    @State private var isHealthKitImporterPresented = false

    // MARK: Google Sheets Sync state

    @State private var isSheetsSyncConfirmationPresented = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    PerformanceHubView(workouts: allWorkouts)
                    MonthlyCalendarView(
                        selectedMonth: $selectedMonth,
                        items: allWorkouts,
                        onDayTap: handleCalendarDayTap
                    )
                    workoutListSection
                }
                .padding(.vertical)
            }
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            startExport()
                        } label: {
                            Label("Export Workouts", systemImage: "square.and.arrow.up")
                        }
                        Button {
                            isPreImportSheetPresented = true
                        } label: {
                            Label("Import Workouts", systemImage: "square.and.arrow.down")
                        }
                        Button {
                            isHealthKitImporterPresented = true
                        } label: {
                            Label("Import from Apple Health", systemImage: "heart.text.square")
                        }
                        sheetsSyncMenuSection
                    } label: {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "ellipsis.circle")
                            // Tiny red dot when the most recent sync failed,
                            // so the user knows something needs attention
                            // without a blocking alert.
                            if case .failed = sheetsSync.status {
                                Circle()
                                    .fill(.red)
                                    .frame(width: 7, height: 7)
                                    .offset(x: 4, y: -3)
                            }
                        }
                    }
                }
            }
            .fileExporter(
                isPresented: $isExporterPresented,
                document: exportDocument,
                contentType: .commaSeparatedText,
                defaultFilename: defaultExportFilename()
            ) { result in
                if case .failure(let error) = result {
                    errorMessage = "Export failed: \(error.localizedDescription)"
                }
            }
            .sheet(isPresented: $isPreImportSheetPresented) {
                CSVImportGatewaySheet(
                    onChooseFile: {
                        isPreImportSheetPresented = false
                        // Delay slightly so the sheet dismissal completes
                        // before the file importer is presented.
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            isImporterPresented = true
                        }
                    },
                    onCancel: { isPreImportSheetPresented = false }
                )
            }
            .fileImporter(
                isPresented: $isImporterPresented,
                allowedContentTypes: [.commaSeparatedText]
            ) { result in
                handleFileImporterResult(result)
            }
            .sheet(item: $pendingImport) { pending in
                ImportCSVConfirmationSheet(
                    filename: pending.filename,
                    parseResult: pending.result,
                    unit: $importUnit,
                    onCancel: { pendingImport = nil },
                    onConfirm: { commitImport(pending.result) }
                )
            }
            .sheet(isPresented: $isHealthKitImporterPresented) {
                ImportHealthKitSheet()
            }
            .alert(
                "Something went wrong",
                isPresented: Binding(
                    get: { errorMessage != nil },
                    set: { if !$0 { errorMessage = nil } }
                ),
                presenting: errorMessage
            ) { _ in
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: { message in
                Text(message)
            }
            .alert(
                "Enable Google Sheets Sync?",
                isPresented: $isSheetsSyncConfirmationPresented
            ) {
                Button("Cancel", role: .cancel) { }
                Button("Enable") { startEnableSheetsSync() }
            } message: {
                Text("This will create a new Google Sheet and overwrite it every time you add or edit a workout. Sync is one-way: any edits you make in Google Sheets will be wiped on the next save. You can disable sync any time from this menu.")
            }
        }
    }

    // MARK: Google Sheets Sync menu

    /// Menu items for the Google Sheets Sync feature. Adapts to the current
    /// coordinator state: not enabled → enable button; failed → retry +
    /// disable; needs auth → re-sign-in + disable; enabled and healthy →
    /// disable only.
    @ViewBuilder
    private var sheetsSyncMenuSection: some View {
        if sheetsSync.isEnabled {
            switch sheetsSync.status {
            case .failed(let reason):
                Button {
                    Task { await sheetsSync.syncNow() }
                } label: {
                    Label("Retry Google Sheets Sync (\(reason))",
                          systemImage: "exclamationmark.arrow.triangle.2.circlepath")
                }
            case .needsAuth:
                Button {
                    Task { await reauthorizeSheetsSync() }
                } label: {
                    Label("Sign in to resume Sheets Sync", systemImage: "person.crop.circle.badge.questionmark")
                }
            default:
                EmptyView()
            }
            Button(role: .destructive) {
                sheetsSync.disable()
            } label: {
                Label("Disable Google Sheets Sync", systemImage: "tablecells.badge.ellipsis")
            }
        } else {
            Button {
                isSheetsSyncConfirmationPresented = true
            } label: {
                Label("Google Sheets Sync", systemImage: "tablecells")
            }
        }
    }

    /// Kicks off the OAuth + sheet creation + initial sync flow. Failures
    /// surface via the shared `errorMessage` alert, and the menu icon's
    /// red dot shows on subsequent debounced syncs.
    private func startEnableSheetsSync() {
        Task {
            do {
                try await sheetsSync.enable()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    /// Re-presents OAuth on a device where sync is enabled in
    /// AppConfiguration but no token exists locally (e.g. fresh device
    /// joined via CloudKit). Reuses the existing spreadsheet ID rather
    /// than creating a new one.
    private func reauthorizeSheetsSync() async {
        do {
            try await sheetsSync.reauthorize()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Section header and workout list.
    private var workoutListSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent Workouts")
                .font(.headline)
                .padding(.horizontal)
            WorkoutListView(
                workouts: allWorkouts,
                navigationRequest: navigationRequest
            )
        }
    }

    // MARK: Calendar navigation

    /// Translates a calendar day tap into a navigation request for the
    /// workout list. Since `allWorkouts` is sorted descending by date, the
    /// first match on a day is the most recent workout for that day.
    private func handleCalendarDayTap(_ day: Date) {
        guard let match = allWorkouts.first(where: { $0.date.isSameDay(as: day) }) else {
            return
        }
        navigationRequest = WorkoutNavigationRequest(workoutID: match.id)
    }

    // MARK: Export

    /// Builds the CSV document from the current workouts and triggers the exporter.
    private func startExport() {
        let unit: WorkoutCSVDistanceUnit = useMetricUnits ? .kilometers : .miles
        let csv = WorkoutCSV.encode(workouts: allWorkouts, unit: unit)
        exportDocument = WorkoutCSVDocument(text: csv)
        isExporterPresented = true
    }

    /// Produces a dated default filename like `workouts-2026-04-09.csv`.
    private func defaultExportFilename() -> String {
        let formatter = HistoryView.filenameDateFormatter
        return "workouts-\(formatter.string(from: Date()))"
    }

    private static let filenameDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    // MARK: Import

    /// Handles the result from `.fileImporter`: reads the picked URL,
    /// parses it, and either presents the confirmation sheet or an error.
    private func handleFileImporterResult(_ result: Result<URL, Error>) {
        switch result {
        case .failure(let error):
            errorMessage = "Import failed: \(error.localizedDescription)"
        case .success(let url):
            let accessed = url.startAccessingSecurityScopedResource()
            defer { if accessed { url.stopAccessingSecurityScopedResource() } }

            do {
                let text = try String(contentsOf: url, encoding: .utf8)
                let parsed = try WorkoutCSV.parse(text)
                importUnit = useMetricUnits ? .kilometers : .miles
                pendingImport = PendingImport(
                    filename: url.lastPathComponent,
                    result: parsed
                )
            } catch WorkoutCSVError.empty {
                errorMessage = "This file is empty."
            } catch WorkoutCSVError.missingHeader {
                errorMessage = "This file is missing a header row."
            } catch {
                errorMessage = "Could not read file: \(error.localizedDescription)"
            }
        }
    }

    /// Inserts all successfully parsed rows as new workouts with parent exercises.
    private func commitImport(_ result: WorkoutCSVParseResult) {
        for row in result.rows {
            let (exercise, workout) = WorkoutCSV.toWorkoutWithExercise(row, unit: importUnit)
            modelContext.insert(exercise)
            modelContext.insert(workout)
        }
        do {
            try modelContext.save()
            // Batch imports skip the per-mutation debounce and sync once
            // after every parsed row has been inserted. Only fired on
            // successful save so a partial-failure path doesn't trigger
            // an upload of inconsistent state.
            Task { await sheetsSync.syncNow() }
        } catch {
            errorMessage = "Saved partial import: \(error.localizedDescription)"
        }
        pendingImport = nil
    }
}

/// A pending import waiting for user confirmation.
private struct PendingImport: Identifiable {
    let id = UUID()
    let filename: String
    let result: WorkoutCSVParseResult
}

/// Gateway sheet shown before opening the file picker, with a link to import help.
private struct CSVImportGatewaySheet: View {
    let onChooseFile: () -> Void
    let onCancel: () -> Void
    @State private var isHelpPresented = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "doc.text")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)

                Text("Select a CSV file to import your workout history.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                Button(action: onChooseFile) {
                    Label("Choose File", systemImage: "folder")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, 40)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Import Workouts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isHelpPresented = true
                    } label: {
                        Image(systemName: "questionmark.circle")
                    }
                }
            }
            .sheet(isPresented: $isHelpPresented) {
                CSVImportHelpView()
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    HistoryView()
        .modelContainer(ModelContainerFactory.makePreviewContainer())
}
