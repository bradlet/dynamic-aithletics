//
//  UITestFixtures.swift
//  Hybrid AIthletics
//
//  Deterministic workout fixtures used by the `HistoryUITests` UI test target.
//  Activated only when the app is launched with `-uiTestSeed`.
//

import Foundation
import SwiftData

/// Seeds a deterministic set of workouts into the shared model container so
/// UI tests can exercise pagination, calendar navigation, and detail-sheet
/// flows against a known data set.
enum UITestFixtures {

    /// Number of fixture workouts. 25 across 10-per-page → 3 pages, enough
    /// to exercise pagination boundaries and last-page-clamp on delete.
    static let workoutCount = 25

    /// Clears any existing workouts in the context and inserts
    /// `workoutCount` fresh ones, one per day backward from today. The most
    /// recent is "Test Workout 1" (today) and the oldest is
    /// "Test Workout 25" (24 days ago).
    static func seed(into container: ModelContainer) {
        let context = container.mainContext

        // Wipe existing workouts so each UI test launch starts clean. This
        // is safe because seeding only runs under `-uiTestSeed`, which also
        // forces an in-memory preview container.
        if let existing = try? context.fetch(FetchDescriptor<Workout>()) {
            for workout in existing {
                context.delete(workout)
            }
        }

        let calendar = Calendar.current
        let baseDate = Date()
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

        try? context.save()
    }
}
