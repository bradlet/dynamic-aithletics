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
import AICoachCore

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

    // MARK: - Generation parameters
    //
    // All generation parameters are centralized in AICoachCore.GenerationConfig
    // so that the eval CLI and the live app use identical settings. Override
    // `generationConfig` here only for temporary local experiments.

    /// Generation parameters — reads from AICoachCore's single source of truth.
    var generationConfig = GenerationConfig.production

    /// Optional callback invoked with download progress (0.0–1.0) during
    /// first-time model weight download. Set by the presenting view before
    /// triggering `loadModel()`.
    var onDownloadProgress: (@Sendable (Double) -> Void)?

    #if canImport(MLXLLM)
    private let configuration = ModelConfiguration(
        id: MLXAICoachService.modelID,
        extraEOSTokens: ["<end_of_turn>"]
    )

    /// Cached model container — populated by `loadModel()` or lazily on first
    /// generation call. Avoids re-downloading on every request.
    private var cachedContainer: ModelContainer?
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

    /// Whether the model is loaded into memory and ready for generation.
    var isModelReady: Bool {
        #if canImport(MLXLLM)
        return cachedContainer != nil
        #else
        return false
        #endif
    }

    /// Downloads (if needed) and loads the model into memory without running
    /// generation. Sets `isModelReady` to `true` on success.
    func loadModel() async throws {
        #if canImport(MLXLLM)
        guard cachedContainer == nil else { return }
        let progressHandler = onDownloadProgress
        cachedContainer = try await LLMModelFactory.shared.loadContainer(
            configuration: configuration
        ) { progress in
            progressHandler?(progress.fractionCompleted)
        }
        #else
        throw AICoachError.notImplemented(message:
            "MLXAICoachService requires the MLX-Swift package."
        )
        #endif
    }

    func suggestAdaptations(_ request: CoachingRequest) async throws -> CoachingResponse {
        #if canImport(MLXLLM)
        let text = try await generate(request: request)
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
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    try await self.generateStreaming(request: request) { chunk in
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

    /// Returns the cached container or loads it on demand.
    private func getContainer() async throws -> ModelContainer {
        if let cachedContainer { return cachedContainer }
        try await loadModel()
        return cachedContainer!
    }

    /// Returns configured generation parameters from `GenerationConfig`.
    private func makeParameters() -> GenerateParameters {
        GenerateParameters(
            maxTokens: generationConfig.maxTokens,
            temperature: generationConfig.temperature,
            topP: generationConfig.topP,
            repetitionPenalty: generationConfig.repetitionPenalty,
            repetitionContextSize: generationConfig.repetitionContextSize
        )
    }

    /// Builds a `UserInput` with proper system/user role separation.
    private func makeUserInput(for request: CoachingRequest) -> UserInput {
        UserInput(chat: [
            .system(AICoachPromptBuilder.systemPreamble),
            .user(AICoachPromptBuilder.buildUserContent(for: request)),
        ])
    }

    /// Detects repetition in generated tokens. Returns `.stop` if a trigram
    /// (3-token sequence) has appeared 3+ times in the last 30 tokens, which
    /// is a reliable signal of degenerate looping.
    private static func checkRepetition(allTokens: [Int]) -> GenerateDisposition {
        let windowSize = 30
        let ngramSize = 3
        let maxRepeats = 3

        guard allTokens.count >= ngramSize else { return .more }

        let start = max(0, allTokens.count - windowSize)
        let window = Array(allTokens[start...])

        guard window.count >= ngramSize else { return .more }

        // Count occurrences of each trigram in the window.
        var counts: [String: Int] = [:]
        for i in 0...(window.count - ngramSize) {
            let key = window[i..<(i + ngramSize)].map(String.init).joined(separator: ",")
            counts[key, default: 0] += 1
            if counts[key]! >= maxRepeats {
                return .stop
            }
        }
        return .more
    }

    /// Loads (or downloads) the model and runs generation to completion.
    private func generate(request: CoachingRequest) async throws -> String {
        let container = try await getContainer()
        let parameters = makeParameters()
        let userInput = makeUserInput(for: request)
        return try await container.perform { [generationConfig] context in
            let input = try await context.processor.prepare(input: userInput)
            var allTokens: [Int] = []
            let result = try MLXLMCommon.generate(
                input: input,
                parameters: parameters,
                context: context,
                didGenerate: { (tokens: [Int]) in
                    allTokens.append(contentsOf: tokens)
                    if allTokens.count >= generationConfig.maxTokens { return .stop }
                    return MLXAICoachService.checkRepetition(allTokens: allTokens)
                }
            )
            return result.output
        }
    }

    /// Streaming variant — yields decoded token chunks to `onChunk` as they are generated.
    private func generateStreaming(
        request: CoachingRequest,
        onChunk: @escaping @Sendable (String) -> Void
    ) async throws {
        let container = try await getContainer()
        let parameters = makeParameters()
        let userInput = makeUserInput(for: request)
        try await container.perform { [generationConfig] context in
            let input = try await context.processor.prepare(input: userInput)
            var allTokens: [Int] = []
            _ = try MLXLMCommon.generate(
                input: input,
                parameters: parameters,
                context: context,
                didGenerate: { (tokens: [Int]) in
                    allTokens.append(contentsOf: tokens)
                    let text = context.tokenizer.decode(tokens: tokens)
                    onChunk(text)
                    if allTokens.count >= generationConfig.maxTokens { return .stop }
                    return MLXAICoachService.checkRepetition(allTokens: allTokens)
                }
            )
        }
    }

    #endif
}
