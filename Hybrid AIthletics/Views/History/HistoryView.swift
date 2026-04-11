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
    @State private var pendingImport: PendingImport?
    @State private var importUnit: WorkoutCSVDistanceUnit = .miles
    @State private var errorMessage: String?

    // MARK: HealthKit Import state

    @State private var isHealthKitImporterPresented = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    SummaryStatsView(workouts: allWorkouts)
                    MonthlyCalendarView(
                        selectedMonth: $selectedMonth,
                        workouts: allWorkouts,
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
                            isImporterPresented = true
                        } label: {
                            Label("Import Workouts", systemImage: "square.and.arrow.down")
                        }
                        Button {
                            isHealthKitImporterPresented = true
                        } label: {
                            Label("Import from Apple Health", systemImage: "heart.text.square")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
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

    /// Inserts all successfully parsed rows as new workouts.
    private func commitImport(_ result: WorkoutCSVParseResult) {
        for row in result.rows {
            let workout = WorkoutCSV.toWorkout(row, unit: importUnit)
            modelContext.insert(workout)
        }
        do {
            try modelContext.save()
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

#Preview {
    HistoryView()
        .modelContainer(ModelContainerFactory.makePreviewContainer())
}
