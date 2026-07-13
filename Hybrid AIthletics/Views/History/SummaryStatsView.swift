//
//  SummaryStatsView.swift
//  Hybrid AIthletics
//
//  Page 1 of the History tab's Performance Hub. Displays mileage stat
//  cards (all-time, this year, this month, this week) plus the current
//  week's average felt rating.
//

import SwiftUI
import SwiftData

/// A grid of stat cards summarizing mileage and effort across time windows.
/// Layout is a 3-row VStack: a full-width All Time card on top, then two
/// rows of two cards each. Sits on page 1 of `PerformanceHubView`.
struct SummaryStatsView: View {
    /// Recorded exercises (pre-filtered to completed by parent).
    let exercises: [Exercise]
    @Environment(\.useMetricUnits) private var useMetricUnits
    @Environment(\.weekStartDay) private var weekStartDay

    /// Exercises whose distance counts toward mileage totals. Walks and other
    /// opted-out activity stay visible in History but don't inflate stats.
    private var countingExercises: [Exercise] {
        exercises.filter(\.countsTowardMileage)
    }

    /// Total recorded mileage across all exercises.
    private var allTimeMiles: Double {
        countingExercises.reduce(0) { $0 + ($1.workout?.distanceMiles ?? 0) }
    }

    /// Total recorded mileage for the current calendar year.
    private var yearMiles: Double {
        let startOfYear = Date().startOfYear
        return countingExercises
            .filter { $0.date >= startOfYear }
            .reduce(0) { $0 + ($1.workout?.distanceMiles ?? 0) }
    }

    /// Total recorded mileage for the current calendar month.
    private var monthMiles: Double {
        let startOfMonth = Date().startOfMonth
        return countingExercises
            .filter { $0.date >= startOfMonth }
            .reduce(0) { $0 + ($1.workout?.distanceMiles ?? 0) }
    }

    /// Total recorded mileage for the current week (start per user preference).
    private var thisWeekMiles: Double {
        WorkoutAggregations.currentWeekMileage(
            exercises: exercises,
            anchor: Date(),
            firstWeekday: weekStartDay
        )
    }

    /// Floor of the current week's average felt rating. `0` when no
    /// workouts in the week have a recorded rating — maps to the
    /// `face.dashed` placeholder via `FeltRatingVisuals`.
    private var avgFeltRatingFloored: Int {
        guard let avg = WorkoutAggregations.currentWeekAverageFeltRating(
            exercises: exercises,
            anchor: Date(),
            firstWeekday: weekStartDay
        ) else {
            return 0
        }
        return Int(avg.rounded(.down))
    }

    var body: some View {
        VStack(spacing: 12) {
            StatCard(
                title: "All Time",
                value: allTimeMiles.formattedDistance(metric: useMetricUnits)
            )
            HStack(spacing: 12) {
                StatCard(title: "This Year", value: yearMiles.formattedDistance(metric: useMetricUnits))
                StatCard(title: "This Month", value: monthMiles.formattedDistance(metric: useMetricUnits))
            }
            VStack(spacing: 6) {
                Text("This Week")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                HStack(spacing: 12) {
                    StatCard(
                        title: "Total Distance",
                        value: thisWeekMiles.formattedDistance(metric: useMetricUnits)
                    )
                    IconStatCard(
                        title: "Feeling like",
                        systemImage: FeltRatingVisuals.symbolName(for: avgFeltRatingFloored),
                        tint: FeltRatingVisuals.tint(for: avgFeltRatingFloored)
                    )
                }
            }
        }
    }
}

/// A single stat card displaying a title and value.
private struct StatCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.bold())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
    }
}

/// A stat card variant whose value is an SF Symbol icon instead of text.
/// Shares its chrome with `StatCard` so the two render at matching heights.
private struct IconStatCard: View {
    let title: String
    let systemImage: String
    let tint: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Image(systemName: systemImage)
                .font(.system(size: 22, weight: .regular))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(tint)
                .contentTransition(.symbolEffect(.replace))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    SummaryStatsView(exercises: [])
        .padding()
        .modelContainer(ModelContainerFactory.makePreviewContainer())
}
