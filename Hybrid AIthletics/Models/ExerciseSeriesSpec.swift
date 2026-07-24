//
//  ExerciseSeriesSpec.swift
//  Hybrid AIthletics
//
//  Pure value types describing a planned exercise series: how often it
//  recurs, when it ends, and how it progresses over time. These are Codable
//  so a future AI-coach tool layer can emit them as JSON and drive
//  ExercisePlanner directly.
//

import Foundation

/// How often occurrences of a planned series recur.
enum SeriesCadence: String, Codable, CaseIterable, Identifiable {
    case oneOff
    case weekly
    case biweekly
    case monthly

    var id: String { rawValue }

    /// Human-readable label for pickers.
    var displayName: String {
        switch self {
        case .oneOff: return "Never"
        case .weekly: return "Weekly"
        case .biweekly: return "Every 2 Weeks"
        case .monthly: return "Monthly"
        }
    }
}

/// Linear progression applied every `everyN` occurrences of a series.
struct SeriesProgression: Codable, Equatable {
    /// Apply the deltas once per this many occurrences (1 = every occurrence,
    /// 2 = every other, 4 ≈ monthly for a weekly series). Values below 1 are
    /// treated as 1 by the generator.
    var everyN: Int = 1
    /// Distance added at each progression step, in miles (may be negative to taper).
    var distanceDeltaMiles: Double = 0
    /// Duration added at each progression step, in seconds (may be negative to taper).
    var durationDeltaSeconds: Int = 0
}

/// Full specification for creating a series of concrete exercises.
struct ExerciseSeriesSpec: Codable, Equatable {
    var name: String
    var type: ExerciseType
    /// Date of the first occurrence.
    var startDate: Date
    var cadence: SeriesCadence
    /// Last day an occurrence may land on (inclusive). Ignored for `.oneOff`.
    var endDate: Date
    /// Planned distance of the first occurrence, in miles.
    var baseDistanceMiles: Double
    /// Planned duration of the first occurrence, in seconds.
    var baseDurationSeconds: Int
    var notes: String = ""
    var countsTowardMileage: Bool = true
    /// Optional linear progression; nil keeps every occurrence at the base values.
    var progression: SeriesProgression? = nil
}

/// One computed occurrence of a series (pure value, pre-Exercise).
struct SeriesOccurrence: Equatable {
    let date: Date
    let distanceMiles: Double
    let durationSeconds: Int
}
