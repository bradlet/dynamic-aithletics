//
//  ImportCSVConfirmationSheet.swift
//  Hybrid AIthletics
//
//  Sheet shown after the user picks a CSV file to import. Summarizes
//  what will be imported and — critically — makes the distance unit
//  selection explicit and prominent, since the CSV schema does not
//  embed the unit in the column name.
//

import SwiftUI

/// Confirmation sheet for a parsed CSV import.
/// The caller provides the parse result and a binding to the chosen
/// distance unit; this sheet does not mutate the SwiftData store.
struct ImportCSVConfirmationSheet: View {
    let filename: String
    let parseResult: WorkoutCSVParseResult
    @Binding var unit: WorkoutCSVDistanceUnit
    let onCancel: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundStyle(.secondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(filename)
                                .font(.subheadline)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            Text("\(parseResult.rows.count) workouts ready to import")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section {
                    Picker("Distance values are in", selection: $unit) {
                        ForEach(WorkoutCSVDistanceUnit.allCases) { unit in
                            Text(unit.displayName).tag(unit)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text("All \(parseResult.rows.count) rows will be interpreted as **\(unit.displayName.lowercased())**. Switch to the other unit if this file was exported from a different preference.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Distance Unit")
                } footer: {
                    EmptyView()
                }

                if !parseResult.skipped.isEmpty {
                    Section {
                        DisclosureGroup("\(parseResult.skipped.count) row\(parseResult.skipped.count == 1 ? "" : "s") skipped") {
                            ForEach(Array(parseResult.skipped.prefix(10).enumerated()), id: \.offset) { _, skipped in
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Line \(skipped.line)")
                                        .font(.caption.monospacedDigit())
                                        .foregroundStyle(.secondary)
                                    Text(skipped.reason)
                                        .font(.caption)
                                }
                                .padding(.vertical, 2)
                            }
                            if parseResult.skipped.count > 10 {
                                Text("…and \(parseResult.skipped.count - 10) more")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } header: {
                        Text("Skipped Rows")
                    } footer: {
                        Text("These rows failed validation and will not be imported.")
                            .font(.footnote)
                    }
                }
            }
            .navigationTitle("Import Workouts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Import \(parseResult.rows.count)") {
                        onConfirm()
                    }
                    .disabled(parseResult.rows.isEmpty)
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var unit: WorkoutCSVDistanceUnit = .miles
    ImportCSVConfirmationSheet(
        filename: "workouts-2026-04-09.csv",
        parseResult: WorkoutCSVParseResult(
            rows: [],
            skipped: [
                .init(line: 3, reason: "invalid date 'yesterday'"),
                .init(line: 5, reason: "invalid distance 'five'")
            ]
        ),
        unit: $unit,
        onCancel: {},
        onConfirm: {}
    )
}
