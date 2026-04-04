//
//  Exercise.swift
//  Dynamic AIthletics
//
//  A planned workout assigned to a specific date in the weekly training calendar.
//  Exercises serve as templates that can be recorded as Workouts when completed.
//

import Foundation
import SwiftData

@Model
final class Exercise {
    /// Stable identifier used for drag-and-drop transfer.
    var id: UUID = UUID()
    /// Display name of the exercise, e.g. "Morning 5K".
    var name: String = ""
    /// The activity category.
    var type: ExerciseType = ExerciseType.run
    /// Planned duration in seconds.
    var durationSeconds: Int = 0
    /// Planned distance in miles (internal storage unit).
    var distanceMiles: Double = 0.0
    /// Optional user notes for the planned exercise.
    var notes: String = ""
    /// The date this exercise is scheduled for, normalized to start of day.
    var scheduledDate: Date = Date()
    /// Whether this exercise repeats on the same day every week.
    var isRepeating: Bool = false

    /// Workouts recorded from this exercise template.
    @Relationship(deleteRule: .nullify, inverse: \Workout.sourceExercise)
    var workouts: [Workout] = []

    /// Creates a new planned exercise.
    /// - Parameters:
    ///   - name: Display name.
    ///   - type: Activity type.
    ///   - durationSeconds: Planned duration in seconds.
    ///   - distanceMiles: Planned distance in miles.
    ///   - notes: Optional notes.
    ///   - scheduledDate: The date to schedule this exercise on (normalized to start of day).
    ///   - isRepeating: Whether this exercise repeats weekly on the same day.
    init(
        name: String,
        type: ExerciseType,
        durationSeconds: Int,
        distanceMiles: Double,
        notes: String = "",
        scheduledDate: Date,
        isRepeating: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.durationSeconds = durationSeconds
        self.distanceMiles = distanceMiles
        self.notes = notes
        self.scheduledDate = scheduledDate.startOfDay
        self.isRepeating = isRepeating
    }
}
