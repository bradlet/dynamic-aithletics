//
//  ExerciseLibrarySheet.swift
//  Hybrid AIthletics
//
//  Browsable strength exercise library. Entries load asynchronously through
//  the `ExerciseLibraryProvider` abstraction (bundled JSON today, mergeable
//  with a server-based catalog later). Searchable and grouped by muscle
//  group; tapping an entry shows details with an Add button.
//

import SwiftUI

/// Sheet presenting the exercise library for adding an exercise to a day.
struct ExerciseLibrarySheet: View {
    /// Source of library entries. Defaults to the app's composite provider.
    var provider: any ExerciseLibraryProvider = .default
    /// Called with the chosen entry; the caller creates the board exercise.
    let onSelect: (LibraryExercise) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var exercises: [LibraryExercise] = []
    @State private var searchText: String = ""
    @State private var loadFailed = false

    /// Entries matching the current search, grouped by primary muscle group.
    private var groupedExercises: [(group: MuscleGroup, entries: [LibraryExercise])] {
        let filtered = searchText.isEmpty ? exercises : exercises.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
            || $0.muscleGroup.rawValue.localizedCaseInsensitiveContains(searchText)
            || $0.equipment.localizedCaseInsensitiveContains(searchText)
        }
        return MuscleGroup.allCases.compactMap { group in
            let entries = filtered
                .filter { $0.muscleGroup == group }
                .sorted { $0.name < $1.name }
            return entries.isEmpty ? nil : (group, entries)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if loadFailed {
                    ContentUnavailableView(
                        "Library Unavailable",
                        systemImage: "exclamationmark.triangle",
                        description: Text("The exercise library could not be loaded.")
                    )
                } else if exercises.isEmpty {
                    ProgressView("Loading library…")
                } else {
                    libraryList
                }
            }
            .navigationTitle("Exercise Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .task {
            do {
                exercises = try await provider.loadExercises()
                loadFailed = exercises.isEmpty
            } catch {
                loadFailed = true
            }
        }
    }

    /// The searchable, muscle-group-sectioned list of library entries.
    private var libraryList: some View {
        List {
            ForEach(groupedExercises, id: \.group) { section in
                Section {
                    ForEach(section.entries) { entry in
                        NavigationLink {
                            LibraryExerciseDetailView(entry: entry) {
                                onSelect(entry)
                                dismiss()
                            }
                        } label: {
                            libraryRow(entry)
                        }
                    }
                } header: {
                    Label(section.group.rawValue, systemImage: "figure.strengthtraining.traditional")
                        .foregroundStyle(section.group.color)
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search exercises")
        .accessibilityIdentifier("exerciseLibrary.list")
    }

    /// A single library row: name, equipment, and difficulty.
    private func libraryRow(_ entry: LibraryExercise) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(entry.name)
                .font(.subheadline.bold())
            HStack(spacing: 6) {
                Text(entry.equipment)
                Text("·")
                Text(entry.difficulty)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Detail

/// Detail view for one library entry with an Add button.
struct LibraryExerciseDetailView: View {
    let entry: LibraryExercise
    /// Called when the user adds this exercise to their board.
    let onAdd: () -> Void

    var body: some View {
        List {
            Section("Description") {
                Text(entry.details)
            }
            Section("Details") {
                LabeledContent("Muscle Group", value: entry.muscleGroup.rawValue)
                if !entry.secondaryMuscleGroups.isEmpty {
                    LabeledContent(
                        "Also Works",
                        value: entry.secondaryMuscleGroups.map(\.rawValue).joined(separator: ", ")
                    )
                }
                LabeledContent("Equipment", value: entry.equipment)
                LabeledContent("Difficulty", value: entry.difficulty)
            }
            Section {
                Button {
                    onAdd()
                } label: {
                    Label("Add to This Day", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .accessibilityIdentifier("exerciseLibrary.add")
            }
        }
        .navigationTitle(entry.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ExerciseLibrarySheet(onSelect: { _ in })
}
