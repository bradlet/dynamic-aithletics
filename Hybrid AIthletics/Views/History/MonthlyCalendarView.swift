//
//  MonthlyCalendarView.swift
//  Hybrid AIthletics
//
//  A month-grid calendar that shows colored dots on days with activity.
//  Accepts any `CalendarDisplayable` items (workouts, exercises, or dots).
//  Tapping a day with items invokes `onDayTap(day)` so the parent can navigate.
//

import SwiftUI

/// Displays a monthly calendar grid with activity indicators.
///
/// Tapping any day invokes `onDayTap(day)`. The parent decides what
/// to do (navigate to an existing item, open a scheduling sheet, etc.).
struct MonthlyCalendarView: View {
    /// The month currently being displayed.
    @Binding var selectedMonth: Date
    /// Items to display as colored dots (workouts, exercises, or lightweight dots).
    let items: [any CalendarDisplayable]
    /// Invoked when the user taps any day in the calendar.
    let onDayTap: (Date) -> Void

    /// Weekday header labels.
    private let weekdayLabels = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    /// Grid columns: 7 days.
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)
    /// The edge new content slides in from during a swipe transition.
    @State private var slideEdge: Edge = .trailing

    var body: some View {
        VStack(spacing: 8) {
            monthHeader
            weekdayHeaderRow
            calendarGrid
                .id(selectedMonth.startOfMonth)
                .transition(.push(from: slideEdge))
        }
        .clipped()
        .padding(.horizontal)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 30)
                .onEnded { value in
                    let horizontal = value.translation.width
                    let vertical = value.translation.height
                    guard abs(horizontal) > abs(vertical), abs(horizontal) > 50 else { return }
                    if horizontal < 0 {
                        slideEdge = .trailing
                        withAnimation(.easeInOut(duration: 0.25)) {
                            changeMonth(by: 1)
                        }
                    } else {
                        slideEdge = .leading
                        withAnimation(.easeInOut(duration: 0.25)) {
                            changeMonth(by: -1)
                        }
                    }
                }
        )
    }

    /// Header with month/year and navigation arrows.
    private var monthHeader: some View {
        HStack {
            Button { navigateMonth(by: -1) } label: {
                Image(systemName: "chevron.left")
            }
            Spacer()
            Text(selectedMonth, format: .dateTime.month(.wide).year())
                .font(.headline)
            Spacer()
            Button { navigateMonth(by: 1) } label: {
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
        let firstDayOffset = days.first?.weekdayIndex ?? 0

        return LazyVGrid(columns: columns, spacing: 2) {
            // Empty cells for days before the month starts.
            ForEach(0..<firstDayOffset, id: \.self) { _ in
                Color.clear.frame(height: 40)
            }
            // Day cells.
            ForEach(days, id: \.self) { day in
                DayCell(
                    day: day,
                    items: itemsForDay(day),
                    isToday: day.isSameDay(as: Date())
                )
                .contentShape(RoundedRectangle(cornerRadius: 6))
                .onTapGesture {
                    onDayTap(day)
                }
                .accessibilityIdentifier("calendarDay.\(Self.dayIdentifier(for: day))")
            }
        }
    }

    /// Returns items scheduled on the given day.
    private func itemsForDay(_ day: Date) -> [any CalendarDisplayable] {
        items.filter { $0.displayDate.isSameDay(as: day) }
    }

    /// Advances or rewinds the displayed month.
    private func changeMonth(by value: Int) {
        if let newMonth = Calendar.current.date(byAdding: .month, value: value, to: selectedMonth) {
            selectedMonth = newMonth
        }
    }

    /// Navigates the month with a matching slide transition (used by chevron buttons).
    private func navigateMonth(by value: Int) {
        slideEdge = value > 0 ? .trailing : .leading
        withAnimation(.easeInOut(duration: 0.25)) {
            changeMonth(by: value)
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
    let items: [any CalendarDisplayable]
    let isToday: Bool

    var body: some View {
        VStack(spacing: 2) {
            Text("\(Calendar.current.component(.day, from: day))")
                .font(.caption)
                .fontWeight(isToday ? .bold : .regular)
                .foregroundStyle(isToday ? .blue : .primary)
            // Colored dot if items exist on this day.
            if let firstItem = items.first {
                Circle()
                    .fill(firstItem.type.color)
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
        items: [],
        onDayTap: { _ in }
    )
}
