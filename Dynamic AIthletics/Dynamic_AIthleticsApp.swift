//
//  Dynamic_AIthleticsApp.swift
//  Dynamic AIthletics
//
//  App entry point. Configures the SwiftData model container
//  and injects it into the view hierarchy.
//

import SwiftUI
import SwiftData

@main
struct Dynamic_AIthleticsApp: App {
    var sharedModelContainer: ModelContainer = ModelContainerFactory.makeContainer()

    /// Shared on-device coach instance. Using MLX-backed service when the
    /// MLX-Swift package + Gemma 4 E2B weights are present; otherwise this
    /// throws `AICoachError.notImplemented` on invocation. Views fall back
    /// to the default `StubAICoachService` via `@Environment(\.aiCoach)`
    /// when this service is not injected.
    private let aiCoach: AICoachService = MLXAICoachService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.aiCoach, aiCoach)
        }
        .modelContainer(sharedModelContainer)
    }
}
