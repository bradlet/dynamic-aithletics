//
//  GoogleSheetsAPI.swift
//  Hybrid AIthletics
//
//  Thin abstraction over Google's OAuth + Sheets REST surface used by
//  `GoogleSheetsSyncCoordinator`. Two implementations:
//    - `LiveGoogleSheetsAPI` — production; uses `GoogleSignIn-iOS` for OAuth
//      and `URLSession` for Sheets v4 REST calls. Gated behind
//      `#if canImport(GoogleSignIn)` so the app compiles when the SPM
//      dependency is not yet installed (mirrors the MLX-Swift pattern).
//    - `StubGoogleSheetsAPI` — in-memory; never touches the network. Used
//      in previews, unit tests, and as the default `@Environment` value.
//

import Foundation
#if canImport(GoogleSignIn)
import GoogleSignIn
import UIKit
#endif

/// OAuth + Sheets REST operations used by the sync coordinator.
/// All methods run on the main actor because OAuth presents UIKit view
/// controllers and the coordinator (also `@MainActor`) drives this layer.
@MainActor
protocol GoogleSheetsAPI: AnyObject {
    /// Whether the device currently holds a valid signed-in user with the
    /// Sheets scope. Synchronous so the coordinator can compute UI state.
    var isAuthorized: Bool { get }

    /// Attempts to silently restore a previous sign-in from Keychain.
    /// Returns `true` on success. Never presents UI.
    func restoreAuthorizationIfPossible() async -> Bool

    /// Presents the OAuth flow if needed and ensures the Sheets scope is
    /// granted. May present UI. Throws on cancellation or denied scope.
    /// Prefers a valid cached session and only presents UI when none can be
    /// silently refreshed — used by the first-time enable flow.
    func authorize() async throws

    /// Forces a fresh interactive sign-in, discarding any cached session
    /// first. Used by the "Sign in to resume" reconnect flow: a silent
    /// refresh can't detect a server-side revoke while the local access token
    /// is still within its ~1h lifetime, so reconnect must always present the
    /// Google sign-in UI to obtain a genuinely fresh grant. Throws on
    /// cancellation or denied scope.
    func reauthorizeInteractively() async throws

    /// Forgets the current user, clearing tokens from Keychain.
    func signOut()

    /// Creates a new Google Sheets spreadsheet with the given title in the
    /// signed-in user's Drive and returns its ID.
    func createSpreadsheet(title: String) async throws -> String

    /// Clears the first sheet of the spreadsheet and writes `rows`
    /// starting at A1. The first row should be the header.
    func overwriteSheet(spreadsheetId: String, rows: [[String]]) async throws
}

// MARK: - Live implementation

#if canImport(GoogleSignIn)

/// Production implementation backed by `GoogleSignIn-iOS` for OAuth and
/// `URLSession` for the Sheets v4 REST endpoints.
@MainActor
final class LiveGoogleSheetsAPI: GoogleSheetsAPI {

    /// Per-file Drive scope. Grants the app read/write/delete access only
    /// to files it created (via `createSpreadsheet`) or that the user
    /// explicitly opens with the app — never the rest of the user's Drive.
    /// Non-sensitive, so no Google verification is required.
    static let scope = "https://www.googleapis.com/auth/drive.file"

    var isAuthorized: Bool {
        guard let user = GIDSignIn.sharedInstance.currentUser else { return false }
        return user.grantedScopes?.contains(Self.scope) == true
    }

    func restoreAuthorizationIfPossible() async -> Bool {
        guard GIDSignIn.sharedInstance.hasPreviousSignIn() else { return false }
        do {
            let user = try await GIDSignIn.sharedInstance.restorePreviousSignIn()
            return user.grantedScopes?.contains(Self.scope) == true
        } catch {
            return false
        }
    }

