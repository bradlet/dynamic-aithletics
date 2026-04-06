//
//  AICoachEnvironment.swift
//  Dynamic AIthletics
//
//  Custom SwiftUI environment key that injects an AICoachService into the
//  view hierarchy. Default value is StubAICoachService so previews and
//  tests never accidentally load the real MLX-backed model.
//

import SwiftUI

/// Environment key for the shared `AICoachService` instance.
private struct AICoachKey: EnvironmentKey {
    static let defaultValue: AICoachService = StubAICoachService()
}

extension EnvironmentValues {
    /// The active AI coach service. Defaults to `StubAICoachService`; the
    /// real implementation is injected at the app root.
    var aiCoach: AICoachService {
        get { self[AICoachKey.self] }
        set { self[AICoachKey.self] = newValue }
    }
}
