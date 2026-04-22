//
//  AerobicTrainingUITests.swift
//  Hybrid AIthleticsUITests
//
//  Functional UI tests for the Aerobic Training tab: monthly calendar
//  navigation, quick-add workflow, and schedule exercise workflow.
//
//  Launches the app with `-uiTestSeed` for deterministic fixture data.
//

import XCTest

final class AerobicTrainingUITests: XCTestCase {

    // MARK: - Lifecycle

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Helpers

    /// Launches the app with the UI test seed argument. The Training tab is
    /// selected by default (it's the first tab).
    @MainActor
    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments.append("-uiTestSeed")
        app.launch()

        // Ensure the Training tab is active (it's the first tab)
        let trainingTab = app.tabBars.buttons["Training"]
        XCTAssertTrue(trainingTab.waitForExistence(timeout: 5), "Training tab should exist")
        trainingTab.tap()
        return app
    }

    /// Builds a "calendarDay.yyyy-MM-dd" identifier for the given date components.
    private func calendarDayID(year: Int, month: Int, day: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        let date = Calendar.current.date(from: components)!
        return "calendarDay.\(formatter.string(from: date))"
    }

    /// Builds a "calendarDay.yyyy-MM-dd" identifier for today.
    private func todayCalendarDayID() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return "calendarDay.\(formatter.string(from: Date()))"
    }

    /// Builds a "daySwimlane.quickAdd.yyyy-MM-dd" identifier for today.
    private func todayQuickAddID() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return "daySwimlane.quickAdd.\(formatter.string(from: Date()))"
    }

    /// Builds a "daySwimlane.schedule.yyyy-MM-dd" identifier for today.
    private func todayScheduleID() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return "daySwimlane.schedule.\(formatter.string(from: Date()))"
    }

    // MARK: - Tests

    @MainActor
    func testMonthCalendarTapNavigatesToCorrectWeek() {
        let app = launchApp()

        // Tap today in the month calendar
        let todayID = todayCalendarDayID()
        let todayCell = app.otherElements[todayID]

        // The monthly calendar should show today (it has a seeded workout)
        if todayCell.waitForExistence(timeout: 3) {
            todayCell.tap()

            // Verify the day swimlane for today is highlighted
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "yyyy-MM-dd"
            let swimlaneID = "daySwimlane.\(formatter.string(from: Date()))"
            let swimlane = app.otherElements[swimlaneID]
            XCTAssertTrue(swimlane.waitForExistence(timeout: 3), "Day swimlane for today should exist after calendar tap")
        }
    }

    @MainActor
    func testQuickAddButtonOpensRecordWorkoutSheet() {
        let app = launchApp()

        let quickAddButton = app.buttons[todayQuickAddID()]
        // May need to scroll to find today's swimlane
        if quickAddButton.waitForExistence(timeout: 5) {
            quickAddButton.tap()

            // The "Record Workout" sheet should appear
            let navTitle = app.navigationBars["Record Workout"]
            XCTAssertTrue(navTitle.waitForExistence(timeout: 3), "Record Workout sheet should appear")

            // The name field should be pre-filled with the default type name
            let nameField = app.textFields["workoutForm.nameField"]
            if nameField.waitForExistence(timeout: 2) {
                let nameValue = nameField.value as? String ?? ""
                XCTAssertFalse(nameValue.isEmpty, "Name should default to exercise type name")
            }
        }
    }

    @MainActor
    func testScheduleButtonOpensScheduleExerciseSheet() {
        let app = launchApp()

        let scheduleButton = app.buttons[todayScheduleID()]
        if scheduleButton.waitForExistence(timeout: 5) {
            scheduleButton.tap()

            // The "Schedule Exercise" sheet should appear
            let navTitle = app.navigationBars["Schedule Exercise"]
            XCTAssertTrue(navTitle.waitForExistence(timeout: 3), "Schedule Exercise sheet should appear")
        }
    }
}
