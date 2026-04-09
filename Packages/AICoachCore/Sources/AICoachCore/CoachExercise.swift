//
//  CoachExercise.swift
//  AICoachCore
//
//  Lightweight value type representing a planned exercise for prompt
//  building. The app converts its SwiftData Exercise model into this
//  type before constructing a CoachingRequest.
//

import Foundation

/// A planned exercise session with the fields needed by the prompt builder.
public struct CoachExercise: Sendable {
    /// The date this exercise is scheduled for.
    public let scheduledDate: Date
    /// The activity category.
    public let type: CoachExerciseType
    /// Planned distance in miles (internal storage unit).
    public let distanceMiles: Double
    /// Planned duration in seconds.
    public let durationSeconds: Int

    public init(
        scheduledDate: Date,
        type: CoachExerciseType,
        distanceMiles: Double,
        durationSeconds: Int
    ) {
        self.scheduledDate = scheduledDate
        self.type = type
        self.distanceMiles = distanceMiles
        self.durationSeconds = durationSeconds
    }
}
