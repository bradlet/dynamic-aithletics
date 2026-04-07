//
//  AddExerciseSheet.swift
//  Hybrid AIthletics
//
//  Form sheet for creating or editing a planned exercise.
//  Supports both create (nil exercise) and edit (existing exercise) modes.
//

import SwiftUI
import SwiftData

/// A form for creating a new exercise or editing an existing one.
struct AddExerciseSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.useMetricUnits) private var useMetricUnits

    /// The exercise to edit, or nil for create mode.
    let exercise: Exercise?
    /// The default date when creating a new exercise.
    let defaultDate: Date

    @State private var name = ""
    @State private var type: ExerciseType = .run
    @State private var hours = 0
    @State private var minutes = 0
    @State private var seconds = 0
    @State private var distance = 0.0
    @State private var notes = ""
    @State private var scheduledDate = Date()
    @State private var isRepeating = false

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
                repeatSection
                notesSection
            }
            .navigationTitle(exercise == nil ? "New Exercise" : "Edit Exercise")
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
        }
    }

    // MARK: - Form Sections

    /// Name and exercise type picker.
    private var nameAndTypeSection: some View {
        Section {
            TextField("Exercise Name", text: $name)
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

    /// Date picker for scheduling.
    private var dateSection: some View {
        Section("Scheduled Date") {
            DatePicker("Date", selection: $scheduledDate, displayedComponents: .date)
        }
    }

    /// Toggle for weekly repetition.
    private var repeatSection: some View {
        Section {
            Toggle("Repeat Weekly", isOn: $isRepeating)
        } footer: {
            if isRepeating {
                Text("This exercise will appear every \(scheduledDate.weekdayName).")
            }
        }
    }

    /// Notes text field.
    private var notesSection: some View {
        Section("Notes") {
            TextField("Optional notes...", text: $notes, axis: .vertical)
                .lineLimit(3...6)
        }
    }

    // MARK: - Actions

    /// Pre-fills form fields from the exercise (edit mode) or defaults (create mode).
    private func populateFields() {
        if let exercise {
            name = exercise.name
            type = exercise.type
            let total = exercise.durationSeconds
            hours = total / 3600
            minutes = (total % 3600) / 60
            seconds = total % 60
            distance = useMetricUnits ? exercise.distanceMiles.toDisplayDistance(metric: true) : exercise.distanceMiles
            notes = exercise.notes
            scheduledDate = exercise.scheduledDate
            isRepeating = exercise.isRepeating
        } else {
            scheduledDate = defaultDate
        }
    }

    /// Saves the exercise (creates new or updates existing).
    private func save() {
        let durationSec = hours * 3600 + minutes * 60 + seconds
        let distanceMiles = useMetricUnits ? distance / 1.60934 : distance

        if let exercise {
            exercise.name = name
            exercise.type = type
            exercise.durationSeconds = durationSec
            exercise.distanceMiles = distanceMiles
            exercise.notes = notes
            exercise.scheduledDate = scheduledDate.startOfDay
            exercise.isRepeating = isRepeating
        } else {
            let newExercise = Exercise(
                name: name,
                type: type,
                durationSeconds: durationSec,
                distanceMiles: distanceMiles,
                notes: notes,
                scheduledDate: scheduledDate,
                isRepeating: isRepeating
            )
            modelContext.insert(newExercise)
        }
        dismiss()
    }
}

#Preview {
    AddExerciseSheet(exercise: nil, defaultDate: Date())
        .modelContainer(ModelContainerFactory.makePreviewContainer())
}
