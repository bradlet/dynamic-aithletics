//
//  DurationFormatting.swift
//  AICoachCore
//
//  Duration formatting utilities used by the prompt builder.
//

import Foundation

extension Double {

    /// Formats this value as a duration string from seconds.
    /// - Returns: A string like "45:00" or "1:30:00".
    var formattedDuration: String {
        let totalSeconds = Int(self)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }
}

extension Int {

    /// Formats this integer (seconds) as a duration string.
    /// - Returns: A string like "45:00" or "1:30:00".
    var formattedDuration: String {
        Double(self).formattedDuration
    }
}
