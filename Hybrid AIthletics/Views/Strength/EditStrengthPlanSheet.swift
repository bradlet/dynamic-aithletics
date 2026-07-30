//
//  EditStrengthPlanSheet.swift
//  Hybrid AIthletics
//
//  Small sheet for setting an exercise's planned set structure (e.g. 3 sets
//  of 8 reps). This is plan-only data the user keeps in mind through the
//  week — it never touches the recorded `StrengthWorkout` history.
//
//  The fields come from `StrengthPlanFields`, shared with the add-from-library
//  flow so both surfaces stay identical.
//

import SwiftUI
import SwiftData

/// Sheet for editing a `StrengthExercise`'s planned sets × reps.
struct EditStrengthPlanSheet: View {
    /// The exercise whose plan is being edited.
    let exercise: StrengthExercise

    @Environment(\.dismiss) private var dismiss

    @State private var draft: StrengthPlanDraft

    /// Creates the sheet, seeding the draft from the existing plan (or a
    /// switched-off 3×8 when the exercise has no plan yet).
    /// - Parameter exercise: The exercise whose plan is being edited.
    init(exercise: StrengthExercise) {
        self.exercise = exercise
        _draft = State(
            initialValue: StrengthPlanDraft(
                plannedSets: exercise.plannedSets,
                plannedReps: exercise.plannedReps
            )
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                StrengthPlanFields(draft: $draft)
            }
            .navigationTitle(exercise.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        draft.apply(to: exercise)
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
