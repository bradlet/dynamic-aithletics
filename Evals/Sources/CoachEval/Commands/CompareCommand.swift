//
//  CompareCommand.swift
//  CoachEval
//
//  Runs the same scenario with multiple parameter configurations and
//  displays a comparison table.
//

import ArgumentParser
import Foundation
import AICoachCore

struct CompareCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "compare",
        abstract: "Run a scenario with multiple configs and compare results."
    )

    @Option(name: .long, help: "Scenario ID to compare.")
    var scenario: String = "high-rpe"

    func run() async throws {
        guard let s = ScenarioLibrary.scenario(id: scenario) else {
            print("Error: Unknown scenario '\(scenario)'. Available: \(ScenarioLibrary.all.map(\.id).joined(separator: ", "))")
            throw ExitCode.validationFailure
        }

        let generator = CoachGenerator()
        try await generator.loadModel()

        // Define configurations to compare
        let configs: [(name: String, config: GenerationConfig, mode: PromptMode)] = [
            ("production", .production, .flat),
            ("production", .production, .chat),
            ("lowerRepPen", .lowerRepPenalty, .chat),
            ("conservative", .conservative, .chat),
        ]

        var results: [(config: String, mode: String, score: QualityScore,
                        wordCount: Int, bulletCount: Int, tps: Double?)] = []

        for (name, config, mode) in configs {
            print("Running \(name) (\(mode.rawValue))...")
            let result = try await generator.generate(
                request: s.request,
                config: config,
                promptMode: mode
            )

            let score = QualityScorer.score(output: result.output, scenario: s)
            let words = result.output.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count
            let bullets = result.output.components(separatedBy: .newlines).filter {
                let t = $0.trimmingCharacters(in: .whitespaces)
                return t.hasPrefix("- ") || t.hasPrefix("* ")
            }.count

            results.append((
                config: name,
                mode: mode.rawValue,
                score: score,
                wordCount: words,
                bulletCount: bullets,
                tps: result.tokensPerSecond
            ))

            // Also print full output for each run
            EvalReport.printReport(
                scenario: s,
                output: result.output,
                score: score,
                promptMode: mode.rawValue,
                tokensPerSecond: result.tokensPerSecond,
                totalTime: result.totalTime
            )
        }

        EvalReport.printComparison(scenario: s, results: results)
    }
}
