//
//  HistoryView.swift
//  Hybrid AIthletics
//
//  Container view for the History tab. Shows summary stats,
//  a monthly calendar, and a paginated list of all recorded workouts.
//

import SwiftUI
import SwiftData

/// The History tab combining summary statistics, a monthly calendar, and a workout log.
struct HistoryView: View {
    @Query(sort: \Workout.date, order: .reverse) private var allWorkouts: [Workout]
    @State private var selectedMonth: Date = Date()

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    SummaryStatsView(workouts: allWorkouts)
                    MonthlyCalendarView(selectedMonth: $selectedMonth, workouts: allWorkouts)
                    workoutListSection
                }
                .padding(.vertical)
            }
            .navigationTitle("History")
        }
    }

    /// Section header and workout list.
    private var workoutListSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent Workouts")
                .font(.headline)
                .padding(.horizontal)
            WorkoutListView(workouts: allWorkouts)
        }
    }
}

#Preview {
    HistoryView()
        .modelContainer(ModelContainerFactory.makePreviewContainer())
}
