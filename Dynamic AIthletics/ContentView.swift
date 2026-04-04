//
//  ContentView.swift
//  Dynamic AIthletics
//
//  Root view containing the three-tab navigation structure.
//  Reads the unit configuration and injects it into the environment.
//

import SwiftUI
import SwiftData

/// The root view that provides tab-based navigation across the app's main sections.
struct ContentView: View {
    @Query private var configurations: [AppConfiguration]
    @Environment(\.modelContext) private var modelContext

    /// Reactively reads the metric preference without fetching in body.
    private var useMetric: Bool { configurations.first?.useMetricUnits ?? false }

    var body: some View {
        TabView {
            AerobicTrainingView()
                .tabItem { Label("Training", systemImage: "figure.run") }
            StrengthTrainingView()
                .tabItem { Label("Strength", systemImage: "dumbbell") }
            HistoryView()
                .tabItem { Label("History", systemImage: "clock") }
        }
        .environment(\.useMetricUnits, useMetric)
        .onAppear { ensureConfigurationExists() }
    }

    /// Creates the singleton AppConfiguration if it doesn't exist yet.
    private func ensureConfigurationExists() {
        if configurations.isEmpty {
            modelContext.insert(AppConfiguration())
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(ModelContainerFactory.makePreviewContainer())
}
