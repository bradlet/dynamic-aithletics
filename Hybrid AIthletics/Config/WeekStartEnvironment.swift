//
//  WeekStartEnvironment.swift
//  Hybrid AIthletics
//
//  Custom SwiftUI environment key for the workout week start preference.
//  Allows any view in the hierarchy to read the configured first weekday
//  without an additional SwiftData query.
//

import SwiftUI

/// Environment key for the workout week start preference.
private struct WeekStartDayKey: EnvironmentKey {
    static let defaultValue = 1
}

extension EnvironmentValues {
    /// First day of the workout week for weekly aggregation math, using the
    /// Calendar weekday convention (1=Sunday ... 7=Saturday). Calendar grids
    /// stay visually Sunday-first regardless of this value.
    var weekStartDay: Int {
        get { self[WeekStartDayKey.self] }
        set { self[WeekStartDayKey.self] = newValue }
    }
}
