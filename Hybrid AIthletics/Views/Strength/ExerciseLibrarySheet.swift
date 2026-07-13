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
    @Environment(\.modelContext) private var modelContext
    @State private var exercises: [LibraryExercise] = []
    @State private var searchText: String = ""
    @State private var loadFailed = false
    @State private var showCreateForm = false

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
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCreateForm = true
                    } label: {
                        Label("New Exercise", systemImage: "plus")
                    }
                    .accessibilityIdentifier("exerciseLibrary.create")
                }
            }
            .sheet(isPresented: $showCreateForm, onDismiss: { Task { await load() } }) {
                UserExerciseFormSheet()
            }
        }
        .task { await load() }
    }

    /// Loads (or reloads) the library entries from the provider.
    private func load() async {
        do {
            exercises = try await provider.loadExercises()
            loadFailed = exercises.isEmpty
        } catch {
            loadFailed = true
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
                        .swipeActions(edge: .trailing) {
                            if entry.isUserCreated {
                                Button(role: .destructive) {
                                    deleteUserEntry(entry)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
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

    /// Deletes a user-created entry from the store and reloads the list.
    private func deleteUserEntry(_ entry: LibraryExercise) {
        try? UserLibraryEditor.delete(entryID: entry.id, in: modelContext)
        Task { await load() }
    }

    /// A single library row: name, equipment, and difficulty, plus a
    /// "Custom" tag on user-created entries.
    private func libraryRow(_ entry: LibraryExercise) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Text(entry.name)
                    .font(.subheadline.bold())
                if entry.isUserCreated {
                    Text("Custom")
                        .font(.caption2.bold())
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(.tint.opacity(0.15))
                        .foregroundStyle(.tint)
                        .clipShape(Capsule())
                }
            }
            HStack(spacing: 6) {
                if !entry.equipment.isEmpty {
                    Text(entry.equipment)
                    Text("·")
                }
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
