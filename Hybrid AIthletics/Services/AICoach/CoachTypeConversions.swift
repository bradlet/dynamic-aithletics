//
//  CoachTypeConversions.swift
//  Hybrid AIthletics
//
//  Extensions to convert the app's SwiftData models (Workout, Exercise,
//  ExerciseType) into AICoachCore's plain types for prompt building.
//

import Foundation
import AICoachCore

extension CoachExerciseType {

    /// Creates a coaching exercise type from the app's UI-aware `ExerciseType`.
    init(from appType: ExerciseType) {
        // Raw values are identical between the two enums by design.
        self = CoachExerciseType(rawValue: appType.rawValue)!
    }
}

extension CoachWorkout {

    /// Creates a coaching workout from the app's SwiftData `Workout` model.
    init(from workout: Workout) {
        self.init(
            date: workout.date,
            type: CoachExerciseType(from: workout.type),
            distanceMiles: workout.distanceMiles,
            durationSeconds: workout.durationSeconds,
            feltRating: workout.feltRating,
            notes: workout.notes
        )
    }
}

extension CoachExercise {

    /// Creates a coaching exercise from the app's SwiftData `Exercise` model.
    init(from exercise: Exercise) {
        self.init(
            scheduledDate: exercise.scheduledDate,
            type: CoachExerciseType(from: exercise.type),
            distanceMiles: exercise.distanceMiles,
            durationSeconds: exercise.durationSeconds
        )
    }
}
