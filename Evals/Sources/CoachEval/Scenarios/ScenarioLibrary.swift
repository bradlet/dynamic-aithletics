//
//  ScenarioLibrary.swift
//  CoachEval
//
//  Predefined evaluation scenarios with synthetic but realistic training data.
//

import Foundation
import AICoachCore

/// Library of predefined evaluation scenarios.
enum ScenarioLibrary {

    /// All available scenarios, keyed by ID.
    static let all: [EvalScenario] = [
        highRPE,
        balanced,
        empty,
        singleHard,
        mixed,
    ]

    /// Looks up a scenario by ID.
    static func scenario(id: String) -> EvalScenario? {
        all.first { $0.id == id }
    }

    // MARK: - Date helpers

    /// Creates a date relative to "today" by offsetting days.
    private static func daysAgo(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: Date())!
    }

    private static func daysFromNow(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: Date())!
    }

    // MARK: - Scenarios

    /// High RPE overtraining: 5 hard workouts in 7 days, demanding upcoming plan.
    static let highRPE = EvalScenario(
        id: "high-rpe",
        name: "High RPE Overtraining",
        description: "5 recent workouts at RPE 8-9 with high mileage, all feeling weak. " +
            "Upcoming plan has more intensity. Coach should recommend reducing volume.",
        request: CoachingRequest(
            recentWorkouts: [
                CoachWorkout(date: daysAgo(6), type: .tempoRun, distanceMiles: 6.0,
                             durationSeconds: 2700, feeling: 2, perceivedExertion: 8,
                             notes: "felt sluggish"),
                CoachWorkout(date: daysAgo(5), type: .easyRun, distanceMiles: 5.0,
                             durationSeconds: 2400, feeling: 2, perceivedExertion: 8,
                             notes: "legs heavy"),
                CoachWorkout(date: daysAgo(4), type: .intervalRun, distanceMiles: 4.0,
                             durationSeconds: 2100, feeling: 1, perceivedExertion: 9,
                             notes: "struggled on last interval"),
                CoachWorkout(date: daysAgo(2), type: .longRun, distanceMiles: 12.0,
                             durationSeconds: 5400, feeling: 1, perceivedExertion: 9,
                             notes: "had to walk last mile"),
                // Feeling left unrecorded — exercises the omission path.
                CoachWorkout(date: daysAgo(1), type: .easyRun, distanceMiles: 4.0,
                             durationSeconds: 2100, perceivedExertion: 8),
            ],
            upcomingExercises: [
                CoachExercise(scheduledDate: daysFromNow(1), type: .intervalRun,
                              distanceMiles: 5.0, durationSeconds: 2400),
                CoachExercise(scheduledDate: daysFromNow(3), type: .tempoRun,
                              distanceMiles: 7.0, durationSeconds: 3000),
                CoachExercise(scheduledDate: daysFromNow(5), type: .longRun,
                              distanceMiles: 14.0, durationSeconds: 6000),
            ],
            useMetricUnits: false
        ),
        expectations: EvalExpectations(
            expectedKeywords: ["reduce", "recovery", "rest", "easy", "volume"]
        )
    )

    /// Balanced training: sensible load, reasonable RPE.
    static let balanced = EvalScenario(
        id: "balanced",
        name: "Balanced Training",
        description: "4 workouts at moderate RPE (5-7) feeling normal to strong, " +
            "well-structured plan. Coach should suggest minor tweaks or maintain the plan.",
        request: CoachingRequest(
            recentWorkouts: [
                CoachWorkout(date: daysAgo(6), type: .easyRun, distanceMiles: 4.0,
                             durationSeconds: 2100, feeling: 4, perceivedExertion: 5),
                CoachWorkout(date: daysAgo(4), type: .tempoRun, distanceMiles: 5.0,
                             durationSeconds: 2400, feeling: 3, perceivedExertion: 6),
                // Feeling left unrecorded — exercises the omission path.
                CoachWorkout(date: daysAgo(2), type: .easyRun, distanceMiles: 4.0,
                             durationSeconds: 2100, perceivedExertion: 5),
                CoachWorkout(date: daysAgo(1), type: .longRun, distanceMiles: 8.0,
                             durationSeconds: 3600, feeling: 3, perceivedExertion: 7),
            ],
            upcomingExercises: [
                CoachExercise(scheduledDate: daysFromNow(1), type: .easyRun,
                              distanceMiles: 4.0, durationSeconds: 2100),
                CoachExercise(scheduledDate: daysFromNow(3), type: .tempoRun,
                              distanceMiles: 5.0, durationSeconds: 2400),
                CoachExercise(scheduledDate: daysFromNow(5), type: .longRun,
                              distanceMiles: 9.0, durationSeconds: 4000),
            ],
            useMetricUnits: false
        ),
        expectations: EvalExpectations(
            expectedKeywords: ["maintain", "continue", "consistent"]
        )
    )

    /// Empty history: no workouts recorded, upcoming plan exists.
    static let empty = EvalScenario(
        id: "empty",
        name: "Empty History",
        description: "No recent workouts, 3 upcoming exercises. " +
            "Coach should acknowledge the lack of data and give general guidance.",
        request: CoachingRequest(
            recentWorkouts: [],
            upcomingExercises: [
                CoachExercise(scheduledDate: daysFromNow(1), type: .easyRun,
                              distanceMiles: 3.0, durationSeconds: 1800),
                CoachExercise(scheduledDate: daysFromNow(3), type: .tempoRun,
                              distanceMiles: 4.0, durationSeconds: 2100),
                CoachExercise(scheduledDate: daysFromNow(5), type: .longRun,
                              distanceMiles: 6.0, durationSeconds: 2700),
            ],
            useMetricUnits: false
        ),
        expectations: EvalExpectations(
            expectedKeywords: ["no", "data", "recorded"],
            forbiddenKeywords: ["RPE"]
        )
    )

    /// Single hard workout with intensity scheduled the next day.
    static let singleHard = EvalScenario(
        id: "single-hard",
        name: "Single Hard Workout",
        description: "One long run at RPE 9 feeling very weak, with notes about heavy legs. " +
            "Interval session scheduled for tomorrow. Coach should recommend postponing intensity.",
        request: CoachingRequest(
            recentWorkouts: [
                CoachWorkout(date: daysAgo(1), type: .longRun, distanceMiles: 10.0,
                             durationSeconds: 4800, feeling: 1, perceivedExertion: 9,
                             notes: "legs felt like lead"),
            ],
            upcomingExercises: [
                CoachExercise(scheduledDate: daysFromNow(0), type: .intervalRun,
                              distanceMiles: 5.0, durationSeconds: 2400),
                CoachExercise(scheduledDate: daysFromNow(2), type: .easyRun,
                              distanceMiles: 4.0, durationSeconds: 2100),
                CoachExercise(scheduledDate: daysFromNow(4), type: .tempoRun,
                              distanceMiles: 5.0, durationSeconds: 2400),
            ],
            useMetricUnits: false
        ),
        expectations: EvalExpectations(
            expectedKeywords: ["recovery", "postpone", "easy", "rest"]
        )
    )

    /// Mixed signals: some easy, one very hard session.
    static let mixed = EvalScenario(
        id: "mixed",
        name: "Mixed Signals",
        description: "Easy runs at low RPE plus one interval at RPE 9. " +
            "Another interval upcoming. Coach should give nuanced advice targeting the hard session.",
        request: CoachingRequest(
            recentWorkouts: [
                CoachWorkout(date: daysAgo(5), type: .easyRun, distanceMiles: 3.0,
                             durationSeconds: 1800, feeling: 4, perceivedExertion: 4),
                // Feeling left unrecorded — exercises the omission path.
                CoachWorkout(date: daysAgo(4), type: .easyRun, distanceMiles: 3.5,
                             durationSeconds: 2000, perceivedExertion: 4),
                CoachWorkout(date: daysAgo(2), type: .intervalRun, distanceMiles: 5.0,
                             durationSeconds: 2400, feeling: 1, perceivedExertion: 9,
                             notes: "could not finish last rep"),
                CoachWorkout(date: daysAgo(1), type: .easyRun, distanceMiles: 3.0,
                             durationSeconds: 1800, feeling: 3, perceivedExertion: 5),
            ],
            upcomingExercises: [
                CoachExercise(scheduledDate: daysFromNow(1), type: .easyRun,
                              distanceMiles: 3.0, durationSeconds: 1800),
                CoachExercise(scheduledDate: daysFromNow(3), type: .intervalRun,
                              distanceMiles: 5.0, durationSeconds: 2400),
                CoachExercise(scheduledDate: daysFromNow(5), type: .longRun,
                              distanceMiles: 8.0, durationSeconds: 3600),
            ],
            useMetricUnits: false
        ),
        expectations: EvalExpectations(
            expectedKeywords: ["interval", "reduce", "intensity"]
        )
    )
}
