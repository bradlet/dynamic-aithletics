//
//  CalendarDisplayable.swift
//  Hybrid AIthletics
//
//  Protocol for items that can appear as dots on a monthly calendar grid.
//  Exercise conforms (via its single `date`), enabling the shared
//  MonthlyCalendarView to display planned or recorded activity uniformly.
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
    var displayDate: Date { date }
}
