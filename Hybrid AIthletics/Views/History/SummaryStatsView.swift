//
//  SummaryStatsView.swift
//  Hybrid AIthletics
//
//  Displays aggregate mileage statistics: all-time, this year, and this month.
//

import SwiftUI
import SwiftData

/// Shows three stat cards with total mileage across different time periods.
struct SummaryStatsView: View {
    /// All recorded workouts (pre-fetched by parent).
    let workouts: [Workout]
    @Environment(\.useMetricUnits) private var useMetricUnits

    /// Total mileage across all recorded workouts.
    private var allTimeMiles: Double {
        workouts.reduce(0) { $0 + $1.distanceMiles }
    }

    /// Total mileage for the current calendar year.
    private var yearMiles: Double {
        let startOfYear = Date().startOfYear
        return workouts
            .filter { $0.date >= startOfYear }
            .reduce(0) { $0 + $1.distanceMiles }
    }

    /// Total mileage for the current calendar month.
    private var monthMiles: Double {
        let startOfMonth = Date().startOfMonth
        return workouts
            .filter { $0.date >= startOfMonth }
            .reduce(0) { $0 + $1.distanceMiles }
    }

    var body: some View {
        HStack(spacing: 12) {
            StatCard(title: "All Time", value: allTimeMiles.formattedDistance(metric: useMetricUnits))
            StatCard(title: "This Year", value: yearMiles.formattedDistance(metric: useMetricUnits))
            StatCard(title: "This Month", value: monthMiles.formattedDistance(metric: useMetricUnits))
        }
        .padding(.horizontal)
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
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    SummaryStatsView(workouts: [])
        .modelContainer(ModelContainerFactory.makePreviewContainer())
}
