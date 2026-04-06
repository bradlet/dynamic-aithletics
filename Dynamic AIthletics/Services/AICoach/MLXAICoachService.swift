//
//  MLXAICoachService.swift
//  Dynamic AIthletics
//
//  Production AI coach backed by Gemma 4 E2B running on-device via MLX-Swift.
//
//  NOTE: This file is a scaffold. It conditionally compiles the real MLX
//  implementation only when the `MLXLLM` module is available. Until the
//  MLX-Swift Swift Package is added to the project and the Gemma 4 E2B
//  MLX weights are bundled under `Resources/Models/gemma-4-e2b-it-mlx-4bit/`,
//  this service throws `AICoachError.notImplemented` on every call.
//
//  To activate the real implementation:
//    1. In Xcode: File → Add Package Dependencies → paste the MLX-Swift
//       examples URL and add the `MLXLLM` / `MLXLLMCommon` products.
//    2. Bundle the model directory as a folder reference (blue folder) in
//       Copy Bundle Resources.
//    3. Fill in the `#if canImport(MLXLLM)` branch below against the
//       package's current public API (the surface is still evolving, so
//       check the README at the time of wiring).
//

import Foundation

#if canImport(MLXLLM)
import MLXLLM
import MLXLLMCommon
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

    /// Runs synchronous generation to completion and returns the full text.
    ///
    /// The exact MLX-Swift API surface continues to evolve, so this wrapper
    /// is intentionally left as a TODO to be filled in against the version
    /// pinned when the SPM dependency is added.
    private func generate(prompt: String) async throws -> String {
        // TODO: Replace with real MLXLLM calls once the package is added.
        // Sketch (pseudo-API, adjust to the pinned version):
        //
        //   let modelURL = try modelDirectoryURL()
        //   let container = try await LLMModelFactory.shared.loadContainer(
        //       configuration: .init(directory: modelURL)
        //   )
        //   let parameters = GenerateParameters(
        //       temperature: temperature, maxTokens: maxTokens
        //   )
        //   let result = try await container.perform { context in
        //       try MLXLMCommon.generate(
        //           input: context.processor.prepare(input: .init(prompt: prompt)),
        //           parameters: parameters,
        //           context: context
        //       )
        //   }
        //   return result.output
        throw AICoachError.notImplemented(message:
            "MLX generate() not yet wired up — fill in against pinned MLXLLM API."
        )
    }

    /// Streaming variant — yields incremental chunks to `onChunk`.
    private func generateStreaming(
        prompt: String,
        onChunk: @escaping (String) -> Void
    ) async throws {
        // TODO: Replace with real MLXLLM streaming calls once the package is added.
        throw AICoachError.notImplemented(message:
            "MLX streaming not yet wired up — fill in against pinned MLXLLM API."
        )
    }

    #endif
}
