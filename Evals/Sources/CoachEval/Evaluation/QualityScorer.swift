//
//  QualityScorer.swift
//  CoachEval
//
//  Automated quality checks for AI coach output. Scores each response
//  on a 100-point scale across multiple dimensions.
//

import Foundation
import AICoachCore

/// Result of a single quality check.
struct QualityCheck {
    let name: String
    let score: Int
    let maxScore: Int
    let passed: Bool
    let detail: String
}

/// Aggregate quality score for a generated response.
struct QualityScore {
    let checks: [QualityCheck]
    var total: Int { checks.map(\.score).reduce(0, +) }
    var maxTotal: Int { checks.map(\.maxScore).reduce(0, +) }
}

/// Scores AI coach output against quality criteria.
enum QualityScorer {

    /// Runs all quality checks on the generated output.
    /// - Parameters:
    ///   - output: The generated text from the model.
    ///   - scenario: The scenario that was evaluated.
    /// - Returns: A `QualityScore` with individual check results.
    static func score(output: String, scenario: EvalScenario) -> QualityScore {
        let checks = [
            checkWordCount(output, maxWords: scenario.expectations.maxWords),
            checkRepetition(output),
            checkBulletStructure(output, expectedRange: scenario.expectations.bulletRange),
            checkActionableLanguage(output),
            checkHallucination(output, scenario: scenario),
            checkCoherentEnding(output),
        ]
        return QualityScore(checks: checks)
    }

    // MARK: - Individual checks

    /// Word count: 50-200 words = full marks (20 pts).
    static func checkWordCount(_ output: String, maxWords: Int) -> QualityCheck {
        let words = output.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count
        let passed = words >= 50 && words <= maxWords
        let score: Int
        if words < 20 || words > maxWords + 100 {
            score = 0
        } else if words < 50 {
            score = 10
        } else if words > maxWords {
            score = 10
        } else {
            score = 20
        }
        return QualityCheck(
            name: "Word count",
            score: score, maxScore: 20, passed: passed,
            detail: "\(words) words (target: 50–\(maxWords))"
        )
    }

    /// No repetition: trigram analysis on words (20 pts).
    static func checkRepetition(_ output: String) -> QualityCheck {
        let words = output.lowercased()
            .split(whereSeparator: { $0.isWhitespace || $0.isNewline })
            .map(String.init)
        let ngramSize = 3
        let maxRepeats = 3

        guard words.count >= ngramSize else {
            return QualityCheck(
                name: "No repetition", score: 20, maxScore: 20,
                passed: true, detail: "Too short to have repetition"
            )
        }

        var counts: [String: Int] = [:]
        var worstTrigram = ""
        var worstCount = 0
        for i in 0...(words.count - ngramSize) {
            let key = words[i..<(i + ngramSize)].joined(separator: " ")
            counts[key, default: 0] += 1
            if counts[key]! > worstCount {
                worstCount = counts[key]!
                worstTrigram = key
            }
        }

        let passed = worstCount < maxRepeats
        let score = passed ? 20 : 0
        let detail = passed
            ? "No trigram repeated \(maxRepeats)+ times"
            : "Trigram \"\(worstTrigram)\" repeated \(worstCount) times"
        return QualityCheck(
            name: "No repetition", score: score, maxScore: 20,
            passed: passed, detail: detail
        )
    }

    /// Bullet structure: 3-5 lines starting with - or * (20 pts).
    static func checkBulletStructure(
        _ output: String,
        expectedRange: ClosedRange<Int>
    ) -> QualityCheck {
        let lines = output.components(separatedBy: .newlines)
        let bulletLines = lines.filter { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            return trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ")
                || (trimmed.first?.isNumber == true && trimmed.contains(". "))
        }
        let count = bulletLines.count
        let passed = expectedRange.contains(count)
        let score: Int
        if count == 0 {
            score = 0
        } else if passed {
            score = 20
        } else {
            score = 10
        }
        return QualityCheck(
            name: "Bullet structure",
            score: score, maxScore: 20, passed: passed,
            detail: "\(count) bullets found (expected: \(expectedRange.lowerBound)–\(expectedRange.upperBound))"
        )
    }

    /// Actionable language: contains coaching verbs (15 pts).
    static func checkActionableLanguage(_ output: String) -> QualityCheck {
        let actionVerbs = [
            "reduce", "increase", "swap", "add", "remove", "keep",
            "maintain", "cap", "replace", "skip", "shorten", "lengthen",
            "lower", "postpone", "move", "drop", "cut",
        ]
        let lower = output.lowercased()
        let found = actionVerbs.filter { lower.contains($0) }
        let score = min(15, found.count * 5)
        let passed = found.count >= 3
        return QualityCheck(
            name: "Actionable language",
            score: score, maxScore: 15, passed: passed,
            detail: "Found: \(found.joined(separator: ", "))"
        )
    }

    /// No hallucination: doesn't reference exercise types absent from input (15 pts).
    static func checkHallucination(_ output: String, scenario: EvalScenario) -> QualityCheck {
        let inputTypes = Set(
            scenario.request.recentWorkouts.map(\.type.rawValue)
            + scenario.request.upcomingExercises.map(\.type.rawValue)
        )
        let allTypes = CoachExerciseType.allCases.map(\.rawValue)
        let lower = output.lowercased()
        let hallucinated = allTypes.filter { type in
            !inputTypes.contains(type) && lower.contains(type.lowercased())
        }
        let passed = hallucinated.isEmpty
        return QualityCheck(
            name: "No hallucination",
            score: passed ? 15 : 0, maxScore: 15, passed: passed,
            detail: passed
                ? "No unreferenced exercise types"
                : "Hallucinated types: \(hallucinated.joined(separator: ", "))"
        )
    }

    /// Coherent ending: ends with punctuation, no template artifacts (10 pts).
    static func checkCoherentEnding(_ output: String) -> QualityCheck {
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasArtifacts = trimmed.contains("<end_of_turn>")
            || trimmed.contains("<start_of_turn>")
            || trimmed.contains("<eos>")
        let endsCleanly: Bool
        if let last = trimmed.last {
            endsCleanly = ".!?".contains(last) || trimmed.hasSuffix(")")
        } else {
            endsCleanly = false
        }
        let passed = endsCleanly && !hasArtifacts
        let score: Int
        if hasArtifacts {
            score = 0
        } else if endsCleanly {
            score = 10
        } else {
            score = 5
        }
        var detail = ""
        if hasArtifacts { detail += "Contains template artifacts. " }
        if !endsCleanly { detail += "Does not end with punctuation. " }
        if passed { detail = "Clean ending" }
        return QualityCheck(
            name: "Coherent ending",
            score: score, maxScore: 10, passed: passed,
            detail: detail.trimmingCharacters(in: .whitespaces)
        )
    }
}
