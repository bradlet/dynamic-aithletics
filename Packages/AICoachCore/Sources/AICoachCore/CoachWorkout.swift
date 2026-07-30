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
    /// How the athlete felt, 1 (very weak) … 5 (very strong). `nil` when not recorded.
    public let feeling: Int?
    /// Rate of Perceived Exertion, 1 (very light) … 10 (maximum effort).
    /// `nil` when not recorded.
    public let perceivedExertion: Int?
    /// User notes about the completed workout.
    public let notes: String

    public init(
        date: Date,
        type: CoachExerciseType,
        distanceMiles: Double,
        durationSeconds: Int,
        feeling: Int? = nil,
        perceivedExertion: Int? = nil,
        notes: String = ""
    ) {
        self.date = date
        self.type = type
        self.distanceMiles = distanceMiles
        self.durationSeconds = durationSeconds
        self.feeling = feeling
        self.perceivedExertion = perceivedExertion
        self.notes = notes
    }
}
