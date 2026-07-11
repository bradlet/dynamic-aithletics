//
//  Date+Week.swift
//  Hybrid AIthletics
//
//  Calendar arithmetic helpers for week and month boundaries.
//  Uses the standard Sunday-start week via `Calendar.current`.
//

import Foundation

extension Date {

    /// Returns this date normalized to midnight (start of day).
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    /// Returns midnight on Sunday of the week containing this date.
    var startOfWeek: Date {
        Calendar.current.dateInterval(of: .weekOfYear, for: self)?.start ?? startOfDay
    }

    /// Returns midnight on the configured first weekday of the week containing
    /// this date. Unlike `startOfWeek`, this sets `firstWeekday` explicitly
    /// rather than relying on the locale default, so a Sunday date with
    /// `firstWeekday: 2` belongs to the *previous* Monday-start week.
    /// - Parameter firstWeekday: Calendar weekday convention (1=Sunday ... 7=Saturday).
    func startOfWeek(firstWeekday: Int) -> Date {
        var cal = Calendar.current
        cal.firstWeekday = firstWeekday
        return cal.dateInterval(of: .weekOfYear, for: self)?.start ?? startOfDay
    }

    /// Returns 23:59:59 on Saturday of the week containing this date.
    var endOfWeek: Date {
        let cal = Calendar.current
        guard let saturday = cal.date(byAdding: .day, value: 6, to: startOfWeek) else { return self }
        return cal.date(bySettingHour: 23, minute: 59, second: 59, of: saturday) ?? saturday
    }

    /// Returns midnight on the first day of the month containing this date.
    var startOfMonth: Date {
        let components = Calendar.current.dateComponents([.year, .month], from: self)
        return Calendar.current.date(from: components) ?? self
    }

    /// Returns 23:59:59 on the last day of the month containing this date.
    var endOfMonth: Date {
        let cal = Calendar.current
        guard let nextMonth = cal.date(byAdding: .month, value: 1, to: startOfMonth),
              let lastDay = cal.date(byAdding: .day, value: -1, to: nextMonth) else { return self }
        return cal.date(bySettingHour: 23, minute: 59, second: 59, of: lastDay) ?? lastDay
    }

    /// Returns the start of the year containing this date.
    var startOfYear: Date {
        let components = Calendar.current.dateComponents([.year], from: self)
        return Calendar.current.date(from: components) ?? self
    }

    /// Returns an array of 7 dates (Sun through Sat) for the week containing this date.
    func daysInWeek() -> [Date] {
        let sunday = startOfWeek
        return (0..<7).compactMap {
            Calendar.current.date(byAdding: .day, value: $0, to: sunday)
        }
    }

    /// Returns an array of all dates in the month containing this date.
    func daysInMonth() -> [Date] {
        let cal = Calendar.current
        let range = cal.range(of: .day, in: .month, for: self) ?? 1..<2
        let start = startOfMonth
        return range.compactMap {
            cal.date(byAdding: .day, value: $0 - 1, to: start)
        }
    }

    /// Cached formatter for full weekday names.
    private static let weekdayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE"
        return f
    }()

    /// Cached formatter for short weekday names.
    private static let shortWeekdayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f
    }()

    /// Full weekday name, e.g. "Monday".
    var weekdayName: String {
        Date.weekdayFormatter.string(from: self)
    }

    /// Short weekday name, e.g. "Mon".
    var shortWeekdayName: String {
        Date.shortWeekdayFormatter.string(from: self)
    }

    /// Whether this date falls on the same calendar day as another date.
    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }

    /// Whether this date falls within the same calendar week (Sun-Sat) as another date.
    func isSameWeek(as other: Date) -> Bool {
        startOfWeek == other.startOfWeek
    }

    /// Whether this date falls within the same calendar month as another date.
    func isSameMonth(as other: Date) -> Bool {
        let cal = Calendar.current
        return cal.component(.year, from: self) == cal.component(.year, from: other)
            && cal.component(.month, from: self) == cal.component(.month, from: other)
    }

    /// The weekday index with Sunday=0 through Saturday=6.
    var weekdayIndex: Int {
        // Calendar weekday: 1=Sun, 2=Mon, ..., 7=Sat
        Calendar.current.component(.weekday, from: self) - 1
    }
}
