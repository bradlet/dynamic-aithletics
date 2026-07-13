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
    @State private var distance: Double?
    @State private var notes = ""
    @State private var scheduledDate: Date
    @State private var isRepeating = false
    @State private var countsTowardMileage = true

    init(exercise: Exercise?, defaultDate: Date) {
        self.exercise = exercise
        self.defaultDate = defaultDate
        _scheduledDate = State(initialValue: defaultDate)
    }

    /// Whether the form has enough data to save.
    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
        && (distance ?? 0) > 0
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
            .navigationTitle(exercise == nil ? "Schedule Exercise" : "Edit Exercise")
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

    // MARK: - Form Sections

    /// Exercise type picker and name field (type first, name secondary).
    private var nameAndTypeSection: some View {
        Section {
            Picker("Type", selection: $type) {
                ForEach(ExerciseType.allCases) { exerciseType in
                    Label(exerciseType.rawValue, systemImage: exerciseType.systemImage)
                        .tag(exerciseType)
                }
            }
            TextField("Exercise name", text: $name)
                .foregroundStyle(name == type.rawValue ? .secondary : .primary)
        }
    }

    /// Duration pickers for hours, minutes, seconds.
    private var durationSection: some View {
        Section("Duration") {
            DurationWheelPickers(hours: $hours, minutes: $minutes, seconds: $seconds)
        }
    }

    /// Distance input field and mileage-counting toggle.
    private var distanceSection: some View {
        Section {
            HStack {
                TextField("0.0", value: $distance, format: .number.precision(.fractionLength(1)))
                    .keyboardType(.decimalPad)
                Text(useMetricUnits ? "km" : "mi")
                    .foregroundStyle(.secondary)
            }
            Toggle("Counts Toward Mileage", isOn: $countsTowardMileage)
                .accessibilityIdentifier("workoutForm.countsTowardMileageToggle")
        } header: {
            Text("Distance")
        } footer: {
            if !countsTowardMileage {
                Text("Distance is tracked but excluded from mileage totals.")
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
            // Leave the field empty (placeholder) when there is no target
            // distance rather than pre-filling a literal 0.0.
            if exercise.distanceMiles > 0 {
                distance = useMetricUnits ? exercise.distanceMiles.toDisplayDistance(metric: true) : exercise.distanceMiles
            }
            notes = exercise.notes
            scheduledDate = exercise.date
            isRepeating = exercise.isRepeating
            countsTowardMileage = exercise.countsTowardMileage
        } else {
            name = type.rawValue
            scheduledDate = defaultDate
        }
    }

    /// Saves the exercise (creates new or updates existing).
    private func save() {
        let durationSec = hours * 3600 + minutes * 60 + seconds
        let distanceMiles = useMetricUnits ? (distance ?? 0) / 1.60934 : (distance ?? 0)

        if let exercise {
            exercise.name = name
            exercise.type = type
            exercise.durationSeconds = durationSec
            exercise.distanceMiles = distanceMiles
            exercise.notes = notes
            exercise.date = scheduledDate.startOfDay
            exercise.isRepeating = isRepeating
            exercise.countsTowardMileage = countsTowardMileage
        } else {
            let newExercise = Exercise(
                name: name,
                type: type,
                durationSeconds: durationSec,
                distanceMiles: distanceMiles,
                notes: notes,
                date: scheduledDate,
                isRepeating: isRepeating,
                countsTowardMileage: countsTowardMileage
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
