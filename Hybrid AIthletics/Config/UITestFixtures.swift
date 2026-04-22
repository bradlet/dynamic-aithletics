//
//  UITestFixtures.swift
//  Hybrid AIthletics
//
//  Deterministic workout and exercise fixtures used by UI test targets.
//  Activated only when the app is launched with `-uiTestSeed`.
//

import Foundation
import SwiftData

/// Seeds a deterministic set of workouts and exercises into the shared model
/// container so UI tests can exercise pagination, calendar navigation,
/// detail-sheet, and aerobic training flows against a known data set.
enum UITestFixtures {

    /// Number of fixture workouts. 25 across 10-per-page → 3 pages, enough
    /// to exercise pagination boundaries and last-page-clamp on delete.
    static let workoutCount = 25

    /// Clears any existing workouts and exercises in the context and inserts
    /// fresh fixtures. The most recent workout is "Test Workout 1" (today)
    /// and the oldest is "Test Workout 25" (24 days ago).
    static func seed(into container: ModelContainer) {
        let context = container.mainContext

        // Wipe existing data so each UI test launch starts clean. This
        // is safe because seeding only runs under `-uiTestSeed`, which also
        // forces an in-memory preview container.
        if let existing = try? context.fetch(FetchDescriptor<Workout>()) {
            for workout in existing {
                context.delete(workout)
            }
        }
        if let existing = try? context.fetch(FetchDescriptor<Exercise>()) {
            for exercise in existing {
                context.delete(exercise)
            }
        }

        let calendar = Calendar.current
        let baseDate = Date()

        // Seed workouts (one per day backward from today)
        for index in 0..<workoutCount {
            let number = index + 1
            guard let day = calendar.date(byAdding: .day, value: -index, to: baseDate) else { continue }
            let workout = Workout(
                name: "Test Workout \(number)",
                type: .run,
                durationSeconds: 1800 + (index * 60),   // 30m, 31m, 32m, ...
                distanceMiles: 3.0 + Double(index) * 0.1,
                notes: "Seeded fixture \(number)",
                date: day,
                feltRating: 5 + (index % 5)
            )
            context.insert(workout)
        }

        // Seed exercises for aerobic training UI tests
        // A repeating exercise (Tuesday runs)
        let tuesday = calendar.date(byAdding: .day, value: 1, to: baseDate) ?? baseDate
        let repeatingExercise = Exercise(
            name: "Test Repeating Run",
            type: .run,
            durationSeconds: 1800,
            distanceMiles: 3.0,
            scheduledDate: tuesday,
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
            scheduledDate: tomorrow,
            isRepeating: false
        )
        context.insert(concreteExercise)

        try? context.save()
    }
}
