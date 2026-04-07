//
//  UnitEnvironment.swift
//  Hybrid AIthletics
//
//  Custom SwiftUI environment key for metric unit preference.
//  Allows any view in the hierarchy to read the unit setting
//  without an additional SwiftData query.
//

import SwiftUI

/// Environment key for the metric units preference.
private struct UseMetricUnitsKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// Whether to display distances in metric units (km vs mi).
    var useMetricUnits: Bool {
        get { self[UseMetricUnitsKey.self] }
        set { self[UseMetricUnitsKey.self] = newValue }
    }
}
