//
//  WeekMileage.swift
//  Hybrid AIthletics
//
//  Pure aggregation helpers for the weekly training header's mileage stats.
//  Kept free of SwiftUI/ModelContext so the math is unit-testable.
//

import Foundation

/// Sums planned and completed distances for a week's exercises.
///
/// The tracked totals (default) exclude exercises opted out of mileage via
/// `Exercise.countsTowardMileage`; pass `includeNonTracked: true` for the
/// "All Mileage" totals that count every exercise regardless of the opt-out.
enum WeekMileage {

    /// Sum of planned exercise distances in miles.
    /// - Parameters:
    ///   - exercises: The exercises scheduled for the week.
    ///   - includeNonTracked: When true, exercises with
    ///     `countsTowardMileage == false` are included in the total.
    static func planned(_ exercises: [Exercise], includeNonTracked: Bool = false) -> Double {
        exercises
            .filter { includeNonTracked || $0.countsTowardMileage }
            .reduce(0) { $0 + $1.distanceMiles }
    }

    /// Sum of recorded (actual) workout distances in miles for completed exercises.
    /// - Parameters:
    ///   - exercises: The exercises scheduled for the week (completed or not).
    ///   - includeNonTracked: When true, exercises with
    ///     `countsTowardMileage == false` are included in the total.
    static func completed(_ exercises: [Exercise], includeNonTracked: Bool = false) -> Double {
        exercises
            .filter(\.isCompleted)
            .filter { includeNonTracked || $0.countsTowardMileage }
            .reduce(0) { $0 + ($1.workout?.distanceMiles ?? 0) }
    }
}
