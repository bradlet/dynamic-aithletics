//
//  ExerciseLibraryProvider.swift
//  Hybrid AIthletics
//
//  Extensible loading layer for the strength exercise library. Today the
//  library ships as a bundled JSON catalog; the provider abstraction lets us
//  later add a server-backed provider and merge its entries with the bundled
//  ones (server entries with a matching id override bundled entries).
//

import Foundation

/// A source of strength exercise library entries.
protocol ExerciseLibraryProvider: Sendable {
    /// Loads all exercises available from this source.
    /// - Returns: The library entries, in no guaranteed order.
    func loadExercises() async throws -> [LibraryExercise]
}

/// Errors thrown while loading the exercise library.
enum ExerciseLibraryError: Error, Equatable {
    /// The bundled catalog resource was not found in the bundle.
    case missingBundledCatalog
}

// MARK: - Bundled Provider

/// Loads the pre-installed exercise catalog from a JSON resource in the app
/// bundle (`StrengthExerciseLibrary.json`).
struct BundledExerciseLibraryProvider: ExerciseLibraryProvider {
    /// The bundle containing the catalog resource. Defaults to the main bundle.
    let bundle: Bundle
    /// The catalog resource name (without extension).
    let resourceName: String

    /// Creates a bundled provider.
    /// - Parameters:
    ///   - bundle: Bundle to load from. Defaults to `.main`.
    ///   - resourceName: JSON resource name. Defaults to "StrengthExerciseLibrary".
    init(bundle: Bundle = .main, resourceName: String = "StrengthExerciseLibrary") {
        self.bundle = bundle
        self.resourceName = resourceName
    }

    /// Loads and decodes the bundled JSON catalog.
    func loadExercises() async throws -> [LibraryExercise] {
        guard let url = bundle.url(forResource: resourceName, withExtension: "json") else {
            throw ExerciseLibraryError.missingBundledCatalog
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([LibraryExercise].self, from: data)
    }
}

// MARK: - Composite Provider

/// Merges entries from multiple providers. Later providers win on id
/// collisions, so ordering `[bundled, server]` lets server data override the
/// pre-installed catalog. A provider that fails to load is skipped so one
/// unreachable source (e.g. the network) never hides the others.
struct CompositeExerciseLibraryProvider: ExerciseLibraryProvider {
    /// The providers to merge, in ascending precedence order.
    let providers: [any ExerciseLibraryProvider]

    /// Creates a composite provider.
    /// - Parameter providers: Sources in ascending precedence order.
    init(providers: [any ExerciseLibraryProvider]) {
        self.providers = providers
    }

    /// Loads from every provider and merges by id (later providers override),
    /// returning entries sorted by name for stable display.
    func loadExercises() async throws -> [LibraryExercise] {
        var merged: [String: LibraryExercise] = [:]
        for provider in providers {
            guard let exercises = try? await provider.loadExercises() else { continue }
            for exercise in exercises {
                merged[exercise.id] = exercise
            }
        }
        return merged.values.sorted { $0.name < $1.name }
    }
}

// MARK: - Default Library

extension ExerciseLibraryProvider where Self == CompositeExerciseLibraryProvider {
    /// The app's default library: the bundled catalog only, ready to grow a
    /// server-backed provider (append it to the array to enable merging).
    static var `default`: CompositeExerciseLibraryProvider {
        CompositeExerciseLibraryProvider(providers: [BundledExerciseLibraryProvider()])
    }
}
