//
//  AerobicTrainingView.swift
//  Hybrid AIthletics
//
//  Top-level view for the Aerobic Training tab.
//  Shows a monthly calendar with exercise dots, a weekly calendar with
//  planned exercises, mileage stats, and sheets for adding/recording.
//

import SwiftUI
import SwiftData
import AICoachCore

/// The aerobic training tab displaying a monthly overview and weekly exercise plan.
struct AerobicTrainingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.useMetricUnits) private var useMetricUnits
    @Query private var allExercises: [Exercise]
    @Query(sort: \Workout.date) private var allWorkouts: [Workout]

    /// The month displayed in the monthly calendar.
    @State private var selectedMonth: Date = Date()
    /// The Monday of the currently displayed week.
    @State private var selectedWeek: Date = Date().startOfWeek
    /// Controls the schedule exercise sheet.
    @State private var showAddExercise = false
    /// The date to default when scheduling a new exercise (set by the calendar button on a day).
    @State private var addExerciseDate: Date = Date()
    /// The exercise selected for recording a workout.
    @State private var recordingExercise: Exercise?
    /// The exercise selected for editing.
    @State private var editingExercise: Exercise?
    /// The request passed to the AI coach sheet when the user taps "Ask Coach".
    @State private var coachRequest: CoachingRequest?
    /// Quick-add request (records a workout directly without scheduling first).
    @State private var quickAddRequest: QuickAddRequest?
    /// Navigation request from monthly calendar tap to highlight a day in the weekly view.
    @State private var exerciseNavigationRequest: ExerciseNavigationRequest?

    /// Exercises scheduled within the currently displayed week, including virtual repeating exercises.
    private var weekExercises: [Exercise] {
        let start = selectedWeek.startOfDay
        let end = selectedWeek.endOfWeek

        // Concrete exercises scheduled this week
        let concrete = allExercises.filter { $0.scheduledDate >= start && $0.scheduledDate <= end }

        // Only show virtual repeating exercises for current week and future
        guard selectedWeek >= Date().startOfWeek else { return concrete }

        // Repeating exercises from other weeks
        let repeating = allExercises.filter { exercise in
            exercise.isRepeating
            && !(exercise.scheduledDate >= start && exercise.scheduledDate <= end)
        }

        // Include repeating exercises whose day-of-week has no matching concrete instance
        let virtual = repeating.filter { template in
            let targetDayIndex = template.scheduledDate.mondayBasedWeekdayIndex
            let alreadyExists = concrete.contains { concreteExercise in
                concreteExercise.scheduledDate.mondayBasedWeekdayIndex == targetDayIndex
                && concreteExercise.name == template.name
                && concreteExercise.type == template.type
            }
            return !alreadyExists
        }

        return concrete + virtual
    }

    /// Workouts recorded within the currently displayed week.
    private var weekWorkouts: [Workout] {
        let start = selectedWeek.startOfDay
        let end = selectedWeek.endOfWeek
        return allWorkouts.filter { $0.date >= start && $0.date <= end }
    }

    /// Calendar display items for the monthly overview.
    private var monthCalendarItems: [any CalendarDisplayable] {
        ExerciseVirtualExpansion.monthItems(allExercises: allExercises, month: selectedMonth)
    }

    /// Sum of planned exercise distances for the current week.
    private var plannedMiles: Double {
        weekExercises.reduce(0) { $0 + $1.distanceMiles }
    }

    /// Sum of recorded workout distances for the current week.
    private var completedMiles: Double {
        weekWorkouts.reduce(0) { $0 + $1.distanceMiles }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    MonthlyCalendarView(
                        selectedMonth: $selectedMonth,
                        items: monthCalendarItems,
                        onDayTap: handleMonthDayTap
                    )
                    .padding(.bottom, 8)
                    Divider()
                    weekHeader
                    Divider()
                    WeeklyCalendarView(
                        days: selectedWeek.daysInWeek(),
                        exercises: weekExercises,
                        workouts: weekWorkouts,
                        onAdd: { date in
                            addExerciseDate = date
                            showAddExercise = true
                        },
                        onQuickAdd: { date in
                            quickAddRequest = QuickAddRequest(date: date)
                        },
                        onRecord: { exercise in
                            recordingExercise = exercise
                        },
                        onEdit: { exercise in
                            editingExercise = exercise
                        },
                        navigationRequest: exerciseNavigationRequest
                    )
                }
            }
            .navigationTitle("Aerobic Training")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showAddExercise, onDismiss: {
                // After scheduling, navigate to and highlight the day so the
                // user sees their new exercise in the weekly view.
                exerciseNavigationRequest = ExerciseNavigationRequest(targetDate: addExerciseDate)
            }) {
                AddExerciseSheet(exercise: nil, defaultDate: addExerciseDate)
            }
            .sheet(item: $recordingExercise) { exercise in
                RecordWorkoutSheet(exercise: exercise, defaultDate: exercise.scheduledDate)
            }
            .sheet(item: $editingExercise) { exercise in
                AddExerciseSheet(exercise: exercise, defaultDate: exercise.scheduledDate)
            }
            .sheet(item: $quickAddRequest) { request in
                RecordWorkoutSheet(exercise: nil, defaultDate: request.date)
            }
            .sheet(item: $coachRequest) { request in
                AICoachSheet(request: request)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        coachRequest = buildCoachRequest()
                    } label: {
                        Label("Ask Coach", systemImage: "sparkles")
                    }
                }
            }
            .onChange(of: exerciseNavigationRequest) { _, newValue in
                guard let request = newValue else { return }
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(2.5))
                    if exerciseNavigationRequest?.id == request.id {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            exerciseNavigationRequest = nil
                        }
                    }
                }
            }
        }
    }

    // MARK: - Month Calendar Navigation

    /// Navigates the weekly view to the week containing the tapped day.
    /// Days with existing items get highlighted; empty days open the schedule sheet.
    private func handleMonthDayTap(_ day: Date) {
        withAnimation {
            selectedWeek = day.startOfWeek
        }
        if !day.isSameMonth(as: selectedMonth) {
            selectedMonth = day.startOfMonth
        }

        let hasItems = monthCalendarItems.contains {
            Calendar.current.isDate($0.displayDate, inSameDayAs: day)
        }
        if hasItems {
            exerciseNavigationRequest = ExerciseNavigationRequest(targetDate: day)
        } else {
            addExerciseDate = day
            showAddExercise = true
        }
    }

    /// Assembles a `CoachingRequest` from the last 4 weeks of workouts and
    /// the next 2 weeks of scheduled exercises. Called from the "Ask Coach"
    /// toolbar button; the query-owning top-level view is the right place to
    /// read SwiftData per the project's "no ViewModels" convention.
    private func buildCoachRequest() -> CoachingRequest {
        let now = Date()
        let calendar = Calendar.current
        let fourWeeksAgo = calendar.date(byAdding: .weekOfYear, value: -4, to: now) ?? now
        let twoWeeksAhead = calendar.date(byAdding: .weekOfYear, value: 2, to: now) ?? now

        let recent = allWorkouts
            .filter { $0.date >= fourWeeksAgo && $0.date <= now }
            .sorted { $0.date < $1.date }
            .map { CoachWorkout(from: $0) }

        let upcoming = allExercises
            .filter { $0.scheduledDate >= now.startOfDay && $0.scheduledDate <= twoWeeksAhead }
            .sorted { $0.scheduledDate < $1.scheduledDate }
            .map { CoachExercise(from: $0) }

        return CoachingRequest(
            recentWorkouts: recent,
            upcomingExercises: upcoming,
            useMetricUnits: useMetricUnits
        )
    }

    /// Header showing week navigation and mileage stats.
    private var weekHeader: some View {
        VStack(spacing: 8) {
            // Week navigation
            HStack {
                Button { changeWeek(by: -1) } label: {
                    Image(systemName: "chevron.left")
                }
                Spacer()
                Text(weekLabel)
                    .font(.subheadline.bold())
                Spacer()
                Button { changeWeek(by: 1) } label: {
                    Image(systemName: "chevron.right")
                }
            }
            // Mileage stats
            HStack(spacing: 16) {
                MileageStat(
                    label: "Planned",
                    value: plannedMiles.formattedDistance(metric: useMetricUnits)
                )
                MileageStat(
                    label: "Completed",
                    value: completedMiles.formattedDistance(metric: useMetricUnits)
                )
                // Completion fraction
                VStack(spacing: 2) {
                    Text("Progress")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(progressText)
                        .font(.caption.bold())
                        .foregroundStyle(progressColor)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }

    /// Formatted label for the current week, e.g. "Apr 7 - Apr 13, 2026".
    private var weekLabel: String {
        let start = selectedWeek
        let end = Calendar.current.date(byAdding: .day, value: 6, to: start) ?? start
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let endFormatter = DateFormatter()
        endFormatter.dateFormat = "MMM d, yyyy"
        return "\(formatter.string(from: start)) - \(endFormatter.string(from: end))"
    }

    /// Progress display text, e.g. "3.0 / 10.0 mi".
    private var progressText: String {
        let completed = completedMiles.toDisplayDistance(metric: useMetricUnits)
        let planned = plannedMiles.toDisplayDistance(metric: useMetricUnits)
        let unit = useMetricUnits ? "km" : "mi"
        return String(format: "%.1f / %.1f %@", completed, planned, unit)
    }

    /// Color indicating completion progress.
    private var progressColor: Color {
        guard plannedMiles > 0 else { return .secondary }
        let fraction = completedMiles / plannedMiles
        if fraction >= 1.0 { return .green }
        if fraction >= 0.5 { return .orange }
        return .red
    }

    /// Navigates forward or backward by one week.
    private func changeWeek(by weeks: Int) {
        if let newWeek = Calendar.current.date(byAdding: .weekOfYear, value: weeks, to: selectedWeek) {
            selectedWeek = newWeek.startOfWeek
        }
    }
}

// MARK: - Quick Add Request

/// Identifiable wrapper for the quick-add sheet presentation.
private struct QuickAddRequest: Identifiable {
    let id = UUID()
    let date: Date
}

/// A small stat display with a label and value.
private struct MileageStat: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.bold())
        }
    }
}

#Preview {
    AerobicTrainingView()
        .modelContainer(ModelContainerFactory.makePreviewContainer())
}
