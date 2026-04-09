//
//  AICoachSheet.swift
//  Hybrid AIthletics
//
//  Modal sheet that streams a coaching suggestion from the injected
//  AICoachService given the user's recent workouts and upcoming plan.
//

import SwiftUI
import AICoachCore

/// A sheet that asks the AI coach for suggestions on adapting the user's
/// upcoming training based on their recent workouts and perceived exertion.
///
/// Opening the sheet immediately starts downloading/loading the model in the
/// background. Once the model is ready a "Generate Suggestions" button appears.
/// The user must tap it explicitly to run inference — download and generation
/// are never conflated.
struct AICoachSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.aiCoach) private var coach

    /// The request assembled by the presenting view.
    let request: CoachingRequest

    // MARK: - State

    @State private var responseText: String = ""
    @State private var isGenerating: Bool = false
    @State private var isLoadingModel: Bool = false
    @State private var modelReady: Bool = false
    @State private var errorMessage: String?
    @State private var downloadProgress: Double?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    headerCard
                    if !modelReady && isLoadingModel {
                        downloadCard
                    }
                    if modelReady {
                        generateButton
                    }
                    if !responseText.isEmpty || isGenerating || errorMessage != nil {
                        responseCard
                    }
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
                    if modelReady && !responseText.isEmpty {
                        Button {
                            Task { await generate() }
                        } label: {
                            Label("Regenerate", systemImage: "arrow.clockwise")
                        }
                        .disabled(isGenerating)
                    }
                }
            }
            .task {
                await prepareModel()
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

    /// Download / model loading progress indicator.
    private var downloadCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                ProgressView()
                Text(downloadProgress != nil
                     ? "Downloading AI coach…"
                     : coach.isModelCached
                        ? "Loading model…"
                        : "Downloading AI coach…")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            if let downloadProgress {
                ProgressView(value: downloadProgress)
                    .tint(.accentColor)
                Text("\(Int(downloadProgress * 100))% — ~2 GB download, this only happens once.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            } else if !coach.isModelCached {
                Text("~2 GB download — this only happens once.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    /// Primary action button to kick off generation.
    @ViewBuilder
    private var generateButton: some View {
        if request.recentWorkouts.isEmpty {
            Label(
                "Start tracking workouts to build a history for the AI coach to use.",
                systemImage: "figure.run"
            )
            .font(.callout)
            .foregroundStyle(.secondary)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        } else if responseText.isEmpty && !isGenerating {
            Button {
                Task { await generate() }
            } label: {
                Label("Generate Suggestions", systemImage: "sparkles")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }

    /// The streaming response body.
    private var responseCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle")
                    .font(.callout)
                    .foregroundStyle(.red)
            } else if responseText.isEmpty && isGenerating {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Generating…")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text(responseText)
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

    /// Downloads/loads the model in the background so it's ready when the
    /// user taps "Generate Suggestions".
    private func prepareModel() async {
        guard !modelReady else { return }
        isLoadingModel = true

        var mutableCoach = coach
        mutableCoach.onDownloadProgress = { fraction in
            Task { @MainActor in
                downloadProgress = fraction
            }
        }

        do {
            try await mutableCoach.loadModel()
            modelReady = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoadingModel = false
        downloadProgress = nil
    }

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
