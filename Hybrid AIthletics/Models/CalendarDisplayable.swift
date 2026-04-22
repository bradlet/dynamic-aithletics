//
//  CalendarDisplayable.swift
//  Hybrid AIthletics
//
//  Protocol for items that can appear as dots on a monthly calendar grid.
//  Both Exercise and Workout conform, enabling the shared MonthlyCalendarView
//  to display either planned or recorded activity.
//

import Foundation

/// A type that can be displayed as a dot on the monthly calendar.
protocol CalendarDisplayable {
    /// The date used for calendar placement.
    var displayDate: Date { get }
    /// The exercise type, used for dot coloring.
    var type: ExerciseType { get }
}

// MARK: - Model Conformances

extension Exercise: CalendarDisplayable {
    var displayDate: Date { scheduledDate }
}

extension Workout: CalendarDisplayable {
    var displayDate: Date { date }
}

// MARK: - CalendarDot

/// Lightweight value type for virtual repeating exercise indicators.
/// Used in the month calendar when we need dots for repeating exercises
/// without creating transient SwiftData model objects.
struct CalendarDot: CalendarDisplayable {
    let displayDate: Date
    let type: ExerciseType
}
