//
//  WeeklyChartView.swift
//  Hybrid AIthletics
//
//  Pages 2 and 3 of the Performance Hub. A parameterized line chart
//  that displays a weekly metric (mileage or average feeling) over
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
/// body. Captures the small differences between the mileage and feeling
/// variants (data source and y-scale).
struct WeeklyChartConfiguration {
    /// Title shown above the chart.
    let title: String
    /// Fixed y-axis domain, or `nil` to auto-scale from the data.
    let fixedYScale: ClosedRange<Double>?
    /// Spacing between y-axis ticks, or `nil` for automatic placement. Short
    /// fixed domains pin a stride so Charts labels every step of the scale
    /// (including its maximum) instead of every other one.
    let yAxisStride: Double?
    /// Projects recorded exercises into weekly points. The last parameter
    /// is the first weekday of the aggregation week (1=Sunday ... 7=Saturday).
    let projection: (_ exercises: [Exercise], _ weekCount: Int, _ anchor: Date, _ firstWeekday: Int) -> [WeeklyMetricPoint]

    static let mileage = WeeklyChartConfiguration(
        title: "Weekly Mileage",
        fixedYScale: nil,
        yAxisStride: nil,
        projection: WorkoutAggregations.weeklyMileage
    )

    /// Feeling runs 1–5, but the domain starts at 0 so a "Very Weak" week
    /// isn't glued to the frame's bottom edge.
    static let feeling = WeeklyChartConfiguration(
        title: "How it's been feeling",
        fixedYScale: 0...5,
        yAxisStride: 1,
        projection: WorkoutAggregations.weeklyAverageFeeling
    )
}

/// Parameterized line chart for a weekly metric. Shows the Performance
/// Hub's mileage and feeling charts via `WeeklyChartConfiguration`.
struct WeeklyChartView: View {
    let exercises: [Exercise]
    let configuration: WeeklyChartConfiguration

    @Environment(\.useMetricUnits) private var useMetricUnits
    @Environment(\.weekStartDay) private var weekStartDay
    @State private var selectedWindow: PerformanceTimeWindow = .oneMonth

    /// Derived chart points for the current window, one per week including
    /// weeks with no data (whose `value` is `nil`).
    private var points: [WeeklyMetricPoint] {
        configuration.projection(exercises, selectedWindow.weekCount, Date(), weekStartDay)
    }

    /// Contiguous runs of weeks that carry a value. Weeks without one are
    /// dropped, and each run becomes its own Charts series so the line
    /// breaks at the gap instead of drawing a chord across it.
    private var segments: [WeeklyChartSegment] {
        WeeklyChartSeries.segments(points)
    }

    /// Pinned x-domain spanning the whole selected window. Required because
    /// the marks no longer include valueless weeks — without this, a 6-month
    /// window whose only data is in the last 3 weeks would silently render
    /// as a 3-week chart.
    private var xDomain: ClosedRange<Date> {
        let dates = points.map(\.weekStart)
        guard let first = dates.first, let last = dates.last, first <= last else {
            let now = Date()
            return now...now.addingTimeInterval(1)
        }
        return first...last
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

    /// Y-scale domain for the chart. Rating charts clamp to their fixed
    /// scale; mileage auto-scales to the max value with a zero baseline so
    /// short/flat weeks are still visible.
    private var yScaleDomain: ClosedRange<Double> {
        if let fixed = configuration.fixedYScale {
            return fixed
        }
        let maxValue = points.compactMap(\.value).max() ?? 0
        // Minimum ceiling of 1 so an all-zero week still renders a baseline.
        let ceiling = max(maxValue * 1.1, 1)
        return 0...ceiling
    }

    /// Y-axis tick placement for this chart.
    private var yAxisValues: AxisMarkValues {
        guard let stride = configuration.yAxisStride else { return .automatic }
        return .stride(by: stride)
    }

    var body: some View {
        VStack(spacing: 8) {
            Text(configuration.title)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity, alignment: .leading)

            Chart {
                ForEach(segments) { segment in
                    ForEach(segment.points) { point in
                        LineMark(
                            x: .value("Week", point.weekStart),
                            y: .value("Value", point.value ?? 0),
                            series: .value("Segment", segment.id)
                        )
                        .interpolationMethod(.monotone)
                        .foregroundStyle(Color.accentColor)
                        .symbol(Circle().strokeBorder(lineWidth: 1.5))
                    }
                }
                // A one-week run has a zero-length path and so draws nothing.
                // Give it an explicit dot; where the line's own symbol does
                // render the two coincide exactly.
                ForEach(segments.filter(\.isSingleton)) { segment in
                    if let point = segment.points.first, let value = point.value {
                        PointMark(
                            x: .value("Week", point.weekStart),
                            y: .value("Value", value)
                        )
                        .foregroundStyle(Color.accentColor)
                        .symbol(Circle().strokeBorder(lineWidth: 1.5))
                    }
                }
            }
            .chartXScale(domain: xDomain)
            .chartYScale(domain: yScaleDomain)
            .chartLegend(.hidden)
            .chartYAxis {
                AxisMarks(position: .leading, values: yAxisValues) { value in
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

#Preview("Feeling") {
    WeeklyChartView(exercises: [], configuration: .feeling)
        .padding()
        .modelContainer(ModelContainerFactory.makePreviewContainer())
}
