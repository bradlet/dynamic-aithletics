//
//  Dynamic_AIthleticsTests.swift
//  Dynamic AIthleticsTests
//
//  Unit tests for models, extensions, and business logic.
//

import Testing
import Foundation
import SwiftData
@testable import Dynamic_AIthletics

// MARK: - ExerciseType Tests

struct ExerciseTypeTests {

    @Test func allCasesHaveRawValues() {
        for type in ExerciseType.allCases {
            #expect(!type.rawValue.isEmpty, "ExerciseType \(type) should have a non-empty rawValue")
        }
    }

    @Test func allCasesHaveSystemImages() {
        for type in ExerciseType.allCases {
            #expect(!type.systemImage.isEmpty, "ExerciseType \(type) should have a systemImage")
        }
    }

    @Test func identifiableConformance() {
        let type = ExerciseType.run
        #expect(type.id == type.rawValue)
    }

    @Test func codableRoundTrip() throws {
        let original = ExerciseType.tempoRun
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ExerciseType.self, from: data)
        #expect(decoded == original)
    }
}

// MARK: - Date+Week Tests

struct DateWeekTests {

    /// Helper to create a date from components.
    private func makeDate(year: Int, month: Int, day: Int, hour: Int = 0, minute: Int = 0) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components)!
    }

    @Test func startOfDayNormalization() {
        let date = makeDate(year: 2026, month: 4, day: 4, hour: 14, minute: 30)
        let start = date.startOfDay
        let cal = Calendar.current
        #expect(cal.component(.hour, from: start) == 0)
        #expect(cal.component(.minute, from: start) == 0)
        #expect(cal.component(.second, from: start) == 0)
    }

    @Test func startOfWeekIsMonday() {
        // April 4, 2026 is a Saturday
        let saturday = makeDate(year: 2026, month: 4, day: 4)
        let startOfWeek = saturday.startOfWeek
        #expect(startOfWeek.weekdayName == "Monday")
    }

    @Test func daysInWeekReturnsSevenDays() {
        let date = makeDate(year: 2026, month: 4, day: 4)
        let days = date.daysInWeek()
        #expect(days.count == 7)
        #expect(days.first!.weekdayName == "Monday")
        // Last day should be Sunday
        #expect(days.last!.shortWeekdayName == "Sun")
    }

    @Test func daysInMonthCorrectCount() {
        // April 2026 has 30 days
        let april = makeDate(year: 2026, month: 4, day: 15)
        #expect(april.daysInMonth().count == 30)
        // February 2026 (non-leap) has 28 days
        let feb = makeDate(year: 2026, month: 2, day: 10)
        #expect(feb.daysInMonth().count == 28)
    }

    @Test func isSameDayComparison() {
        let morning = makeDate(year: 2026, month: 4, day: 4, hour: 8)
        let evening = makeDate(year: 2026, month: 4, day: 4, hour: 20)
        let nextDay = makeDate(year: 2026, month: 4, day: 5, hour: 8)
        #expect(morning.isSameDay(as: evening))
        #expect(!morning.isSameDay(as: nextDay))
    }

    @Test func isSameWeekComparison() {
        // Mon Mar 30 and Sun Apr 5 are in the same week (Mon-Sun)
        let monday = makeDate(year: 2026, month: 3, day: 30)
        let sunday = makeDate(year: 2026, month: 4, day: 5)
        #expect(monday.isSameWeek(as: sunday))
        // The next Monday is a different week
        let nextMonday = makeDate(year: 2026, month: 4, day: 6)
        #expect(!monday.isSameWeek(as: nextMonday))
    }

    @Test func isSameMonthComparison() {
        let early = makeDate(year: 2026, month: 4, day: 1)
        let late = makeDate(year: 2026, month: 4, day: 30)
        let nextMonth = makeDate(year: 2026, month: 5, day: 1)
        #expect(early.isSameMonth(as: late))
        #expect(!early.isSameMonth(as: nextMonth))
    }

    @Test func mondayBasedWeekdayIndex() {
        // Create a known Monday
        let monday = makeDate(year: 2026, month: 3, day: 30)
        #expect(monday.mondayBasedWeekdayIndex == 0)
        // Tuesday
        let tuesday = makeDate(year: 2026, month: 3, day: 31)
        #expect(tuesday.mondayBasedWeekdayIndex == 1)
        // Sunday
        let sunday = makeDate(year: 2026, month: 4, day: 5)
        #expect(sunday.mondayBasedWeekdayIndex == 6)
    }

    @Test func startOfYearIsJanuaryFirst() {
        let date = makeDate(year: 2026, month: 7, day: 15)
        let startOfYear = date.startOfYear
        let cal = Calendar.current
        #expect(cal.component(.month, from: startOfYear) == 1)
        #expect(cal.component(.day, from: startOfYear) == 1)
        #expect(cal.component(.year, from: startOfYear) == 2026)
    }
}

