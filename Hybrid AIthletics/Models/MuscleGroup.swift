//
//  MuscleGroup.swift
//  Hybrid AIthletics
//
//  Muscle groups targeted by strength exercises. Decoding falls back to
//  `.other` for unknown raw values so exercise data loaded from a future
//  server-based library can introduce new groups without breaking old clients.
//

import Foundation
import SwiftUI

/// A muscle group targeted by a strength exercise.
enum MuscleGroup: String, Codable, CaseIterable, Identifiable, Sendable {
    case chest = "Chest"
    case back = "Back"
    case shoulders = "Shoulders"
    case biceps = "Biceps"
    case triceps = "Triceps"
    case forearms = "Forearms"
    case core = "Core"
    case quads = "Quads"
    case hamstrings = "Hamstrings"
    case glutes = "Glutes"
    case calves = "Calves"
    case fullBody = "Full Body"
    case other = "Other"

    var id: String { rawValue }

    /// Tolerant decoding: unknown raw values (e.g. from a newer server
    /// library) decode as `.other` instead of throwing.
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = MuscleGroup(rawValue: raw) ?? .other
    }

    /// Accent color for cards and library grouping.
    var color: Color {
        switch self {
        case .chest, .back: return .red
        case .shoulders, .biceps, .triceps, .forearms: return .orange
        case .core: return .yellow
        case .quads, .hamstrings, .glutes, .calves: return .purple
        case .fullBody: return .teal
        case .other: return .gray
        }
    }
}
