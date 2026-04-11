//
//  HealthKitWorkout.swift
//  Hybrid AIthletics
//
//  Source-agnostic snapshot of an `HKWorkout`. This DTO is what crosses
//  the boundary between `HealthKitImportService` and SwiftUI views, so
//  view code never has to import HealthKit directly and tests can build
//  fixtures by hand without an `HKHealthStore`.
//

import Foundation
import HealthKit

/// A lightweight, `Sendable` projection of the HealthKit workout data
/// we care about. Built once inside the import service and passed around
/// freely across isolation boundaries.
struct HealthKitWorkout: Sendable, Equatable, Identifiable {
    /// `HKWorkout.uuid.uuidString`. Stable across devices and used as the
    /// dedup anchor when importing into SwiftData.
    let id: String
    /// Raw activity type from HealthKit. Mapped to `ExerciseType` at
    /// transform time via `HealthKitWorkoutMapper`.
    let activityType: HKWorkoutActivityType
    /// Absolute start time of the workout.
    let startDate: Date
    /// Total elapsed time in seconds (`HKWorkout.duration`).
    let duration: TimeInterval
    /// Total distance in miles, or `nil` for activity types that don't
    /// report distance (e.g. elliptical, strength, "other").
    let distanceMiles: Double?
}
