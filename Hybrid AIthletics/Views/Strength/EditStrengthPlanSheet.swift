//
//  EditStrengthPlanSheet.swift
//  Hybrid AIthletics
//
//  Small sheet for setting an exercise's planned set structure (e.g. 3 sets
//  of 8 reps). This is plan-only data the user keeps in mind through the
//  week — it never touches the recorded `StrengthWorkout` history.
//

import SwiftUI
import SwiftData

/// Sheet for editing a `StrengthExercise`'s planned sets × reps.
struct EditStrengthPlanSheet: View {
    /// The exercise whose plan is being edited.
    let exercise: StrengthExercise

    @Environment(\.dismiss) private var dismiss

    @State private var sets: Int
    @State private var reps: Int

    /// Creates the sheet, seeding the steppers from the existing plan or a
    /// common 3×8 default.
    /// - Parameter exercise: The exercise whose plan is being edited.
    init(exercise: StrengthExercise) {
        self.exercise = exercise
        _sets = State(initialValue: exercise.plannedSets ?? 3)
        _reps = State(initialValue: exercise.plannedReps ?? 8)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Stepper("Sets: \(sets)", value: $sets, in: 1...20)
                        .accessibilityIdentifier("editPlan.setsStepper")
                    Stepper("Reps: \(reps)", value: $reps, in: 1...100)
                        .accessibilityIdentifier("editPlan.repsStepper")
                } header: {
                    Text("Planned Sets × Reps")
                } footer: {
                    Text("A reminder of your set structure for the week. Not stored with recorded weights.")
                }
                if exercise.plannedSummary != nil {
                    Section {
                        Button("Clear Plan", role: .destructive) {
                            exercise.plannedSets = nil
                            exercise.plannedReps = nil
                            dismiss()
                        }
                        .accessibilityIdentifier("editPlan.clear")
                    }
                }
            }
            .navigationTitle(exercise.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        exercise.plannedSets = sets
                        exercise.plannedReps = reps
                        dismiss()
                    }
                    .accessibilityIdentifier("editPlan.save")
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    EditStrengthPlanSheet(
        exercise: StrengthExercise(name: "Back Squat", muscleGroup: .quads, plannedSets: 3, plannedReps: 8)
    )
    .modelContainer(ModelContainerFactory.makePreviewContainer())
}
