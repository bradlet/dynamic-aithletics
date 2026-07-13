//
//  UserExerciseFormSheet.swift
//  Hybrid AIthletics
//
//  Form for creating a user's own exercise library entry, with the same
//  fields bundled catalog entries carry: name, description, primary and
//  secondary muscle groups, equipment, and difficulty. Saved entries persist
//  as `UserLibraryExercise` models and surface in the library through
//  `UserLocalExerciseLibraryProvider`.
//

import SwiftUI
import SwiftData

/// Sheet for creating a new `UserLibraryExercise`.
struct UserExerciseFormSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name: String = ""
    @State private var details: String = ""
    @State private var muscleGroup: MuscleGroup = .other
    @State private var secondaryMuscleGroups: Set<MuscleGroup> = []
    @State private var equipment: String = ""
    @State private var difficulty: String = "Beginner"

    /// Difficulty labels matching the bundled catalog's values.
    private static let difficulties = ["Beginner", "Intermediate", "Advanced"]

    /// Whether the form can be saved.
    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Exercise") {
                    TextField("Name", text: $name)
                        .accessibilityIdentifier("userExerciseForm.name")
                    TextField("Description", text: $details, axis: .vertical)
                        .lineLimit(2...4)
                        .accessibilityIdentifier("userExerciseForm.details")
                }
                Section("Muscle Group") {
                    Picker("Muscle Group", selection: $muscleGroup) {
                        ForEach(MuscleGroup.allCases) { group in
                            Text(group.rawValue).tag(group)
                        }
                    }
                    .accessibilityIdentifier("userExerciseForm.muscleGroup")
                }
                Section {
                    ForEach(MuscleGroup.allCases.filter { $0 != muscleGroup }) { group in
                        Button {
                            toggleSecondary(group)
                        } label: {
                            HStack {
                                Text(group.rawValue)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if secondaryMuscleGroups.contains(group) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.tint)
                                }
                            }
                        }
                        .accessibilityIdentifier("userExerciseForm.secondary.\(group.rawValue)")
                    }
                } header: {
                    Text("Also Works")
                } footer: {
                    Text("Optional secondary muscle groups this exercise also targets.")
                }
                Section("Details") {
                    TextField("Equipment", text: $equipment)
                        .accessibilityIdentifier("userExerciseForm.equipment")
                    Picker("Difficulty", selection: $difficulty) {
                        ForEach(Self.difficulties, id: \.self) { level in
                            Text(level).tag(level)
                        }
                    }
                    .accessibilityIdentifier("userExerciseForm.difficulty")
                }
            }
            .navigationTitle("New Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                        .accessibilityIdentifier("userExerciseForm.save")
                }
            }
        }
    }

    /// Adds or removes a group from the secondary selection.
    private func toggleSecondary(_ group: MuscleGroup) {
        if secondaryMuscleGroups.contains(group) {
            secondaryMuscleGroups.remove(group)
        } else {
            secondaryMuscleGroups.insert(group)
        }
    }

    /// Inserts the new entry and saves the context so the library's provider
    /// (which reads through a fresh context) sees it on reload, then dismisses.
    private func save() {
        guard let exercise = UserLibraryEditor.makeExercise(
            name: name,
            details: details,
            muscleGroup: muscleGroup,
            secondaryMuscleGroups: MuscleGroup.allCases.filter { secondaryMuscleGroups.contains($0) && $0 != muscleGroup },
            equipment: equipment,
            difficulty: difficulty
        ) else { return }
        modelContext.insert(exercise)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Editor

/// Owns the user-library mutation path so it can be unit-tested without a
/// view (same pattern as `WorkoutEditor`).
enum UserLibraryEditor {
    /// Builds a user library entry from trimmed form input.
    /// - Returns: The new model, or `nil` when the trimmed name is empty.
    static func makeExercise(
        name: String,
        details: String,
        muscleGroup: MuscleGroup,
        secondaryMuscleGroups: [MuscleGroup],
        equipment: String,
        difficulty: String
    ) -> UserLibraryExercise? {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return nil }
        return UserLibraryExercise(
            name: trimmedName,
            details: details.trimmingCharacters(in: .whitespacesAndNewlines),
            muscleGroup: muscleGroup,
            secondaryMuscleGroups: secondaryMuscleGroups,
            equipment: equipment.trimmingCharacters(in: .whitespacesAndNewlines),
            difficulty: difficulty
        )
    }

    /// Deletes the user entry with the given library id and saves. A no-op
    /// for ids without the user prefix (bundled entries are not deletable).
    /// - Parameters:
    ///   - entryID: The `LibraryExercise.id` of the entry to delete.
    ///   - context: The context to delete from.
    static func delete(entryID: String, in context: ModelContext) throws {
        guard entryID.hasPrefix(UserLibraryExercise.idPrefix) else { return }
        let descriptor = FetchDescriptor<UserLibraryExercise>(
            predicate: #Predicate { $0.id == entryID }
        )
        for exercise in try context.fetch(descriptor) {
            context.delete(exercise)
        }
        try context.save()
    }
}

#Preview {
    UserExerciseFormSheet()
        .modelContainer(ModelContainerFactory.makePreviewContainer())
}
