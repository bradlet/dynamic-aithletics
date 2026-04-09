//
//  InspectPromptCommand.swift
//  CoachEval
//
//  Prints the raw prompt for a scenario without running the model.
//  Useful for iterating on prompt text without waiting for generation.
//

import ArgumentParser
import Foundation
import AICoachCore

struct InspectPromptCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "inspect",
        abstract: "Print the raw prompt for a scenario (no model needed)."
    )

    @Option(name: .long, help: "Scenario ID to inspect.")
    var scenario: String = "high-rpe"

    @Option(name: .long, help: "Prompt mode: flat or chat.")
    var promptMode: String = "chat"

    func run() async throws {
        guard let mode = PromptMode(rawValue: promptMode) else {
            print("Error: --prompt-mode must be 'flat' or 'chat'")
            throw ExitCode.validationFailure
        }

        guard let s = ScenarioLibrary.scenario(id: scenario) else {
            print("Error: Unknown scenario '\(scenario)'. Available: \(ScenarioLibrary.all.map(\.id).joined(separator: ", "))")
            throw ExitCode.validationFailure
        }

        let divider = String(repeating: "=", count: 60)
        print(divider)
        print("Scenario: \(s.id) (\(s.name))")
        print("Prompt mode: \(mode.rawValue)")
        print(divider)

        switch mode {
        case .flat:
            print("\n[Single user message]")
            print(AICoachPromptBuilder.buildPrompt(for: s.request))
        case .chat:
            print("\n[System message]")
            print(AICoachPromptBuilder.systemPreamble)
            print("\n[User message]")
            print(AICoachPromptBuilder.buildUserContent(for: s.request))
        }
        print("")
    }
}
