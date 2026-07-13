//
//  StrengthExerciseCard.swift
//  Hybrid AIthletics
//
//  A kanban card for one strength exercise: name, muscle group, and the most
//  recent recorded weight. Draggable between lanes/days; tap to record a
//  weight entry; context menu for moving, offloading, and deleting.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// MARK: - Drag Transfer Type

/// Custom UTType for strength exercise drag-and-drop within the app.
extension UTType {
    static let strengthExerciseDragItem = UTType(exportedAs: "com.hybridaithletics.strengthexercise")
}

/// Lightweight transferable payload carrying only the strength exercise's UUID.
struct StrengthExerciseDragItem: Transferable, Codable {
    let exerciseID: UUID

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .strengthExerciseDragItem)
    }
}

// MARK: - Card

/// A compact kanban card for a strength exercise.
struct StrengthExerciseCard: View {
    let exercise: StrengthExercise
    /// Called when the user taps the card to record a weight entry.
    let onRecord: () -> Void
    /// Called when the user picks a destination day from the context menu.
    let onMoveToDay: (Int) -> Void
    /// Called when the user toggles the exercise between active and offloaded.
    let onToggleOffloaded: () -> Void
    /// Called when the user confirms deletion.
    let onDelete: () -> Void

    @Environment(\.useMetricUnits) private var useMetricUnits
    @State private var showDeleteConfirmation = false
    @State private var showPlanEditor = false

    /// Cached formatter for the latest-workout date, e.g. "Jun 12".
    private static let workoutDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()

    var body: some View {
        Button(action: onRecord) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "dumbbell.fill")
                        .foregroundStyle(exercise.muscleGroup.color)
                        .font(.caption)
                    Text(exercise.name)
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: 0)
                }
                HStack(spacing: 6) {
                    Text(exercise.muscleGroup.rawValue)
                        .font(.caption2.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(exercise.muscleGroup.color.opacity(0.15))
                        .foregroundStyle(exercise.muscleGroup.color)
                        .clipShape(Capsule())
                    if let plan = exercise.plannedSummary {
                        Text(plan)
                            .font(.caption2.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.secondary.opacity(0.15))
                            .foregroundStyle(.secondary)
                            .clipShape(Capsule())
                    }
                    if let latest = exercise.latestWorkout {
                        Text(latestSummary(latest))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    } else {
                        Text("No records yet")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(exercise.muscleGroup.color.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(exercise.muscleGroup.color.opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("strengthCard.\(exercise.id.uuidString)")
        .draggable(StrengthExerciseDragItem(exerciseID: exercise.id))
        .contextMenu {
            Button { onRecord() } label: {
                Label("Record Weight", systemImage: "checkmark.circle")
            }
            Button { showPlanEditor = true } label: {
                Label("Edit Plan", systemImage: "list.number")
            }
            Menu {
                ForEach(0..<7, id: \.self) { dayIndex in
                    Button(Calendar.current.weekdaySymbols[dayIndex]) {
                        onMoveToDay(dayIndex)
                    }
                }
            } label: {
                Label("Move to Day", systemImage: "calendar")
            }
            Button { onToggleOffloaded() } label: {
                Label(
                    exercise.isOffloaded ? "Move to Active Plan" : "Offload",
                    systemImage: exercise.isOffloaded ? "tray.and.arrow.up" : "tray.and.arrow.down"
                )
            }
            Button(role: .destructive) { showDeleteConfirmation = true } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .sheet(isPresented: $showPlanEditor) {
            EditStrengthPlanSheet(exercise: exercise)
        }
        .confirmationDialog(
            "Delete \(exercise.name)?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) { onDelete() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete the exercise and all recorded weights.")
        }
    }

    /// One-line summary of the latest record, e.g. "185 lb · Max · Jun 12".
    private func latestSummary(_ workout: StrengthWorkout) -> String {
        let weight = workout.weightPounds.formattedWeight(metric: useMetricUnits)
        let date = Self.workoutDateFormatter.string(from: workout.date)
        return "\(weight) · \(workout.recordingType.shortLabel) · \(date)"
    }
}

#Preview {
    let exercise = StrengthExercise(
        name: "Barbell Bench Press",
        muscleGroup: .chest,
        plannedSets: 3,
        plannedReps: 8,
        workouts: [StrengthWorkout(weightPounds: 185, recordingType: .maxWeight)]
    )
    return StrengthExerciseCard(
        exercise: exercise,
        onRecord: {},
        onMoveToDay: { _ in },
        onToggleOffloaded: {},
        onDelete: {}
    )
    .modelContainer(ModelContainerFactory.makePreviewContainer())
    .padding()
}
