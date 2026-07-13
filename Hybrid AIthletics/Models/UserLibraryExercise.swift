//
//  UserLibraryExercise.swift
//  Hybrid AIthletics
//
//  A user-created exercise library entry. Unlike the bundled catalog (plain
//  `LibraryExercise` values decoded from JSON), user entries are SwiftData
//  models so they persist and sync via CloudKit. The store is empty by
//  default and only written by explicit user actions. Entries surface in the
//  library UI through `UserLocalExerciseLibraryProvider`, mapped to
//  `LibraryExercise` via `libraryEntry`.
//

import Foundation
import SwiftData

@Model
final class UserLibraryExercise {
    /// Prefix on every user-created entry id, guaranteeing no collision with
    /// bundled catalog slugs and letting the UI detect user entries.
    static let idPrefix = "user-"

    /// Stable string identifier, "user-<uuid>". Referenced by
    /// `StrengthExercise.libraryExerciseID` like any bundled slug.
    var id: String = UserLibraryExercise.idPrefix + UUID().uuidString
    /// Display name, e.g. "Weighted Dips".
    var name: String = ""
    /// Short description of the movement and how to perform it.
    var details: String = ""
    /// Raw value of the primary muscle group. Stored as String because
    /// `MuscleGroup`'s custom tolerant `init(from:)` makes SwiftData treat
    /// the enum as a composite Codable attribute, which crashes its encoder
    /// on save. Access through `muscleGroup`, never this.
    private var muscleGroupRaw: String = MuscleGroup.other.rawValue
    /// JSON-encoded raw values of the secondary muscle groups. SwiftData
    /// persists `Data?` reliably where a `[MuscleGroup]` attribute would
    /// crash (see `muscleGroupRaw`). Access through `secondaryMuscleGroups`,
    /// never this.
    private var secondaryMuscleGroupsData: Data? = nil
    /// Equipment needed, e.g. "Barbell", "Dumbbells", "Bodyweight".
    var equipment: String = ""
    /// Difficulty label matching the bundled catalog's values.
    var difficulty: String = "Beginner"
    /// Creation timestamp, used for stable load ordering.
    var createdAt: Date = Date()

    /// Primary muscle group targeted. Unknown stored raw values (e.g. synced
    /// from a newer app version) read as `.other`.
    var muscleGroup: MuscleGroup {
        get { MuscleGroup(rawValue: muscleGroupRaw) ?? .other }
        set { muscleGroupRaw = newValue.rawValue }
    }

    /// Secondary muscle groups also worked, encoded to/from
    /// `secondaryMuscleGroupsData` as a JSON array of raw values.
    var secondaryMuscleGroups: [MuscleGroup] {
        get {
            guard let secondaryMuscleGroupsData,
                  let raws = try? JSONDecoder().decode([String].self, from: secondaryMuscleGroupsData)
            else { return [] }
            return raws.map { MuscleGroup(rawValue: $0) ?? .other }
        }
        set {
            secondaryMuscleGroupsData = newValue.isEmpty
                ? nil
                : try? JSONEncoder().encode(newValue.map(\.rawValue))
        }
    }

    /// This entry mapped to the value type the library UI consumes.
    var libraryEntry: LibraryExercise {
        LibraryExercise(
            id: id,
            name: name,
            details: details,
            muscleGroup: muscleGroup,
            secondaryMuscleGroups: secondaryMuscleGroups,
            equipment: equipment,
            difficulty: difficulty
        )
    }

    /// Creates a user library exercise. The id and creation timestamp are
    /// generated automatically.
    /// - Parameters:
    ///   - name: Display name.
    ///   - details: Short description of the movement.
    ///   - muscleGroup: Primary muscle group.
    ///   - secondaryMuscleGroups: Secondary muscle groups also worked.
    ///   - equipment: Equipment needed.
    ///   - difficulty: Difficulty label.
    init(
        name: String,
        details: String = "",
        muscleGroup: MuscleGroup = .other,
        secondaryMuscleGroups: [MuscleGroup] = [],
        equipment: String = "",
        difficulty: String = "Beginner"
    ) {
        self.id = UserLibraryExercise.idPrefix + UUID().uuidString
        self.name = name
        self.details = details
        self.muscleGroup = muscleGroup
        self.secondaryMuscleGroups = secondaryMuscleGroups
        self.equipment = equipment
        self.difficulty = difficulty
        self.createdAt = Date()
    }
}

// MARK: - User-Created Detection

extension LibraryExercise {
    /// Whether this entry was created by the user (and is therefore
    /// deletable) as opposed to shipping in the bundled catalog.
    var isUserCreated: Bool { id.hasPrefix(UserLibraryExercise.idPrefix) }
}
