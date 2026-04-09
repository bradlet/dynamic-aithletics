//
//  EvalScenario.swift
//  CoachEval
//
//  Defines an evaluation scenario with a coaching request and expectations
//  for what a good response should look like.
//

import Foundation
import AICoachCore

/// A single evaluation scenario with synthetic training data and expected
/// output characteristics.
struct EvalScenario {
    /// Short identifier used on the command line (e.g. "high-rpe").
    let id: String
    /// Human-readable name for reports.
    let name: String
    /// Description of what this scenario tests.
    let description: String
    /// The coaching request with synthetic workout/exercise data.
    let request: CoachingRequest
    /// What a good response should look like.
    let expectations: EvalExpectations
}

/// Expected characteristics of a good AI coach response.
struct EvalExpectations {
    /// Keywords that SHOULD appear in the response.
    var expectedKeywords: [String] = []
    /// Keywords that should NOT appear (indicates hallucination).
    var forbiddenKeywords: [String] = []
    /// Expected bullet count range.
    var bulletRange: ClosedRange<Int> = 3...5
    /// Maximum acceptable word count.
    var maxWords: Int = 200
}