// MARK: - Double+Distance Tests

struct DoubleDistanceTests {

    @Test func formattedDistanceMiles() {
        let distance = 5.25
        let formatted = distance.formattedDistance(metric: false)
        #expect(formatted == "5.2 mi")
    }

    @Test func formattedDistanceKilometers() {
        let distance = 5.0 // 5 miles
        let formatted = distance.formattedDistance(metric: true)
        // 5 * 1.60934 = 8.0467
        #expect(formatted == "8.0 km")
    }

    @Test func toDisplayDistanceMiles() {
        let miles = 3.5
        #expect(miles.toDisplayDistance(metric: false) == 3.5)
    }

    @Test func toDisplayDistanceMetric() {
        let miles = 1.0
        let km = miles.toDisplayDistance(metric: true)
        // Should be approximately 1.60934
        #expect(km > 1.609 && km < 1.610)
    }

    @Test func formattedDurationMinutesOnly() {
        let formatted = Double(2700).formattedDuration // 45 minutes
        #expect(formatted == "45:00")
    }

    @Test func formattedDurationWithHours() {
        let formatted = Double(5400).formattedDuration // 1h 30m
        #expect(formatted == "1:30:00")
    }

    @Test func formattedDurationWithSeconds() {
        let formatted = Double(125).formattedDuration // 2m 5s
        #expect(formatted == "2:05")
    }

    @Test func intFormattedDuration() {
        let formatted = 3661.formattedDuration // 1h 1m 1s
        #expect(formatted == "1:01:01")
    }
}

// MARK: - Exercise Model Tests

struct ExerciseModelTests {

    /// Creates a fresh in-memory container for each test.
    private func makeContext() throws -> ModelContext {
        let container = ModelContainerFactory.makePreviewContainer()
        return ModelContext(container)
    }

    @Test func exerciseInitNormalizesDate() {
        let date = Calendar.current.date(
            bySettingHour: 15, minute: 30, second: 45,
            of: Date()
        )!
        let exercise = Exercise(
            name: "Test Run",
            type: .run,
            durationSeconds: 1800,
            distanceMiles: 3.0,
            scheduledDate: date
        )
        let cal = Calendar.current
        #expect(cal.component(.hour, from: exercise.scheduledDate) == 0)
        #expect(cal.component(.minute, from: exercise.scheduledDate) == 0)
    }

    @Test func exerciseDefaultValues() {
        let exercise = Exercise(
            name: "Morning 5K",
            type: .easyRun,
            durationSeconds: 1500,
            distanceMiles: 3.1,
            scheduledDate: Date()
        )
        #expect(exercise.name == "Morning 5K")
        #expect(exercise.type == .easyRun)
        #expect(exercise.durationSeconds == 1500)
        #expect(exercise.distanceMiles == 3.1)
        #expect(exercise.notes == "")
        #expect(exercise.workouts.isEmpty)
    }

    @Test func exercisePersistence() throws {
        let context = try makeContext()
        let exercise = Exercise(
            name: "Tempo Run",
            type: .tempoRun,
            durationSeconds: 2400,
            distanceMiles: 5.0,
            scheduledDate: Date()
        )
        context.insert(exercise)
        try context.save()

        let descriptor = FetchDescriptor<Exercise>()
        let fetched = try context.fetch(descriptor)
        #expect(fetched.count == 1)
        #expect(fetched.first?.name == "Tempo Run")
        #expect(fetched.first?.type == .tempoRun)
    }
}

// MARK: - Workout Model Tests

struct WorkoutModelTests {

    private func makeContext() throws -> ModelContext {
        let container = ModelContainerFactory.makePreviewContainer()
        return ModelContext(container)
    }

    @Test func workoutDraftFromExercise() {
        let exercise = Exercise(
            name: "5K Run",
            type: .run,
            durationSeconds: 1500,
            distanceMiles: 3.1,
            notes: "Easy pace",
            scheduledDate: Date()
        )
        let workout = Workout.draft(from: exercise)
        #expect(workout.name == "5K Run")
        #expect(workout.type == .run)
        #expect(workout.durationSeconds == 1500)
        #expect(workout.distanceMiles == 3.1)
        #expect(workout.notes == "") // Notes NOT copied from exercise
        #expect(workout.sourceExercise === exercise)
    }

