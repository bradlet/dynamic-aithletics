//
//  PerformanceHubView.swift
//  Hybrid AIthletics
//
//  Swipeable three-page container shown at the top of the History tab.
//  Wraps the summary stat cards (page 1), the weekly mileage chart
//  (page 2), and the weekly average felt-rating chart (page 3) inside
//  a paged `TabView` with page-dot indicators.
//

import SwiftUI
import SwiftData

/// The Performance Hub: a left/right swipeable container with page dots
/// that exposes summary stats plus two weekly trend charts above the
/// History tab's monthly calendar.
///
/// The `TabView` has a fixed frame height — `TabView(.page)` expands to
/// fill its parent, so inside `HistoryView`'s `ScrollView`/`LazyVStack`
/// it would otherwise collapse to zero. Page dots are rendered by a
/// custom `PageIndicator` below the TabView so they don't overlap the
/// chart x-axis.
struct PerformanceHubView: View {
    /// Recorded exercises (pre-filtered to completed by parent).
    let exercises: [Exercise]

    @State private var selectedPage: Int = 0

    var body: some View {
        VStack(spacing: 8) {
            TabView(selection: $selectedPage) {
                SummaryStatsView(exercises: exercises)
                    .padding(.horizontal)
                    .tag(0)

                WeeklyChartView(exercises: exercises, configuration: .mileage)
                    .padding(.horizontal)
                    .tag(1)

                WeeklyChartView(exercises: exercises, configuration: .feeling)
                    .padding(.horizontal)
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 240)

            PageIndicator(currentIndex: selectedPage, count: 3)
        }
    }
}

/// Custom page indicator rendered below the `TabView`. Native dots sit
/// inside the TabView frame and overlap the chart x-axis, so we draw
/// our own below.
private struct PageIndicator: View {
    let currentIndex: Int
    let count: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { i in
                Circle()
                    .fill(i == currentIndex
                          ? Color.primary.opacity(0.85)
                          : Color.secondary.opacity(0.35))
                    .frame(width: 6, height: 6)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: currentIndex)
        .accessibilityElement()
        .accessibilityLabel("Page \(currentIndex + 1) of \(count)")
    }
}

#Preview {
    PerformanceHubView(exercises: [])
        .modelContainer(ModelContainerFactory.makePreviewContainer())
}
