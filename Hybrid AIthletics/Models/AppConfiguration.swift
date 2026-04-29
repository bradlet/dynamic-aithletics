//
//  AppConfiguration.swift
//  Hybrid AIthletics
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

    /// Whether the user has enabled the auto-export Google Sheets Sync feature.
    /// When `true`, every workout add/edit/delete schedules a debounced full
    /// overwrite of the spreadsheet identified by `googleSheetsSpreadsheetID`.
    /// Synced across devices via CloudKit; OAuth tokens are not synced and
    /// each device must sign in independently.
    var googleSheetsSyncEnabled: Bool = false

    /// The Google Sheets spreadsheet ID created for this user when they
    /// enabled sync. Empty when sync has never been enabled. The app creates
    /// this spreadsheet on first enable rather than asking the user to pick
    /// one.
    var googleSheetsSpreadsheetID: String = ""

    /// Creates a new configuration with default values.
    init(
        useMetricUnits: Bool = false,
        googleSheetsSyncEnabled: Bool = false,
        googleSheetsSpreadsheetID: String = ""
    ) {
        self.useMetricUnits = useMetricUnits
        self.googleSheetsSyncEnabled = googleSheetsSyncEnabled
        self.googleSheetsSpreadsheetID = googleSheetsSpreadsheetID
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
