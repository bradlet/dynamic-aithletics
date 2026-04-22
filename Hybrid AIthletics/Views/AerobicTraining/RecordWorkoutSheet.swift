//
//  RecordWorkoutSheet.swift
//  Hybrid AIthletics
//
//  Form sheet for recording a completed workout.
//  When given a source exercise, pre-fills from its defaults.
//  When exercise is nil (quick add), creates both an Exercise and Workout on save.
//

import SwiftUI
import SwiftData

/// A form for recording a workout, optionally pre-filled from a planned exercise.
struct RecordWorkoutSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.useMetricUnits) private var useMetricUnits

    /// The exercise template to pre-fill defaults from, or nil for quick add.
    let exercise: Exercise?
    /// The default date for the workout (used when exercise is nil).
    let defaultDate: Date

    @State private var name = ""
    @State private var type: ExerciseType = .run
    @State private var hours = 0
    @State private var minutes = 0
    @State private var seconds = 0
    @State private var distance = 0.0
    @State private var notes = ""
    @State private var workoutDate = Date()
    @State private var feltRating = 0
    @State private var previousType: ExerciseType = .run

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
                    date: $workoutDate,
                    notes: $notes,
                    feltRating: $feltRating
                )
            }
            .navigationTitle("Record Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                }
            }
            .onAppear { populateFields() }
            .onChange(of: type) { oldType, newType in
                if name == oldType.rawValue {
                    name = newType.rawValue
                }
            }
        }
    }

    // MARK: - Actions

    /// Pre-fills form fields from the source exercise template or defaults.
    private func populateFields() {
        if let exercise {
            name = exercise.name
            type = exercise.type
            let total = exercise.durationSeconds
            hours = total / 3600
            minutes = (total % 3600) / 60
            seconds = total % 60
            distance = useMetricUnits ? exercise.distanceMiles.toDisplayDistance(metric: true) : exercise.distanceMiles
            previousType = exercise.type
        } else {
            name = type.rawValue
            previousType = type
        }
        workoutDate = defaultDate
    }

    /// Creates and saves the workout record. When no source exercise exists,
    /// also creates a matching exercise so every workout has a source.
    private func save() {
        let durationSec = hours * 3600 + minutes * 60 + seconds
        let distanceMiles = useMetricUnits ? distance / 1.60934 : distance

        let sourceExercise: Exercise
        if let exercise {
            sourceExercise = exercise
        } else {
            let newExercise = Exercise(
                name: name,
                type: type,
                durationSeconds: durationSec,
                distanceMiles: distanceMiles,
                notes: notes,
                scheduledDate: workoutDate,
                isRepeating: false
            )
            modelContext.insert(newExercise)
            sourceExercise = newExercise
        }

        let workout = Workout(
            name: name,
            type: type,
            durationSeconds: durationSec,
            distanceMiles: distanceMiles,
            notes: notes,
            date: workoutDate.startOfDay,
            feltRating: feltRating,
            sourceExercise: sourceExercise
        )
        modelContext.insert(workout)
        dismiss()
    }
}

#Preview {
    let container = ModelContainerFactory.makePreviewContainer()
    let exercise = Exercise(
        name: "Morning Run",
        type: .run,
        durationSeconds: 1800,
        distanceMiles: 3.0,
        scheduledDate: Date()
    )
    return RecordWorkoutSheet(exercise: exercise, defaultDate: Date())
        .modelContainer(container)
}
