//
//  Double+Weight.swift
//  Hybrid AIthletics
//
//  Weight formatting helpers. Weights are stored in pounds internally
//  (mirroring the miles-internally convention for distance) and converted
//  for display based on the user's unit preference.
//

import Foundation

extension Double {

    /// Pounds per kilogram conversion factor.
    static let poundsPerKilogram: Double = 2.204622621848776

    /// Converts this weight in pounds to the display unit.
    /// - Parameter metric: Whether to convert to kilograms.
    /// - Returns: The weight in kilograms if metric, otherwise unchanged pounds.
    func toDisplayWeight(metric: Bool) -> Double {
        metric ? self / Double.poundsPerKilogram : self
    }

    /// Converts a user-entered display weight back to internal pounds.
    /// - Parameter metric: Whether the entered value is in kilograms.
    /// - Returns: The weight in pounds.
    func fromDisplayWeight(metric: Bool) -> Double {
        metric ? self * Double.poundsPerKilogram : self
    }

    /// Formats this weight in pounds for display, e.g. "185 lb" or "83.9 kg".
    /// Whole numbers drop the decimal.
    /// - Parameter metric: Whether to display in kilograms.
    /// - Returns: A formatted weight string with unit suffix.
    func formattedWeight(metric: Bool) -> String {
        let value = toDisplayWeight(metric: metric)
        let unit = metric ? "kg" : "lb"
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f %@", value, unit)
        }
        return String(format: "%.1f %@", value, unit)
    }
}