    func authorize() async throws {
        // Silent path: reuse an existing or restorable session, but only if
        // its refresh token still produces a fresh access token. When the
        // refresh token has expired or been revoked (e.g. the 7-day
        // Testing-mode timer), `refreshTokensIfNeeded()` throws — in which
        // case we must fall through to a fresh interactive sign-in rather
        // than dead-ending. (Reusing the stale `currentUser` here was the
        // original reconnect bug: scope is still granted, so re-consent was
        // skipped and the throw left no recovery path.)
        var cached = GIDSignIn.sharedInstance.currentUser
        if cached == nil, GIDSignIn.sharedInstance.hasPreviousSignIn() {
            cached = try? await GIDSignIn.sharedInstance.restorePreviousSignIn()
        }
        if let user = cached, (try? await user.refreshTokensIfNeeded()) != nil {
            try await ensureScope(on: user)
            return
        }

        // No session, or the cached session's token can no longer refresh.
        try await interactiveSignIn()
    }

    func reauthorizeInteractively() async throws {
        // Always re-present sign-in. Unlike `authorize()`, this never trusts a
        // cached session: a revoked grant can still look valid locally until
        // the access token expires, so silently reusing it would loop the user
        // back to `.needsAuth` without ever fixing the connection.
        try await interactiveSignIn()
    }

    /// Discards any cached session and presents a fresh Google sign-in,
    /// re-granting the Sheets scope and priming an access token. Shared by
    /// `authorize()`'s fallback and `reauthorizeInteractively()`.
    private func interactiveSignIn() async throws {
        GIDSignIn.sharedInstance.signOut()
        guard let presenter = Self.topViewController() else {
            throw GoogleSheetsSyncError.noPresenterAvailable
        }
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenter)
        try await ensureScope(on: result.user)
        try await result.user.refreshTokensIfNeeded()
    }

    /// Requests the Sheets scope interactively if the user has not yet
    /// granted it. No-op when the scope is already present.
    private func ensureScope(on user: GIDGoogleUser) async throws {
        guard user.grantedScopes?.contains(Self.scope) != true else { return }
        guard let presenter = Self.topViewController() else {
            throw GoogleSheetsSyncError.noPresenterAvailable
        }
        _ = try await user.addScopes([Self.scope], presenting: presenter)
    }

    func signOut() {
        GIDSignIn.sharedInstance.signOut()
    }

    func createSpreadsheet(title: String) async throws -> String {
        let token = try await accessToken()
        let url = URL(string: "https://sheets.googleapis.com/v4/spreadsheets")!
        let body: [String: Any] = ["properties": ["title": title]]
        let data = try JSONSerialization.data(withJSONObject: body)
        let response = try await sendJSON(method: "POST", url: url, token: token, body: data)
        guard let json = try JSONSerialization.jsonObject(with: response) as? [String: Any],
              let id = json["spreadsheetId"] as? String else {
            throw GoogleSheetsSyncError.invalidResponse("missing spreadsheetId")
        }
        return id
    }

    func overwriteSheet(spreadsheetId: String, rows: [[String]]) async throws {
        let token = try await accessToken()
        let base = "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetId)"
        // Clear the entire default sheet by name. "Sheet1" is the default
        // tab name Google Sheets gives a spreadsheet created via
        // `createSpreadsheet`. Using the sheet name instead of an A1 range
        // covers any number of columns/rows the user may have manually
        // expanded the sheet to.
        let clearURL = URL(string: "\(base)/values/Sheet1:clear")!
        _ = try await sendJSON(method: "POST", url: clearURL, token: token, body: Data("{}".utf8))
        // Write fresh rows starting at A1, RAW so dates/numbers stay verbatim.
        let writeBody: [String: Any] = ["range": "Sheet1!A1", "values": rows]
        let writeData = try JSONSerialization.data(withJSONObject: writeBody)
        let writeURL = URL(string: "\(base)/values/Sheet1!A1?valueInputOption=RAW")!
        _ = try await sendJSON(method: "PUT", url: writeURL, token: token, body: writeData)
    }

    // MARK: - Helpers

    private func accessToken() async throws -> String {
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            throw GoogleSheetsSyncError.notAuthorized
        }
        do {
            try await user.refreshTokensIfNeeded()
        } catch {
            // The refresh token has expired or been revoked (e.g. the 7-day
            // Testing-mode timer). Surface this as `.notAuthorized` so the
            // coordinator can route it to `.needsAuth` and prompt re-sign-in,
            // rather than showing a generic "retry" that would just fail again.
            throw GoogleSheetsSyncError.notAuthorized
        }
        return user.accessToken.tokenString
    }

    private func sendJSON(method: String, url: URL, token: String, body: Data) async throws -> Data {
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = body
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else {
            throw GoogleSheetsSyncError.invalidResponse("not an HTTP response")
        }
        guard (200...299).contains(http.statusCode) else {
            let bodyString = String(data: data, encoding: .utf8) ?? "<binary>"
            throw GoogleSheetsSyncError.httpError(status: http.statusCode, body: bodyString)
        }
        return data
    }

    /// Walks the active scene's view controller stack to find the top-most
    /// presenter for OAuth UI. Returns `nil` only in unusual lifecycle
    /// states (e.g. before the first window appears).
    private static func topViewController() -> UIViewController? {
        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            guard let root = windowScene.keyWindow?.rootViewController else { continue }
            var top = root
            while let presented = top.presentedViewController { top = presented }
            return top
        }
        return nil
    }
}

