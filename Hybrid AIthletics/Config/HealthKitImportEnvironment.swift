//
//  HealthKitImportEnvironment.swift
//  Hybrid AIthletics
//
//  Custom SwiftUI environment key that injects a `HealthKitImportService`
//  into the view hierarchy. Default value is `StubHealthKitImportService`
//  so previews and tests never trigger a real HealthKit authorization
//  prompt.
//

import SwiftUI

/// Environment key for the shared `HealthKitImportService` instance.
private struct HealthKitImportKey: EnvironmentKey {
    static let defaultValue: HealthKitImportService = StubHealthKitImportService()
}

extension EnvironmentValues {
    /// The active HealthKit import service. Defaults to
    /// `StubHealthKitImportService`; the real implementation is injected
    /// at the app root.
    var healthKitImport: HealthKitImportService {
        get { self[HealthKitImportKey.self] }
        set { self[HealthKitImportKey.self] = newValue }
    }
}
