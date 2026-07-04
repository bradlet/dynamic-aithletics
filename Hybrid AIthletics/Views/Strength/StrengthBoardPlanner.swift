//
//  StrengthBoardPlanner.swift
//  Hybrid AIthletics
//
//  Owns the mutation logic for the strength kanban board: which lane an
//  exercise lives in (day + active/offloaded section) and its order within
//  that lane. Kept out of the views so the ordering math is unit-testable
//  (same pattern as `WorkoutEditor` in WorkoutDetailSheet).
//

import Foundation

/// Pure board-mutation helpers for the strength weekly kanban board.
///
/// A "lane" is one section of one day's column: `(weekdayIndex, isOffloaded)`.
/// Order within a lane is `sortOrder` ascending; these helpers renumber the
/// destination lane 0..n-1 on every mutation so order stays dense and stable.
enum StrengthBoardPlanner {

    /// Returns the exercises in a single lane, in board order.
    /// - Parameters:
    ///   - all: All strength exercises.
    ///   - day: Day-of-week lane (Sunday=0 ... Saturday=6).
    ///   - offloaded: Whether to return the offloaded section.
    static func lane(_ all: [StrengthExercise], day: Int, offloaded: Bool) -> [StrengthExercise] {
        all.filter { $0.weekdayIndex == day && $0.isOffloaded == offloaded }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    /// The sort order for appending a new exercise at the end of a lane.
    static func nextSortOrder(_ all: [StrengthExercise], day: Int, offloaded: Bool) -> Int {
        (lane(all, day: day, offloaded: offloaded).last?.sortOrder ?? -1) + 1
    }

    /// Moves an exercise to a lane, inserting before a target exercise or
    /// appending at the end. Handles reorders within a lane, moves between
    /// the active and offloaded sections, and moves across days. Renumbers
    /// the destination lane so `sortOrder` stays dense.
    /// - Parameters:
    ///   - moving: The exercise being moved.
    ///   - day: Destination day-of-week lane.
    ///   - offloaded: Whether the destination is the offloaded section.
    ///   - target: Lane member to insert before, or `nil` to append at the end.
    ///   - all: All strength exercises (used to compute lane membership).
    static func move(
        _ moving: StrengthExercise,
        toDay day: Int,
        offloaded: Bool,
        before target: StrengthExercise?,
        in all: [StrengthExercise]
    ) {
        var destination = lane(all, day: day, offloaded: offloaded)
        destination.removeAll { $0.id == moving.id }

        let insertIndex: Int
        if let target, let targetIndex = destination.firstIndex(where: { $0.id == target.id }) {
            insertIndex = targetIndex
        } else {
            insertIndex = destination.count
        }
        destination.insert(moving, at: insertIndex)

        moving.weekdayIndex = day
        moving.isOffloaded = offloaded
        for (index, exercise) in destination.enumerated() {
            exercise.sortOrder = index
        }
    }
}
