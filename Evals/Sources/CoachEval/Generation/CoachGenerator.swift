//
//  CoachGenerator.swift
//  CoachEval
//
//  Wraps MLX model loading and generation. Supports two prompt modes
//  for A/B comparison: "flat" (current broken app behavior) and "chat"
//  (proper system/user role separation).
//

import Foundation
import AICoachCore
import MLXLLM
import MLXLMCommon

/// How the prompt is formatted before being sent to the model.
enum PromptMode: String, CaseIterable {
    /// Current app behavior: entire prompt (system + user) in a single user message.
    case flat
    /// Fixed behavior: system preamble in system role, training data in user role.
    case chat
}

/// Result of a single generation run.
struct GenerationResult {
    let output: String
    let tokenCount: Int
    let totalTime: TimeInterval
    var tokensPerSecond: Double {
        totalTime > 0 ? Double(tokenCount) / totalTime : 0
    }
}

/// Loads the Gemma model and generates coaching responses.
final class CoachGenerator {

    /// Hugging Face model ID — must match the app's MLXAICoachService.modelID.
    static let modelID = "mlx-community/gemma-3-4b-it-qat-4bit"

    private let configuration: ModelConfiguration
    private var cachedContainer: ModelContainer?

    init() {
        self.configuration = ModelConfiguration(
            id: Self.modelID,
            extraEOSTokens: ["<end_of_turn>"]
        )
    }

    /// Downloads (if needed) and loads the model into memory.
    func loadModel() async throws {
        guard cachedContainer == nil else { return }
        print("Loading model \(Self.modelID)...")
        let startTime = Date()
        cachedContainer = try await LLMModelFactory.shared.loadContainer(
            configuration: configuration
        ) { progress in
            let percent = Int(progress.fractionCompleted * 100)
            print("\r  Downloading: \(percent)%", terminator: "")
            fflush(stdout)
            if percent >= 100 { print("") }
        }
        let elapsed = Date().timeIntervalSince(startTime)
        print("Model loaded in \(String(format: "%.1f", elapsed))s")
    }

    /// Generates a coaching response for the given scenario.
    func generate(
        request: CoachingRequest,
        config: GenerationConfig,
        promptMode: PromptMode
    ) async throws -> GenerationResult {
        guard let container = cachedContainer else {
            throw CoachGeneratorError.modelNotLoaded
        }

        let userInput: UserInput
        switch promptMode {
        case .flat:
            let prompt = AICoachPromptBuilder.buildPrompt(for: request)
            userInput = UserInput(prompt: prompt)
        case .chat:
            userInput = UserInput(chat: [
                .system(AICoachPromptBuilder.systemPreamble),
                .user(AICoachPromptBuilder.buildUserContent(for: request)),
            ])
        }

        let parameters = GenerateParameters(
            maxTokens: config.maxTokens,
            temperature: config.temperature,
            topP: config.topP,
            repetitionPenalty: config.repetitionPenalty,
            repetitionContextSize: config.repetitionContextSize
        )

        let startTime = Date()
        let result: (output: String, tokenCount: Int) = try await container.perform { context in
            let input = try await context.processor.prepare(input: userInput)
            let stream = try MLXLMCommon.generate(
                input: input,
                parameters: parameters,
                context: context
            )
            var output = ""
            var tokenCount = 0
            for await event in stream {
                switch event {
                case .chunk(let text):
                    output += text
                case .info(let info):
                    tokenCount = info.generationTokenCount
                case .toolCall:
                    break
                }
            }
            return (output, tokenCount)
        }

        let totalTime = Date().timeIntervalSince(startTime)
        return GenerationResult(
            output: result.output,
            tokenCount: result.tokenCount,
            totalTime: totalTime
        )
    }
}

enum CoachGeneratorError: Error, LocalizedError {
    case modelNotLoaded

    var errorDescription: String? {
        switch self {
        case .modelNotLoaded:
            return "Model not loaded. Call loadModel() first."
        }
    }
}
