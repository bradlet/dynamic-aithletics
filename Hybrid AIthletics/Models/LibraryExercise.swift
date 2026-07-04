//
//  LibraryExercise.swift
//  Hybrid AIthletics
//
//  A strength exercise definition in the exercise library. Plain Codable
//  value type decoded from the bundled JSON catalog (and, in the future,
//  merged with entries from a server-based library). NOT a SwiftData model —
//  the library is reference data, not user data. Users add a library entry
//  to their board, which creates a `StrengthExercise` linked back here via
//  `StrengthExercise.libraryExerciseID`.
//

import Foundation

/// A catalog entry describing a strength exercise the user can add to
/// their weekly board.
struct LibraryExercise: Codable, Hashable, Sendable, Identifiable {
    /// Stable string identifier (slug), e.g. "barbell-bench-press". Server
    /// entries with the same id override bundled ones on merge.
    let id: String
    /// Display name, e.g. "Barbell Bench Press".
    let name: String
    /// Short description of the movement and how to perform it.
    let details: String
    /// Primary muscle group targeted.
    let muscleGroup: MuscleGroup
    /// Secondary muscle groups also worked.
    let secondaryMuscleGroups: [MuscleGroup]
    /// Equipment needed, e.g. "Barbell", "Dumbbells", "Bodyweight".
    let equipment: String
    /// Difficulty label, e.g. "Beginner", "Intermediate", "Advanced". Kept
    /// as a free-form string for forward compatibility with server data.
    let difficulty: String

    private enum CodingKeys: String, CodingKey {
        case id, name
        case details = "description"
        case muscleGroup, secondaryMuscleGroups, equipment, difficulty
    }

    /// Creates a library exercise entry.
    init(
        id: String,
        name: String,
        details: String,
        muscleGroup: MuscleGroup,
        secondaryMuscleGroups: [MuscleGroup] = [],
        equipment: String,
        difficulty: String
    ) {
        self.id = id
        self.name = name
        self.details = details
        self.muscleGroup = muscleGroup
        self.secondaryMuscleGroups = secondaryMuscleGroups
        self.equipment = equipment
        self.difficulty = difficulty
    }

    /// Tolerant decoding: `secondaryMuscleGroups` may be omitted in source
    /// JSON, defaulting to empty.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.details = try container.decode(String.self, forKey: .details)
        self.muscleGroup = try container.decode(MuscleGroup.self, forKey: .muscleGroup)
        self.secondaryMuscleGroups = try container.decodeIfPresent([MuscleGroup].self, forKey: .secondaryMuscleGroups) ?? []
        self.equipment = try container.decode(String.self, forKey: .equipment)
        self.difficulty = try container.decode(String.self, forKey: .difficulty)
    }
}
