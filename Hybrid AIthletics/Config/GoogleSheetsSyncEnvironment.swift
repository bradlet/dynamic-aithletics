//
//  GoogleSheetsSyncEnvironment.swift
//  Hybrid AIthletics
//
//  SwiftUI environment key that injects the shared
//  `GoogleSheetsSyncCoordinator`. Default value is a coordinator backed by
//  the in-memory `StubGoogleSheetsAPI` so previews and tests never trigger
//  real OAuth or hit the network.
//

import SwiftUI

/// Environment key for the shared `GoogleSheetsSyncCoordinator` instance.
/// Default is a stub-backed coordinator so previews never touch the network.
private struct GoogleSheetsSyncKey: EnvironmentKey {
    @MainActor
    static let defaultValue: GoogleSheetsSyncCoordinator = GoogleSheetsSyncCoordinator(
        api: StubGoogleSheetsAPI(isAuthorized: false)
    )
}

extension EnvironmentValues {
    /// The active Google Sheets sync coordinator. Defaults to a stub-backed
    /// instance; the production coordinator is injected at the app root.
    var googleSheetsSync: GoogleSheetsSyncCoordinator {
        get { self[GoogleSheetsSyncKey.self] }
        set { self[GoogleSheetsSyncKey.self] = newValue }
    }
}
