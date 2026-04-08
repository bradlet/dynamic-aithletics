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
    var sharedModelContainer: ModelContainer = ModelContainerFactory.makeContainer()

    /// Shared on-device coach instance. Uses MLX-Swift to download and run
    /// Gemma 3 4B on-device. The model is downloaded from Hugging Face on
    /// first use and cached locally for offline access. When the MLX-Swift
    /// package is not available, invocations throw `AICoachError.notImplemented`.
    private let aiCoach: AICoachService = MLXAICoachService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.aiCoach, aiCoach)
        }
        .modelContainer(sharedModelContainer)
    }
}
