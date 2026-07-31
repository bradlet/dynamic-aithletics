//
//  CalendarDayDot.swift
//  Hybrid AIthletics
//
//  Decides how a monthly-calendar day cell draws its activity dot. Extracted
//  from `MonthlyCalendarView` so the "did anything that day count as
//  training?" rule can be unit-tested without spinning up SwiftUI.
//

import Foundation

/// How a day's activity dot should be drawn.
enum CalendarDotStyle: Equatable {
    /// No activity on this day.
    case none
    /// Activity that counts toward training progress.
    case solid(ExerciseType)
    /// Activity that was explicitly opted out of training progress.
    case hollow(ExerciseType)
}

/// Stateless dot-style resolution for the monthly calendar.
enum CalendarDayDot {

    /// Resolves the dot style for one day's items.
    ///
    /// The dot takes its colour from the first item, matching the pre-existing
    /// single-dot-per-day display. It draws hollow only when *nothing* that
    /// day counted toward training — a day holding a real run alongside an
    /// opted-out walk still reads as a training day.
    /// - Parameter items: Items falling on the day, in display order.
    /// - Returns: `.none` when the day is empty, otherwise a solid or hollow
    ///   dot in the first item's type colour.
    static func style(for items: [any CalendarDisplayable]) -> CalendarDotStyle {
        guard let first = items.first else { return .none }
        let countsAsTraining = items.contains { $0.countsTowardTraining }
        return countsAsTraining ? .solid(first.type) : .hollow(first.type)
    }
}
