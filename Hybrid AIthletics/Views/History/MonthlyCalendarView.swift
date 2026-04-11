//
//  MonthlyCalendarView.swift
//  Hybrid AIthletics
//
//  A month-grid calendar that shows colored dots on days with recorded workouts.
//  Tapping a day with workouts invokes `onDayTap(day)` so the parent view can
//  navigate to that workout in the list below.
//

import SwiftUI
import SwiftData

/// Displays a monthly calendar grid with workout indicators.
///
/// Tapping a day that contains at least one workout invokes `onDayTap(day)`.
/// The parent (`HistoryView`) is responsible for translating that into a
/// `WorkoutNavigationRequest` for `WorkoutListView`.
struct MonthlyCalendarView: View {
    /// The month currently being displayed.
    @Binding var selectedMonth: Date
    /// All recorded workouts (filtered by caller or unfiltered).
    let workouts: [Workout]
    /// Invoked when the user taps a day that has at least one workout.
    let onDayTap: (Date) -> Void

    /// Weekday header labels.
    private let weekdayLabels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    /// Grid columns: 7 days.
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)

    var body: some View {
        VStack(spacing: 8) {
            monthHeader
            weekdayHeaderRow
            calendarGrid
        }
        .padding(.horizontal)
    }

    /// Header with month/year and navigation arrows.
    private var monthHeader: some View {
        HStack {
            Button { changeMonth(by: -1) } label: {
                Image(systemName: "chevron.left")
            }
            Spacer()
            Text(selectedMonth, format: .dateTime.month(.wide).year())
                .font(.headline)
            Spacer()
            Button { changeMonth(by: 1) } label: {
                Image(systemName: "chevron.right")
            }
        }
    }

    /// Row of weekday labels.
    private var weekdayHeaderRow: some View {
        LazyVGrid(columns: columns, spacing: 2) {
            ForEach(weekdayLabels, id: \.self) { label in
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    /// The grid of day cells for the current month.
    private var calendarGrid: some View {
        let days = selectedMonth.daysInMonth()
        let firstDayOffset = days.first?.mondayBasedWeekdayIndex ?? 0

        return LazyVGrid(columns: columns, spacing: 2) {
            // Empty cells for days before the month starts.
            ForEach(0..<firstDayOffset, id: \.self) { _ in
                Color.clear.frame(height: 40)
            }
            // Day cells.
            ForEach(days, id: \.self) { day in
                DayCell(
                    day: day,
                    workouts: workoutsForDay(day),
                    isToday: day.isSameDay(as: Date())
                )
                .contentShape(RoundedRectangle(cornerRadius: 6))
                .onTapGesture {
                    let dayWorkouts = workoutsForDay(day)
                    if !dayWorkouts.isEmpty {
                        onDayTap(day)
                    }
                }
                .accessibilityIdentifier("calendarDay.\(Self.dayIdentifier(for: day))")
            }
        }
    }

    /// Returns workouts that occurred on the given day.
    private func workoutsForDay(_ day: Date) -> [Workout] {
        workouts.filter { $0.date.isSameDay(as: day) }
    }

    /// Advances or rewinds the displayed month.
    private func changeMonth(by value: Int) {
        if let newMonth = Calendar.current.date(byAdding: .month, value: value, to: selectedMonth) {
            selectedMonth = newMonth
        }
    }

    /// Stable "yyyy-MM-dd" identifier for accessibility.
    private static let dayIdentifierFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private static func dayIdentifier(for day: Date) -> String {
        dayIdentifierFormatter.string(from: day)
    }
}

/// A single day cell in the monthly calendar grid.
private struct DayCell: View {
    let day: Date
    let workouts: [Workout]
    let isToday: Bool

    var body: some View {
        VStack(spacing: 2) {
            Text("\(Calendar.current.component(.day, from: day))")
                .font(.caption)
                .fontWeight(isToday ? .bold : .regular)
                .foregroundStyle(isToday ? .blue : .primary)
            // Colored dot if workouts exist on this day.
            if let firstWorkout = workouts.first {
                Circle()
                    .fill(firstWorkout.type.color)
                    .frame(width: 6, height: 6)
            } else {
                Circle()
                    .fill(.clear)
                    .frame(width: 6, height: 6)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 40)
        .background(
            isToday
                ? Color.blue.opacity(0.1)
                : Color.clear,
            in: RoundedRectangle(cornerRadius: 6)
        )
    }
}

#Preview {
    MonthlyCalendarView(
        selectedMonth: .constant(Date()),
        workouts: [],
        onDayTap: { _ in }
    )
    .modelContainer(ModelContainerFactory.makePreviewContainer())
}
