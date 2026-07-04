//
//  StrengthWorkout.swift
//  Hybrid AIthletics
//
//  A single recorded strength session for a `StrengthExercise`. Plain Codable
//  value type (NOT a SwiftData @Model) stored as a JSON-encoded array inline
//  on `StrengthExercise.workouts` — same pattern as `Exercise.workout`.
//  Strength exercises themselves are undated (they live on the weekly board);
//  the date lives here, on the recorded instance.
//

import Foundation

/// A recorded weight entry for a strength exercise: when it happened, how
/// much was lifted, and what kind of measurement the weight represents.
struct StrengthWorkout: Codable, Hashable, Sendable, Identifiable {
    /// Stable identifier for list identity and future editing/deletion.
    var id: UUID = UUID()
    /// The day the workout was performed.
    var date: Date = Date()
    /// Weight lifted, in pounds (internal storage unit — mirrors the app's
    /// miles-internally convention for distance).
    var weightPounds: Double = 0.0
    /// What the recorded weight represents (max, average, first set, ...).
    var recordingType: WeightRecordingType = .maxWeight
    /// Optional post-workout notes.
    var notes: String = ""

    /// Creates a recorded strength workout.
    /// - Parameters:
    ///   - date: The day the workout was performed.
    ///   - weightPounds: Weight lifted in pounds.
    ///   - recordingType: What the weight measurement represents.
    ///   - notes: Optional notes.
    init(
        date: Date = Date(),
        weightPounds: Double = 0.0,
        recordingType: WeightRecordingType = .maxWeight,
        notes: String = ""
    ) {
        self.id = UUID()
        self.date = date
        self.weightPounds = weightPounds
        self.recordingType = recordingType
        self.notes = notes
    }
}
