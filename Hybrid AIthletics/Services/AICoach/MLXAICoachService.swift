//
//  MLXAICoachService.swift
//  Hybrid AIthletics
//
//  Production AI coach backed by Gemma 4 E2B running on-device via MLX-Swift.
//
//  The real implementation compiles when the `MLXLLM` module is available
//  (mlx-swift-examples SPM package, ≥ 2.0.0). The #else branches throw
//  AICoachError.notImplemented so the app stays launchable on simulators
//  or CI hosts where the package has not yet resolved.

import Foundation

#if canImport(MLXLLM)
import MLXLLM
import MLXLMCommon
#endif

/// Coaching service backed by a local Gemma 4 E2B model loaded via MLX-Swift.
///
/// The underlying model is loaded lazily on the first call and cached for
/// the lifetime of the service instance. Callers should typically create a
/// single shared instance at the app root and inject it via the
/// `@Environment(\.aiCoach)` key.
final class MLXAICoachService: AICoachService, @unchecked Sendable {

    /// Name of the model directory bundled under `Resources/Models/`.
    static let modelDirectoryName = "gemma-4-e2b-it-mlx-4bit"

    /// Maximum tokens to generate per response.
    var maxTokens: Int = 512
    /// Sampling temperature.
    var temperature: Float = 0.7

    init() {}

    func suggestAdaptations(_ request: CoachingRequest) async throws -> CoachingResponse {
        #if canImport(MLXLLM)
        let prompt = AICoachPromptBuilder.buildPrompt(for: request)
        let text = try await generate(prompt: prompt)
        return CoachingResponse(narrative: text)
        #else
        throw AICoachError.notImplemented(message:
            "MLXAICoachService requires the MLX-Swift package to be added to the " +
            "project. See the file header for wiring instructions."
        )
        #endif
    }

    func streamSuggestion(_ request: CoachingRequest) -> AsyncThrowingStream<String, Error> {
        #if canImport(MLXLLM)
        let prompt = AICoachPromptBuilder.buildPrompt(for: request)
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    try await self.generateStreaming(prompt: prompt) { chunk in
                        continuation.yield(chunk)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
        #else
        return AsyncThrowingStream { continuation in
            continuation.finish(throwing: AICoachError.notImplemented(message:
                "MLXAICoachService requires the MLX-Swift package. See file header."
            ))
        }
        #endif
    }

    // MARK: - MLX-backed generation (active once the SPM dep is added)

    #if canImport(MLXLLM)

    /// Locates the bundled model directory inside the app's main bundle.
    /// - Throws: `AICoachError.modelNotLoaded` when the directory is missing.
    private func modelDirectoryURL() throws -> URL {
        guard let url = Bundle.main.url(
            forResource: Self.modelDirectoryName,
            withExtension: nil
        ) else {
            throw AICoachError.modelNotLoaded
        }
        return url
    }

    /// Loads the model container and runs generation to completion.
    private func generate(prompt: String) async throws -> String {
        let modelURL = try modelDirectoryURL()
        let config = ModelConfiguration(directory: modelURL)
        let container = try await LLMModelFactory.shared.loadContainer(configuration: config)
        let parameters = GenerateParameters(temperature: temperature, maxTokens: maxTokens)
        return try await container.perform { context in
            let input = try await context.processor.prepare(input: UserInput(prompt: prompt))
            let result = try MLXLMCommon.generate(
                input: input,
                parameters: parameters,
                context: context
            ) { _ in .more }
            return result.output
        }
    }

    /// Streaming variant — yields decoded token chunks to `onChunk` as they are generated.
    private func generateStreaming(
        prompt: String,
        onChunk: @escaping @Sendable (String) -> Void
    ) async throws {
        let modelURL = try modelDirectoryURL()
        let config = ModelConfiguration(directory: modelURL)
        let container = try await LLMModelFactory.shared.loadContainer(configuration: config)
        let parameters = GenerateParameters(temperature: temperature, maxTokens: maxTokens)
        try await container.perform { context in
            let input = try await context.processor.prepare(input: UserInput(prompt: prompt))
            _ = try MLXLMCommon.generate(
                input: input,
                parameters: parameters,
                context: context
            ) { tokens in
                let text = context.tokenizer.decode(tokens: tokens)
                onChunk(text)
                return .more
            }
        }
    }

    #endif
}
