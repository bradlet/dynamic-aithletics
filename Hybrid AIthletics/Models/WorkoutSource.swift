//
//  WorkoutSource.swift
//  Hybrid AIthletics
//
//  Provenance categories for a `Workout`. Stored on `Workout.source` as the
//  raw string value so CloudKit sees a primitive and adding future cases
//  does not require a SwiftData schema migration.
//

import Foundation

/// Provenance for a recorded workout. The raw value is what's persisted on
/// `Workout.source`; callers should route reads through `Workout.workoutSource`
/// for type-safe handling.
enum WorkoutSource: String {
    /// Entered by the user through the in-app record flow.
    case manual = "Manual"
    /// Created via CSV import.
    case csv = "CSV"
    /// Imported from Apple Health (Apple Watch / iOS Workout app).
    case appleHealth = "Apple Exercise App"
    /// Fallback used when the persisted `source` string does not match
    /// any known case (e.g. data written by a newer app version).
    case unknown = "Unknown"
}

extension Workout {
    /// Typed accessor over the persisted `source` string field.
    /// Returns `.unknown` if the stored value does not match any known case.
    var workoutSource: WorkoutSource {
        WorkoutSource(rawValue: source) ?? .unknown
    }
}
