//
//  StrengthCoachExport.swift
//  Hybrid AIthletics
//
//  Serializes strength training data to JSON for the AI coach. These are
//  plain Codable snapshot types (mirroring AICoachCore's CoachWorkout /
//  CoachExercise pattern) so strength data can be wired into coaching
//  prompts later without touching the SwiftData models. When that happens,
//  these types should move into the AICoachCore package so the Evals CLI
//  can share them.
//

import Foundation

/// Snapshot of one recorded weight entry, for AI coach serialization.
struct CoachStrengthWorkout: Codable, Equatable, Sendable {
    /// The day the workout was performed.
    let date: Date
    /// Weight lifted in pounds.
    let weightPounds: Double
    /// What the weight represents (e.g. "Max Weight", "Average Weight").
    let recordingType: String
    /// Post-workout notes, omitted from JSON when empty.
    let notes: String?

    /// Creates a snapshot from a recorded strength workout.
    init(from workout: StrengthWorkout) {
        self.date = workout.date
        self.weightPounds = workout.weightPounds
        self.recordingType = workout.recordingType.rawValue
        self.notes = workout.notes.isEmpty ? nil : workout.notes
    }
}

/// Snapshot of one board exercise and its recorded history, for AI coach
/// serialization.
struct CoachStrengthExercise: Codable, Equatable, Sendable {
    /// Display name, e.g. "Barbell Bench Press".
    let name: String
    /// Primary muscle group raw value, e.g. "Chest".
    let muscleGroup: String
    /// Day-of-week lane (Sunday=0 ... Saturday=6).
    let weekdayIndex: Int
    /// Whether the exercise is offloaded (out of the active weekly plan).
    let isOffloaded: Bool
    /// User notes, omitted from JSON when empty.
    let notes: String?
    /// Recorded weight entries, oldest first.
    let workouts: [CoachStrengthWorkout]

    /// Creates a snapshot from a board exercise.
    init(from exercise: StrengthExercise) {
        self.name = exercise.name
        self.muscleGroup = exercise.muscleGroup.rawValue
        self.weekdayIndex = exercise.weekdayIndex
        self.isOffloaded = exercise.isOffloaded
        self.notes = exercise.notes.isEmpty ? nil : exercise.notes
        self.workouts = exercise.workouts
            .sorted { $0.date < $1.date }
            .map { CoachStrengthWorkout(from: $0) }
    }
}

/// Converts strength board data into JSON for AI coach prompts.
enum StrengthCoachExporter {

    /// Shared encoder: ISO 8601 dates and sorted keys for deterministic,
    /// prompt-friendly output.
    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }()

    /// Converts board exercises into coach snapshots, in board order
    /// (day, then section, then position).
    static func snapshots(from exercises: [StrengthExercise]) -> [CoachStrengthExercise] {
        exercises
            .sorted {
                ($0.weekdayIndex, $0.isOffloaded ? 1 : 0, $0.sortOrder)
                    < ($1.weekdayIndex, $1.isOffloaded ? 1 : 0, $1.sortOrder)
            }
            .map { CoachStrengthExercise(from: $0) }
    }

    /// Serializes board exercises to JSON data.
    static func jsonData(from exercises: [StrengthExercise]) throws -> Data {
        try encoder.encode(snapshots(from: exercises))
    }

    /// Serializes board exercises to a JSON string.
    static func jsonString(from exercises: [StrengthExercise]) throws -> String {
        String(decoding: try jsonData(from: exercises), as: UTF8.self)
    }
}
