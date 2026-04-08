//
//  MLXAICoachService.swift
//  Hybrid AIthletics
//
//  Production AI coach backed by Gemma 3 4B running on-device via MLX-Swift.
//
//  The model is downloaded from Hugging Face on first use and cached locally
//  for offline access. The real implementation compiles when the `MLXLLM`
//  module is available (mlx-swift-examples SPM package, >= 2.0.0). The #else
//  branches throw AICoachError.notImplemented so the app stays launchable on
//  simulators or CI hosts where the package has not yet resolved.

import Foundation

#if canImport(MLXLLM)
import MLXLLM
import MLXLMCommon
import Tokenizers
#endif

/// Coaching service backed by Gemma 3 4B downloaded from Hugging Face and run
/// on-device via MLX-Swift.
///
/// The model is downloaded lazily on the first call and cached in the app's
/// caches directory. Subsequent launches load the cached copy (works offline).
/// Callers should create a single shared instance at the app root and inject
/// it via `@Environment(\.aiCoach)`.
final class MLXAICoachService: AICoachService, @unchecked Sendable {

    /// Hugging Face model ID — downloaded on first use, cached locally.
    static let modelID = "mlx-community/gemma-3-4b-it-qat-4bit"

    /// Maximum tokens to generate per response.
    var maxTokens: Int = 512
    /// Sampling temperature.
    var temperature: Float = 0.7

    #if canImport(MLXLLM)
    private let configuration = ModelConfiguration(id: MLXAICoachService.modelID)
    #endif

    /// Whether the model weights are already cached on disk.
    var isModelCached: Bool {
        #if canImport(MLXLLM)
        let dir = configuration.modelDirectory()
        return FileManager.default.fileExists(
            atPath: dir.appendingPathComponent("config.json").path
        )
        #else
        return false
        #endif
    }

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

    /// Loads (or downloads) the model and runs generation to completion.
    private func generate(prompt: String) async throws -> String {
        let container = try await LLMModelFactory.shared.loadContainer(
            configuration: configuration
        )
        let parameters = GenerateParameters(maxTokens: maxTokens, temperature: temperature)
        return try await container.perform { context in
            let input = try await context.processor.prepare(input: UserInput(prompt: prompt))
            let result = try MLXLMCommon.generate(
                input: input,
                parameters: parameters,
                context: context,
                didGenerate: { (_: [Int]) in .more }
            )
            return result.output
        }
    }

    /// Streaming variant — yields decoded token chunks to `onChunk` as they are generated.
    private func generateStreaming(
        prompt: String,
        onChunk: @escaping @Sendable (String) -> Void
    ) async throws {
        let container = try await LLMModelFactory.shared.loadContainer(
            configuration: configuration
        )
        let parameters = GenerateParameters(maxTokens: maxTokens, temperature: temperature)
        try await container.perform { context in
            let input = try await context.processor.prepare(input: UserInput(prompt: prompt))
            _ = try MLXLMCommon.generate(
                input: input,
                parameters: parameters,
                context: context,
                didGenerate: { (tokens: [Int]) in
                    let text = context.tokenizer.decode(tokens: tokens)
                    onChunk(text)
                    return .more
                }
            )
        }
    }

    #endif
}
