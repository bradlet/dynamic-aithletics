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

/// A request to focus a specific workout inside the list. A fresh `id` is
/// generated per tap so repeat taps of the same day still fire `.onChange`.
struct WorkoutNavigationRequest: Equatable, Identifiable {
    let id: UUID
    let workoutID: UUID

    init(workoutID: UUID) {
        self.id = UUID()
        self.workoutID = workoutID
    }
}

/// Displays recorded workouts in discrete pages, newest first. 10 per page.
struct WorkoutListView: View {
    /// Pre-sorted workouts (descending by date) from parent.
    let workouts: [Workout]
    /// Navigation focus request from the monthly calendar. A new value jumps
    /// the list to the page containing `workoutID` and briefly highlights
    /// that row.
    let navigationRequest: WorkoutNavigationRequest?

    @Environment(\.useMetricUnits) private var useMetricUnits

    @State private var currentPage = 0
    @State private var selectedWorkout: Workout?
    @State private var highlightedID: UUID?

    /// Workouts per page.
    private let pageSize = 10

    private var totalPages: Int {
        WorkoutListPagination.totalPages(count: workouts.count, pageSize: pageSize)
    }

    /// The slice of `workouts` visible on the current page.
    private var pageWorkouts: [Workout] {
        let start = currentPage * pageSize
        guard start < workouts.count else { return [] }
        let end = min(start + pageSize, workouts.count)
        return Array(workouts[start..<end])
    }

    var body: some View {
        Group {
            if workouts.isEmpty {
                ContentUnavailableView(
                    "No Workouts Yet",
                    systemImage: "figure.run",
                    description: Text("Record a workout from your training plan to see it here.")
                )
            } else {
                VStack(spacing: 12) {
                    LazyVStack(spacing: 8) {
                        ForEach(pageWorkouts) { workout in
                            Button {
                                selectedWorkout = workout
                            } label: {
                                WorkoutRow(
                                    workout: workout,
                                    useMetricUnits: useMetricUnits,
                                    isHighlighted: highlightedID == workout.id
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
        .sheet(item: $selectedWorkout) { workout in
            WorkoutDetailSheet(workout: workout)
        }
        .onChange(of: navigationRequest) { _, newValue in
            handleNavigation(newValue)
        }
        .onChange(of: workouts.count) { _, _ in
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
              let index = workouts.firstIndex(where: { $0.id == request.workoutID })
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

/// A single row displaying a workout's key details: name, date, distance,
/// duration, and derived pace.
private struct WorkoutRow: View {
    let workout: Workout
    let useMetricUnits: Bool
    let isHighlighted: Bool

    var body: some View {
        HStack {
            Image(systemName: workout.type.systemImage)
                .foregroundStyle(workout.type.color)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text(workout.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
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
                Text(workout.durationSeconds.formattedPace(
                    distanceMiles: workout.distanceMiles,
                    metric: useMetricUnits
                ))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
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
        .accessibilityIdentifier("workoutRow.\(workout.id.uuidString)")
        .accessibilityLabel(workout.name)
    }
}

#Preview {
    ScrollView {
        WorkoutListView(workouts: [], navigationRequest: nil)
    }
    .modelContainer(ModelContainerFactory.makePreviewContainer())
}
