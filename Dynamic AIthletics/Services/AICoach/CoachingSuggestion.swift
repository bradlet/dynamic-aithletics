//
//  CoachingSuggestion.swift
//  Dynamic AIthletics
//
//  Value types that describe an AI coaching request (recent workouts +
//  upcoming planned exercises) and the coach's response.
//

import Foundation

/// Inputs to the AI coach: the athlete's recent training history and their
/// upcoming planned training.
///
/// The coach uses the recent workouts (including subjective `feltRating`)
/// to assess how the athlete has been handling their training load, then
/// suggests adaptations to the upcoming exercises. Conforms to `Identifiable`
/// so that it can drive `.sheet(item:)` presentations directly.
struct CoachingRequest: Identifiable {
    /// Stable identity used by SwiftUI sheet presentation.
    let id: UUID
    /// Completed workouts from the lookback window, chronologically ordered.
    let recentWorkouts: [Workout]
    /// Planned exercises in the forward-looking window, chronologically ordered.
    let upcomingExercises: [Exercise]
    /// Whether to render distances in kilometers (true) or miles (false).
    let useMetricUnits: Bool

    init(
        id: UUID = UUID(),
        recentWorkouts: [Workout],
        upcomingExercises: [Exercise],
        useMetricUnits: Bool
    ) {
        self.id = id
        self.recentWorkouts = recentWorkouts
        self.upcomingExercises = upcomingExercises
        self.useMetricUnits = useMetricUnits
    }
}

/// The coach's free-text response.
///
/// V1 is narrative text only. Structured edits (e.g. "change Monday's run
/// to 5 mi easy") are tracked as future work in the ADR.
struct CoachingResponse {
    /// The coach's full commentary and suggestions as plain text.
    let narrative: String
}
