//
//  ExerciseType.swift
//  Hybrid AIthletics
//
//  Defines the available exercise types for aerobic training.
//  Running-focused with cross-training options.
//

import SwiftUI

/// Categorizes exercises by activity type. Used by both Exercise (planned) and Workout (recorded) models.
enum ExerciseType: String, Codable, CaseIterable, Identifiable {
    case run = "Run"
    case longRun = "Long Run"
    case tempoRun = "Tempo Run"
    case intervalRun = "Interval Run"
    case easyRun = "Easy Run"
    case recoveryRun = "Recovery Run"
    case walk = "Walk"
    case bike = "Bike"
    case swim = "Swim"
    case hike = "Hike"
    case elliptical = "Elliptical"
    case race = "Race"
    case other = "Other"

    var id: String { rawValue }

    /// SF Symbol name for display in exercise cards and lists.
    var systemImage: String {
        switch self {
        case .run, .longRun, .tempoRun, .intervalRun, .easyRun, .recoveryRun:
            return "figure.run"
        case .walk:
            return "figure.walk"
        case .bike:
            return "figure.outdoor.cycle"
        case .swim:
            return "figure.pool.swim"
        case .hike:
            return "figure.hiking"
        case .elliptical:
            return "figure.elliptical"
        case .race:
            return "flag.checkered.2.crossed"
        case .other:
            return "figure.mixed.cardio"
        }
    }

    /// Accent color for cards and calendar indicators.
    var color: Color {
        switch self {
        case .run, .longRun:
            return .blue
        case .tempoRun, .intervalRun:
            return .orange
        case .easyRun, .recoveryRun:
            return .green
        case .walk:
            return .mint
        case .bike:
            return .purple
        case .swim:
            return .cyan
        case .hike:
            return .brown
        case .elliptical:
            return .indigo
        case .race:
            return .red
        case .other:
            return .gray
        }
    }

    /// Short lowercase key for CSV data entry.
    var csvKey: String {
        switch self {
        case .run: return "run"
        case .longRun: return "long"
        case .tempoRun: return "tempo"
        case .intervalRun: return "interval"
        case .easyRun: return "easy"
        case .recoveryRun: return "recovery"
        case .walk: return "walk"
        case .bike: return "bike"
        case .swim: return "swim"
        case .hike: return "hike"
        case .elliptical: return "elliptical"
        case .race: return "race"
        case .other: return "other"
        }
    }

    /// Looks up an exercise type by its CSV key (case-insensitive).
    /// Also recognizes "cross" as an alias for `.other`.
    static func fromCSV(_ key: String) -> ExerciseType? {
        let lowered = key.lowercased().trimmingCharacters(in: .whitespaces)
        if lowered == "cross" { return .other }
        return allCases.first { $0.csvKey == lowered }
    }
}
