//
//  WorkoutCSV.swift
//  Hybrid AIthletics
//
//  Pure CSV encoding and parsing for the Workout model.
//  Deliberately has no SwiftData or SwiftUI dependencies so it is fully
//  unit-testable. The schema is fixed (see `header`) and column order is
//  never inferred from headers on import.
//

import Foundation

/// Distance unit for the single `distance` column in the CSV schema.
/// The unit is not embedded in the column name or header; callers must
/// supply it when encoding and decoding.
enum WorkoutCSVDistanceUnit: String, CaseIterable, Identifiable {
    case miles
    case kilometers

    var id: String { rawValue }

    /// Human-readable label for UI.
    var displayName: String {
        switch self {
        case .miles: return "Miles"
        case .kilometers: return "Kilometers"
        }
    }

    /// Converts a value expressed in this unit to miles (internal storage).
    func toMiles(_ value: Double) -> Double {
        switch self {
        case .miles: return value
        case .kilometers: return value / 1.60934
        }
    }

    /// Converts miles to a value expressed in this unit.
    func fromMiles(_ miles: Double) -> Double {
        switch self {
        case .miles: return miles
        case .kilometers: return miles * 1.60934
        }
    }
}

/// A single parsed CSV row before being materialized into a `Workout`.
struct WorkoutCSVRow: Equatable {
    var date: Date
    var name: String
    var type: ExerciseType
    var durationSeconds: Int
    /// Distance expressed in the unit chosen by the caller of `parse`/`encode`.
    var distance: Double
    var notes: String
    var feltRating: Int
}

/// Errors raised only for whole-file failures. Per-row problems are
/// collected into `ParseResult.skipped` instead of throwing.
enum WorkoutCSVError: Error, Equatable {
    case empty
    case missingHeader
}

/// Result of parsing a CSV document.
struct WorkoutCSVParseResult: Equatable {
    /// Successfully parsed rows, in source order.
    var rows: [WorkoutCSVRow]
    /// Lines that failed validation, paired with a short human-readable reason.
    /// Line numbers are 1-based and refer to the row's starting line in the
    /// source text (header row is line 1).
    var skipped: [SkippedRow]

    struct SkippedRow: Equatable {
        var line: Int
        var reason: String
    }
}

/// Stateless CSV codec for `Workout` history.
enum WorkoutCSV {

    /// Fixed schema header. Column order is authoritative; header names
    /// are written on export but ignored on import (the schema is fixed).
    static let header = "date,name,type,duration_seconds,distance,notes,felt_rating"

    // MARK: - Encoding

    /// Encodes workouts to a CSV string with the fixed schema.
    /// - Parameters:
    ///   - workouts: Workouts to serialize, in the order they should appear.
    ///   - unit: Unit to use for the `distance` column. Values are converted
    ///           from the internal miles storage before being written.
    /// - Returns: A full CSV document ending with a trailing newline.
    static func encode(workouts: [Workout], unit: WorkoutCSVDistanceUnit) -> String {
        var output = header + "\n"
        for workout in workouts {
            output += encodeRow(workout: workout, unit: unit) + "\n"
        }
        return output
    }

    /// Serializes a single workout as one CSV row (no trailing newline).
    static func encodeRow(workout: Workout, unit: WorkoutCSVDistanceUnit) -> String {
        let date = iso8601Formatter.string(from: workout.date)
        let distance = unit.fromMiles(workout.distanceMiles)
        let fields: [String] = [
            escape(date),
            escape(workout.name),
            escape(workout.type.rawValue),
            String(workout.durationSeconds),
            formatDistance(distance),
            escape(workout.notes),
            String(workout.feltRating)
        ]
        return fields.joined(separator: ",")
    }

    // MARK: - Decoding

    /// Parses a CSV document into rows. The first non-empty line is
    /// assumed to be the header and discarded without validation.
    /// - Parameter csv: Full CSV document text.
    /// - Throws: `WorkoutCSVError.empty` if the document is empty or whitespace only.
    ///           `WorkoutCSVError.missingHeader` if no header line can be found.
    /// - Returns: A `WorkoutCSVParseResult` with successful rows and skipped rows.
    static func parse(_ csv: String) throws -> WorkoutCSVParseResult {
        let trimmed = csv.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw WorkoutCSVError.empty }

        let records = tokenize(csv)
        guard !records.isEmpty else { throw WorkoutCSVError.missingHeader }

        // First record is the header — discard without validation (schema is fixed).
        let dataRecords = records.dropFirst()

        var rows: [WorkoutCSVRow] = []
        var skipped: [WorkoutCSVParseResult.SkippedRow] = []

        for record in dataRecords {
            // Skip fully blank lines silently.
            if record.fields.count == 1 && record.fields[0].isEmpty { continue }

            let outcome = decodeRow(record.fields)
            switch outcome {
            case .row(let row):
                rows.append(row)
            case .skip(let reason):
                skipped.append(.init(line: record.startLine, reason: reason))
            }
        }

