//
//  StrengthExercise.swift
//  Hybrid AIthletics
//
//  A strength exercise on the weekly kanban board. Unlike aerobic `Exercise`,
//  a strength exercise has NO date — it lives permanently in a day-of-week
//  lane (or that lane's "offloaded" section) and accumulates dated
//  `StrengthWorkout` records over time as the user logs weights against it.
//

import Foundation
import SwiftData

@Model
final class StrengthExercise {
    /// Stable identifier used for drag-and-drop transfer and list identity.
    var id: UUID = UUID()
    /// Display name, e.g. "Barbell Bench Press".
    var name: String = ""
    /// Identifier of the library entry this exercise was added from, or `nil`
    /// for an exercise with no library provenance. Lets us re-resolve library
    /// metadata (description, equipment) without denormalizing all of it.
    var libraryExerciseID: String? = nil
    /// Raw value of the primary muscle group. Stored as String because
    /// `MuscleGroup`'s custom tolerant `init(from:)` makes SwiftData treat
    /// the enum as a composite Codable attribute, which crashes its encoder
    /// on save. Access through `muscleGroup`, never this.
    private var muscleGroupRaw: String = MuscleGroup.other.rawValue
    /// The day-of-week lane this exercise lives in (Sunday=0 ... Saturday=6).
    var weekdayIndex: Int = 0
    /// Whether the exercise sits in the lane's lower "offloaded" section —
    /// kept in mind but dragged out of the active plan for the week.
    var isOffloaded: Bool = false
    /// Position within its lane section (active or offloaded). Lower = higher
    /// on the board. Order matters per swimlane.
    var sortOrder: Int = 0
    /// Optional user notes for the exercise.
    var notes: String = ""

    /// Primary muscle group, denormalized from the library for card display.
    /// Unknown stored raw values (e.g. synced from a newer app version) read
    /// as `.other`.
    var muscleGroup: MuscleGroup {
        get { MuscleGroup(rawValue: muscleGroupRaw) ?? .other }
        set { muscleGroupRaw = newValue.rawValue }
    }

    /// JSON-encoded backing store for the recorded workouts. SwiftData
    /// persists `Data?` reliably and CloudKit mirrors it as a blob (composite
    /// Codable attributes fatalError on fetch — see `Exercise.workoutData`).
    /// Access through `workouts`, never this.
    private var workoutsData: Data? = nil

    /// All recorded weight entries for this exercise, oldest first. Encoded
    /// to/from `workoutsData` as JSON so records ride along inside this single
    /// entity (no second table, no CloudKit relationship).
    var workouts: [StrengthWorkout] {
        get {
            guard let workoutsData else { return [] }
            return (try? JSONDecoder().decode([StrengthWorkout].self, from: workoutsData)) ?? []
        }
        set {
            workoutsData = newValue.isEmpty ? nil : try? JSONEncoder().encode(newValue)
        }
    }

    /// The most recently dated workout record, if any. Used for card display.
    var latestWorkout: StrengthWorkout? {
        workouts.max(by: { $0.date < $1.date })
    }

    /// Creates a strength exercise.
    /// - Parameters:
    ///   - name: Display name.
    ///   - libraryExerciseID: Library entry this was added from, if any.
    ///   - muscleGroup: Primary muscle group.
    ///   - weekdayIndex: Day-of-week lane (Sunday=0 ... Saturday=6).
    ///   - isOffloaded: Whether it starts in the offloaded section.
    ///   - sortOrder: Position within the lane section.
    ///   - notes: Optional notes.
    ///   - workouts: Recorded weight entries, if any.
    init(
        name: String,
        libraryExerciseID: String? = nil,
        muscleGroup: MuscleGroup = .other,
        weekdayIndex: Int = 0,
        isOffloaded: Bool = false,
        sortOrder: Int = 0,
        notes: String = "",
        workouts: [StrengthWorkout] = []
    ) {
        self.id = UUID()
        self.name = name
        self.libraryExerciseID = libraryExerciseID
        self.muscleGroup = muscleGroup
        self.weekdayIndex = weekdayIndex
        self.isOffloaded = isOffloaded
        self.sortOrder = sortOrder
        self.notes = notes
        self.workouts = workouts
    }
}
