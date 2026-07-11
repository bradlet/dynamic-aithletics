//
//  SettingsView.swift
//  Hybrid AIthletics
//
//  App-wide preferences sheet, opened from the History tab's toolbar.
//  Edits the singleton `AppConfiguration` (SwiftData, CloudKit-synced).
//

import SwiftUI
import SwiftData

/// A form for app-wide preferences: workout week start day and units.
///
/// The week-start picker only affects weekly aggregation math (weekly
/// mileage buckets, "This Week" stats); calendar grids stay visually
/// Sunday-first regardless.
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var configurations: [AppConfiguration]

    /// Weekday display names indexed by Calendar weekday - 1 (Sunday first).
    private static let weekdaySymbols = Calendar.current.weekdaySymbols

    var body: some View {
        NavigationStack {
            Form {
                if let config = configurations.first {
                    @Bindable var config = config
                    Section {
                        Picker("Week starts on", selection: $config.weekStartDay) {
                            ForEach(1...7, id: \.self) { weekday in
                                Text(Self.weekdaySymbols[weekday - 1]).tag(weekday)
                            }
                        }
                        .accessibilityIdentifier("settings.weekStartDay")
                    } header: {
                        Text("Training Week")
                    } footer: {
                        Text("Weekly mileage and stats count workouts from this day. The calendar layout stays Sunday-first.")
                    }
                    Section("Units") {
                        Toggle("Use metric units (km)", isOn: $config.useMetricUnits)
                            .accessibilityIdentifier("settings.useMetricUnits")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .accessibilityIdentifier("settings.doneButton")
                }
            }
            .onChange(of: configurations.first?.weekStartDay) { saveChanges() }
            .onChange(of: configurations.first?.useMetricUnits) { saveChanges() }
            .onAppear { ensureConfigurationExists() }
        }
    }

    /// Persists preference edits immediately so other devices sync promptly.
    private func saveChanges() {
        try? modelContext.save()
    }

    /// Creates the singleton AppConfiguration if it doesn't exist yet
    /// (mirrors `ContentView.ensureConfigurationExists`; matters for a
    /// fresh install where this sheet appears before any workout is saved,
    /// and for previews).
    private func ensureConfigurationExists() {
        if configurations.isEmpty {
            modelContext.insert(AppConfiguration())
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(ModelContainerFactory.makePreviewContainer())
}
