//
//  StubAICoachService.swift
//  Hybrid AIthletics
//
//  Deterministic AI coach implementation used by SwiftUI previews and unit
//  tests. Returns a canned response without loading any real model, so it
//  is fast, hermetic, and safe to invoke anywhere the real MLX-backed
//  service would be inappropriate.
//

import Foundation
import AICoachCore

/// A stub coach that returns a fixed, human-readable response.
///
/// Use this as the default `@Environment(\.aiCoach)` value so previews do
/// not trigger MLX loading, and in tests that only care about the view
/// layer's wiring rather than actual model output.
struct StubAICoachService: AICoachService {

    /// Default canned narrative returned by every call. Composed to read
    /// plausibly even without any real analysis.
    static let defaultNarrative: String = """
    Based on your last few weeks, your easy days look well-controlled but your \
    tempo sessions have been landing high on the RPE scale. For the coming two \
    weeks, I'd swap Wednesday's interval session for a second easy run, keep \
    the long run but cap it at 90 minutes, and preserve Saturday's tempo at a \
    slightly reduced volume. If your felt-ratings trend back down, we can \
    reintroduce intensity the following week.
    """

    let narrative: String

    init(narrative: String = StubAICoachService.defaultNarrative) {
        self.narrative = narrative
    }

    func suggestAdaptations(_ request: CoachingRequest) async throws -> CoachingResponse {
        CoachingResponse(narrative: narrative)
    }

    func streamSuggestion(_ request: CoachingRequest) -> AsyncThrowingStream<String, Error> {
        // Yield the canned text in small chunks so that streaming UIs can
        // exercise their typing/progress states against the stub.
        let text = narrative
        return AsyncThrowingStream { continuation in
            Task {
                let chunkSize = 24
                var index = text.startIndex
                while index < text.endIndex {
                    try? await Task.sleep(nanoseconds: 20_000_000) // 20ms
                    let end = text.index(index, offsetBy: chunkSize, limitedBy: text.endIndex) ?? text.endIndex
                    continuation.yield(String(text[index..<end]))
                    index = end
                }
                continuation.finish()
            }
        }
    }
}
