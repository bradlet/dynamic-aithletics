//
//  StubHealthKitImportService.swift
//  Hybrid AIthletics
//
//  In-memory `HealthKitImportService` used by SwiftUI previews and unit
//  tests. Returns a canned set of `HealthKitWorkout` fixtures so the UI
//  can be exercised without granting Health permissions or running on a
//  real device.
//

import Foundation
import HealthKit

/// A stub implementation of `HealthKitImportService` that returns a fixed
/// set of fake workouts. Never touches `HKHealthStore`.
struct StubHealthKitImportService: HealthKitImportService {
    /// The full fixture set this stub will return from `fetchRecentWorkouts`.
    /// Exposed so tests can assert against it.
    let fixtures: [HealthKitWorkout]

    /// Creates a stub with the default fixture set (5 workouts across the
    /// last 14 days, spanning the most common activity types).
    init() {
        let now = Date()
        self.fixtures = [
            HealthKitWorkout(
                id: "stub-run-1",
                activityType: .running,
                startDate: now.addingTimeInterval(-1 * 86400),
                duration: 1800,
                distanceMiles: 3.1
            ),
            HealthKitWorkout(
                id: "stub-walk-1",
                activityType: .walking,
                startDate: now.addingTimeInterval(-3 * 86400),
                duration: 2400,
                distanceMiles: 1.8
            ),
            HealthKitWorkout(
                id: "stub-bike-1",
                activityType: .cycling,
                startDate: now.addingTimeInterval(-5 * 86400),
                duration: 3600,
                distanceMiles: 12.4
            ),
            HealthKitWorkout(
                id: "stub-swim-1",
                activityType: .swimming,
                startDate: now.addingTimeInterval(-7 * 86400),
                duration: 1500,
                distanceMiles: 0.75
            ),
            HealthKitWorkout(
                id: "stub-elliptical-1",
                activityType: .elliptical,
                startDate: now.addingTimeInterval(-10 * 86400),
                duration: 1800,
                distanceMiles: nil
            )
        ]
    }

    /// Creates a stub with a caller-supplied fixture set.
    init(fixtures: [HealthKitWorkout]) {
        self.fixtures = fixtures
    }

    func requestAuthorization() async throws {
        // No-op: the stub pretends the user already granted access.
    }

    func fetchRecentWorkouts(since: Date, limit: Int) async throws -> [HealthKitWorkout] {
        let filtered = fixtures
            .filter { $0.startDate >= since }
            .sorted { $0.startDate > $1.startDate }
        return Array(filtered.prefix(limit))
    }
}
