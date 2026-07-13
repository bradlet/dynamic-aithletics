//
//  Exercise.swift
//  Hybrid AIthletics
//
//  A single training activity — planned, recorded, or both. The planning
//  fields (type, target duration/distance, notes, date) always apply. Once
//  the activity has actually been performed, the recorded-only data lives in
//  the nested `workout` value object. `workout == nil` means planned only;
//  a non-nil `workout` means it was recorded.
//

import Foundation
import SwiftData

@Model
final class Exercise {
    /// Stable identifier used for drag-and-drop transfer and list identity.
    var id: UUID = UUID()
    /// Display name of the exercise, e.g. "Morning 5K".
    var name: String = ""
    /// The activity category.
    var type: ExerciseType = ExerciseType.run
    /// Planned (target) duration in seconds.
    var durationSeconds: Int = 0
    /// Planned (target) distance in miles (internal storage unit).
    var distanceMiles: Double = 0.0
    /// Optional user notes for the planned exercise.
    var notes: String = ""
    /// The single date for this activity — the day it is planned and/or
    /// performed. Keeps the full timestamp so the History tab can display
    /// time-of-day. Day/week grouping flows through `Date+Week` helpers.
    var date: Date = Date()
    /// Whether this exercise repeats on the same day every week.
    var isRepeating: Bool = false
    /// Whether this exercise's recorded distance counts toward mileage
    /// aggregates (weekly totals, stat cards, charts). Defaults to `true` so
    /// every pre-existing record keeps counting; turn off for casual activity
    /// (e.g. walks) that should be tracked but not treated as training volume.
    var countsTowardMileage: Bool = true

    /// JSON-encoded backing store for the nested recorded workout. SwiftData
    /// persists `Data?` reliably and CloudKit mirrors it as a blob. We do NOT
    /// store `Workout?` directly as a Codable composite attribute: SwiftData's
    /// composite decoder (`ModelCoders`) `fatalError`s on *fetch* of an
    /// optional value struct. Access the workout through `workout`, never this.
    private var workoutData: Data? = nil

    /// Recorded-instance data, present once the activity has been performed.
    /// `nil` means the exercise is planned only. Encoded to/from `workoutData`
    /// as JSON so it rides along inside this single record (no second table).
    var workout: Workout? {
        get {
            guard let workoutData else { return nil }
            return try? JSONDecoder().decode(Workout.self, from: workoutData)
        }
        set {
            if let newValue {
                workoutData = try? JSONEncoder().encode(newValue)
            } else {
                workoutData = nil
            }
        }
    }

    /// Whether this exercise has been recorded. Cheap — checks the backing
    /// `Data?` directly without decoding.
    var isCompleted: Bool { workoutData != nil }

    /// Creates an exercise.
    /// - Parameters:
    ///   - name: Display name.
    ///   - type: Activity type.
    ///   - durationSeconds: Planned duration in seconds.
    ///   - distanceMiles: Planned distance in miles.
    ///   - notes: Optional notes.
    ///   - date: The day this activity is planned and/or performed.
    ///   - isRepeating: Whether this exercise repeats weekly on the same day.
    ///   - countsTowardMileage: Whether the distance counts toward mileage aggregates.
    ///   - workout: Recorded data, if the activity has been performed.
    init(
        name: String,
        type: ExerciseType,
        durationSeconds: Int,
        distanceMiles: Double,
        notes: String = "",
        date: Date,
        isRepeating: Bool = false,
        countsTowardMileage: Bool = true,
        workout: Workout? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.durationSeconds = durationSeconds
        self.distanceMiles = distanceMiles
        self.notes = notes
        self.date = date
        self.isRepeating = isRepeating
        self.countsTowardMileage = countsTowardMileage
        self.workout = workout
    }
}
