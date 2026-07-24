//
//  ExercisePlanner.swift
//  Hybrid AIthletics
//
//  Stateless bulk-CRUD surface for exercise series. All methods take a
//  ModelContext so callers (UI today, an AI-coach tool layer later) can
//  drive plan changes through one small, tested interface.
//

import Foundation
import SwiftData

/// Which members of a series a bulk mutation targets.
enum SeriesScope: Equatable {
    /// Every member of the series.
    case all
    /// Members whose date falls on or after the given day (inclusive by calendar day).
    case from(Date)

    /// Whether the given date is inside this scope.
    func contains(_ date: Date) -> Bool {
        switch self {
        case .all:
            return true
        case .from(let boundary):
            return date.startOfDay >= boundary.startOfDay
        }
    }
}

/// Per-field bulk mutations; nil = leave unchanged. An absolute set wins
/// over the corresponding scale if both are given.
struct SeriesMutations: Equatable {
    var name: String? = nil
    var type: ExerciseType? = nil
    var notes: String? = nil
    var countsTowardMileage: Bool? = nil
    /// Move each occurrence by this many days (negative = earlier).
    var shiftDays: Int? = nil
    /// Set the absolute planned distance in miles.
    var distanceMiles: Double? = nil
    /// Set the absolute planned duration in seconds.
    var durationSeconds: Int? = nil
    /// Multiply the planned distance (0.8 = 20% deload).
    var scaleDistance: Double? = nil
    /// Multiply the planned duration.
    var scaleDuration: Double? = nil
}

/// Bulk create/read/update/delete for exercise series.
enum ExercisePlanner {
    /// Generates occurrences for the spec and inserts one concrete Exercise
    /// per occurrence, all tagged with a fresh shared seriesID. A `.oneOff`
    /// spec inserts a single untagged exercise — a lone exercise is not a
    /// series. Returns the inserted exercises sorted by date.
    @discardableResult
    static func createSeries(_ spec: ExerciseSeriesSpec, in context: ModelContext) -> [Exercise] {
        let occurrences = SeriesGenerator.occurrences(for: spec)
        let seriesID: UUID? = spec.cadence == .oneOff ? nil : UUID()
        let exercises = occurrences.map { occurrence in
            Exercise(
                name: spec.name,
                type: spec.type,
                durationSeconds: occurrence.durationSeconds,
                distanceMiles: occurrence.distanceMiles,
                notes: spec.notes,
                date: occurrence.date,
                seriesID: seriesID,
                countsTowardMileage: spec.countsTowardMileage
            )
        }
        for exercise in exercises {
            context.insert(exercise)
        }
        return exercises
    }

    /// Fetches members of the series in date order, optionally scoped.
    static func members(of seriesID: UUID, scope: SeriesScope = .all, in context: ModelContext) -> [Exercise] {
        let descriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate { $0.seriesID == seriesID },
            sortBy: [SortDescriptor(\.date)]
        )
        let fetched = (try? context.fetch(descriptor)) ?? []
        return fetched.filter { scope.contains($0.date) }
    }

    /// Applies mutations to scoped members. Only planned fields are touched —
    /// a completed member keeps its recorded `workout` untouched.
    static func updateSeries(_ seriesID: UUID, scope: SeriesScope, mutations: SeriesMutations, in context: ModelContext) {
        for exercise in members(of: seriesID, scope: scope, in: context) {
            if let name = mutations.name { exercise.name = name }
            if let type = mutations.type { exercise.type = type }
            if let notes = mutations.notes { exercise.notes = notes }
            if let counts = mutations.countsTowardMileage { exercise.countsTowardMileage = counts }
            if let shiftDays = mutations.shiftDays,
               let shifted = Calendar.current.date(byAdding: .day, value: shiftDays, to: exercise.date) {
                exercise.date = shifted
            }
            if let distance = mutations.distanceMiles {
                exercise.distanceMiles = distance
            } else if let scale = mutations.scaleDistance {
                exercise.distanceMiles = max(0, exercise.distanceMiles * scale)
            }
            if let duration = mutations.durationSeconds {
                exercise.durationSeconds = duration
            } else if let scale = mutations.scaleDuration {
                exercise.durationSeconds = max(0, Int((Double(exercise.durationSeconds) * scale).rounded()))
            }
        }
    }

    /// Deletes scoped members. Completed members are preserved unless
    /// `includeCompleted` is true — recorded history is kept by default.
    /// Truncating a series ("end it in June") is `deleteSeries(scope: .from(july1))`.
    static func deleteSeries(_ seriesID: UUID, scope: SeriesScope, includeCompleted: Bool = false, in context: ModelContext) {
        for exercise in members(of: seriesID, scope: scope, in: context) {
            guard includeCompleted || !exercise.isCompleted else { continue }
            context.delete(exercise)
        }
    }

    /// Removes an exercise from its series without deleting it
    /// ("apply to this one only" edits).
    static func detach(_ exercise: Exercise) {
        exercise.seriesID = nil
    }
}
