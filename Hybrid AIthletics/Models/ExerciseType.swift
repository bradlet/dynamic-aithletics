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
        case .other:
            return .gray
        }
    }
}
