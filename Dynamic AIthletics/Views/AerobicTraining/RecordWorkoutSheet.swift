//
//  RecordWorkoutSheet.swift
//  Dynamic AIthletics
//
//  Form sheet for recording a completed workout.
//  Pre-fills from the source exercise's defaults; all fields are editable.
//

import SwiftUI
import SwiftData

/// A form for recording a workout, pre-filled from a planned exercise.
struct RecordWorkoutSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.useMetricUnits) private var useMetricUnits

    /// The exercise template to pre-fill defaults from.
    let exercise: Exercise

    @State private var name = ""
    @State private var type: ExerciseType = .run
    @State private var hours = 0
    @State private var minutes = 0
    @State private var seconds = 0
    @State private var distance = 0.0
    @State private var notes = ""
    @State private var workoutDate = Date()

    /// Whether the form has enough data to save.
    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                nameAndTypeSection
                durationSection
                distanceSection
                dateSection
                notesSection
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
            .onAppear { populateFromExercise() }
        }
    }

    // MARK: - Form Sections

    /// Name and exercise type picker.
    private var nameAndTypeSection: some View {
        Section {
            TextField("Workout Name", text: $name)
            Picker("Type", selection: $type) {
                ForEach(ExerciseType.allCases) { exerciseType in
                    Label(exerciseType.rawValue, systemImage: exerciseType.systemImage)
                        .tag(exerciseType)
                }
            }
        }
    }

    /// Duration pickers for hours, minutes, seconds.
    private var durationSection: some View {
        Section("Duration") {
            HStack {
                Picker("Hours", selection: $hours) {
                    ForEach(0..<24) { Text("\($0)h").tag($0) }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                Picker("Minutes", selection: $minutes) {
                    ForEach(0..<60) { Text("\($0)m").tag($0) }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                Picker("Seconds", selection: $seconds) {
                    ForEach(0..<60) { Text("\($0)s").tag($0) }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
            }
            .frame(height: 120)
        }
    }

    /// Distance input field.
    private var distanceSection: some View {
        Section("Distance") {
            HStack {
                TextField("0.0", value: $distance, format: .number.precision(.fractionLength(1)))
                    .keyboardType(.decimalPad)
                Text(useMetricUnits ? "km" : "mi")
                    .foregroundStyle(.secondary)
            }
        }
    }

    /// Date and time picker for when the workout was performed.
    private var dateSection: some View {
        Section("Date & Time") {
            DatePicker("When", selection: $workoutDate)
        }
    }

    /// Notes text field.
    private var notesSection: some View {
        Section("Notes") {
            TextField("How did it go?", text: $notes, axis: .vertical)
                .lineLimit(3...6)
        }
    }

    // MARK: - Actions

    /// Pre-fills form fields from the source exercise template.
    private func populateFromExercise() {
        name = exercise.name
        type = exercise.type
        let total = exercise.durationSeconds
        hours = total / 3600
        minutes = (total % 3600) / 60
        seconds = total % 60
        distance = useMetricUnits ? exercise.distanceMiles.toDisplayDistance(metric: true) : exercise.distanceMiles
        workoutDate = Date()
    }

    /// Creates and saves the workout record.
    private func save() {
        let durationSec = hours * 3600 + minutes * 60 + seconds
        let distanceMiles = useMetricUnits ? distance / 1.60934 : distance

        let workout = Workout(
            name: name,
            type: type,
            durationSeconds: durationSec,
            distanceMiles: distanceMiles,
            notes: notes,
            date: workoutDate,
            sourceExercise: exercise
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
    return RecordWorkoutSheet(exercise: exercise)
        .modelContainer(container)
}
