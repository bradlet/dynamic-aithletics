//
//  WeeklyChartView.swift
//  Hybrid AIthletics
//
//  Pages 2 and 3 of the Performance Hub. A parameterized line chart
//  that displays a weekly metric (mileage or average felt rating) over
//  a selectable rolling window (1M / 3M / 6M). A single view is reused
//  for both charts because they differ only in data source, y-scale,
//  and axis label — captured in `WeeklyChartConfiguration`.
//

import SwiftUI
import SwiftData
import Charts

/// Selectable rolling time windows for the Performance Hub weekly charts.
enum PerformanceTimeWindow: String, CaseIterable, Identifiable {
    case oneMonth
    case threeMonth
    case sixMonth

    var id: String { rawValue }

    /// Number of Sunday-start weeks this window covers.
    var weekCount: Int {
        switch self {
        case .oneMonth:   return 4
        case .threeMonth: return 13
        case .sixMonth:   return 26
        }
    }

    /// Short label for the segmented pill.
    var label: String {
        switch self {
        case .oneMonth:   return "1M"
        case .threeMonth: return "3M"
        case .sixMonth:   return "6M"
        }
    }

    /// Stride used for x-axis *labels*. Tick marks and grid lines are
    /// still drawn every week regardless of this stride — only the
    /// textual labels are thinned out so wide windows stay readable.
    var labelStride: (component: Calendar.Component, count: Int) {
        switch self {
        case .oneMonth:   return (.weekOfYear, 1)
        case .threeMonth: return (.weekOfYear, 4)
        case .sixMonth:   return (.month, 2)
        }
    }

    /// Whether x-axis labels include the day of month. The 6-month
    /// window uses month-only labels ("Apr") to avoid clutter; the
    /// shorter windows use month + day ("Apr 6").
    var labelIncludesDay: Bool {
        switch self {
        case .oneMonth, .threeMonth: return true
        case .sixMonth:              return false
        }
    }
}

/// Per-chart configuration that slots into the shared `WeeklyChartView`
/// body. Captures the small differences between the mileage and felt-
/// rating variants (data source, y-scale, axis label).
struct WeeklyChartConfiguration {
    /// Title shown above the chart.
    let title: String
    /// Whether the y-axis is clamped to `0...10` (felt rating).
    let fixedYScaleZeroToTen: Bool
    /// Projects recorded exercises into weekly points.
    let projection: (_ exercises: [Exercise], _ weekCount: Int, _ anchor: Date) -> [WeeklyMetricPoint]
    /// Whether the y value represents a distance in miles. When `true`
    /// the chart applies metric conversion and shows a unit axis label.
    let isDistance: Bool

    static let mileage = WeeklyChartConfiguration(
        title: "Weekly Mileage",
        fixedYScaleZeroToTen: false,
        projection: WorkoutAggregations.weeklyMileage,
        isDistance: true
    )

    static let feltRating = WeeklyChartConfiguration(
        title: "How it's been feeling",
        fixedYScaleZeroToTen: true,
        projection: WorkoutAggregations.weeklyAverageFeltRating,
        isDistance: false
    )
}

/// Parameterized line chart for a weekly metric. Shows the Performance
/// Hub's mileage and felt-rating charts via `WeeklyChartConfiguration`.
struct WeeklyChartView: View {
    let exercises: [Exercise]
    let configuration: WeeklyChartConfiguration

    @Environment(\.useMetricUnits) private var useMetricUnits
    @State private var selectedWindow: PerformanceTimeWindow = .oneMonth

    /// Derived chart points for the current window. For distance charts
    /// we materialize a converted copy when metric is on so `LineMark`
    /// positions and the axis label stay aligned.
    private var points: [WeeklyMetricPoint] {
        let raw = configuration.projection(exercises, selectedWindow.weekCount, Date())
        guard configuration.isDistance, useMetricUnits else { return raw }
        return raw.map {
            WeeklyMetricPoint(weekStart: $0.weekStart, value: $0.value)
        }
    }

    /// Subset of `points` dates used for x-axis tick marks and labels.
    /// Filtered from the actual week-start data dates so ticks align
    /// exactly with plotted points.
    private var labelDates: [Date] {
        let dates = points.map(\.weekStart)
        guard let first = dates.first else { return [] }
        let (component, count) = selectedWindow.labelStride
        return dates.filter { date in
            let comps = Calendar.current.dateComponents([component], from: first, to: date)
            let diff: Int
            switch component {
            case .weekOfYear: diff = comps.weekOfYear ?? 0
            case .month:      diff = comps.month ?? 0
            default:          diff = 0
            }
            return diff % count == 0
        }
    }

    /// Y-scale domain for the chart. Felt rating is clamped to the
    /// rating scale; mileage auto-scales to the max value with a zero
    /// baseline so short/flat weeks are still visible.
    private var yScaleDomain: ClosedRange<Double> {
        if configuration.fixedYScaleZeroToTen {
            return 0...10
        }
        let maxValue = points.map(\.value).max() ?? 0
        // Minimum ceiling of 1 so an all-zero week still renders a baseline.
        let ceiling = max(maxValue * 1.1, 1)
        return 0...ceiling
    }

    var body: some View {
        VStack(spacing: 8) {
            Text(configuration.title)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity, alignment: .leading)

            Chart(points) { point in
                LineMark(
                    x: .value("Week", point.weekStart),
                    y: .value("Value", point.value)
                )
                .interpolationMethod(.monotone)
                .symbol(Circle().strokeBorder(lineWidth: 1.5))
            }
            .chartYScale(domain: yScaleDomain)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let d = value.as(Double.self) {
                            Text("\(Int(d))")
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: labelDates) { _ in
                    AxisTick()
                    if selectedWindow.labelIncludesDay {
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    } else {
                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                    }
                }
            }
            .frame(height: 150)
            .animation(.easeInOut(duration: 0.35), value: selectedWindow)
            .animation(.easeInOut(duration: 0.35), value: useMetricUnits)

            Picker("Window", selection: $selectedWindow) {
                ForEach(PerformanceTimeWindow.allCases) { window in
                    Text(window.label).tag(window)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}

#Preview("Mileage") {
    WeeklyChartView(exercises: [], configuration: .mileage)
        .padding()
        .modelContainer(ModelContainerFactory.makePreviewContainer())
}

#Preview("Felt Rating") {
    WeeklyChartView(exercises: [], configuration: .feltRating)
        .padding()
        .modelContainer(ModelContainerFactory.makePreviewContainer())
}
