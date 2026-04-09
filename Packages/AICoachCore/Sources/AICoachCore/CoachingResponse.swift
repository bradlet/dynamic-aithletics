//
//  CoachingResponse.swift
//  AICoachCore
//
//  The coach's free-text response.
//

import Foundation

/// The coach's response containing suggestions for training adjustments.
public struct CoachingResponse: Sendable {
    /// The coach's full commentary and suggestions as plain text.
    public let narrative: String

    public init(narrative: String) {
        self.narrative = narrative
    }
}
