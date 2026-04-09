//
//  DistanceFormatting.swift
//  AICoachCore
//
//  Distance formatting and conversion utilities used by the prompt builder.
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
}
