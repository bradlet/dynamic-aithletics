//
//  PlannedTargetFields.swift
//  Hybrid AIthletics
//
//  "Planned Target" form section shown alongside the completed fields in
//  the unified workout editor, so a recorded exercise's plan and actuals
//  are visible and editable side by side.
//

import SwiftUI

/// A single `Form` section editing an exercise's planned target distance and
/// duration. State is owned by the parent via bindings; `distance` is in the
/// user's display units (parent converts to miles on save) and is optional so
/// an unset target shows the placeholder instead of a literal `0.0`. The
/// footer shows a live plan-vs-completed hint tinted with the
/// `PlanPerformance` color.
struct PlannedTargetFields: View {
    @Binding var distance: Double?
    @Binding var hours: Int
    @Binding var minutes: Int
    @Binding var seconds: Int
    /// The live completed distance from the parent form, in display units.
    /// `nil` means the field is empty (treated as zero).
    let completedDistance: Double?

    @Environment(\.useMetricUnits) private var useMetricUnits

    var body: some View {
        Section {
            HStack {
                TextField("0.0", value: $distance, format: .number.precision(.fractionLength(1)))
                    .keyboardType(.decimalPad)
                    .accessibilityIdentifier("workoutForm.plannedDistanceField")
                Text(useMetricUnits ? "km" : "mi")
                    .foregroundStyle(.secondary)
            }
            DurationWheelPickers(hours: $hours, minutes: $minutes, seconds: $seconds)
        } header: {
            Text("Planned Target")
        } footer: {
            if let performance {
                Text("Completed \(completedMiles.formattedDistance(metric: useMetricUnits)) of \(plannedMiles.formattedDistance(metric: useMetricUnits)) planned")
                    .foregroundStyle(performance.color)
            }
        }
    }

    /// The live completed distance converted back to miles for classification.
    private var completedMiles: Double {
        let display = completedDistance ?? 0
        return useMetricUnits ? display / 1.60934 : display
    }

    /// The edited planned distance converted back to miles for classification.
    private var plannedMiles: Double {
        let display = distance ?? 0
        return useMetricUnits ? display / 1.60934 : display
    }

    /// Performance of the completed distance against the edited plan.
    private var performance: PlanPerformance? {
        PlanPerformance.classify(completedMiles: completedMiles, plannedMiles: plannedMiles)
    }
}

#Preview {
    Form {
        PlannedTargetFields(
            distance: .constant(3.0 as Double?),
            hours: .constant(0),
            minutes: .constant(30),
            seconds: .constant(0),
            completedDistance: 4.1
        )
    }
}
