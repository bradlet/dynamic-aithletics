//
//  GoogleSheetsSyncError.swift
//  Hybrid AIthletics
//
//  Errors surfaced by the Google Sheets sync stack — the API layer
//  (`GoogleSheetsAPI`) and the orchestrating coordinator
//  (`GoogleSheetsSyncCoordinator`).
//

import Foundation

/// Errors produced by the Google Sheets sync feature. `LocalizedError`
/// messages are surfaced verbatim in the History tab's "sync failed"
/// menu indicator.
enum GoogleSheetsSyncError: Error, LocalizedError {
    /// The `GoogleSignIn` SPM dependency has not been added to the target,
    /// so the live API is a no-op throw stub. README setup step missing.
    case notImplemented

    /// `GoogleSheetsSyncCoordinator.attach(modelContainer:)` was not called
    /// before an enable/sync attempt. Programmer error.
    case notAttached

    /// The user is not signed in (or sign-in was cancelled) but a write was
    /// attempted. The coordinator surfaces this as `.needsAuth` status, not
    /// as a thrown error to the caller.
    case notAuthorized

    /// No `UIViewController` was available to present the OAuth sign-in UI.
    /// Should not happen in normal app lifecycle.
    case noPresenterAvailable

    /// The Sheets REST endpoint returned a non-2xx status.
    case httpError(status: Int, body: String)

    /// The Sheets REST endpoint returned a successful status but the body
    /// could not be decoded as expected.
    case invalidResponse(String)

    var errorDescription: String? {
        switch self {
        case .notImplemented:
            return "Google Sheets sync is not available — the GoogleSignIn package is not installed."
        case .notAttached:
            return "Google Sheets sync is not ready yet."
        case .notAuthorized:
            return "Sign in with Google to sync."
        case .noPresenterAvailable:
            return "Could not present sign-in screen."
        case .httpError(let status, let body):
            return "Google Sheets API error \(status): \(body)"
        case .invalidResponse(let detail):
            return "Unexpected response from Google Sheets: \(detail)"
        }
    }
}
