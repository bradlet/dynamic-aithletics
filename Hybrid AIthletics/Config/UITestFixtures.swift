//
//  UITestFixtures.swift
//  Hybrid AIthletics
//
//  Deterministic exercise fixtures used by UI test targets.
//  Activated only when the app is launched with `-uiTestSeed`.
//

import Foundation
import SwiftData

/// Seeds a deterministic set of exercises into the shared model container so
/// UI tests can exercise pagination, calendar navigation, detail-sheet, and
/// aerobic training flows against a known data set.
enum UITestFixtures {

    /// Number of recorded fixture exercises. 25 across 10-per-page → 3 pages,
    /// enough to exercise pagination boundaries and last-page-clamp on delete.
    static let workoutCount = 25

    /// Clears any existing exercises in the context and inserts fresh
    /// fixtures. The most recent recorded exercise is "Test Workout 1" (today)
    /// and the oldest is "Test Workout 25" (24 days ago); two additional
    /// planned-only exercises (no `workout`) seed the training calendar.
    static func seed(into container: ModelContainer) {
        let context = container.mainContext

        // Wipe existing data so each UI test launch starts clean. This
        // is safe because seeding only runs under `-uiTestSeed`, which also
        // forces an in-memory preview container.
        if let existing = try? context.fetch(FetchDescriptor<Exercise>()) {
            for exercise in existing {
                context.delete(exercise)
            }
        }

        let calendar = Calendar.current
        let baseDate = Date()

        // Seed recorded exercises (one per day backward from today). Each
        // carries a `workout` so it appears in the History tab. Two fixtures
        // record a distance different from plan so the training tab's
        // completed/planned split renders in the above- and below-plan states.
        for index in 0..<workoutCount {
            let number = index + 1
            guard let day = calendar.date(byAdding: .day, value: -index, to: baseDate) else { continue }
            let duration = 1800 + (index * 60)   // 30m, 31m, 32m, ...
            let miles = 3.0 + Double(index) * 0.1
            // index 1 → "Test Workout 2" (yesterday): above plan (gold).
            // index 2 → "Test Workout 3" (two days ago): below plan (yellow).
            let workoutMiles: Double = switch index {
            case 1: miles + 1.0
            case 2: miles - 1.0
            default: miles
            }
            let exercise = Exercise(
                name: "Test Workout \(number)",
                type: .run,
                durationSeconds: duration,
                distanceMiles: miles,
                notes: "Seeded fixture \(number)",
                date: day,
                isRepeating: false,
                workout: Workout(
                    durationSeconds: duration,
                    distanceMiles: workoutMiles,
                    notes: "Seeded fixture \(number)",
                    feltRating: 5 + (index % 5)
                )
            )
            context.insert(exercise)
        }

        // Seed planned-only exercises for aerobic training UI tests.
        // A repeating exercise (Tuesday runs)
        let tuesday = calendar.date(byAdding: .day, value: 1, to: baseDate) ?? baseDate
        let repeatingExercise = Exercise(
            name: "Test Repeating Run",
            type: .run,
            durationSeconds: 1800,
            distanceMiles: 3.0,
            date: tuesday,
            isRepeating: true
        )
        context.insert(repeatingExercise)

        // A concrete exercise tomorrow
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: baseDate) ?? baseDate
        let concreteExercise = Exercise(
            name: "Test Concrete Run",
            type: .longRun,
            durationSeconds: 3600,
            distanceMiles: 6.0,
            date: tomorrow,
            isRepeating: false
        )
        context.insert(concreteExercise)

        try? context.save()
    }
}
