//
//  ExerciseCardView.swift
//  Hybrid AIthletics
//
//  Displays a single planned exercise as a compact card.
//  Supports drag-and-drop between day swimlanes, swipe-to-delete, and tap-to-record.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// MARK: - Drag Transfer Type

/// Custom UTType for exercise drag-and-drop within the app.
extension UTType {
    static let exerciseDragItem = UTType(exportedAs: "com.hybridaithletics.exercise")
}

/// Lightweight transferable payload carrying only the exercise's UUID.
struct ExerciseDragItem: Transferable, Codable {
    let exerciseID: UUID

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .exerciseDragItem)
    }
}

// MARK: - Exercise Card

/// A compact card displaying an exercise's name, type icon, distance, and duration.
struct ExerciseCardView: View {
    let exercise: Exercise
    /// Called when the user taps the card to record a workout.
    let onRecord: () -> Void
    /// Called when the user taps to edit the exercise.
    let onEdit: () -> Void
    /// Whether a workout has already been recorded for this exercise.
    var hasRecordedWorkout: Bool = false
    /// Binding to the ID of the exercise currently showing its delete button (shared across all cards).
    @Binding var swipeDeleteActiveID: UUID?
    /// Whether this card displays a virtual repeating instance (template shown on a different week).
    var isVirtual: Bool = false
    @Environment(\.useMetricUnits) private var useMetricUnits
    @Environment(\.modelContext) private var modelContext
    @State private var showDeleteConfirmation = false

    /// Whether this card is currently in delete mode (red X visible).
    private var isInDeleteMode: Bool {
        swipeDeleteActiveID == exercise.id
    }

    var body: some View {
        HStack(spacing: 0) {
            cardContent
            if isInDeleteMode {
                deleteButton
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .draggable(ExerciseDragItem(exerciseID: exercise.id))
        .gesture(
            DragGesture(minimumDistance: 15)
                .onEnded { value in
                    let horizontal = value.translation.width
                    withAnimation(.spring(response: 0.3)) {
                        if horizontal < -60 {
                            swipeDeleteActiveID = exercise.id
                        } else if swipeDeleteActiveID == exercise.id {
                            swipeDeleteActiveID = nil
                        }
                    }
                }
        )
        .contextMenu {
            if !hasRecordedWorkout {
                Button { onRecord() } label: {
                    Label("Record Workout", systemImage: "checkmark.circle")
                }
            }
            Button { onEdit() } label: {
                Label("Edit", systemImage: "pencil")
            }
            Button(role: .destructive) { showDeleteConfirmation = true } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .confirmationDialog(
            isVirtual ? "Stop repeating \(exercise.name)?" : "Delete \(exercise.name)?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(isVirtual ? "Stop Repeating" : "Delete", role: .destructive) { deleteExerciseAndWorkouts() }
            Button("Cancel", role: .cancel) {
                withAnimation(.spring(response: 0.3)) { swipeDeleteActiveID = nil }
            }
        } message: {
            if isVirtual {
                Text("This exercise will no longer appear on future weeks. Past exercises and workout records will be preserved.")
            } else {
                Text("This will permanently delete the exercise and all associated workout records.")
            }
        }
    }

    /// The main card content (icon, name, metadata, record button).
    private var cardContent: some View {
        HStack(spacing: 8) {
            Image(systemName: exercise.type.systemImage)
                .foregroundStyle(exercise.type.color)
                .font(.caption)
            VStack(alignment: .leading, spacing: 1) {
                Text(exercise.name)
                    .font(.caption.bold())
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Text(exercise.distanceMiles.formattedDistance(metric: useMetricUnits))
                    Text("·")
                    Text(exercise.durationSeconds.formattedDuration)
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
            Spacer()
            if exercise.isRepeating {
                Image(systemName: "repeat")
                    .foregroundStyle(.secondary)
                    .font(.caption2)
            }
            if !hasRecordedWorkout {
                Button { onRecord() } label: {
                    Image(systemName: "checkmark.circle")
                        .foregroundStyle(.green)
                        .font(.callout)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(exercise.type.color.opacity(0.1))
    }

    /// Red X delete button revealed by swiping left on the card.
    private var deleteButton: some View {
        Button {
            showDeleteConfirmation = true
        } label: {
            Image(systemName: "xmark.circle.fill")
                .font(.title3)
                .foregroundStyle(.white)
        }
        .frame(width: 44)
        .frame(maxHeight: .infinity)
        .background(Color.red)
    }

    /// Deletes this exercise (its nested workout record goes with it), or
    /// stops recurrence for virtual repeating instances.
    private func deleteExerciseAndWorkouts() {
        withAnimation {
            if isVirtual {
                exercise.isRepeating = false
            } else {
                modelContext.delete(exercise)
            }
            swipeDeleteActiveID = nil
        }
    }
}

#Preview {
    let container = ModelContainerFactory.makePreviewContainer()
    let exercise = Exercise(
        name: "Morning Run",
        type: .run,
        durationSeconds: 1800,
        distanceMiles: 3.0,
        date: Date()
    )
    return ExerciseCardView(
        exercise: exercise,
        onRecord: {},
        onEdit: {},
        swipeDeleteActiveID: .constant(nil)
    )
    .modelContainer(container)
    .padding()
}
