//
//  AICoachPromptBuilder.swift
//  Hybrid AIthletics
//
//  Pure function that turns a CoachingRequest into the prompt text sent to
//  the on-device LLM. Kept as a non-actor namespace enum so it is trivial
//  to test without touching any runtime state.
//

import Foundation

/// Stateless helpers for building the prompt passed to the AI coach.
enum AICoachPromptBuilder {

    /// Date formatter used for workout/exercise line prefixes. Cached per
    /// project convention (never allocate in computed properties).
    private static let lineDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd EEE" // e.g. "2026-04-06 Mon"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    /// System preamble that establishes the coach persona and response style.
    ///
    /// Structured as explicit rules with a bullet-point output format to help
    /// the 4B model stay focused and avoid degenerate looping.
    static let systemPreamble: String = """
    You are an experienced competitive running coach. Review the athlete's \
    recent training and upcoming plan, then give concrete, conservative \
    suggestions for adaptations — adjusting workout type, duration, distance, \
    intensity, or adding/removing sessions.

    Rules:
    - ONLY reference workouts and sessions listed below.
    - Weigh the athlete's perceived exertion (RPE, 1–10) when assessing load.
    - Respond with 3–5 bullet points. Each bullet is one specific suggestion.
    - Keep the total response under 200 words. Do not repeat yourself.
    """

    /// Builds the full prompt string for the given request.
    /// - Parameter request: The coaching request to serialize.
    /// - Returns: A prompt ready to be tokenized by the underlying model.
    static func buildPrompt(for request: CoachingRequest) -> String {
        var sections: [String] = [systemPreamble, ""]

        sections.append("Recent training (\(request.recentWorkouts.count) workouts):")
        if request.recentWorkouts.isEmpty {
            sections.append("- (no workouts recorded in the lookback window)")
        } else {
            for workout in request.recentWorkouts {
                sections.append(workoutLine(workout, metric: request.useMetricUnits))
            }
        }
        sections.append("")

        sections.append("Upcoming plan (\(request.upcomingExercises.count) scheduled):")
        if request.upcomingExercises.isEmpty {
            sections.append("- (no upcoming exercises scheduled)")
        } else {
            for exercise in request.upcomingExercises {
                sections.append(exerciseLine(exercise, metric: request.useMetricUnits))
            }
        }
        sections.append("")

        sections.append(
            "Based on how the athlete has been handling their training load, " +
            "what should change about the upcoming plan?"
        )

        return sections.joined(separator: "\n")
    }

    // MARK: - Line formatters

    /// Formats a single completed workout as one prompt line.
    static func workoutLine(_ workout: Workout, metric: Bool) -> String {
        let date = lineDateFormatter.string(from: workout.date)
        let distance = workout.distanceMiles.formattedDistance(metric: metric)
        let duration = workout.durationSeconds.formattedDuration
        var line = "- \(date) \(workout.type.rawValue), \(distance), \(duration)"
        if workout.feltRating > 0 {
            line += ", RPE \(workout.feltRating)/10"
        }
        let trimmedNotes = workout.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedNotes.isEmpty {
            line += " — \"\(trimmedNotes)\""
        }
        return line
    }

    /// Formats a single planned exercise as one prompt line.
    static func exerciseLine(_ exercise: Exercise, metric: Bool) -> String {
        let date = lineDateFormatter.string(from: exercise.scheduledDate)
        let distance = exercise.distanceMiles.formattedDistance(metric: metric)
        let duration = exercise.durationSeconds.formattedDuration
        return "- \(date) \(exercise.type.rawValue), \(distance), \(duration)"
    }
}