        return WorkoutCSVParseResult(rows: rows, skipped: skipped)
    }

    /// Converts a parsed row to a `Workout`, applying the distance unit
    /// conversion to produce the internal miles storage value.
    static func toWorkout(_ row: WorkoutCSVRow, unit: WorkoutCSVDistanceUnit) -> Workout {
        Workout(
            name: row.name,
            type: row.type,
            durationSeconds: row.durationSeconds,
            distanceMiles: unit.toMiles(row.distance),
            notes: row.notes,
            date: row.date,
            feltRating: row.feltRating
        )
    }

    // MARK: - Internals

    /// A single logical CSV record after field splitting. `startLine` is
    /// the 1-based line number in the source text (handles embedded newlines).
    private struct Record {
        var fields: [String]
        var startLine: Int
    }

    /// ISO8601 formatter with internet date-time format.
    private static let iso8601Formatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    /// Fallback ISO8601 formatter that also accepts fractional seconds, since
    /// some exports (and many CSV editors) produce them.
    private static let iso8601FractionalFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    /// RFC 4180 field escape: wrap in quotes if the field contains a comma,
    /// quote, or newline; double any embedded quotes.
    private static func escape(_ field: String) -> String {
        let needsQuoting = field.contains(",") || field.contains("\"") || field.contains("\n") || field.contains("\r")
        guard needsQuoting else { return field }
        let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }

    /// Formats distance with fixed 2-decimal precision using the POSIX locale
    /// so the decimal separator is always a period.
    private static func formatDistance(_ value: Double) -> String {
        String(format: "%.2f", value)
    }

    /// Tokenizes a CSV document into records, handling RFC 4180 quoted
    /// fields with embedded commas, quotes, and newlines.
    private static func tokenize(_ csv: String) -> [Record] {
        var records: [Record] = []
        var currentFields: [String] = []
        var currentField = ""
        var inQuotes = false
        var line = 1
        var recordStartLine = 1

        let chars = Array(csv)
        var i = 0
        while i < chars.count {
            let c = chars[i]

            if inQuotes {
                if c == "\"" {
                    // Doubled quote inside a quoted field → literal quote.
                    if i + 1 < chars.count && chars[i + 1] == "\"" {
                        currentField.append("\"")
                        i += 2
                        continue
                    }
                    inQuotes = false
                    i += 1
                    continue
                }
                if c == "\n" { line += 1 }
                currentField.append(c)
                i += 1
                continue
            }

            switch c {
            case "\"":
                inQuotes = true
                i += 1
            case ",":
                currentFields.append(currentField)
                currentField = ""
                i += 1
            case "\r":
                // Normalize CRLF/CR to LF by deferring to the newline branch.
                if i + 1 < chars.count && chars[i + 1] == "\n" {
                    i += 1 // consume \r, let \n handler finish the record
                    continue
                }
                fallthrough
            case "\n":
                currentFields.append(currentField)
                records.append(Record(fields: currentFields, startLine: recordStartLine))
                currentFields = []
                currentField = ""
                line += 1
                recordStartLine = line
                i += 1
            default:
                currentField.append(c)
                i += 1
            }
        }

        // Flush trailing field/record (file may not end with a newline).
        if !currentField.isEmpty || !currentFields.isEmpty {
            currentFields.append(currentField)
            records.append(Record(fields: currentFields, startLine: recordStartLine))
        }

        return records
    }

    /// Outcome of decoding a single tokenized row.
    private enum DecodeOutcome {
        case row(WorkoutCSVRow)
        case skip(String)
    }

    /// Decodes a tokenized row's fields into a `WorkoutCSVRow`.
    /// Returns `.skip` with a short human-readable reason on failure.
    private static func decodeRow(_ fields: [String]) -> DecodeOutcome {
        guard fields.count >= 7 else {
            return .skip("expected 7 fields, got \(fields.count)")
        }

        let dateString = fields[0]
        let name = fields[1]
        let typeString = fields[2]
        let durationString = fields[3]
        let distanceString = fields[4]
        let notes = fields[5]
        let ratingString = fields[6]

        guard let date = parseDate(dateString) else {
            return .skip("invalid date '\(dateString)'")
        }
        guard let duration = Int(durationString.trimmingCharacters(in: .whitespaces)) else {
            return .skip("invalid duration_seconds '\(durationString)'")
        }
        guard let distance = Double(distanceString.trimmingCharacters(in: .whitespaces)) else {
            return .skip("invalid distance '\(distanceString)'")
        }
        guard let rating = Int(ratingString.trimmingCharacters(in: .whitespaces)) else {
            return .skip("invalid felt_rating '\(ratingString)'")
        }

        let type = ExerciseType(rawValue: typeString) ?? .other

        return .row(WorkoutCSVRow(
            date: date,
            name: name,
            type: type,
            durationSeconds: duration,
            distance: distance,
            notes: notes,
            feltRating: rating
        ))
    }

    /// Parses an ISO8601 date, falling back to the fractional-seconds variant.
    private static func parseDate(_ string: String) -> Date? {
        let trimmed = string.trimmingCharacters(in: .whitespaces)
        if let d = iso8601Formatter.date(from: trimmed) { return d }
        if let d = iso8601FractionalFormatter.date(from: trimmed) { return d }
        return nil
    }
}