    @Test func workoutPersistence() throws {
        let context = try makeContext()
        let workout = Workout(
            name: "Morning Run",
            type: .run,
            durationSeconds: 1800,
            distanceMiles: 3.0,
            notes: "Felt great",
            date: Date()
        )
        context.insert(workout)
        try context.save()

        let descriptor = FetchDescriptor<Workout>()
        let fetched = try context.fetch(descriptor)
        #expect(fetched.count == 1)
        #expect(fetched.first?.name == "Morning Run")
        #expect(fetched.first?.notes == "Felt great")
    }

    @Test func workoutExerciseRelationship() throws {
        let context = try makeContext()
        let exercise = Exercise(
            name: "Tempo Run",
            type: .tempoRun,
            durationSeconds: 2400,
            distanceMiles: 5.0,
            scheduledDate: Date()
        )
        context.insert(exercise)

        let workout = Workout.draft(from: exercise)
        context.insert(workout)
        try context.save()

        #expect(workout.sourceExercise?.id == exercise.id)
        #expect(exercise.workouts.count == 1)
    }
}

// MARK: - AppConfiguration Tests

struct AppConfigurationTests {

    private func makeContext() throws -> ModelContext {
        let container = ModelContainerFactory.makePreviewContainer()
        return ModelContext(container)
    }

    @Test func currentCreatesDefaultIfMissing() throws {
        let context = try makeContext()
        let config = AppConfiguration.current(in: context)
        #expect(config.useMetricUnits == false)
    }

    @Test func currentReturnsSameInstance() throws {
        let context = try makeContext()
        let config1 = AppConfiguration.current(in: context)
        config1.useMetricUnits = true
        let config2 = AppConfiguration.current(in: context)
        #expect(config2.useMetricUnits == true)
    }
}

// MARK: - ExerciseDragItem Tests

struct ExerciseDragItemTests {

    @Test func codableRoundTrip() throws {
        let id = UUID()
        let item = ExerciseDragItem(exerciseID: id)
        let data = try JSONEncoder().encode(item)
        let decoded = try JSONDecoder().decode(ExerciseDragItem.self, from: data)
        #expect(decoded.exerciseID == id)
    }
}

// MARK: - Exercise Repeat Tests

struct ExerciseRepeatTests {

    /// Helper to create a date from components.
    private func makeDate(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return Calendar.current.date(from: components)!
    }

    private func makeContext() throws -> ModelContext {
        let container = ModelContainerFactory.makePreviewContainer()
        return ModelContext(container)
    }

    @Test func isRepeatingDefaultsFalse() {
        let exercise = Exercise(
            name: "Run", type: .run,
            durationSeconds: 1800, distanceMiles: 3.0,
            scheduledDate: Date()
        )
        #expect(exercise.isRepeating == false)
    }

    @Test func isRepeatingCanBeSetTrue() {
        let exercise = Exercise(
            name: "Run", type: .run,
            durationSeconds: 1800, distanceMiles: 3.0,
            scheduledDate: Date(), isRepeating: true
        )
        #expect(exercise.isRepeating == true)
    }

    @Test func repeatingExerciseMatchesDayOfWeek() {
        // March 30, 2026 is a Monday
        let monday = makeDate(year: 2026, month: 3, day: 30)
        let exercise = Exercise(
            name: "Monday Run", type: .run,
            durationSeconds: 1800, distanceMiles: 3.0,
            scheduledDate: monday, isRepeating: true
        )
        #expect(exercise.scheduledDate.mondayBasedWeekdayIndex == 0)
        #expect(exercise.isRepeating == true)
    }

    @Test func repeatingExercisePersistence() throws {
        let context = try makeContext()
        let exercise = Exercise(
            name: "Weekly Tempo", type: .tempoRun,
            durationSeconds: 2400, distanceMiles: 5.0,
            scheduledDate: Date(), isRepeating: true
        )
        context.insert(exercise)
        try context.save()

        let descriptor = FetchDescriptor<Exercise>()
        let fetched = try context.fetch(descriptor)
        #expect(fetched.count == 1)
        #expect(fetched.first?.isRepeating == true)
    }

    @Test func nonRepeatingExercisePersistence() throws {
        let context = try makeContext()
        let exercise = Exercise(
            name: "One-off Run", type: .run,
            durationSeconds: 1800, distanceMiles: 3.0,
            scheduledDate: Date(), isRepeating: false
        )
        context.insert(exercise)
        try context.save()

        let descriptor = FetchDescriptor<Exercise>()
        let fetched = try context.fetch(descriptor)
        #expect(fetched.first?.isRepeating == false)
    }
}
