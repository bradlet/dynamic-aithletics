//
//  WeeklyCalendarView.swift
//  Hybrid AIthletics
//
//  Renders 7 day swimlanes (Mon-Sun) for the selected week.
//  Each lane shows exercises for that day and accepts drops for rescheduling.
//  Supports virtual repeating exercises that are materialized on interaction.
//

import SwiftUI
import SwiftData

/// A weekly view with vertical swimlanes for each day, showing planned exercises.
struct WeeklyCalendarView: View {
    /// The 7 dates (Mon-Sun) for the displayed week.
    let days: [Date]
    /// Exercises for the current week, including virtual repeating exercises (pre-filtered by parent).
    let exercises: [Exercise]
    /// Workouts recorded this week (pre-filtered by parent).
    let workouts: [Workout]
    /// Called when the user taps + on a specific day.
    let onAdd: (Date) -> Void
    /// Called when the user taps an exercise to record it.
    let onRecord: (Exercise) -> Void
    /// Called when the user wants to edit an exercise.
    let onEdit: (Exercise) -> Void

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                ForEach(days, id: \.self) { day in
                    DaySwimlane(
                        day: day,
                        exercises: exercisesForDay(day),
                        hasWorkoutsRecorded: { exercise in
                            hasRecordedWorkout(for: exercise)
                        },
                        onAdd: { onAdd(day) },
                        onRecord: { exercise in
                            let target = materializeIfNeeded(exercise, for: day)
                            onRecord(target)
                        },
                        onEdit: { exercise in
                            let target = materializeIfNeeded(exercise, for: day)
                            onEdit(target)
                        },
                        onDrop: { exerciseID in
                            rescheduleExercise(id: exerciseID, to: day)
                        }
                    )
                    if day != days.last {
                        Divider()
                    }
                }
            }
        }
    }

    /// Returns exercises scheduled for the given day, including virtual repeating exercises.
    private func exercisesForDay(_ day: Date) -> [Exercise] {
        exercises.filter { exercise in
            exercise.scheduledDate.isSameDay(as: day)
            || (exercise.isRepeating && exercise.scheduledDate.mondayBasedWeekdayIndex == day.mondayBasedWeekdayIndex)
        }
    }

    /// Returns true if the exercise is a virtual repeating instance (template from another week).
    private func isVirtual(_ exercise: Exercise) -> Bool {
        exercise.isRepeating && !days.contains(where: { exercise.scheduledDate.isSameDay(as: $0) })
    }

    /// Materializes a virtual repeating exercise into a concrete instance for the given day. Returns the original if already concrete.
    @discardableResult
    private func materializeIfNeeded(_ exercise: Exercise, for day: Date) -> Exercise {
        guard isVirtual(exercise) else { return exercise }
        let concrete = Exercise(
            name: exercise.name,
            type: exercise.type,
            durationSeconds: exercise.durationSeconds,
            distanceMiles: exercise.distanceMiles,
            notes: exercise.notes,
            scheduledDate: day,
            isRepeating: false
        )
        modelContext.insert(concrete)
        return concrete
    }

    /// Checks whether any workout has been recorded for this exercise this week.
    private func hasRecordedWorkout(for exercise: Exercise) -> Bool {
        workouts.contains { $0.sourceExercise == exercise }
    }

    /// Moves an exercise to a new day by updating its scheduledDate. Materializes virtual exercises first.
    private func rescheduleExercise(id: UUID, to day: Date) {
        guard let exercise = exercises.first(where: { $0.id == id }) else { return }
        if isVirtual(exercise) {
            materializeIfNeeded(exercise, for: day)
        } else {
            withAnimation {
                exercise.scheduledDate = day.startOfDay
            }
        }
    }
}

/// A single day's swimlane showing its label, exercises, and add button.
private struct DaySwimlane: View {
    let day: Date
    let exercises: [Exercise]
    /// Closure that checks if a given exercise has a recorded workout.
    let hasWorkoutsRecorded: (Exercise) -> Bool
    let onAdd: () -> Void
    let onRecord: (Exercise) -> Void
    let onEdit: (Exercise) -> Void
    let onDrop: (UUID) -> Void

    /// Whether this swimlane is for today.
    private var isToday: Bool { day.isSameDay(as: Date()) }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            dayHeader
            exerciseList
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(isToday ? Color.blue.opacity(0.05) : Color.clear)
        .dropDestination(for: ExerciseDragItem.self) { items, _ in
            guard let item = items.first else { return false }
            onDrop(item.exerciseID)
            return true
        }
    }

    /// Day label with short weekday, date number, and add button.
    private var dayHeader: some View {
        HStack {
            Text(day.shortWeekdayName)
                .font(.caption.bold())
                .foregroundStyle(isToday ? .blue : .primary)
            Text(day, format: .dateTime.month(.abbreviated).day())
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Button(action: onAdd) {
                Image(systemName: "plus.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.blue)
            }
        }
    }

    /// List of exercise cards for this day.
    private var exerciseList: some View {
        ForEach(exercises) { exercise in
            HStack(spacing: 4) {
                ExerciseCardView(
                    exercise: exercise,
                    onRecord: { onRecord(exercise) },
                    onEdit: { onEdit(exercise) }
                )
                // Checkmark indicator if a workout has been recorded.
                if hasWorkoutsRecorded(exercise) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                }
            }
        }
    }
}

#Preview {
    let days = Date().daysInWeek()
    WeeklyCalendarView(
        days: days,
        exercises: [],
        workouts: [],
        onAdd: { _ in },
        onRecord: { _ in },
        onEdit: { _ in }
    )
    .modelContainer(ModelContainerFactory.makePreviewContainer())
}
