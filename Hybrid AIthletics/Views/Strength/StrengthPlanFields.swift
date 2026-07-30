//
//  StrengthPlanFields.swift
//  Hybrid AIthletics
//
//  The planned sets × reps editor, shared by the two flows that can set a
//  plan: adding an exercise from the library (`LibraryExerciseDetailView`)
//  and editing an existing card's plan (`EditStrengthPlanSheet`). Keeping one
//  component means the add flow always has parity with the edit flow.
//
//  `StrengthPlanDraft` holds the in-flight form state and owns the mapping
//  back onto `StrengthExercise.plannedSets` / `plannedReps`, so the mutation
//  path is unit-testable without a view (same pattern as `WorkoutEditor`).
//

import SwiftUI

// MARK: - Draft

/// Editable state for an exercise's planned set structure.
///
/// A plan exists only when *both* sets and reps are set; `isPlanned == false`
/// maps back to `nil` for both stored fields. The steppers keep their last
/// values while the plan is switched off so toggling doesn't lose them.
struct StrengthPlanDraft: Equatable, Sendable {
    /// Sets a newly planned exercise starts on.
    static let defaultSets = 3
    /// Reps a newly planned exercise starts on.
    static let defaultReps = 8
    /// Allowed stepper range for sets.
    static let setsRange = 1...20
    /// Allowed stepper range for reps.
    static let repsRange = 1...100

    /// Whether the exercise should carry a planned sets × reps at all.
    var isPlanned: Bool
    /// Planned number of sets (meaningful only when `isPlanned`).
    var sets: Int
    /// Planned reps per set (meaningful only when `isPlanned`).
    var reps: Int

    /// Creates a draft with the plan switched on.
    /// - Parameters:
    ///   - sets: Starting sets value.
    ///   - reps: Starting reps value.
    init(sets: Int = StrengthPlanDraft.defaultSets, reps: Int = StrengthPlanDraft.defaultReps) {
        self.isPlanned = true
        self.sets = sets
        self.reps = reps
    }

    /// Seeds a draft from an exercise's stored plan. The plan reads as absent
    /// unless both values are stored, in which case the steppers start on the
    /// shared defaults.
    /// - Parameters:
    ///   - plannedSets: Stored planned sets, if any.
    ///   - plannedReps: Stored planned reps, if any.
    init(plannedSets: Int?, plannedReps: Int?) {
        self.isPlanned = plannedSets != nil && plannedReps != nil
        self.sets = plannedSets ?? Self.defaultSets
        self.reps = plannedReps ?? Self.defaultReps
    }

    /// The value to store in `StrengthExercise.plannedSets`.
    var plannedSets: Int? { isPlanned ? sets : nil }

    /// The value to store in `StrengthExercise.plannedReps`.
    var plannedReps: Int? { isPlanned ? reps : nil }

    /// Compact badge text for the drafted plan, e.g. "3×8", or `nil` when the
    /// plan is switched off. Mirrors `StrengthExercise.plannedSummary`.
    var summary: String? {
        guard isPlanned else { return nil }
        return "\(sets)×\(reps)"
    }

    /// Writes the draft onto an exercise's plan fields.
    /// - Parameter exercise: The exercise to update.
    func apply(to exercise: StrengthExercise) {
        exercise.plannedSets = plannedSets
        exercise.plannedReps = plannedReps
    }
}

// MARK: - Fields

/// Form section with the plan toggle and the sets/reps steppers. Must be used
/// inside a `Form` or `List`.
struct StrengthPlanFields: View {
    /// The draft being edited.
    @Binding var draft: StrengthPlanDraft

    var body: some View {
        Section {
            Toggle("Plan Sets × Reps", isOn: $draft.isPlanned)
                .accessibilityIdentifier("planFields.toggle")
            if draft.isPlanned {
                Stepper("Sets: \(draft.sets)", value: $draft.sets, in: StrengthPlanDraft.setsRange)
                    .accessibilityIdentifier("planFields.setsStepper")
                Stepper("Reps: \(draft.reps)", value: $draft.reps, in: StrengthPlanDraft.repsRange)
                    .accessibilityIdentifier("planFields.repsStepper")
            }
        } header: {
            Text("Planned Sets × Reps")
        } footer: {
            Text("A reminder of your set structure for the week. Not stored with recorded weights.")
        }
    }
}

#Preview {
    @Previewable @State var draft = StrengthPlanDraft()
    Form {
        StrengthPlanFields(draft: $draft)
    }
}
