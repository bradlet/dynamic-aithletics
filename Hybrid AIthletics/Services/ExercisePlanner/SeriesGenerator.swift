//
//  SeriesGenerator.swift
//  Hybrid AIthletics
//
//  Pure expansion of an ExerciseSeriesSpec into dated occurrence values.
//  No SwiftData, no side effects — fully unit-testable.
//

import Foundation

/// Expands an `ExerciseSeriesSpec` into the concrete occurrences it describes.
enum SeriesGenerator {
    /// Hard cap on generated occurrences (weekly ≈ 7.7 years). Excess is truncated.
    static let maxOccurrences = 400

    /// Computes the dated occurrences for a spec, sorted ascending by date.
    ///
    /// Semantics:
    /// - `.oneOff` yields exactly one occurrence at `startDate`; `endDate` is ignored.
    /// - `.weekly` / `.biweekly` step 7 / 14 days from `startDate`.
    /// - `.monthly` adds `k` months to the original `startDate` for each step
    ///   (never iteratively month-by-month), so a Jan 31 start clamps to
    ///   Feb 28/29 but restores to Mar 31 — no permanent drift.
    /// - `endDate` is inclusive by calendar day; `endDate < startDate` yields [].
    /// - Progression: for 0-based occurrence index `i`, the deltas are applied
    ///   `i / everyN` times, and resulting values are clamped at 0.
    static func occurrences(for spec: ExerciseSeriesSpec) -> [SeriesOccurrence] {
        guard spec.cadence != .oneOff else {
            return [occurrence(for: spec, index: 0, date: spec.startDate)]
        }

        let calendar = Calendar.current
        let endDay = spec.endDate.startOfDay
        var result: [SeriesOccurrence] = []

        for index in 0..<maxOccurrences {
            let date: Date?
            switch spec.cadence {
            case .oneOff:
                date = nil
            case .weekly:
                date = calendar.date(byAdding: .day, value: 7 * index, to: spec.startDate)
            case .biweekly:
                date = calendar.date(byAdding: .day, value: 14 * index, to: spec.startDate)
            case .monthly:
                date = calendar.date(byAdding: .month, value: index, to: spec.startDate)
            }
            guard let date, date.startOfDay <= endDay else { break }
            result.append(occurrence(for: spec, index: index, date: date))
        }
        return result
    }

    /// Builds one occurrence with progression applied for the given 0-based index.
    private static func occurrence(for spec: ExerciseSeriesSpec, index: Int, date: Date) -> SeriesOccurrence {
        let steps: Int
        if let progression = spec.progression {
            steps = index / max(1, progression.everyN)
        } else {
            steps = 0
        }
        let distanceDelta = spec.progression?.distanceDeltaMiles ?? 0
        let durationDelta = spec.progression?.durationDeltaSeconds ?? 0
        return SeriesOccurrence(
            date: date,
            distanceMiles: max(0, spec.baseDistanceMiles + Double(steps) * distanceDelta),
            durationSeconds: max(0, spec.baseDurationSeconds + steps * durationDelta)
        )
    }
}
