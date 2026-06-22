//
//  HealthKitWorkoutMapper.swift
//  Hybrid AIthletics
//
//  Stateless mapping from HealthKit types to the app's domain types.
//  Pure functions only — no `HKHealthStore`, no SwiftData, no async.
//  This is the primary test surface for the HealthKit import feature.
//

import Foundation
import HealthKit

/// Namespace for pure mapping helpers between HealthKit and app types.
enum HealthKitWorkoutMapper {

    /// Best-fit mapping from `HKWorkoutActivityType` to the app's
    /// `ExerciseType` enum. HealthKit does not distinguish between
    /// long / tempo / interval / easy / recovery variants of a run,
    /// so all running activity types collapse to `.run`; the user can
    /// reclassify a workout after import if desired.
    /// - Parameter activityType: The raw activity type from `HKWorkout`.
    /// - Returns: The closest-matching `ExerciseType`, or `.other` for any
    ///   HealthKit activity not represented in the app.
    static func exerciseType(for activityType: HKWorkoutActivityType) -> ExerciseType {
        switch activityType {
        case .running:
            return .run
        case .walking:
            return .walk
        case .cycling:
            return .bike
        case .swimming:
            return .swim
        case .hiking:
            return .hike
        case .elliptical:
            return .elliptical
        default:
            return .other
        }
    }

    /// Converts a `HealthKitWorkout` DTO into a new completed `Exercise`
    /// instance ready for insertion into SwiftData. The exercise's date/type
    /// and planned metrics mirror the imported activity; its nested `workout`
    /// records the actuals with `source = "Apple Exercise App"` and
    /// `externalID` seeded from the HealthKit UUID so repeat imports can be
    /// deduplicated.
    /// - Parameter dto: The HealthKit workout DTO to transform.
    /// - Returns: A new unsaved completed `Exercise` instance.
    static func toExercise(_ dto: HealthKitWorkout) -> Exercise {
        let type = exerciseType(for: dto.activityType)
        let seconds = Int(dto.duration)
        let miles = dto.distanceMiles ?? 0.0
        return Exercise(
            name: type.rawValue,
            type: type,
            durationSeconds: seconds,
            distanceMiles: miles,
            notes: "",
            date: dto.startDate,
            isRepeating: false,
            workout: Workout(
                durationSeconds: seconds,
                distanceMiles: miles,
                notes: "",
                feltRating: 0,
                source: WorkoutSource.appleHealth.rawValue,
                externalID: dto.id
            )
        )
    }
}
