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

    /// Converts a `HealthKitWorkout` DTO into a new `Workout` model instance
    /// ready for insertion into SwiftData. Sets `source` to
    /// `"Apple Exercise App"` and seeds `externalID` with the HealthKit UUID
    /// so repeat imports can be deduplicated.
    /// - Parameter dto: The HealthKit workout DTO to transform.
    /// - Returns: A new unsaved `Workout` instance.
    static func toWorkout(_ dto: HealthKitWorkout) -> Workout {
        let type = exerciseType(for: dto.activityType)
        return Workout(
            name: type.rawValue,
            type: type,
            durationSeconds: Int(dto.duration),
            distanceMiles: dto.distanceMiles ?? 0.0,
            notes: "",
            date: dto.startDate,
            feltRating: 0,
            source: WorkoutSource.appleHealth.rawValue,
            externalID: dto.id,
            sourceExercise: nil
        )
    }
}
