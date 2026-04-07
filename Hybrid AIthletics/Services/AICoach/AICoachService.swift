//
//  AICoachService.swift
//  Hybrid AIthletics
//
//  Protocol abstraction over the on-device coaching model so that the
//  rest of the app never directly depends on MLX (or any specific runtime).
//  Implementations include StubAICoachService (used in previews and tests)
//  and MLXAICoachService (production, backed by Gemma 4 E2B).
//

import Foundation

/// A service that produces coaching suggestions for an athlete's training plan.
///
/// Implementations are expected to be cheap to construct but may perform
/// expensive work (e.g. loading model weights) lazily on first invocation.
/// All operations are asynchronous and cancellable via Swift concurrency.
protocol AICoachService: Sendable {
    /// Returns a single coaching response for the given request.
    /// - Parameter request: Recent workouts + upcoming exercises.
    /// - Returns: The coach's full response once generation finishes.
    func suggestAdaptations(_ request: CoachingRequest) async throws -> CoachingResponse

    /// Streams the coach's response as it is generated, token by token
    /// (or chunk by chunk, depending on the backing runtime).
    /// - Parameter request: Recent workouts + upcoming exercises.
    /// - Returns: An async stream yielding incremental text fragments.
    func streamSuggestion(_ request: CoachingRequest) -> AsyncThrowingStream<String, Error>
}

/// Errors that can be surfaced by an `AICoachService` implementation.
enum AICoachError: Error, LocalizedError {
    /// The underlying model could not be located or loaded from disk.
    case modelNotLoaded
    /// Generation failed for an implementation-specific reason.
    case generationFailed(underlying: Error)
    /// The implementation has not yet been wired up (e.g. MLX dependency missing).
    case notImplemented(message: String)

    var errorDescription: String? {
        switch self {
        case .modelNotLoaded:
            return "The coaching model could not be loaded."
        case .generationFailed(let underlying):
            return "Coach generation failed: \(underlying.localizedDescription)"
        case .notImplemented(let message):
            return message
        }
    }
}
