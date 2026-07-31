//
//  WorkoutListView.swift
//  Hybrid AIthletics
//
//  A paginated, reverse-chronological list of all recorded workouts with
//  discrete prev/next page controls. Rows are tappable and present a
//  `WorkoutDetailSheet` for editing or deleting the workout. A navigation
//  request from the calendar view can jump the list to the page containing
//  a specific workout and briefly highlight its row.
//

import SwiftUI
import SwiftData

/// A request to focus a specific recorded exercise inside the list. A fresh
/// `id` is generated per tap so repeat taps of the same day still fire
/// `.onChange`. `workoutID` carries the `Exercise.id` of the target.
struct WorkoutNavigationRequest: Equatable, Identifiable {
    let id: UUID
    let workoutID: UUID

    init(workoutID: UUID) {
        self.id = UUID()
        self.workoutID = workoutID
    }
}

/// Displays recorded exercises in discrete pages, newest first. 10 per page.
struct WorkoutListView: View {
    /// Pre-sorted completed exercises (descending by date) from parent.
    let exercises: [Exercise]
    /// Navigation focus request from the monthly calendar. A new value jumps
    /// the list to the page containing the target exercise and briefly
    /// highlights that row.
    let navigationRequest: WorkoutNavigationRequest?

    @Environment(\.useMetricUnits) private var useMetricUnits

    @State private var currentPage = 0
    @State private var selectedExercise: Exercise?
    @State private var highlightedID: UUID?

    /// Exercises per page.
    private let pageSize = 10

    private var totalPages: Int {
        WorkoutListPagination.totalPages(count: exercises.count, pageSize: pageSize)
    }

    /// The slice of `exercises` visible on the current page.
    private var pageExercises: [Exercise] {
        let start = currentPage * pageSize
        guard start < exercises.count else { return [] }
        let end = min(start + pageSize, exercises.count)
        return Array(exercises[start..<end])
    }

    var body: some View {
        Group {
            if exercises.isEmpty {
                ContentUnavailableView(
                    "No Workouts Yet",
                    systemImage: "figure.run",
                    description: Text("Record a workout from your training plan to see it here.")
                )
            } else {
                VStack(spacing: 12) {
                    LazyVStack(spacing: 8) {
                        ForEach(pageExercises) { exercise in
                            Button {
                                selectedExercise = exercise
                            } label: {
                                WorkoutRow(
                                    exercise: exercise,
                                    useMetricUnits: useMetricUnits,
                                    isHighlighted: highlightedID == exercise.id
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    paginationControls
                }
                .padding(.horizontal)
            }
        }
        .sheet(item: $selectedExercise) { exercise in
            WorkoutDetailSheet(exercise: exercise)
        }
        .onChange(of: navigationRequest) { _, newValue in
            handleNavigation(newValue)
        }
        .onChange(of: exercises.count) { _, _ in
            clampPage()
        }
    }

    // MARK: - Pagination controls

    private var paginationControls: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if currentPage > 0 { currentPage -= 1 }
                }
            } label: {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
            }
            .buttonStyle(.plain)
            .disabled(currentPage == 0)
            .accessibilityLabel("Previous page")
            .accessibilityIdentifier("workoutList.prevPage")

            Spacer()

            Text("Page \(currentPage + 1) of \(totalPages)")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .accessibilityIdentifier("workoutList.pageLabel")

            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if currentPage < totalPages - 1 { currentPage += 1 }
                }
            } label: {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
            }
            .buttonStyle(.plain)
            .disabled(currentPage >= totalPages - 1)
            .accessibilityLabel("Next page")
            .accessibilityIdentifier("workoutList.nextPage")
        }
        .padding(.top, 4)
    }

    // MARK: - Navigation handling

    /// Jumps to the page containing `request.workoutID` and briefly highlights
    /// its row. Repeat taps of the same calendar day produce a new request id
    /// so `.onChange` re-fires even with the same workout id.
    private func handleNavigation(_ request: WorkoutNavigationRequest?) {
        guard let request,
              let index = exercises.firstIndex(where: { $0.id == request.workoutID })
        else { return }
        let targetPage = WorkoutListPagination.pageIndex(forItemAt: index, pageSize: pageSize)
        withAnimation(.easeInOut(duration: 0.25)) {
            currentPage = targetPage
            highlightedID = request.workoutID
        }
        // Fade the highlight after a brief dwell.
        let focusID = request.workoutID
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2.5))
            if highlightedID == focusID {
                withAnimation(.easeInOut(duration: 0.4)) {
                    highlightedID = nil
                }
            }
        }
    }

    /// Clamps `currentPage` into the valid range after the underlying list
    /// shrinks (e.g. the user deletes the last workout on the current page).
    private func clampPage() {
        if currentPage >= totalPages {
            currentPage = max(0, totalPages - 1)
        }
    }
}

// MARK: - Row

/// A single row displaying a recorded exercise's key details: name, date,
/// and the recorded distance, duration, and derived pace.
///
/// Exercises opted out of training progress (`countsTowardMileage == false`)
/// are dimmed and carry an explicit badge, so a walk never reads as a session
/// that contributed to the athlete's load.
private struct WorkoutRow: View {
    let exercise: Exercise
    let useMetricUnits: Bool
    let isHighlighted: Bool

    /// Recorded actuals. Falls back to planned values if `workout` is nil
    /// (shouldn't happen — this list is filtered to completed exercises).
    private var distanceMiles: Double { exercise.workout?.distanceMiles ?? exercise.distanceMiles }
    private var durationSeconds: Int { exercise.workout?.durationSeconds ?? exercise.durationSeconds }

    /// Whether this exercise was opted out of training progress.
    private var isNonTraining: Bool { !exercise.countsTowardMileage }

    var body: some View {
        HStack {
            Image(systemName: exercise.type.systemImage)
                .foregroundStyle(exercise.type.color)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(exercise.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if isNonTraining {
                    nonTrainingBadge
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(distanceMiles.formattedDistance(metric: useMetricUnits))
                    .font(.subheadline.bold())
                Text(durationSeconds.formattedDuration)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(durationSeconds.formattedPace(
                    distanceMiles: distanceMiles,
                    metric: useMetricUnits
                ))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
        // Dim the whole row rather than restyling each label, so the row
        // still reads as a unit and the highlight treatment is unaffected.
        .opacity(isNonTraining ? 0.55 : 1)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
        .background(
            Color.accentColor
                .opacity(isHighlighted ? 0.18 : 0),
            in: RoundedRectangle(cornerRadius: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(
                    Color.accentColor.opacity(isHighlighted ? 0.65 : 0),
                    lineWidth: 1.5
                )
        )
        .contentShape(RoundedRectangle(cornerRadius: 10))
        .animation(.easeInOut(duration: 0.3), value: isHighlighted)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("workoutRow.\(exercise.id.uuidString)")
        // The badge is folded into the row's own label — `children: .combine`
        // absorbs descendants, so it is not separately queryable.
        .accessibilityLabel(
            isNonTraining ? "\(exercise.name), not counted as training" : exercise.name
        )
    }

    /// Chip marking a row that was opted out of training progress. Echoes the
    /// hollow calendar dot with the same dashed-circle motif.
    private var nonTrainingBadge: some View {
        Label("Not training", systemImage: "circle.dashed")
            .labelStyle(.titleAndIcon)
            .font(.caption2.weight(.medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Capsule().fill(Color.secondary.opacity(0.15)))
            .padding(.top, 2)
    }
}

#Preview {
    ScrollView {
        WorkoutListView(exercises: [], navigationRequest: nil)
    }
    .modelContainer(ModelContainerFactory.makePreviewContainer())
}