#else

/// Compile-time placeholder when `GoogleSignIn-iOS` is not installed.
/// Every operation throws `.notImplemented` so the app builds and runs
/// (with sync disabled) before the SPM dependency is wired up.
@MainActor
final class LiveGoogleSheetsAPI: GoogleSheetsAPI {
    var isAuthorized: Bool { false }
    func restoreAuthorizationIfPossible() async -> Bool { false }
    func authorize() async throws { throw GoogleSheetsSyncError.notImplemented }
    func reauthorizeInteractively() async throws { throw GoogleSheetsSyncError.notImplemented }
    func signOut() {}
    func createSpreadsheet(title: String) async throws -> String { throw GoogleSheetsSyncError.notImplemented }
    func overwriteSheet(spreadsheetId: String, rows: [[String]]) async throws { throw GoogleSheetsSyncError.notImplemented }
}

#endif

// MARK: - Stub (previews + tests)

/// In-memory stub that records calls without touching the network. Used by
/// SwiftUI previews, unit tests, and as the default `@Environment` value
/// so previews never trigger real OAuth.
@MainActor
final class StubGoogleSheetsAPI: GoogleSheetsAPI {
    /// Toggle between "user is signed in" and "needs auth" states for tests.
    var isAuthorized: Bool

    /// Most recent rows written via `overwriteSheet`, for test assertions.
    private(set) var lastWrittenRows: [[String]]?
    /// Most recent spreadsheet ID written via `overwriteSheet`.
    private(set) var lastSpreadsheetID: String?
    /// IDs returned from `createSpreadsheet`, in the order they were created.
    private(set) var createdSpreadsheetIDs: [String] = []
    /// Total `overwriteSheet` calls. Used to assert debounce behavior.
    private(set) var overwriteCount: Int = 0
    /// When non-nil, `overwriteSheet` throws this error on the next call.
    var nextOverwriteError: Error?

    init(isAuthorized: Bool = true) {
        self.isAuthorized = isAuthorized
    }

    func restoreAuthorizationIfPossible() async -> Bool { isAuthorized }

    func authorize() async throws { isAuthorized = true }

    /// Number of `reauthorizeInteractively()` calls, so tests can assert the
    /// reconnect path forces a fresh sign-in instead of reusing a cached one.
    private(set) var reauthorizeInteractivelyCount = 0

    func reauthorizeInteractively() async throws {
        reauthorizeInteractivelyCount += 1
        isAuthorized = true
    }

    func signOut() {
        isAuthorized = false
        lastWrittenRows = nil
        lastSpreadsheetID = nil
    }

    func createSpreadsheet(title: String) async throws -> String {
        let id = "stub-sheet-\(createdSpreadsheetIDs.count + 1)"
        createdSpreadsheetIDs.append(id)
        return id
    }

    func overwriteSheet(spreadsheetId: String, rows: [[String]]) async throws {
        if let error = nextOverwriteError {
            nextOverwriteError = nil
            throw error
        }
        // Mirror real URLSession behavior: bail with CancellationError if
        // the calling task has been cancelled. Catches regressions where
        // the coordinator accidentally cancels its own in-flight sync.
        try Task.checkCancellation()
        overwriteCount += 1
        lastWrittenRows = rows
        lastSpreadsheetID = spreadsheetId
    }
}
