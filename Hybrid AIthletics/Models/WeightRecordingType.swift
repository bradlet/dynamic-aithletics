//
//  WeightRecordingType.swift
//  Hybrid AIthletics
//
//  How the weight of a recorded strength workout was measured. Differentiating
//  the recording type lets us graph e.g. 1-rep max over time separately from
//  the average working weight across sets.
//

import Foundation

/// The kind of weight measurement captured by a `StrengthWorkout`.
enum WeightRecordingType: String, Codable, CaseIterable, Identifiable, Sendable {
    case maxWeight = "Max Weight"
    case averageWeight = "Average Weight"
    case firstSetWeight = "First Set Weight"
    case lastSetWeight = "Last Set Weight"
    case minWeight = "Min Weight"

    var id: String { rawValue }

    /// Short label for compact card display, e.g. "Max".
    var shortLabel: String {
        switch self {
        case .maxWeight: return "Max"
        case .averageWeight: return "Avg"
        case .firstSetWeight: return "First Set"
        case .lastSetWeight: return "Last Set"
        case .minWeight: return "Min"
        }
    }
}
