//
//  MonthlyCalendarView.swift
//  Hybrid AIthletics
//
//  A month-grid calendar that shows colored dots on days with recorded workouts.
//  Tapping a day with workouts shows a detail popover.
//

import SwiftUI
import SwiftData

/// Displays a monthly calendar grid with workout indicators and day-tap popovers.
struct MonthlyCalendarView: View {
    /// The month currently being displayed.
    @Binding var selectedMonth: Date
    /// All recorded workouts (filtered by caller or unfiltered).
    let workouts: [Workout]
    @Environment(\.useMetricUnits) private var useMetricUnits

    /// The day selected for the detail popover.
    @State private var selectedDay: Date?
    /// Whether the detail popover is showing.
    @State private var showPopover = false

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
        .popover(isPresented: $showPopover) {
            if let day = selectedDay {
                DayDetailPopover(
                    day: day,
                    workouts: workoutsForDay(day),
                    useMetricUnits: useMetricUnits
                )
                .presentationCompactAdaptation(.popover)
            }
        }
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
                .onTapGesture {
                    let dayWorkouts = workoutsForDay(day)
                    if !dayWorkouts.isEmpty {
                        selectedDay = day
                        showPopover = true
                    }
                }
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

/// Popover showing workout details for a selected day.
private struct DayDetailPopover: View {
    let day: Date
    let workouts: [Workout]
    let useMetricUnits: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(day, format: .dateTime.weekday(.wide).month(.abbreviated).day())
                .font(.headline)
            Divider()
            ForEach(workouts) { workout in
                HStack {
                    Image(systemName: workout.type.systemImage)
                        .foregroundStyle(workout.type.color)
                    VStack(alignment: .leading) {
                        Text(workout.name)
                            .font(.subheadline.bold())
                        Text("\(workout.distanceMiles.formattedDistance(metric: useMetricUnits)) - \(workout.durationSeconds.formattedDuration)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .frame(minWidth: 200)
    }
}

#Preview {
    MonthlyCalendarView(selectedMonth: .constant(Date()), workouts: [])
        .modelContainer(ModelContainerFactory.makePreviewContainer())
}
