//
//  WorkoutAggregations.swift
//  Hybrid AIthletics
//
//  Pure, stateless aggregation helpers used by the History tab's
//  Performance Hub. Groups recorded exercises into Monday-start weekly
//  buckets and computes mileage / felt-rating summaries. Each exercise's
//  placement uses its `date`; its metrics come from the nested `workout`.
//  Extracted so the math can be unit-tested without spinning up SwiftUI.
//

import Foundation

/// A single weekly data point for chart or stat-card consumption.
/// `weekStart` is Monday midnight for the week containing the data
/// and also serves as the Chart x-axis value. `value` is either total
/// miles or an average felt rating depending on the projection used.
struct WeeklyMetricPoint: Identifiable, Equatable {
    /// Monday midnight at the start of this week.
    let weekStart: Date
    /// Metric value for this week: total miles or average felt rating.
    /// Empty buckets always carry `0` per product spec.
    let value: Double

    var id: Date { weekStart }
}

/// Stateless aggregation helpers for the Performance Hub.
enum WorkoutAggregations {

    // MARK: - Bucketing primitive

    /// Groups `exercises` into the last `weekCount` Monday-start weeks,
    /// ending in the week containing `anchor`. Empty weeks are present
    /// with an empty array. Returned chronologically (oldest first).
    /// - Parameters:
    ///   - exercises: Source recorded exercises. Order irrelevant.
    ///   - weekCount: Number of weeks in the rolling window. Must be > 0.
    ///   - anchor: Date whose week becomes the tail of the window.
    static func weeklyBuckets(
        exercises: [Exercise],
        weekCount: Int,
        anchor: Date
    ) -> [(weekStart: Date, exercises: [Exercise])] {
        guard weekCount > 0 else { return [] }

        let calendar = Calendar.current
        let tailMonday = anchor.startOfWeek

        // Build the ordered list of week-start Mondays, oldest first.
        let weekStarts: [Date] = (0..<weekCount).compactMap { offset in
            let weeksBack = weekCount - 1 - offset
            return calendar.date(byAdding: .weekOfYear, value: -weeksBack, to: tailMonday)
        }

        // Group all exercises by their own week start for O(n) lookup.
        let grouped = Dictionary(grouping: exercises) { $0.date.startOfWeek }

        return weekStarts.map { start in
            (weekStart: start, exercises: grouped[start] ?? [])
        }
    }

    // MARK: - Mileage projections

    /// Sums recorded `distanceMiles` per week across the rolling window.
    /// Empty weeks yield `0`. Values are always in miles; callers apply
    /// metric conversion at the display layer.
    static func weeklyMileage(
        exercises: [Exercise],
        weekCount: Int,
        anchor: Date
    ) -> [WeeklyMetricPoint] {
        weeklyBuckets(exercises: exercises, weekCount: weekCount, anchor: anchor)
            .map { bucket in
                let total = bucket.exercises.reduce(0.0) { $0 + ($1.workout?.distanceMiles ?? 0) }
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
        anchor: Date
    ) -> [WeeklyMetricPoint] {
        weeklyBuckets(exercises: exercises, weekCount: weekCount, anchor: anchor)
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

    /// Total recorded miles in the Monday-Sunday week containing `anchor`.
    static func currentWeekMileage(
        exercises: [Exercise],
        anchor: Date
    ) -> Double {
        let weekStart = anchor.startOfWeek
        return exercises
            .filter { $0.date.startOfWeek == weekStart }
            .reduce(0.0) { $0 + ($1.workout?.distanceMiles ?? 0) }
    }

    /// Average recorded `feltRating` in the Mon-Sun week containing `anchor`,
    /// excluding workouts with `feltRating == 0`. Returns `nil` when no
    /// workouts in the week have a recorded rating (caller displays "—").
    static func currentWeekAverageFeltRating(
        exercises: [Exercise],
        anchor: Date
    ) -> Double? {
        let weekStart = anchor.startOfWeek
        let ratings = exercises
            .filter { $0.date.startOfWeek == weekStart }
            .compactMap { $0.workout?.feltRating }
            .filter { $0 > 0 }
        guard !ratings.isEmpty else { return nil }
        let sum = ratings.reduce(0, +)
        return Double(sum) / Double(ratings.count)
    }
}
