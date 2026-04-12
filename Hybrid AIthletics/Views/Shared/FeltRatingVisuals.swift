//
//  FeltRatingVisuals.swift
//  Hybrid AIthletics
//
//  Shared felt-rating → SF Symbol / tint mapping. Single source of
//  truth so the `FeltRatingPicker` used for data entry and the
//  "Feeling like" stat card in `SummaryStatsView` render the same
//  face and tint for the same rating.
//

import SwiftUI

/// Stateless rating → visual mapping for felt-rating display.
enum FeltRatingVisuals {

    /// SF Symbol name for a rating. `0` (unset) returns the dashed
    /// placeholder; `1...10` morph across three expression tiers.
    static func symbolName(for rating: Int) -> String {
        switch rating {
        case 1...4:  return "face.dashed"           // struggle (red tint carries meaning)
        case 5...7:  return "face.smiling"          // steady
        case 8...10: return "face.smiling.inverse"  // triumph
        default:     return "face.dashed"           // unset / out-of-range
        }
    }

    /// Red → amber → green tint for a rating via HSB interpolation.
    /// Returns `.secondary` when `rating == 0` (unset) to match the
    /// neutral placeholder face.
    static func tint(for rating: Int) -> Color {
        guard rating > 0 else { return .secondary }
        let clamped = Double(max(1, min(10, rating)) - 1) / 9.0  // 0...1
        let hue: Double = 0.0 + (0.37 * clamped)                 // ~red → ~green
        return Color(hue: hue, saturation: 0.78, brightness: 0.92)
    }
}
