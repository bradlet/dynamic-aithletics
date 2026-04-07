//
//  WorkoutListView.swift
//  Hybrid AIthletics
//
//  A paginated, reverse-chronological list of all recorded workouts.
//  Loads more items as the user scrolls to the bottom.
//

import SwiftUI
import SwiftData

/// Displays recorded workouts in a paginated list, newest first.
struct WorkoutListView: View {
    /// Pre-sorted workouts (descending by date) from parent.
    let workouts: [Workout]
    @Environment(\.useMetricUnits) private var useMetricUnits

    /// Number of workouts currently visible; increases on scroll.
    @State private var visibleCount = 20

    /// Page size for loading more workouts.
    private let pageSize = 20

    var body: some View {
        if workouts.isEmpty {
            ContentUnavailableView(
                "No Workouts Yet",
                systemImage: "figure.run",
                description: Text("Record a workout from your training plan to see it here.")
            )
        } else {
            LazyVStack(spacing: 8) {
                ForEach(workouts.prefix(visibleCount)) { workout in
                    WorkoutRow(workout: workout, useMetricUnits: useMetricUnits)
                }
                // Sentinel to trigger loading more items.
                if visibleCount < workouts.count {
                    ProgressView()
                        .onAppear {
                            visibleCount += pageSize
                        }
                }
            }
            .padding(.horizontal)
        }
    }
}

/// A single row displaying a workout's key details.
private struct WorkoutRow: View {
    let workout: Workout
    let useMetricUnits: Bool

    var body: some View {
        HStack {
            Image(systemName: workout.type.systemImage)
                .foregroundStyle(workout.type.color)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text(workout.name)
                    .font(.headline)
                Text(workout.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(workout.distanceMiles.formattedDistance(metric: useMetricUnits))
                    .font(.subheadline.bold())
                Text(workout.durationSeconds.formattedDuration)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    ScrollView {
        WorkoutListView(workouts: [])
    }
    .modelContainer(ModelContainerFactory.makePreviewContainer())
}
