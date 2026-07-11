//
//  PlanPerformance.swift
//  Hybrid AIthletics
//
//  Classifies a recorded workout's distance against its planned distance
//  so exercise cards can tint their completed half by performance.
//

import SwiftUI

/// Classification of a recorded workout's distance against its plan.
/// Extracted from `ExerciseCardView` so tint selection is unit-testable.
enum PlanPerformance: Hashable {
    case belowPlan
    case atPlan
    case abovePlan

    /// Distances within this many miles of plan count as at-plan.
    /// Absorbs km↔mi round-trip drift from metric entry and the
    /// 1-decimal display precision of `formattedDistance(metric:)`.
    static let defaultToleranceMiles = 0.05

    /// Classifies a completed distance against a planned distance (both in miles).
    /// Returns `nil` when `completedMiles` is `nil` (nothing recorded → no split shown).
    static func classify(
        completedMiles: Double?,
        plannedMiles: Double,
        toleranceMiles: Double = defaultToleranceMiles
    ) -> PlanPerformance? {
        guard let completedMiles else { return nil }
        let delta = completedMiles - plannedMiles
        if abs(delta) <= toleranceMiles { return .atPlan }
        return delta < 0 ? .belowPlan : .abovePlan
    }

    /// Tint for the completed (left) half of the split card. Never red.
    var color: Color {
        switch self {
        case .belowPlan: .yellow
        case .atPlan: .green
        case .abovePlan: .performanceGold
        }
    }
}

extension Color {
    /// Goldenrod used for above-plan performance (SwiftUI has no system gold).
    static let performanceGold = Color(red: 0.83, green: 0.62, blue: 0.09)
}
