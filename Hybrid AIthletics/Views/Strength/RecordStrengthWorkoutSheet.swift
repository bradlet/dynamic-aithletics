//
//  RecordStrengthWorkoutSheet.swift
//  Hybrid AIthletics
//
//  Form for recording a weight entry against a strength exercise: the date,
//  the weight lifted, and what kind of measurement the weight represents
//  (max / average / first set / last set / min).
//

import SwiftUI
import SwiftData

/// Sheet for recording a `StrengthWorkout` on a `StrengthExercise`.
struct RecordStrengthWorkoutSheet: View {
    /// The exercise being recorded against.
    let exercise: StrengthExercise

    @Environment(\.dismiss) private var dismiss
    @Environment(\.useMetricUnits) private var useMetricUnits

    @State private var date: Date = Date()
    @State private var weightText: String = ""
    @State private var recordingType: WeightRecordingType = .maxWeight
    @State private var notes: String = ""

    /// The entered weight parsed into display units, if valid.
    private var enteredWeight: Double? {
        Double(weightText.replacingOccurrences(of: ",", with: "."))
    }

    /// Whether the form can be saved.
    private var canSave: Bool {
        (enteredWeight ?? 0) > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("Exercise", value: exercise.name)
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                } header: {
                    Text("Workout")
                }
                Section {
                    HStack {
                        TextField("Weight", text: $weightText)
                            .keyboardType(.decimalPad)
                            .accessibilityIdentifier("recordStrength.weightField")
                        Text(useMetricUnits ? "kg" : "lb")
                            .foregroundStyle(.secondary)
                    }
                    Picker("Measurement", selection: $recordingType) {
                        ForEach(WeightRecordingType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .accessibilityIdentifier("recordStrength.typePicker")
                } header: {
                    Text("Weight")
                } footer: {
                    Text("Choose what the weight represents so trends like 1-rep max and average working weight can be tracked separately.")
                }
                Section("Notes") {
                    TextField("Optional notes", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Record Weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                        .accessibilityIdentifier("recordStrength.save")
                }
            }
        }
    }

    /// Appends the new workout record to the exercise and dismisses.
    private func save() {
        guard let displayWeight = enteredWeight else { return }
        let workout = StrengthWorkout(
            date: date,
            weightPounds: displayWeight.fromDisplayWeight(metric: useMetricUnits),
            recordingType: recordingType,
            notes: notes
        )
        exercise.workouts = exercise.workouts + [workout]
        dismiss()
    }
}

#Preview {
    RecordStrengthWorkoutSheet(
        exercise: StrengthExercise(name: "Back Squat", muscleGroup: .quads)
    )
    .modelContainer(ModelContainerFactory.makePreviewContainer())
}
