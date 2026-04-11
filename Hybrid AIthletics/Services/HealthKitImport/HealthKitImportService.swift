//
//  HealthKitImportService.swift
//  Hybrid AIthletics
//
//  Protocol abstraction over the HealthKit workout fetch flow. Views
//  depend on this protocol (via `@Environment(\.healthKitImport)`) so
//  that the real service can be swapped for `StubHealthKitImportService`
//  in previews and tests without ever hitting `HKHealthStore`.
//

import Foundation

/// A service that requests permission to read Apple Health workouts and
/// returns them as source-agnostic `HealthKitWorkout` DTOs.
///
/// Implementations are expected to be cheap to construct but may trigger
/// system permission prompts on the first `requestAuthorization` call.
protocol HealthKitImportService: Sendable {
    /// Requests read access for workouts. Must be called before `fetchRecentWorkouts`.
    /// Throws `HealthKitImportError.healthDataUnavailable` on devices without Health,
    /// or `.authorizationFailed` if the system call errors.
    func requestAuthorization() async throws

    /// Fetches recent workouts from the health store, sorted newest first.
    /// - Parameters:
    ///   - since: Inclusive lower bound on the workout `startDate`.
    ///   - limit: Maximum number of workouts to return.
    /// - Returns: DTOs in descending `startDate` order.
    func fetchRecentWorkouts(since: Date, limit: Int) async throws -> [HealthKitWorkout]
}

/// Errors surfaced by `HealthKitImportService` implementations.
enum HealthKitImportError: Error, LocalizedError {
    /// `HKHealthStore.isHealthDataAvailable()` returned false.
    case healthDataUnavailable
    /// The system authorization call threw.
    case authorizationFailed(underlying: Error)
    /// The underlying `HKSampleQuery` returned an error.
    case queryFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .healthDataUnavailable:
            return "Apple Health is not available on this device."
        case .authorizationFailed(let error):
            return "Could not request Apple Health access: \(error.localizedDescription)"
        case .queryFailed(let error):
            return "Could not load workouts from Apple Health: \(error.localizedDescription)"
        }
    }
}
