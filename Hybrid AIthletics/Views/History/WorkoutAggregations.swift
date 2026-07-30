//
//  WorkoutAggregations.swift
//  Hybrid AIthletics
//
//  Pure, stateless aggregation helpers used by the History tab's
//  Performance Hub. Groups recorded exercises into weekly buckets
//  (week start configurable via `firstWeekday`, default Sunday) and
//  computes mileage / felt-rating summaries. Each exercise's
//  placement uses its `date`; its metrics come from the nested `workout`.
//  Extracted so the math can be unit-tested without spinning up SwiftUI.
//

import Foundation

/// A single weekly data point for chart or stat-card consumption.
/// `weekStart` is midnight on the first day of the week containing the data
/// and also serves as the Chart x-axis value. `value` is either total
/// miles or an average felt rating depending on the projection used.
struct WeeklyMetricPoint: Identifiable, Equatable {
    /// Midnight at the start of this week (first weekday per configuration).
    let weekStart: Date
    /// Metric value for this week, or `nil` when the week has no data — the
    /// chart breaks its line there rather than plotting a false zero. Mileage
    /// never produces `nil`: an empty week genuinely *is* zero miles.
    let value: Double?

    var id: Date { weekStart }
}

/// Stateless aggregation helpers for the Performance Hub.
enum WorkoutAggregations {

    // MARK: - Bucketing primitive

    /// Groups `exercises` into the last `weekCount` weeks starting on
    /// `firstWeekday`, ending in the week containing `anchor`. Empty weeks
    /// are present with an empty array. Returned chronologically (oldest first).
    /// - Parameters:
    ///   - exercises: Source recorded exercises. Order irrelevant.
    ///   - weekCount: Number of weeks in the rolling window. Must be > 0.
    ///   - anchor: Date whose week becomes the tail of the window.
    ///   - firstWeekday: First day of the week (1=Sunday ... 7=Saturday).
    static func weeklyBuckets(
        exercises: [Exercise],
        weekCount: Int,
        anchor: Date,
        firstWeekday: Int = 1
    ) -> [(weekStart: Date, exercises: [Exercise])] {
        guard weekCount > 0 else { return [] }

        var calendar = Calendar.current
        calendar.firstWeekday = firstWeekday
        let tailWeekStart = calendar.dateInterval(of: .weekOfYear, for: anchor)?.start ?? anchor.startOfDay

        // Build the ordered list of week starts, oldest first.
        let weekStarts: [Date] = (0..<weekCount).compactMap { offset in
            let weeksBack = weekCount - 1 - offset
            return calendar.date(byAdding: .weekOfYear, value: -weeksBack, to: tailWeekStart)
        }

        // Group all exercises by their own week start for O(n) lookup.
        let grouped = Dictionary(grouping: exercises) {
            calendar.dateInterval(of: .weekOfYear, for: $0.date)?.start ?? $0.date.startOfDay
        }

        return weekStarts.map { start in
            (weekStart: start, exercises: grouped[start] ?? [])
        }
    }

    // MARK: - Mileage projections

    /// Sums recorded `distanceMiles` per week across the rolling window,
    /// excluding exercises opted out via `countsTowardMileage == false`.
    /// Empty weeks yield `0`. Values are always in miles; callers apply
    /// metric conversion at the display layer.
    static func weeklyMileage(
        exercises: [Exercise],
        weekCount: Int,
        anchor: Date,
        firstWeekday: Int = 1
    ) -> [WeeklyMetricPoint] {
        weeklyBuckets(exercises: exercises, weekCount: weekCount, anchor: anchor, firstWeekday: firstWeekday)
            .map { bucket in
                let total = bucket.exercises
                    .filter(\.countsTowardMileage)
                    .reduce(0.0) { $0 + ($1.workout?.distanceMiles ?? 0) }
                return WeeklyMetricPoint(weekStart: bucket.weekStart, value: total)
            }
    }

    // MARK: - Felt-rating projections

    /// Averages recorded `feltRating` per week, excluding exercises whose
    /// workout has `feltRating == 0` (unrecorded). Empty weeks and weeks with
    /// only unrated workouts both yield `0` per product spec.
    static func weeklyAverageFeltRating(
        exercises: [Exercise],
        weekCount: Int,
        anchor: Date,
        firstWeekday: Int = 1
    ) -> [WeeklyMetricPoint] {
        weeklyBuckets(exercises: exercises, weekCount: weekCount, anchor: anchor, firstWeekday: firstWeekday)
            .map { bucket in
                let ratings = bucket.exercises.compactMap { $0.workout?.feltRating }.filter { $0 > 0 }
                let average: Double
                if ratings.isEmpty {
                    average = 0
                } else {
                    let sum = ratings.reduce(0, +)
                    average = Double(sum) / Double(ratings.count)
                }
                return WeeklyMetricPoint(weekStart: bucket.weekStart, value: average)
            }
    }

    // MARK: - Stat-card helpers

    /// Total recorded miles in the week containing `anchor`, where the
    /// week starts on `firstWeekday` (1=Sunday ... 7=Saturday). Exercises
    /// opted out via `countsTowardMileage == false` are excluded.
    static func currentWeekMileage(
        exercises: [Exercise],
        anchor: Date,
        firstWeekday: Int = 1
    ) -> Double {
        var calendar = Calendar.current
        calendar.firstWeekday = firstWeekday
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: anchor)?.start
        return exercises
            .filter(\.countsTowardMileage)
            .filter { calendar.dateInterval(of: .weekOfYear, for: $0.date)?.start == weekStart }
            .reduce(0.0) { $0 + ($1.workout?.distanceMiles ?? 0) }
    }

    /// Average recorded `feltRating` in the week containing `anchor` (week
    /// starting on `firstWeekday`), excluding workouts with `feltRating == 0`.
    /// Returns `nil` when no workouts in the week have a recorded rating
    /// (caller displays "—").
    static func currentWeekAverageFeltRating(
        exercises: [Exercise],
        anchor: Date,
        firstWeekday: Int = 1
    ) -> Double? {
        var calendar = Calendar.current
        calendar.firstWeekday = firstWeekday
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: anchor)?.start
        let ratings = exercises
            .filter { calendar.dateInterval(of: .weekOfYear, for: $0.date)?.start == weekStart }
            .compactMap { $0.workout?.feltRating }
            .filter { $0 > 0 }
        guard !ratings.isEmpty else { return nil }
        let sum = ratings.reduce(0, +)
        return Double(sum) / Double(ratings.count)
    }
}
