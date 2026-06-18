//
//  ExerciseVirtualExpansion.swift
//  Hybrid AIthletics
//
//  Pure functions for expanding repeating exercises into calendar display items
//  across a full month. Used by AerobicTrainingView's monthly calendar.
//

import Foundation

/// Computes calendar display items for a month, including virtual dots
/// for repeating exercises that don't have concrete instances on a given day.
enum ExerciseVirtualExpansion {

    /// Returns calendar-displayable items for the given month.
    ///
    /// Concrete exercises scheduled within the month are included directly.
    /// Repeating exercises from other months produce lightweight `CalendarDot`
    /// instances for each matching weekday, unless a concrete exercise with the
    /// same name and type already exists on that day.
    ///
    /// - Parameters:
    ///   - allExercises: Every exercise in the data store.
    ///   - month: Any date within the target month.
    /// - Returns: An array of items suitable for `MonthlyCalendarView`.
    static func monthItems(
        allExercises: [Exercise],
        month: Date
    ) -> [any CalendarDisplayable] {
        let start = month.startOfMonth
        let end = month.endOfMonth
        let monthDays = month.daysInMonth()

        let concrete = allExercises.filter {
            $0.date >= start && $0.date <= end
        }

        var items: [any CalendarDisplayable] = concrete

        // Repeating exercises whose original date is outside this month
        let repeating = allExercises.filter { $0.isRepeating }

        for template in repeating {
            let targetDayIndex = template.date.mondayBasedWeekdayIndex
            for day in monthDays {
                guard day.mondayBasedWeekdayIndex == targetDayIndex,
                      day >= template.date.startOfDay else { continue }
                let alreadyExists = concrete.contains { existing in
                    existing.date.isSameDay(as: day)
                    && existing.name == template.name
                    && existing.type == template.type
                }
                if !alreadyExists {
                    items.append(CalendarDot(displayDate: day, type: template.type))
                }
            }
        }

        return items
    }
}
