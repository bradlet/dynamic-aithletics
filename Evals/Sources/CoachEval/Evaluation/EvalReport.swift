//
//  EvalReport.swift
//  CoachEval
//
//  Formatted output for evaluation results.
//

import Foundation

/// Formats evaluation results for terminal output.
enum EvalReport {

    /// Prints a full evaluation report for a single scenario run.
    static func printReport(
        scenario: EvalScenario,
        output: String,
        score: QualityScore,
        promptMode: String,
        tokensPerSecond: Double?,
        totalTime: TimeInterval?
    ) {
        let divider = String(repeating: "=", count: 60)
        print("\n\(divider)")
        print("Scenario: \(scenario.id) (\(scenario.name))")
        print("Prompt mode: \(promptMode)")
        print(divider)

        print("\n--- Generated Output ---")
        print(output)

        print("\n--- Quality Score: \(score.total)/\(score.maxTotal) ---")
        for check in score.checks {
            let status = check.passed ? "PASS" : "FAIL"
            print("  [\(status)] \(check.name): \(check.detail) (\(check.score)/\(check.maxScore))")
        }

        if let tps = tokensPerSecond, let time = totalTime {
            print("\nGeneration stats: \(String(format: "%.1f", tps)) tok/s, " +
                  "\(String(format: "%.2f", time))s total")
        }
        print("")
    }

    /// Prints a comparison table across multiple runs.
    static func printComparison(
        scenario: EvalScenario,
        results: [(config: String, mode: String, score: QualityScore,
                    wordCount: Int, bulletCount: Int, tps: Double?)]
    ) {
        let divider = String(repeating: "=", count: 70)
        print("\n\(divider)")
        print("Comparison: \(scenario.id) (\(scenario.name))")
        print(divider)

        let header = String(
            format: "| %-14s | %-4s | %5s | %5s | %7s | %7s |",
            "Config", "Mode", "Score", "Words", "Bullets", "Tok/s"
        )
        let line = String(repeating: "-", count: header.count)
        print(header)
        print(line)

        for r in results {
            let tps = r.tps.map { String(format: "%.1f", $0) } ?? "n/a"
            let row = String(
                format: "| %-14s | %-4s | %5d | %5d | %7d | %7s |",
                r.config, r.mode, r.score.total, r.wordCount, r.bulletCount, tps
            )
            print(row)
        }
        print("")
    }
}
