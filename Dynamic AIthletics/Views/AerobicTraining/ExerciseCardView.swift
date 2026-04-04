//
//  ExerciseCardView.swift
//  Dynamic AIthletics
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
    static let exerciseDragItem = UTType(exportedAs: "com.dynamicaithletics.exercise")
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
    @Environment(\.useMetricUnits) private var useMetricUnits
    @Environment(\.modelContext) private var modelContext
    @State private var showDeleteConfirmation = false

    var body: some View {
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
            Button { onRecord() } label: {
                Image(systemName: "checkmark.circle")
                    .foregroundStyle(.green)
                    .font(.callout)
            }
            .buttonStyle(.plain)
        }
        .padding(8)
        .background(exercise.type.color.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
        .draggable(ExerciseDragItem(exerciseID: exercise.id))
        .contextMenu {
            Button { onRecord() } label: {
                Label("Record Workout", systemImage: "checkmark.circle")
            }
            Button { onEdit() } label: {
                Label("Edit", systemImage: "pencil")
            }
            Button(role: .destructive) { showDeleteConfirmation = true } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .confirmationDialog(
            "Delete \(exercise.name)?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) { deleteExercise() }
        } message: {
            Text("Any recorded workouts will keep their data but lose their link to this exercise.")
        }
    }

    /// Deletes this exercise from the model context.
    private func deleteExercise() {
        withAnimation {
            modelContext.delete(exercise)
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
        scheduledDate: Date()
    )
    return ExerciseCardView(exercise: exercise, onRecord: {}, onEdit: {})
        .modelContainer(container)
        .padding()
}
