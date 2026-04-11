//
//  Double+Distance.swift
//  Hybrid AIthletics
//
//  Distance formatting and conversion utilities.
//  All distances are stored internally in miles.
//

import Foundation

/// Conversion factor from miles to kilometers.
private let milesToKm = 1.60934

extension Double {

    /// Formats this distance value for display with the appropriate unit label.
    /// - Parameter metric: If true, converts from miles to km before formatting.
    /// - Returns: A string like "5.2 mi" or "8.4 km".
    func formattedDistance(metric: Bool) -> String {
        let value = metric ? self * milesToKm : self
        let unit = metric ? "km" : "mi"
        return String(format: "%.1f %@", value, unit)
    }

    /// Converts a stored miles value to the display unit.
    /// - Parameter metric: If true, converts to kilometers.
    /// - Returns: The distance in the target unit.
    func toDisplayDistance(metric: Bool) -> Double {
        metric ? self * milesToKm : self
    }

    /// Formats this value as a duration string from seconds.
    /// - Returns: A string like "45:00" or "1:30:00".
    var formattedDuration: String {
        let totalSeconds = Int(self)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }
}

extension Int {

    /// Formats this integer (seconds) as a duration string.
    /// - Returns: A string like "45:00" or "1:30:00".
    var formattedDuration: String {
        Double(self).formattedDuration
    }

    /// Formats this value (seconds of duration) as an average pace given a
    /// distance in miles, in the user's preferred unit.
    /// - Parameters:
    ///   - distanceMiles: The distance the duration was covered over, in miles.
    ///   - metric: If `true`, returns pace as minutes per kilometer; otherwise minutes per mile.
    /// - Returns: A string like `"7:32 /mi"` or `"4:41 /km"`. Returns `"--"`
    ///   when `distanceMiles` is zero or negative (e.g. strength workouts) or
    ///   when the computation would be non-finite.
    func formattedPace(distanceMiles: Double, metric: Bool) -> String {
        guard distanceMiles > 0 else { return "--" }
        let distance = metric ? distanceMiles * milesToKm : distanceMiles
        guard distance > 0 else { return "--" }
        let secondsPerUnit = Double(self) / distance
        guard secondsPerUnit.isFinite else { return "--" }
        let totalSeconds = Int(secondsPerUnit)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d /%@", minutes, seconds, metric ? "km" : "mi")
    }
}
