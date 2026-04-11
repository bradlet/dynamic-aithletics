//
//  Hybrid_AIthleticsApp.swift
//  Hybrid AIthletics
//
//  App entry point. Configures the SwiftData model container
//  and injects it into the view hierarchy.
//

import SwiftUI
import SwiftData

@main
struct Hybrid_AIthleticsApp: App {
    var sharedModelContainer: ModelContainer = Self.makeContainerForLaunch()

    /// Shared on-device coach instance. Uses MLX-Swift to download and run
    /// Gemma 3 4B on-device. The model is downloaded from Hugging Face on
    /// first use and cached locally for offline access. When the MLX-Swift
    /// package is not available, invocations throw `AICoachError.notImplemented`.
    private let aiCoach: AICoachService = MLXAICoachService()

    /// Shared HealthKit import service. Backed by a real `HKHealthStore`,
    /// used by the History tab's "Import from Apple Health" flow.
    private let healthKitImport: HealthKitImportService = LiveHealthKitImportService()

    init() {
        // When launched by the UI test harness with `-uiTestSeed`, replace any
        // existing workouts in the container with a deterministic fixture set.
        // This runs against the same `sharedModelContainer` the view hierarchy
        // will use (preview container when seeded — see makeContainerForLaunch).
        if CommandLine.arguments.contains("-uiTestSeed") {
            UITestFixtures.seed(into: sharedModelContainer)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.aiCoach, aiCoach)
                .environment(\.healthKitImport, healthKitImport)
        }
        .modelContainer(sharedModelContainer)
    }

    /// Builds the model container to install into the view hierarchy.
    /// - Normally returns `ModelContainerFactory.makeContainer()` (on-disk + CloudKit).
    /// - When launched with `-uiTestSeed`, returns an in-memory preview container
    ///   so UI tests get a clean, deterministic state that never touches CloudKit.
    private static func makeContainerForLaunch() -> ModelContainer {
        if CommandLine.arguments.contains("-uiTestSeed") {
            return ModelContainerFactory.makePreviewContainer()
        }
        return ModelContainerFactory.makeContainer()
    }
}
