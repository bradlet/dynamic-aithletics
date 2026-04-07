//
//  Workout.swift
//  Hybrid AIthletics
//
//  A recorded instance of a completed exercise session.
//  Workouts track actual performance and can optionally reference
//  the Exercise template they were created from.
//

import Foundation
import SwiftData

@Model
final class Workout {
    /// Unique identifier.
    var id: UUID = UUID()
    /// Name of the workout as recorded.
    var name: String = ""
    /// The activity category.
    var type: ExerciseType = ExerciseType.run
    /// Actual duration in seconds.
    var durationSeconds: Int = 0
    /// Actual distance in miles (internal storage unit).
    var distanceMiles: Double = 0.0
    /// User notes about the completed workout.
    var notes: String = ""
    /// The date and time the workout was performed.
    var date: Date = Date()
    /// User's subjective Rate of Perceived Exertion after completing the workout
    /// on a 1–10 scale. A value of `0` means the user did not record a rating.
    /// Feeds the on-device AI Coach's training-load assessment.
    var feltRating: Int = 0

    /// The exercise template this workout was recorded from, if any.
    var sourceExercise: Exercise?

    /// Creates a new recorded workout.
    /// - Parameters:
    ///   - name: Workout name.
    ///   - type: Activity type.
    ///   - durationSeconds: Actual duration in seconds.
    ///   - distanceMiles: Actual distance in miles.
    ///   - notes: Optional notes.
    ///   - date: When the workout was performed.
    ///   - feltRating: Subjective 1–10 effort rating. `0` means not recorded.
    ///   - sourceExercise: The planned exercise this was recorded from, if any.
    init(
        name: String,
        type: ExerciseType,
        durationSeconds: Int,
        distanceMiles: Double,
        notes: String = "",
        date: Date = Date(),
        feltRating: Int = 0,
        sourceExercise: Exercise? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.durationSeconds = durationSeconds
        self.distanceMiles = distanceMiles
        self.notes = notes
        self.date = date
        self.feltRating = feltRating
        self.sourceExercise = sourceExercise
    }

    /// Creates a draft workout pre-filled from an exercise template.
    /// The user can edit all fields before saving.
    /// - Parameter exercise: The exercise to copy defaults from.
    /// - Returns: A new unsaved Workout with fields copied from the exercise.
    static func draft(from exercise: Exercise) -> Workout {
        Workout(
            name: exercise.name,
            type: exercise.type,
            durationSeconds: exercise.durationSeconds,
            distanceMiles: exercise.distanceMiles,
            notes: "",
            date: Date(),
            sourceExercise: exercise
        )
    }
}
