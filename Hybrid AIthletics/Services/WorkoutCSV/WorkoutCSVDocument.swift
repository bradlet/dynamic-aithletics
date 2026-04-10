//
//  WorkoutCSVDocument.swift
//  Hybrid AIthletics
//
//  FileDocument wrapper that carries a pre-encoded CSV string to
//  SwiftUI's `.fileExporter`. Import uses `.fileImporter` (URL-based)
//  and does not go through this type.
//

import SwiftUI
import UniformTypeIdentifiers

/// A SwiftUI `FileDocument` that writes a UTF-8 CSV string to disk.
struct WorkoutCSVDocument: FileDocument {
    /// Content types this document can read/write. We only handle CSV.
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }
    static var writableContentTypes: [UTType] { [.commaSeparatedText] }

    /// Raw CSV payload as a string.
    var text: String

    /// Designated initializer for export.
    init(text: String) {
        self.text = text
    }

    /// Reading initializer. Not currently used by the app (import goes
    /// through `.fileImporter`) but required by `FileDocument`.
    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents,
           let string = String(data: data, encoding: .utf8) {
            self.text = string
        } else {
            self.text = ""
        }
    }

    /// Serializes the CSV text as UTF-8.
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = Data(text.utf8)
        return FileWrapper(regularFileWithContents: data)
    }
}
