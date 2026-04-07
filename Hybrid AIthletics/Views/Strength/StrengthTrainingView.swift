//
//  StrengthTrainingView.swift
//  Hybrid AIthletics
//
//  Placeholder view for the strength training tab.
//  Will be implemented in a future iteration with weekly calendar and exercises.
//

import SwiftUI

/// Placeholder for the strength training weekly calendar (coming soon).
struct StrengthTrainingView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Strength Training",
                systemImage: "dumbbell",
                description: Text("Coming soon")
            )
            .navigationTitle("Strength")
        }
    }
}

#Preview {
    StrengthTrainingView()
}
