//
//  CoachWorkout.swift
//  AICoachCore
//
//  Lightweight value type representing a completed workout for prompt
//  building. The app converts its SwiftData Workout model into this
//  type before constructing a CoachingRequest.
//

import Foundation

/// A completed workout session with the fields needed by the prompt builder.
public struct CoachWorkout: Sendable {
    /// When the workout was performed.
    public let date: Date
    /// The activity category.
    public let type: CoachExerciseType
    /// Actual distance in miles (internal storage unit).
    public let distanceMiles: Double
    /// Actual duration in seconds.
    public let durationSeconds: Int
    /// Subjective Rate of Perceived Exertion (1–10). `0` means unrated.
    public let feltRating: Int
    /// User notes about the completed workout.
    public let notes: String

    public init(
        date: Date,
        type: CoachExerciseType,
        distanceMiles: Double,
        durationSeconds: Int,
        feltRating: Int = 0,
        notes: String = ""
    ) {
        self.date = date
        self.type = type
        self.distanceMiles = distanceMiles
        self.durationSeconds = durationSeconds
        self.feltRating = feltRating
        self.notes = notes
    }
}
