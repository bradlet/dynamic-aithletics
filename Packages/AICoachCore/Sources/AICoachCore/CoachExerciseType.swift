//
//  CoachExerciseType.swift
//  AICoachCore
//
//  Exercise type enum with raw values matching the app's ExerciseType.
//  Contains only the data needed for prompt building — no UI properties
//  (systemImage, color) which remain in the app.
//

import Foundation

/// Categorizes exercises by activity type. Raw values match the app's
/// `ExerciseType` enum so conversions are lossless.
public enum CoachExerciseType: String, Codable, CaseIterable, Sendable {
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
}
