//
//  WorkoutFormFields.swift
//  Hybrid AIthletics
//
//  Reusable Form sections describing a workout (name/type, duration, distance,
//  date, notes, felt rating). Shared by `RecordWorkoutSheet` (create) and
//  `WorkoutDetailSheet` (edit) so the two flows stay layout-identical.
//

import SwiftUI

/// The six `Form` sections that describe a workout. Intended to be embedded
/// directly inside a parent `Form { ... }`.
///
/// All state is owned by the parent view via bindings — this view is a pure
/// presentational grouping. `distance` is expected to be in the user's display
/// units (miles or km depending on `useMetricUnits`); conversion to the
/// internal miles storage is the parent's responsibility.
struct WorkoutFormFields: View {
    @Binding var name: String
    @Binding var type: ExerciseType
    @Binding var hours: Int
    @Binding var minutes: Int
    @Binding var seconds: Int
    @Binding var distance: Double
    @Binding var date: Date
    @Binding var notes: String
    @Binding var feltRating: Int

    @Environment(\.useMetricUnits) private var useMetricUnits

    var body: some View {
        nameAndTypeSection
        durationSection
        distanceSection
        dateSection
        notesSection
        feltRatingSection
    }

    // MARK: - Sections

    /// Name and exercise type picker.
    private var nameAndTypeSection: some View {
        Section {
            TextField("Workout Name", text: $name)
                .accessibilityIdentifier("workoutForm.nameField")
            Picker("Type", selection: $type) {
                ForEach(ExerciseType.allCases) { exerciseType in
                    Label(exerciseType.rawValue, systemImage: exerciseType.systemImage)
                        .tag(exerciseType)
                }
            }
        }
    }

    /// Duration pickers for hours, minutes, seconds.
    private var durationSection: some View {
        Section("Duration") {
            HStack {
                Picker("Hours", selection: $hours) {
                    ForEach(0..<24) { Text("\($0)h").tag($0) }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                Picker("Minutes", selection: $minutes) {
                    ForEach(0..<60) { Text("\($0)m").tag($0) }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                Picker("Seconds", selection: $seconds) {
                    ForEach(0..<60) { Text("\($0)s").tag($0) }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
            }
            .frame(height: 120)
        }
    }

    /// Distance input field. Unit label follows the user's preference.
    private var distanceSection: some View {
        Section("Distance") {
            HStack {
                TextField("0.0", value: $distance, format: .number.precision(.fractionLength(1)))
                    .keyboardType(.decimalPad)
                    .accessibilityIdentifier("workoutForm.distanceField")
                Text(useMetricUnits ? "km" : "mi")
                    .foregroundStyle(.secondary)
            }
        }
    }

    /// Date and time picker.
    private var dateSection: some View {
        Section("Date & Time") {
            DatePicker("When", selection: $date)
        }
    }

    /// Notes text field.
    private var notesSection: some View {
        Section("Notes") {
            TextField("How did it go?", text: $notes, axis: .vertical)
                .lineLimit(3...6)
        }
    }

    /// Subjective 1–10 effort rating that feeds the AI coach's load assessment.
    private var feltRatingSection: some View {
        Section("How did it feel?") {
            FeltRatingPicker(value: $feltRating)
        }
    }
}
