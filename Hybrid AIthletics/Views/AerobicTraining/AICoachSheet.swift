//
//  AICoachSheet.swift
//  Hybrid AIthletics
//
//  Modal sheet that streams a coaching suggestion from the injected
//  AICoachService given the user's recent workouts and upcoming plan.
//

import SwiftUI

/// A sheet that asks the AI coach for suggestions on adapting the user's
/// upcoming training based on their recent workouts and perceived exertion.
struct AICoachSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.aiCoach) private var coach

    /// The request assembled by the presenting view.
    let request: CoachingRequest

    @State private var responseText: String = ""
    @State private var isGenerating: Bool = false
    @State private var errorMessage: String?
    @State private var hasStarted: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    headerCard
                    responseCard
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Coach")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Task { await generate() }
                    } label: {
                        Label("Regenerate", systemImage: "arrow.clockwise")
                    }
                    .disabled(isGenerating || request.recentWorkouts.isEmpty)
                }
            }
            .task {
                guard !hasStarted else { return }
                hasStarted = true
                guard !request.recentWorkouts.isEmpty else { return }
                await generate()
            }
        }
    }

    // MARK: - Subviews

    /// Branding/header card that frames the suggestion.
    private var headerCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "sparkles")
                .font(.title2)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.accentColor)
                .frame(width: 44, height: 44)
                .background(
                    Circle().fill(Color.accentColor.opacity(0.15))
                )
            VStack(alignment: .leading, spacing: 2) {
                Text("On-device Coach")
                    .font(.headline)
                Text("\(request.recentWorkouts.count) recent • \(request.upcomingExercises.count) upcoming")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    /// The streaming response body.
    private var responseCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            if request.recentWorkouts.isEmpty {
                Label(
                    "Start tracking workouts to build a history for the AI coach to use.",
                    systemImage: "figure.run"
                )
                .font(.callout)
                .foregroundStyle(.secondary)
            } else if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle")
                    .font(.callout)
                    .foregroundStyle(.red)
            } else if responseText.isEmpty && isGenerating {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        ProgressView()
                        Text(coach.isModelCached
                             ? "Warming up coach…"
                             : "Downloading AI coach…")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    if !coach.isModelCached {
                        Text("~2 GB download — this only happens once.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            } else {
                Text(responseText.isEmpty ? " " : responseText)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    // MARK: - Actions

    /// Kicks off a streaming generation and appends chunks to `responseText`.
    private func generate() async {
        responseText = ""
        errorMessage = nil
        isGenerating = true
        defer { isGenerating = false }

        do {
            for try await chunk in coach.streamSuggestion(request) {
                responseText += chunk
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    AICoachSheet(
        request: CoachingRequest(
            recentWorkouts: [],
            upcomingExercises: [],
            useMetricUnits: false
        )
    )
}
