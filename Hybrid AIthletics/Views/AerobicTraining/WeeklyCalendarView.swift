//
//  WeeklyCalendarView.swift
//  Hybrid AIthletics
//
//  Renders 7 day swimlanes for the selected week, ordered by the caller
//  (top day = the user's configured week start).
//  Each lane shows exercises for that day and accepts drops for rescheduling.
//

import SwiftUI
import SwiftData

/// Navigation request to highlight a specific day in the weekly view.
struct ExerciseNavigationRequest: Equatable, Identifiable {
    let id: UUID
    let targetDate: Date

    init(targetDate: Date) {
        self.id = UUID()
        self.targetDate = targetDate
    }
}

/// A weekly view with vertical swimlanes for each day, showing planned exercises.
struct WeeklyCalendarView: View {
    /// The 7 dates for the displayed week, in display order (first = week start).
    let days: [Date]
    /// Exercises for the current week (pre-filtered by parent).
    let exercises: [Exercise]
    /// Called when the user taps the schedule button on a specific day.
    let onAdd: (Date) -> Void
    /// Called when the user taps the quick-add button on a specific day.
    let onQuickAdd: (Date) -> Void
    /// Called when the user taps an exercise to record it.
    let onRecord: (Exercise) -> Void
    /// Called when the user wants to edit an exercise.
    let onEdit: (Exercise) -> Void
    /// Optional navigation request to highlight a specific day.
    let navigationRequest: ExerciseNavigationRequest?

    @Environment(\.modelContext) private var modelContext
    /// Tracks which exercise card is currently showing the swipe-to-delete button.
    @State private var swipeDeleteActiveID: UUID?

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
                        onQuickAdd: { onQuickAdd(day) },
                        onRecord: onRecord,
                        onEdit: onEdit,
                        onDrop: { exerciseID in
                            rescheduleExercise(id: exerciseID, to: day)
                        },
                        isHighlighted: navigationRequest?.targetDate.isSameDay(as: day) == true,
                        swipeDeleteActiveID: $swipeDeleteActiveID
                    )
                    if day != days.last {
                        Divider()
                    }
                }
            }
        }
        .simultaneousGesture(
            TapGesture().onEnded {
                if swipeDeleteActiveID != nil {
                    withAnimation(.spring(response: 0.3)) {
                        swipeDeleteActiveID = nil
                    }
                }
            }
        )
    }

    /// Returns exercises scheduled for the given day.
    private func exercisesForDay(_ day: Date) -> [Exercise] {
        exercises.filter { $0.date.isSameDay(as: day) }
    }

    /// Checks whether this exercise has been recorded.
    private func hasRecordedWorkout(for exercise: Exercise) -> Bool {
        exercise.isCompleted
    }

    /// Moves an exercise to a new day by updating its date.
    private func rescheduleExercise(id: UUID, to day: Date) {
        guard let exercise = exercises.first(where: { $0.id == id }) else { return }
        withAnimation {
            exercise.date = day.startOfDay
        }
    }

    /// Stable "yyyy-MM-dd" identifier for accessibility.
    private static let dayIdentifierFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    static func dayID(_ day: Date) -> String {
        dayIdentifierFormatter.string(from: day)
    }
}

/// A single day's swimlane showing its label, exercises, and action buttons.
private struct DaySwimlane: View {
    let day: Date
    let exercises: [Exercise]
    /// Closure that checks if a given exercise has a recorded workout.
    let hasWorkoutsRecorded: (Exercise) -> Bool
    let onAdd: () -> Void
    let onQuickAdd: () -> Void
    let onRecord: (Exercise) -> Void
    let onEdit: (Exercise) -> Void
    let onDrop: (UUID) -> Void
    let isHighlighted: Bool
    /// Binding to the ID of the exercise card currently showing its delete button.
    @Binding var swipeDeleteActiveID: UUID?

    /// Whether this swimlane is for today.
    private var isToday: Bool { day.isSameDay(as: Date()) }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            dayHeader
            exerciseList
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .frame(minHeight: 30, alignment: .top)
        .background(
            isHighlighted
                ? Color.accentColor.opacity(0.12)
                : (isToday ? Color.blue.opacity(0.05) : Color.clear)
        )
        .contentShape(Rectangle())
        .accessibilityIdentifier("daySwimlane.\(WeeklyCalendarView.dayID(day))")
        .dropDestination(for: ExerciseDragItem.self) { items, _ in
            guard let item = items.first else { return false }
            onDrop(item.exerciseID)
            return true
        }
    }

    /// Day label with short weekday, date number, and action buttons. Also a drop target.
    private var dayHeader: some View {
        HStack {
            Text(day.shortWeekdayName)
                .font(.caption.bold())
                .foregroundStyle(isToday ? .blue : .primary)
            Text(day, format: .dateTime.month(.abbreviated).day())
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            HStack(spacing: 12) {
                Button(action: onQuickAdd) {
                    Image(systemName: "plus.circle.fill")
                        .font(.body)
                        .foregroundStyle(.green)
                }
                .accessibilityLabel("Quick add workout")
                .accessibilityIdentifier("daySwimlane.quickAdd.\(WeeklyCalendarView.dayID(day))")
                Button(action: onAdd) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.body)
                        .foregroundStyle(.blue)
                }
                .accessibilityLabel("Schedule exercise")
                .accessibilityIdentifier("daySwimlane.schedule.\(WeeklyCalendarView.dayID(day))")
            }
        }
        .contentShape(Rectangle())
        .dropDestination(for: ExerciseDragItem.self) { items, _ in
            guard let item = items.first else { return false }
            onDrop(item.exerciseID)
            return true
        }
    }

    /// List of exercise cards for this day. Completion is signaled by the
    /// card's diagonal completed/planned split rather than a checkmark.
    private var exerciseList: some View {
        ForEach(exercises) { exercise in
            ExerciseCardView(
                exercise: exercise,
                onRecord: { onRecord(exercise) },
                onEdit: { onEdit(exercise) },
                hasRecordedWorkout: hasWorkoutsRecorded(exercise),
                swipeDeleteActiveID: $swipeDeleteActiveID
            )
        }
    }
}

#Preview {
    let days = Date().daysInWeek()
    WeeklyCalendarView(
        days: days,
        exercises: [],
        onAdd: { _ in },
        onQuickAdd: { _ in },
        onRecord: { _ in },
        onEdit: { _ in },
        navigationRequest: nil
    )
    .modelContainer(ModelContainerFactory.makePreviewContainer())
}
