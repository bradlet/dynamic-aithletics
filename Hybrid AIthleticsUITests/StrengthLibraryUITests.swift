//
//  StrengthLibraryUITests.swift
//  Hybrid AIthleticsUITests
//
//  Functional UI tests for the user-created exercise library flow: creating
//  a custom exercise through the library sheet's '+' form and removing it
//  again with swipe-to-delete.
//
//  Launches the app with `-uiTestSeed` for a deterministic in-memory store,
//  so the user library always starts empty.
//

import XCTest

final class StrengthLibraryUITests: XCTestCase {

    // MARK: - Lifecycle

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Helpers

    /// Launches the app with the UI test seed argument and switches to the
    /// Strength tab.
    @MainActor
    private func launchOnStrengthTab() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments.append("-uiTestSeed")
        app.launch()

        let strengthTab = app.tabBars.buttons["Strength"]
        XCTAssertTrue(strengthTab.waitForExistence(timeout: 5), "Strength tab should exist")
        strengthTab.tap()
        return app
    }

    // MARK: - Tests

    @MainActor
    func testCreateAndDeleteUserLibraryExercise() {
        let app = launchOnStrengthTab()

        // Open the exercise library sheet.
        let libraryButton = app.buttons["strength.libraryButton"]
        XCTAssertTrue(libraryButton.waitForExistence(timeout: 5), "Library button should exist")
        libraryButton.tap()

        // Open the creation form via the '+' button.
        let createButton = app.buttons["exerciseLibrary.create"]
        XCTAssertTrue(createButton.waitForExistence(timeout: 5), "Create button should exist")
        createButton.tap()

        // Fill in the name and save (all other fields keep their defaults).
        let nameField = app.textFields["userExerciseForm.name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5), "Name field should exist")
        nameField.tap()
        nameField.typeText("UITest Custom Move")

        let saveButton = app.buttons["userExerciseForm.save"]
        XCTAssertTrue(saveButton.isEnabled, "Save should enable once a name is entered")
        saveButton.tap()

        // The new entry lands in the "Other" section at the bottom of the
        // long list, so filter with search to bring it on screen.
        let searchField = app.searchFields.firstMatch
        if !searchField.waitForExistence(timeout: 2) {
            app.swipeDown()
        }
        XCTAssertTrue(searchField.waitForExistence(timeout: 5), "Search field should exist")
        searchField.tap()
        searchField.typeText("UITest")

        // The new entry appears in the reloaded, filtered library list.
        let newRow = app.staticTexts["UITest Custom Move"]
        XCTAssertTrue(newRow.waitForExistence(timeout: 5), "Created exercise should appear in the library")

        // Swipe the row and delete it.
        newRow.swipeLeft()
        let deleteButton = app.buttons["Delete"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 5), "Swipe should reveal a Delete action")
        deleteButton.tap()

        // The entry is gone after the list reloads.
        XCTAssertFalse(
            app.staticTexts["UITest Custom Move"].waitForExistence(timeout: 2),
            "Deleted exercise should no longer appear in the library"
        )
    }
}
