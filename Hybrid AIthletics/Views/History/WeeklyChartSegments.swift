//
//  WeeklyChartSegments.swift
//  Hybrid AIthletics
//
//  Splits a run of weekly metric points into contiguous stretches that
//  actually have data, so `WeeklyChartView` can draw a line that *breaks*
//  across weeks with no value instead of dipping to a false zero. Extracted
//  so the segmentation can be unit-tested without spinning up SwiftUI.
//

import Foundation

/// One contiguous run of weeks that all carry a value.
///
/// Swift Charts joins every `LineMark` that shares a `series` value, and
/// simply omitting a mark draws a straight chord across the gap rather than
/// breaking the line — so a chart with holes has to emit one series per run.
struct WeeklyChartSegment: Identifiable, Equatable {
    /// Chronological run number, starting at `0`. Doubles as the Charts
    /// `series` discriminator.
    let id: Int
    /// Points in this run, oldest first. Every element has a non-nil `value`.
    let points: [WeeklyMetricPoint]

    /// Whether this run holds a single week. A one-vertex path has no length,
    /// so the caller must draw an explicit `PointMark` for these.
    var isSingleton: Bool { points.count == 1 }
}

/// Stateless segmentation helpers for `WeeklyChartView`.
enum WeeklyChartSeries {

    /// Splits weekly points into contiguous runs of non-nil values, dropping
    /// the valueless weeks entirely. Runs are numbered from `0`, oldest first.
    ///
    /// An all-non-nil input (as the mileage projection always produces) yields
    /// exactly one segment, so segmented rendering is a no-op for that chart.
    /// - Parameter points: Weekly points in chronological order.
    /// - Returns: Contiguous runs, or an empty array when nothing has a value.
    static func segments(_ points: [WeeklyMetricPoint]) -> [WeeklyChartSegment] {
        var result: [WeeklyChartSegment] = []
        var run: [WeeklyMetricPoint] = []

        for point in points {
            if point.value != nil {
                run.append(point)
            } else if !run.isEmpty {
                result.append(WeeklyChartSegment(id: result.count, points: run))
                run = []
            }
        }
        if !run.isEmpty {
            result.append(WeeklyChartSegment(id: result.count, points: run))
        }
        return result
    }
}
