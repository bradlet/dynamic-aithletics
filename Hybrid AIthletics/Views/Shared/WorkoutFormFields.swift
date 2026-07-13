//
//  WorkoutFormFields.swift
//  Hybrid AIthletics
//
//  Reusable Form sections describing a workout (name/type, duration, distance,
//  date, notes, felt rating). Shared by `RecordWorkoutSheet` (create) and
//  `WorkoutDetailSheet` (edit) so the two flows stay layout-identical.
//

import SwiftUI

/// The `Form` sections that describe a workout. Intended to be embedded
/// directly inside a parent `Form { ... }`.
///
/// All state is owned by the parent view via bindings — this view is a pure
/// presentational grouping. `distance` is expected to be in the user's display
/// units (miles or km depending on `useMetricUnits`); conversion to the
/// internal miles storage is the parent's responsibility. It is optional so
/// the field starts empty (placeholder only) instead of a literal `0.0` the
/// user has to delete; parents treat `nil` as zero on save.
///
/// `plannedSection` is an optional slot rendered between the distance and
/// date sections; the unified editor injects `PlannedTargetFields` there and
/// sets `usesCompletedHeaders` so the actuals read "Completed Duration" /
/// "Completed Distance" in contrast to the planned target.
struct WorkoutFormFields<PlannedSection: View>: View {
    @Binding var name: String
    @Binding var type: ExerciseType
    @Binding var hours: Int
    @Binding var minutes: Int
    @Binding var seconds: Int
    @Binding var distance: Double?
    @Binding var date: Date
    @Binding var notes: String
    @Binding var feltRating: Int
    @Binding var countsTowardMileage: Bool
    /// Retitles the duration/distance headers as "Completed …" when a
    /// planned section is shown alongside them.
    var usesCompletedHeaders: Bool = false
    @ViewBuilder var plannedSection: () -> PlannedSection

    @Environment(\.useMetricUnits) private var useMetricUnits

    var body: some View {
        nameAndTypeSection
        durationSection
        distanceSection
        plannedSection()
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
        Section(usesCompletedHeaders ? "Completed Duration" : "Duration") {
            DurationWheelPickers(hours: $hours, minutes: $minutes, seconds: $seconds)
        }
    }

    /// Distance input field and mileage-counting toggle. Unit label follows
    /// the user's preference.
    private var distanceSection: some View {
        Section {
            HStack {
                TextField("0.0", value: $distance, format: .number.precision(.fractionLength(1)))
                    .keyboardType(.decimalPad)
                    .accessibilityIdentifier("workoutForm.distanceField")
                Text(useMetricUnits ? "km" : "mi")
                    .foregroundStyle(.secondary)
            }
            Toggle("Counts Toward Mileage", isOn: $countsTowardMileage)
                .accessibilityIdentifier("workoutForm.countsTowardMileageToggle")
        } header: {
            Text(usesCompletedHeaders ? "Completed Distance" : "Distance")
        } footer: {
            if !countsTowardMileage {
                Text("Distance is tracked but excluded from mileage totals.")
            }
        }
    }

    /// Date picker (date only — time is not tracked).
    private var dateSection: some View {
        Section("Date") {
            DatePicker("When", selection: $date, displayedComponents: .date)
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

extension WorkoutFormFields where PlannedSection == EmptyView {
    /// Convenience initializer for forms without a planned target section
    /// (e.g. `RecordWorkoutSheet`), matching the pre-slot signature.
    init(
        name: Binding<String>,
        type: Binding<ExerciseType>,
        hours: Binding<Int>,
        minutes: Binding<Int>,
        seconds: Binding<Int>,
        distance: Binding<Double?>,
        date: Binding<Date>,
        notes: Binding<String>,
        feltRating: Binding<Int>,
        countsTowardMileage: Binding<Bool>
    ) {
        self.init(
            name: name,
            type: type,
            hours: hours,
            minutes: minutes,
            seconds: seconds,
            distance: distance,
            date: date,
            notes: notes,
            feltRating: feltRating,
            countsTowardMileage: countsTowardMileage,
            usesCompletedHeaders: false,
            plannedSection: { EmptyView() }
        )
    }
}
