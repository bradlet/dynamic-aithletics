//
//  StrengthTrainingView.swift
//  Hybrid AIthletics
//
//  Top-level view for the Strength tab: a kanban-style weekly board. One
//  column per day (Sunday-Saturday), swipeable left/right like a project
//  management board. Each column has the day's active plan plus a lower
//  "offloaded" section for exercises kept in mind but out of the week's plan.
//  Exercises are undated; recorded weights (`StrengthWorkout`) carry dates.
//

import SwiftUI
import SwiftData

/// The strength training tab displaying the weekly kanban board.
struct StrengthTrainingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allExercises: [StrengthExercise]

    /// The day column currently shown (Sunday=0 ... Saturday=6).
    @State private var selectedDay: Int = Date().weekdayIndex
    /// Whether the exercise library sheet is presented.
    @State private var showLibrary = false
    /// The exercise a weight is being recorded against (nil = sheet hidden).
    @State private var recordingExercise: StrengthExercise?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                dayStrip
                Divider()
                TabView(selection: $selectedDay) {
                    ForEach(0..<7, id: \.self) { dayIndex in
                        StrengthDayColumn(
                            dayIndex: dayIndex,
                            allExercises: allExercises,
                            onRecord: { recordingExercise = $0 },
                            onAddExercise: { showLibrary = true },
                            onDrop: { id, offloaded, target in
                                handleDrop(id: id, day: dayIndex, offloaded: offloaded, target: target)
                            },
                            onMoveToDay: { exercise, day in
                                moveToDay(exercise, day: day)
                            },
                            onDelete: { exercise in
                                withAnimation { modelContext.delete(exercise) }
                            }
                        )
                        .tag(dayIndex)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("Strength")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showLibrary = true
                    } label: {
                        Label("Exercise Library", systemImage: "books.vertical")
                    }
                    .accessibilityIdentifier("strength.libraryButton")
                }
            }
            .sheet(isPresented: $showLibrary) {
                ExerciseLibrarySheet(provider: .withUserLibrary(container: modelContext.container)) { entry in
                    addFromLibrary(entry)
                }
            }
            .sheet(item: $recordingExercise) { exercise in
                RecordStrengthWorkoutSheet(exercise: exercise)
            }
        }
    }

    // MARK: - Day Strip

    /// Tappable Sun-Sat chips above the board. Each chip is also a drop
    /// target, so a card can be dragged onto a chip to move it to that day.
    private var dayStrip: some View {
        HStack(spacing: 4) {
            ForEach(0..<7, id: \.self) { dayIndex in
                dayChip(dayIndex)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    /// One day chip with the short weekday name and planned-exercise count.
    private func dayChip(_ dayIndex: Int) -> some View {
        let isSelected = selectedDay == dayIndex
        let isToday = Date().weekdayIndex == dayIndex
        let count = StrengthBoardPlanner.lane(allExercises, day: dayIndex, offloaded: false).count
        return Button {
            withAnimation { selectedDay = dayIndex }
        } label: {
            VStack(spacing: 2) {
                Text(Calendar.current.shortWeekdaySymbols[dayIndex])
                    .font(.caption.bold())
                Text("\(count)")
                    .font(.caption2)
                    .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue : (isToday ? Color.blue.opacity(0.12) : Color.gray.opacity(0.08)))
            )
            .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("strength.dayChip.\(dayIndex)")
        // Dragging a card onto a chip moves it to the end of that day's plan.
        // The board deliberately stays on the day the user is viewing — the
        // chip's count updating is the confirmation that the move landed.
        .dropDestination(for: StrengthExerciseDragItem.self) { items, _ in
            guard let item = items.first else { return false }
            handleDrop(id: item.exerciseID, day: dayIndex, offloaded: false, target: nil)
            return true
        }
    }

    // MARK: - Board Mutations

    /// Adds a library entry to the end of the selected day's active plan.
    private func addFromLibrary(_ entry: LibraryExercise) {
        let exercise = StrengthExercise(
            name: entry.name,
            libraryExerciseID: entry.id,
            muscleGroup: entry.muscleGroup,
            weekdayIndex: selectedDay,
            sortOrder: StrengthBoardPlanner.nextSortOrder(allExercises, day: selectedDay, offloaded: false)
        )
        withAnimation { modelContext.insert(exercise) }
    }

    /// Resolves a dropped card ID and moves it via the board planner.
    private func handleDrop(id: UUID, day: Int, offloaded: Bool, target: StrengthExercise?) {
        guard let moving = allExercises.first(where: { $0.id == id }) else { return }
        withAnimation {
            StrengthBoardPlanner.move(moving, toDay: day, offloaded: offloaded, before: target, in: allExercises)
        }
    }

    /// Context-menu move: appends the exercise to the target day's active plan.
    /// Like a drag onto a day chip, this leaves the board on the current day
    /// rather than following the exercise.
    private func moveToDay(_ exercise: StrengthExercise, day: Int) {
        withAnimation {
            StrengthBoardPlanner.move(exercise, toDay: day, offloaded: false, before: nil, in: allExercises)
        }
    }
}

#Preview {
    StrengthTrainingView()
        .modelContainer(ModelContainerFactory.makePreviewContainer())
}
