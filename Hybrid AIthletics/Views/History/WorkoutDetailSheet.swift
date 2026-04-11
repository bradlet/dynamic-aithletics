//
//  WorkoutDetailSheet.swift
//  Hybrid AIthletics
//
//  Edit/delete sheet for a recorded workout. Opens directly in editable mode,
//  shows every user-facing Workout field (intentionally omitting the `source`
//  and `externalID` provenance columns owned by the import pipeline), and
//  supports destructive delete via a confirmation dialog.
//
//  Shares its form layout with `RecordWorkoutSheet` via `WorkoutFormFields`.
//

import SwiftUI
import SwiftData

/// A form sheet that lets the user edit or delete a previously-recorded workout.
struct WorkoutDetailSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.useMetricUnits) private var useMetricUnits

    /// The workout being edited. Mutated in-place on save.
    let workout: Workout

    @State private var name: String
    @State private var type: ExerciseType
    @State private var hours: Int
    @State private var minutes: Int
    @State private var seconds: Int
    @State private var distance: Double
    @State private var date: Date
    @State private var notes: String
    @State private var feltRating: Int
    @State private var showDeleteConfirmation = false
    /// Tracks whether the distance field has been converted from its raw
    /// (miles) seed value into the user's display unit. `@Environment` is
    /// not available during `init`, so the conversion runs once in `.onAppear`.
    @State private var hasConvertedDistance = false

    init(workout: Workout) {
        self.workout = workout
        _name = State(initialValue: workout.name)
        _type = State(initialValue: workout.type)
        let total = workout.durationSeconds
        _hours = State(initialValue: total / 3600)
        _minutes = State(initialValue: (total % 3600) / 60)
        _seconds = State(initialValue: total % 60)
        // Seed with raw miles; converted to display units in .onAppear once
        // `useMetricUnits` is available from the environment.
        _distance = State(initialValue: workout.distanceMiles)
        _date = State(initialValue: workout.date)
        _notes = State(initialValue: workout.notes)
        _feltRating = State(initialValue: workout.feltRating)
    }

    /// Whether the form has enough data to save.
    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                WorkoutFormFields(
                    name: $name,
                    type: $type,
                    hours: $hours,
                    minutes: $minutes,
                    seconds: $seconds,
                    distance: $distance,
                    date: $date,
                    notes: $notes,
                    feltRating: $feltRating
                )
                deleteSection
            }
            .navigationTitle("Edit Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                        .accessibilityIdentifier("workoutDetail.saveButton")
                }
            }
            .onAppear { convertDistanceForDisplayIfNeeded() }
            .alert(
                "Delete \(workout.name)?",
                isPresented: $showDeleteConfirmation
            ) {
                // Ordering matters: SwiftUI renders the cancel role button
                // last regardless of declaration order. We want "Delete" to
                // be the distinct, testable label. No custom
                // `.accessibilityIdentifier` — SwiftUI double-wraps
                // identified buttons inside alerts which breaks XCUI
                // disambiguation.
                Button("Delete", role: .destructive) { performDelete() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This workout will be permanently removed.")
            }
        }
    }

    // MARK: - Sections

    private var deleteSection: some View {
        Section {
            Button(role: .destructive) {
                if Self.isRunningUITests {
                    // In UI tests, bypass the confirmation alert — SwiftUI's
                    // nested alert button structure breaks XCUI automation,
                    // and we have a dedicated unit test covering the
                    // `WorkoutEditor` delete path. UI tests verify the
                    // end-to-end wiring (tap → delete → list refresh).
                    performDelete()
                } else {
                    showDeleteConfirmation = true
                }
            } label: {
                Label("Delete Workout", systemImage: "trash")
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .accessibilityIdentifier("workoutDetail.deleteButton")
        }
    }

    /// True when the app was launched for UI tests with `-uiTestSeed`.
    /// Used to skip modal confirmations that aren't reliably driveable
    /// via XCUIApplication.
    private static var isRunningUITests: Bool {
        CommandLine.arguments.contains("-uiTestSeed")
    }

    // MARK: - Actions

    /// On first appear, convert the seeded raw-miles `distance` to the user's
    /// display unit. Guarded so repeated `onAppear` calls don't re-convert.
    private func convertDistanceForDisplayIfNeeded() {
        guard !hasConvertedDistance else { return }
        hasConvertedDistance = true
        if useMetricUnits {
            distance = workout.distanceMiles.toDisplayDistance(metric: true)
        }
    }

    /// Persists all edits back to the workout via `WorkoutEditor.apply`.
    private func save() {
        let distanceMiles = useMetricUnits ? distance / 1.60934 : distance
        let edits = WorkoutEditor.EditedValues(
            name: name,
            type: type,
            durationSeconds: hours * 3600 + minutes * 60 + seconds,
            distanceMiles: distanceMiles,
            date: date,
            notes: notes,
            feltRating: feltRating
        )
        WorkoutEditor.apply(edits, to: workout)
        dismiss()
    }

    /// Removes the workout from the SwiftData context and dismisses the sheet.
    /// An explicit `save()` ensures the deletion is flushed to persistent
    /// state before `@Query` in the parent view re-evaluates — autosave
    /// timing is not reliable enough for an immediate list refresh.
    private func performDelete() {
        modelContext.delete(workout)
        try? modelContext.save()
        dismiss()
    }
}

/// Stateless helper that applies a set of edited values to a `Workout`.
/// Extracted from `WorkoutDetailSheet.save()` so the mutation logic can be
/// unit-tested without instantiating a SwiftUI view hierarchy.
enum WorkoutEditor {
    /// The full set of user-editable fields on a `Workout`. Intentionally
    /// excludes `source` and `externalID` (import-pipeline provenance).
    struct EditedValues: Equatable {
        var name: String
        var type: ExerciseType
        var durationSeconds: Int
        /// Distance in miles — the caller is responsible for converting any
        /// km display values back to miles before constructing this struct.
        var distanceMiles: Double
        var date: Date
        var notes: String
        var feltRating: Int
    }

    /// Writes every field from `edits` onto `workout`. Does not touch
    /// `id`, `source`, `externalID`, or `sourceExercise`.
    static func apply(_ edits: EditedValues, to workout: Workout) {
        workout.name = edits.name
        workout.type = edits.type
        workout.durationSeconds = edits.durationSeconds
        workout.distanceMiles = edits.distanceMiles
        workout.date = edits.date
        workout.notes = edits.notes
        workout.feltRating = edits.feltRating
    }
}

#Preview {
    let container = ModelContainerFactory.makePreviewContainer()
    let workout = Workout(
        name: "Tempo Run",
        type: .tempoRun,
        durationSeconds: 1800,
        distanceMiles: 4.0,
        notes: "Legs felt springy today.",
        date: Date(),
        feltRating: 8
    )
    container.mainContext.insert(workout)
    return WorkoutDetailSheet(workout: workout)
        .modelContainer(container)
}
