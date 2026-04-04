//
//  AppConfiguration.swift
//  Dynamic AIthletics
//
//  Singleton app-wide preferences stored in SwiftData.
//  Syncs via CloudKit alongside other model data.
//

import Foundation
import SwiftData

@Model
final class AppConfiguration {
    /// Whether to display distances in metric units (km). Default is false (miles).
    var useMetricUnits: Bool = false

    /// Creates a new configuration with default values.
    /// - Parameter useMetricUnits: Whether to use metric units. Defaults to false (miles).
    init(useMetricUnits: Bool = false) {
        self.useMetricUnits = useMetricUnits
    }

    /// Fetches the singleton configuration, creating one if it doesn't exist.
    /// - Parameter context: The model context to query.
    /// - Returns: The app configuration instance.
    static func current(in context: ModelContext) -> AppConfiguration {
        let descriptor = FetchDescriptor<AppConfiguration>()
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        let config = AppConfiguration()
        context.insert(config)
        return config
    }
}
