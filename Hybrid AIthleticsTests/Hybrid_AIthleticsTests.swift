//
//  Hybrid_AIthleticsTests.swift
//  Hybrid AIthleticsTests
//
//  Unit tests for models, extensions, and business logic.
//

import Testing
import Foundation
import SwiftData
import SwiftUI
import AICoachCore
@testable import Hybrid_AIthletics

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

    @Test func startOfWeekIsSunday() {
        // April 4, 2026 is a Saturday
        let saturday = makeDate(year: 2026, month: 4, day: 4)
        let startOfWeek = saturday.startOfWeek
        #expect(startOfWeek.weekdayName == "Sunday")
    }

    @Test func startOfWeekFirstWeekdaySundayMatchesDefault() {
        // Wednesday April 8, 2026
        let wednesday = makeDate(year: 2026, month: 4, day: 8)
        #expect(wednesday.startOfWeek(firstWeekday: 1) == wednesday.startOfWeek)
    }

    @Test func startOfWeekFirstWeekdayMondayReturnsMonday() {
        // Wednesday April 8, 2026 -> Monday April 6, 2026
        let wednesday = makeDate(year: 2026, month: 4, day: 8)
        let start = wednesday.startOfWeek(firstWeekday: 2)
        #expect(start == makeDate(year: 2026, month: 4, day: 6))
        #expect(start.weekdayName == "Monday")
    }

    @Test func startOfWeekMondayStartPutsSundayInPreviousWeek() {
        // Sunday April 5, 2026 belongs to the Monday-start week of Mar 30.
        let sunday = makeDate(year: 2026, month: 4, day: 5)
        let start = sunday.startOfWeek(firstWeekday: 2)
        #expect(start == makeDate(year: 2026, month: 3, day: 30))
    }

    @Test func daysInWeekReturnsSevenDays() {
        let date = makeDate(year: 2026, month: 4, day: 4)
        let days = date.daysInWeek()
        #expect(days.count == 7)
        #expect(days.first!.weekdayName == "Sunday")
        // Last day should be Saturday
        #expect(days.last!.shortWeekdayName == "Sat")
    }

    @Test func daysInWeekFirstWeekdaySundayMatchesDefault() {
        let date = makeDate(year: 2026, month: 4, day: 8)
        #expect(date.daysInWeek(firstWeekday: 1) == date.daysInWeek())
    }

    @Test func daysInWeekFirstWeekdayMondayOrdersMondayFirst() {
        // Wednesday April 8, 2026 -> Mon Apr 6 through Sun Apr 12
        let wednesday = makeDate(year: 2026, month: 4, day: 8)
        let days = wednesday.daysInWeek(firstWeekday: 2)
        #expect(days.count == 7)
        #expect(days.first == makeDate(year: 2026, month: 4, day: 6))
        #expect(days.first!.weekdayName == "Monday")
        #expect(days.last == makeDate(year: 2026, month: 4, day: 12))
        #expect(days.last!.weekdayName == "Sunday")
    }

    @Test func daysInWeekFirstWeekdaySaturdayOrdersSaturdayFirst() {
        // Wednesday April 8, 2026 -> Sat Apr 4 through Fri Apr 10
        let wednesday = makeDate(year: 2026, month: 4, day: 8)
        let days = wednesday.daysInWeek(firstWeekday: 7)
        #expect(days.first == makeDate(year: 2026, month: 4, day: 4))
        #expect(days.last == makeDate(year: 2026, month: 4, day: 10))
    }

    @Test func endOfWeekFirstWeekdaySundayMatchesDefault() {
        let date = makeDate(year: 2026, month: 4, day: 8)
        #expect(date.endOfWeek(firstWeekday: 1) == date.endOfWeek)
    }

    @Test func endOfWeekFirstWeekdayMondayEndsOnSunday() {
        // Wednesday April 8, 2026 -> Sunday April 12, 23:59:59
        let wednesday = makeDate(year: 2026, month: 4, day: 8)
        let end = wednesday.endOfWeek(firstWeekday: 2)
        let cal = Calendar.current
        #expect(end.weekdayName == "Sunday")
        #expect(cal.component(.day, from: end) == 12)
        #expect(cal.component(.hour, from: end) == 23)
        #expect(cal.component(.minute, from: end) == 59)
        #expect(cal.component(.second, from: end) == 59)
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
        // Sun Mar 29 and Sat Apr 4 are in the same week (Sun-Sat)
        let sunday = makeDate(year: 2026, month: 3, day: 29)
        let saturday = makeDate(year: 2026, month: 4, day: 4)
        #expect(sunday.isSameWeek(as: saturday))
        // The next Sunday is a different week
        let nextSunday = makeDate(year: 2026, month: 4, day: 5)
        #expect(!sunday.isSameWeek(as: nextSunday))
    }

    @Test func isSameMonthComparison() {
        let early = makeDate(year: 2026, month: 4, day: 1)
        let late = makeDate(year: 2026, month: 4, day: 30)
        let nextMonth = makeDate(year: 2026, month: 5, day: 1)
        #expect(early.isSameMonth(as: late))
        #expect(!early.isSameMonth(as: nextMonth))
    }

    @Test func weekdayIndex() {
        // Create a known Sunday
        let sunday = makeDate(year: 2026, month: 4, day: 5)
        #expect(sunday.weekdayIndex == 0)
        // Monday
        let monday = makeDate(year: 2026, month: 3, day: 30)
        #expect(monday.weekdayIndex == 1)
        // Saturday
        let saturday = makeDate(year: 2026, month: 4, day: 4)
        #expect(saturday.weekdayIndex == 6)
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

// MARK: - WeekMileage Tests

struct WeekMileageTests {

    /// A planned-only exercise (no recorded workout).
    private func makePlanned(miles: Double, counts: Bool = true) -> Exercise {
        Exercise(
            name: "planned",
            type: .run,
            durationSeconds: 1800,
            distanceMiles: miles,
            date: Date(),
            countsTowardMileage: counts
        )
    }

    /// A completed exercise whose recorded distance may differ from the plan.
    private func makeCompleted(plannedMiles: Double, recordedMiles: Double, counts: Bool = true) -> Exercise {
        Exercise(
            name: "completed",
            type: .run,
            durationSeconds: 1800,
            distanceMiles: plannedMiles,
            date: Date(),
            countsTowardMileage: counts,
            workout: Workout(durationSeconds: 1800, distanceMiles: recordedMiles)
        )
    }

    @Test func plannedEmptyInputIsZero() {
        #expect(WeekMileage.planned([]) == 0)
        #expect(WeekMileage.planned([], includeNonTracked: true) == 0)
    }

    @Test func plannedSumsScheduledDistances() {
        let exercises = [makePlanned(miles: 3.0), makePlanned(miles: 5.0)]
        #expect(WeekMileage.planned(exercises) == 8.0)
    }

    @Test func plannedExcludesOptedOutByDefault() {
        let exercises = [makePlanned(miles: 3.0), makePlanned(miles: 2.0, counts: false)]
        #expect(WeekMileage.planned(exercises) == 3.0)
    }

    @Test func plannedIncludesOptedOutWhenNonTrackedRequested() {
        let exercises = [makePlanned(miles: 3.0), makePlanned(miles: 2.0, counts: false)]
        #expect(WeekMileage.planned(exercises, includeNonTracked: true) == 5.0)
    }

    @Test func completedOnlySumsCompletedExercises() {
        let exercises = [
            makePlanned(miles: 10.0),
            makeCompleted(plannedMiles: 5.0, recordedMiles: 4.5)
        ]
        #expect(WeekMileage.completed(exercises) == 4.5)
    }

    @Test func completedUsesRecordedNotPlannedDistance() {
        let exercises = [makeCompleted(plannedMiles: 5.0, recordedMiles: 6.2)]
        #expect(WeekMileage.completed(exercises) == 6.2)
    }

    @Test func completedExcludesOptedOutByDefault() {
        let exercises = [
            makeCompleted(plannedMiles: 5.0, recordedMiles: 5.0),
            makeCompleted(plannedMiles: 2.0, recordedMiles: 2.0, counts: false)
        ]
        #expect(WeekMileage.completed(exercises) == 5.0)
    }

    @Test func completedIncludesOptedOutWhenNonTrackedRequested() {
        let exercises = [
            makeCompleted(plannedMiles: 5.0, recordedMiles: 5.0),
            makeCompleted(plannedMiles: 2.0, recordedMiles: 2.0, counts: false)
        ]
        #expect(WeekMileage.completed(exercises, includeNonTracked: true) == 7.0)
    }

    @Test func weekWithOnlyOptedOutTrackedTotalsAreZeroButAllTotalsAreNot() {
        let exercises = [
            makePlanned(miles: 3.0, counts: false),
            makeCompleted(plannedMiles: 2.0, recordedMiles: 2.5, counts: false)
        ]
        #expect(WeekMileage.planned(exercises) == 0)
        #expect(WeekMileage.completed(exercises) == 0)
        #expect(WeekMileage.planned(exercises, includeNonTracked: true) == 5.0)
        #expect(WeekMileage.completed(exercises, includeNonTracked: true) == 2.5)
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

    @Test func exerciseInitPreservesDateTimeComponent() {
        // The merged Exercise no longer normalizes the date to midnight — it
        // stores the full timestamp it was given so the History tab can show
        // time-of-day.
        let date = Calendar.current.date(
            bySettingHour: 15, minute: 30, second: 45,
            of: Date()
        )!
        let exercise = Exercise(
            name: "Test Run",
            type: .run,
            durationSeconds: 1800,
            distanceMiles: 3.0,
            date: date
        )
        let cal = Calendar.current
        #expect(cal.component(.hour, from: exercise.date) == 15)
        #expect(cal.component(.minute, from: exercise.date) == 30)
        #expect(cal.component(.second, from: exercise.date) == 45)
    }

    @Test func exerciseDefaultValues() {
        let exercise = Exercise(
            name: "Morning 5K",
            type: .easyRun,
            durationSeconds: 1500,
            distanceMiles: 3.1,
            date: Date()
        )
        #expect(exercise.name == "Morning 5K")
        #expect(exercise.type == .easyRun)
        #expect(exercise.durationSeconds == 1500)
        #expect(exercise.distanceMiles == 3.1)
        #expect(exercise.notes == "")
        // A freshly planned exercise has no recorded workout and counts
        // toward mileage totals.
        #expect(exercise.workout == nil)
        #expect(exercise.isCompleted == false)
        #expect(exercise.countsTowardMileage == true)
    }

    @Test func settingWorkoutMarksExerciseCompleted() {
        let exercise = Exercise(
            name: "Morning 5K",
            type: .easyRun,
            durationSeconds: 1500,
            distanceMiles: 3.1,
            date: Date()
        )
        #expect(exercise.isCompleted == false)

        exercise.workout = Workout(durationSeconds: 1500, distanceMiles: 3.1, feltRating: 7)
        #expect(exercise.isCompleted == true)
    }

    @Test func exercisePersistence() throws {
        let context = try makeContext()
        let exercise = Exercise(
            name: "Tempo Run",
            type: .tempoRun,
            durationSeconds: 2400,
            distanceMiles: 5.0,
            date: Date()
        )
        context.insert(exercise)
        try context.save()

        let descriptor = FetchDescriptor<Exercise>()
        let fetched = try context.fetch(descriptor)
        #expect(fetched.count == 1)
        #expect(fetched.first?.name == "Tempo Run")
        #expect(fetched.first?.type == .tempoRun)
    }

    @Test func nestedWorkoutRoundTripsThroughSwiftData() throws {
        // The recorded workout is stored inline as a Codable composite
        // attribute (no second table). Verify every nested field survives a
        // save + fetch cycle.
        let context = try makeContext()
        let exercise = Exercise(
            name: "Long Run",
            type: .longRun,
            durationSeconds: 3600,
            distanceMiles: 8.0,
            date: Date(),
            workout: Workout(
                durationSeconds: 3550,
                distanceMiles: 8.2,
                notes: "negative split",
                feltRating: 9,
                source: WorkoutSource.appleHealth.rawValue,
                externalID: "hk-uuid-123"
            )
        )
        context.insert(exercise)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Exercise>())
        #expect(fetched.count == 1)
        let workout = try #require(fetched.first?.workout)
        #expect(workout.durationSeconds == 3550)
        #expect(workout.distanceMiles == 8.2)
        #expect(workout.notes == "negative split")
        #expect(workout.feltRating == 9)
        #expect(workout.source == WorkoutSource.appleHealth.rawValue)
        #expect(workout.externalID == "hk-uuid-123")
        #expect(fetched.first?.isCompleted == true)
    }

    @Test func completedVsPlannedFilteringInMemory() throws {
        let context = try makeContext()
        let planned1 = Exercise(name: "Planned A", type: .run, durationSeconds: 1800, distanceMiles: 3.0, date: Date())
        let planned2 = Exercise(name: "Planned B", type: .easyRun, durationSeconds: 2400, distanceMiles: 4.0, date: Date())
        let completed1 = Exercise(
            name: "Done A", type: .tempoRun, durationSeconds: 2400, distanceMiles: 5.0, date: Date(),
            workout: Workout(durationSeconds: 2400, distanceMiles: 5.0, feltRating: 7)
        )
        let completed2 = Exercise(
            name: "Done B", type: .longRun, durationSeconds: 3600, distanceMiles: 8.0, date: Date(),
            workout: Workout(durationSeconds: 3600, distanceMiles: 8.0, feltRating: 8)
        )
        for e in [planned1, completed1, planned2, completed2] { context.insert(e) }
        try context.save()

        let all = try context.fetch(FetchDescriptor<Exercise>())
        let completed = all.filter { $0.workout != nil }
        #expect(completed.count == 2)
        #expect(Set(completed.map(\.name)) == ["Done A", "Done B"])
    }
}

// MARK: - Exercise Mileage Counting Tests

struct ExerciseMileageCountingTests {

    private func makeContext() throws -> ModelContext {
        let container = ModelContainerFactory.makePreviewContainer()
        return ModelContext(container)
    }

    @Test func countsTowardMileageDefaultsTrue() {
        let exercise = Exercise(
            name: "Morning Run",
            type: .run,
            durationSeconds: 1800,
            distanceMiles: 3.0,
            date: Date()
        )
        #expect(exercise.countsTowardMileage == true)
    }

    @Test func countsTowardMileageCanBeSetFalse() {
        let exercise = Exercise(
            name: "Lunch Walk",
            type: .other,
            durationSeconds: 1200,
            distanceMiles: 1.0,
            date: Date(),
            countsTowardMileage: false
        )
        #expect(exercise.countsTowardMileage == false)
    }

    @Test func countsTowardMileagePersistsThroughSwiftData() throws {
        let context = try makeContext()
        let walk = Exercise(
            name: "Evening Walk",
            type: .other,
            durationSeconds: 1800,
            distanceMiles: 1.5,
            date: Date(),
            countsTowardMileage: false,
            workout: Workout(durationSeconds: 1800, distanceMiles: 1.5)
        )
        let run = Exercise(
            name: "Tempo Run",
            type: .tempoRun,
            durationSeconds: 2400,
            distanceMiles: 5.0,
            date: Date(),
            workout: Workout(durationSeconds: 2400, distanceMiles: 5.0)
        )
        context.insert(walk)
        context.insert(run)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Exercise>())
        #expect(fetched.count == 2)
        #expect(fetched.first { $0.name == "Evening Walk" }?.countsTowardMileage == false)
        #expect(fetched.first { $0.name == "Tempo Run" }?.countsTowardMileage == true)
    }
}

// MARK: - Workout Model Tests

struct WorkoutModelTests {

    private func makeContext() throws -> ModelContext {
        let container = ModelContainerFactory.makePreviewContainer()
        return ModelContext(container)
    }

    @Test func workoutDraftFromExercise() {
        // `Workout(draftFrom:)` copies the planned target metrics into the
        // actuals and starts unrated with empty notes (notes are NOT copied
        // from the planning notes) and a manual source.
        let exercise = Exercise(
            name: "5K Run",
            type: .run,
            durationSeconds: 1500,
            distanceMiles: 3.1,
            notes: "Easy pace",
            date: Date()
        )
        let workout = Workout(draftFrom: exercise)
        #expect(workout.durationSeconds == 1500)
        #expect(workout.distanceMiles == 3.1)
        #expect(workout.notes == "") // planning notes NOT copied
        #expect(workout.feltRating == 0)
        #expect(workout.source == WorkoutSource.manual.rawValue)
        #expect(workout.externalID == nil)
    }

    @Test func workoutDefaultValues() {
        let workout = Workout()
        #expect(workout.durationSeconds == 0)
        #expect(workout.distanceMiles == 0.0)
        #expect(workout.notes == "")
        #expect(workout.feltRating == 0)
        #expect(workout.source == WorkoutSource.manual.rawValue)
        #expect(workout.externalID == nil)
    }

    @Test func workoutCodableRoundTrip() throws {
        // Workout is a plain Codable value type; verify it round-trips
        // through JSON (the same machinery SwiftData uses for the inline
        // composite attribute).
        let original = Workout(
            durationSeconds: 1800,
            distanceMiles: 3.0,
            notes: "Felt great",
            feltRating: 8,
            source: WorkoutSource.csv.rawValue,
            externalID: "abc"
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Workout.self, from: data)
        #expect(decoded == original)
    }

    @Test func nestedWorkoutPersistsOnExercise() throws {
        // Workout is not a model — it persists only as part of an Exercise.
        let context = try makeContext()
        let exercise = Exercise(
            name: "Morning Run",
            type: .run,
            durationSeconds: 1800,
            distanceMiles: 3.0,
            date: Date(),
            workout: Workout(
                durationSeconds: 1800,
                distanceMiles: 3.0,
                notes: "Felt great"
            )
        )
        context.insert(exercise)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Exercise>())
        #expect(fetched.count == 1)
        #expect(fetched.first?.name == "Morning Run")
        #expect(fetched.first?.workout?.notes == "Felt great")
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

    @Test func weekStartDayDefaultsToSunday() throws {
        let config = AppConfiguration()
        #expect(config.weekStartDay == 1)
    }

    @Test func weekStartDayAcceptsExplicitValue() throws {
        let config = AppConfiguration(weekStartDay: 2)
        #expect(config.weekStartDay == 2)
    }

    @Test func weekStartDayPersists() throws {
        let context = try makeContext()
        let config = AppConfiguration.current(in: context)
        config.weekStartDay = 3
        try context.save()
        let fetched = AppConfiguration.current(in: context)
        #expect(fetched.weekStartDay == 3)
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
            date: Date()
        )
        #expect(exercise.isRepeating == false)
    }

    @Test func isRepeatingCanBeSetTrue() {
        let exercise = Exercise(
            name: "Run", type: .run,
            durationSeconds: 1800, distanceMiles: 3.0,
            date: Date(), isRepeating: true
        )
        #expect(exercise.isRepeating == true)
    }

    @Test func repeatingExerciseMatchesDayOfWeek() {
        // April 5, 2026 is a Sunday
        let sunday = makeDate(year: 2026, month: 4, day: 5)
        let exercise = Exercise(
            name: "Sunday Run", type: .run,
            durationSeconds: 1800, distanceMiles: 3.0,
            date: sunday, isRepeating: true
        )
        #expect(exercise.date.weekdayIndex == 0)
        #expect(exercise.isRepeating == true)
    }

    @Test func repeatingExercisePersistence() throws {
        let context = try makeContext()
        let exercise = Exercise(
            name: "Weekly Tempo", type: .tempoRun,
            durationSeconds: 2400, distanceMiles: 5.0,
            date: Date(), isRepeating: true
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
            date: Date(), isRepeating: false
        )
        context.insert(exercise)
        try context.save()

        let descriptor = FetchDescriptor<Exercise>()
        let fetched = try context.fetch(descriptor)
        #expect(fetched.first?.isRepeating == false)
    }
}

// MARK: - Exercise Series Membership Tests

struct ExerciseSeriesMembershipTests {

    private func makeContext() throws -> ModelContext {
        let container = ModelContainerFactory.makePreviewContainer()
        return ModelContext(container)
    }

    @Test func seriesIDDefaultsNil() {
        let exercise = Exercise(
            name: "Run", type: .run,
            durationSeconds: 1800, distanceMiles: 3.0,
            date: Date()
        )
        #expect(exercise.seriesID == nil)
    }

    @Test func seriesIDCanBeSet() {
        let seriesID = UUID()
        let exercise = Exercise(
            name: "Run", type: .run,
            durationSeconds: 1800, distanceMiles: 3.0,
            date: Date(), seriesID: seriesID
        )
        #expect(exercise.seriesID == seriesID)
    }

    @Test func seriesIDPersistence() throws {
        let context = try makeContext()
        let seriesID = UUID()
        let exercise = Exercise(
            name: "Weekly Tempo", type: .tempoRun,
            durationSeconds: 2400, distanceMiles: 5.0,
            date: Date(), seriesID: seriesID
        )
        context.insert(exercise)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Exercise>())
        #expect(fetched.count == 1)
        #expect(fetched.first?.seriesID == seriesID)
    }

    @Test func fetchBySeriesIDPredicate() throws {
        let context = try makeContext()
        let seriesID = UUID()
        let member = Exercise(
            name: "Series Run", type: .run,
            durationSeconds: 1800, distanceMiles: 3.0,
            date: Date(), seriesID: seriesID
        )
        let standalone = Exercise(
            name: "One-off Run", type: .run,
            durationSeconds: 1800, distanceMiles: 3.0,
            date: Date()
        )
        context.insert(member)
        context.insert(standalone)
        try context.save()

        let descriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate { $0.seriesID == seriesID }
        )
        let fetched = try context.fetch(descriptor)
        #expect(fetched.count == 1)
        #expect(fetched.first?.name == "Series Run")
    }
}

// MARK: - Series Generator Tests

struct SeriesGeneratorTests {

    /// Helper to create a date from components.
    private func makeDate(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return Calendar.current.date(from: components)!
    }

    /// Convenience spec with sensible defaults for run-shaped tests.
    private func makeSpec(
        startDate: Date,
        cadence: SeriesCadence,
        endDate: Date,
        baseDistanceMiles: Double = 3.0,
        baseDurationSeconds: Int = 1800,
        progression: SeriesProgression? = nil
    ) -> ExerciseSeriesSpec {
        ExerciseSeriesSpec(
            name: "Run", type: .run,
            startDate: startDate, cadence: cadence, endDate: endDate,
            baseDistanceMiles: baseDistanceMiles,
            baseDurationSeconds: baseDurationSeconds,
            progression: progression
        )
    }

    @Test func oneOffYieldsSingleOccurrenceIgnoringEndDate() {
        let start = makeDate(year: 2026, month: 4, day: 5)
        // End date before start would empty any recurring cadence; oneOff ignores it.
        let spec = makeSpec(startDate: start, cadence: .oneOff, endDate: makeDate(year: 2026, month: 1, day: 1))
        let occurrences = SeriesGenerator.occurrences(for: spec)
        #expect(occurrences.count == 1)
        #expect(occurrences.first?.date == start)
        #expect(occurrences.first?.distanceMiles == 3.0)
        #expect(occurrences.first?.durationSeconds == 1800)
    }

    @Test func weeklyCountOverSixMonths() {
        // Jan 5 → Jul 5 2026 is 181 days: occurrences at 7k for k = 0...25.
        let spec = makeSpec(
            startDate: makeDate(year: 2026, month: 1, day: 5),
            cadence: .weekly,
            endDate: makeDate(year: 2026, month: 7, day: 5)
        )
        #expect(SeriesGenerator.occurrences(for: spec).count == 26)
    }

    @Test func weeklyOccurrencesAreSevenDaysApart() {
        let spec = makeSpec(
            startDate: makeDate(year: 2026, month: 1, day: 5),
            cadence: .weekly,
            endDate: makeDate(year: 2026, month: 2, day: 5)
        )
        let dates = SeriesGenerator.occurrences(for: spec).map(\.date)
        for (earlier, later) in zip(dates, dates.dropFirst()) {
            let days = Calendar.current.dateComponents([.day], from: earlier, to: later).day
            #expect(days == 7)
        }
    }

    @Test func endDateLandingOnOccurrenceIsIncluded() {
        // Jan 5 + 21 days = Jan 26: end date exactly on the 4th occurrence.
        let spec = makeSpec(
            startDate: makeDate(year: 2026, month: 1, day: 5),
            cadence: .weekly,
            endDate: makeDate(year: 2026, month: 1, day: 26)
        )
        let occurrences = SeriesGenerator.occurrences(for: spec)
        #expect(occurrences.count == 4)
        #expect(occurrences.last?.date == makeDate(year: 2026, month: 1, day: 26))
    }

    @Test func endDateJustBeforeNextOccurrenceExcludesIt() {
        // Jan 25 is one day before the Jan 26 occurrence.
        let spec = makeSpec(
            startDate: makeDate(year: 2026, month: 1, day: 5),
            cadence: .weekly,
            endDate: makeDate(year: 2026, month: 1, day: 25)
        )
        #expect(SeriesGenerator.occurrences(for: spec).count == 3)
    }

    @Test func biweeklyOccurrencesAreFourteenDaysApart() {
        let spec = makeSpec(
            startDate: makeDate(year: 2026, month: 1, day: 5),
            cadence: .biweekly,
            endDate: makeDate(year: 2026, month: 3, day: 5)
        )
        let dates = SeriesGenerator.occurrences(for: spec).map(\.date)
        #expect(dates.count == 5)
        for (earlier, later) in zip(dates, dates.dropFirst()) {
            let days = Calendar.current.dateComponents([.day], from: earlier, to: later).day
            #expect(days == 14)
        }
    }

    @Test func monthlyPreservesDayOfMonth() {
        let spec = makeSpec(
            startDate: makeDate(year: 2026, month: 1, day: 15),
            cadence: .monthly,
            endDate: makeDate(year: 2026, month: 6, day: 15)
        )
        let dates = SeriesGenerator.occurrences(for: spec).map(\.date)
        #expect(dates.count == 6)
        for date in dates {
            #expect(Calendar.current.component(.day, from: date) == 15)
        }
    }

    @Test func monthlyClampsFebruaryButRestoresMarch() {
        // Jan 31 anchored monthly: Feb clamps to 28 (2026), Mar restores to 31.
        let spec = makeSpec(
            startDate: makeDate(year: 2026, month: 1, day: 31),
            cadence: .monthly,
            endDate: makeDate(year: 2026, month: 3, day: 31)
        )
        let dates = SeriesGenerator.occurrences(for: spec).map(\.date)
        #expect(dates == [
            makeDate(year: 2026, month: 1, day: 31),
            makeDate(year: 2026, month: 2, day: 28),
            makeDate(year: 2026, month: 3, day: 31)
        ])
    }

    @Test func monthlyClampsToLeapDayInLeapYear() {
        let spec = makeSpec(
            startDate: makeDate(year: 2028, month: 1, day: 31),
            cadence: .monthly,
            endDate: makeDate(year: 2028, month: 2, day: 29)
        )
        let dates = SeriesGenerator.occurrences(for: spec).map(\.date)
        #expect(dates.last == makeDate(year: 2028, month: 2, day: 29))
    }

    @Test func endDateBeforeStartYieldsEmpty() {
        let spec = makeSpec(
            startDate: makeDate(year: 2026, month: 4, day: 5),
            cadence: .weekly,
            endDate: makeDate(year: 2026, month: 4, day: 4)
        )
        #expect(SeriesGenerator.occurrences(for: spec).isEmpty)
    }

    @Test func progressionEveryOccurrenceIsLinear() {
        let spec = makeSpec(
            startDate: makeDate(year: 2026, month: 1, day: 5),
            cadence: .weekly,
            endDate: makeDate(year: 2026, month: 1, day: 26),
            progression: SeriesProgression(everyN: 1, distanceDeltaMiles: 0.5, durationDeltaSeconds: 300)
        )
        let occurrences = SeriesGenerator.occurrences(for: spec)
        #expect(occurrences.map(\.distanceMiles) == [3.0, 3.5, 4.0, 4.5])
        #expect(occurrences.map(\.durationSeconds) == [1800, 2100, 2400, 2700])
    }

    @Test func progressionEveryOtherOccurrenceStepsInPairs() {
        let spec = makeSpec(
            startDate: makeDate(year: 2026, month: 1, day: 5),
            cadence: .weekly,
            endDate: makeDate(year: 2026, month: 2, day: 2),
            progression: SeriesProgression(everyN: 2, distanceDeltaMiles: 0.5, durationDeltaSeconds: 300)
        )
        let occurrences = SeriesGenerator.occurrences(for: spec)
        #expect(occurrences.map(\.distanceMiles) == [3.0, 3.0, 3.5, 3.5, 4.0])
    }

    @Test func progressionEveryFourthStepsAtIndexFour() {
        let spec = makeSpec(
            startDate: makeDate(year: 2026, month: 1, day: 5),
            cadence: .weekly,
            endDate: makeDate(year: 2026, month: 2, day: 9),
            progression: SeriesProgression(everyN: 4, distanceDeltaMiles: 1.0, durationDeltaSeconds: 600)
        )
        let occurrences = SeriesGenerator.occurrences(for: spec)
        #expect(occurrences.map(\.distanceMiles) == [3.0, 3.0, 3.0, 3.0, 4.0, 4.0])
    }

    @Test func nilProgressionKeepsBaseValues() {
        let spec = makeSpec(
            startDate: makeDate(year: 2026, month: 1, day: 5),
            cadence: .weekly,
            endDate: makeDate(year: 2026, month: 2, day: 2)
        )
        let occurrences = SeriesGenerator.occurrences(for: spec)
        #expect(occurrences.allSatisfy { $0.distanceMiles == 3.0 && $0.durationSeconds == 1800 })
    }

    @Test func negativeDeltaClampsAtZero() {
        let spec = makeSpec(
            startDate: makeDate(year: 2026, month: 1, day: 5),
            cadence: .weekly,
            endDate: makeDate(year: 2026, month: 2, day: 2),
            baseDistanceMiles: 1.0,
            baseDurationSeconds: 600,
            progression: SeriesProgression(everyN: 1, distanceDeltaMiles: -0.5, durationDeltaSeconds: -300)
        )
        let occurrences = SeriesGenerator.occurrences(for: spec)
        #expect(occurrences.map(\.distanceMiles) == [1.0, 0.5, 0.0, 0.0, 0.0])
        #expect(occurrences.map(\.durationSeconds) == [600, 300, 0, 0, 0])
    }

    @Test func zeroEveryNIsTreatedAsOne() {
        let spec = makeSpec(
            startDate: makeDate(year: 2026, month: 1, day: 5),
            cadence: .weekly,
            endDate: makeDate(year: 2026, month: 1, day: 19),
            progression: SeriesProgression(everyN: 0, distanceDeltaMiles: 0.5)
        )
        let occurrences = SeriesGenerator.occurrences(for: spec)
        #expect(occurrences.map(\.distanceMiles) == [3.0, 3.5, 4.0])
    }

    @Test func occurrenceCountIsCapped() {
        let spec = makeSpec(
            startDate: makeDate(year: 2026, month: 1, day: 1),
            cadence: .weekly,
            endDate: makeDate(year: 2046, month: 1, day: 1)
        )
        #expect(SeriesGenerator.occurrences(for: spec).count == SeriesGenerator.maxOccurrences)
    }
}

// MARK: - Workout Felt Rating Tests

struct WorkoutFeltRatingTests {

    private func makeContext() throws -> ModelContext {
        let container = ModelContainerFactory.makePreviewContainer()
        return ModelContext(container)
    }

    @Test func feltRatingDefaultsToZero() {
        let workout = Workout(
            durationSeconds: 1800,
            distanceMiles: 3.0
        )
        #expect(workout.feltRating == 0)
    }

    @Test func feltRatingCanBeSetExplicitly() {
        let workout = Workout(
            durationSeconds: 2400,
            distanceMiles: 5.0,
            feltRating: 8
        )
        #expect(workout.feltRating == 8)
    }

    @Test func feltRatingPersistsThroughSwiftData() throws {
        // The rating lives inside the nested workout; it persists as part of
        // the owning Exercise.
        let context = try makeContext()
        let exercise = Exercise(
            name: "Interval",
            type: .intervalRun,
            durationSeconds: 2700,
            distanceMiles: 4.0,
            date: Date(),
            workout: Workout(durationSeconds: 2700, distanceMiles: 4.0, feltRating: 9)
        )
        context.insert(exercise)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Exercise>())
        #expect(fetched.first?.workout?.feltRating == 9)
    }

    @Test func draftFromExerciseStartsUnrated() {
        let exercise = Exercise(
            name: "Long Run",
            type: .longRun,
            durationSeconds: 3600,
            distanceMiles: 8.0,
            date: Date()
        )
        let draft = Workout(draftFrom: exercise)
        #expect(draft.feltRating == 0)
        #expect(draft.notes == "")
    }
}

// MARK: - Coach Type Conversion Tests

struct CoachTypeConversionTests {

    @Test func workoutConversionPreservesAllFields() {
        // CoachWorkout(from:) now takes a completed Exercise: date/type come
        // from the exercise, metrics/RPE/notes from its nested workout.
        let date = Date()
        let exercise = Exercise(
            name: "Morning Run",
            type: .tempoRun,
            durationSeconds: 2400,
            distanceMiles: 5.0,
            date: date,
            workout: Workout(
                durationSeconds: 2400,
                distanceMiles: 5.0,
                notes: "felt great",
                feltRating: 7
            )
        )
        let coachWorkout = CoachWorkout(from: exercise)
        #expect(coachWorkout.date == date)
        #expect(coachWorkout.type == .tempoRun)
        #expect(coachWorkout.distanceMiles == 5.0)
        #expect(coachWorkout.durationSeconds == 2400)
        #expect(coachWorkout.feltRating == 7)
        #expect(coachWorkout.notes == "felt great")
    }

    @Test func exerciseConversionPreservesAllFields() {
        let date = Date()
        let exercise = Exercise(
            name: "Long Run",
            type: .longRun,
            durationSeconds: 3600,
            distanceMiles: 10.0,
            date: date
        )
        let coachExercise = CoachExercise(from: exercise)
        #expect(coachExercise.scheduledDate == date)
        #expect(coachExercise.type == .longRun)
        #expect(coachExercise.distanceMiles == 10.0)
        #expect(coachExercise.durationSeconds == 3600)
    }

    @Test func exerciseTypeConversionAllCases() {
        for appType in ExerciseType.allCases {
            let coachType = CoachExerciseType(from: appType)
            #expect(coachType.rawValue == appType.rawValue)
        }
    }
}

// MARK: - Stub AI Coach Service Tests

struct StubAICoachServiceTests {

    @Test func stubReturnsNonEmptyNarrative() async throws {
        let service = StubAICoachService()
        let request = CoachingRequest(
            recentWorkouts: [],
            upcomingExercises: [],
            useMetricUnits: false
        )
        let response = try await service.suggestAdaptations(request)
        #expect(!response.narrative.isEmpty)
    }

    @Test func stubStreamsAllChunks() async throws {
        let service = StubAICoachService(narrative: "hello coach")
        let request = CoachingRequest(
            recentWorkouts: [],
            upcomingExercises: [],
            useMetricUnits: false
        )
        var assembled = ""
        for try await chunk in service.streamSuggestion(request) {
            assembled += chunk
        }
        #expect(assembled == "hello coach")
    }
}

// MARK: - WorkoutCSV Tests

struct WorkoutCSVTests {

    /// Fixed reference date: 2026-04-09T07:30:00Z
    private var referenceDate: Date {
        var components = DateComponents()
        components.year = 2026
        components.month = 4
        components.day = 9
        components.hour = 7
        components.minute = 30
        components.second = 0
        components.timeZone = TimeZone(identifier: "UTC")
        return Calendar(identifier: .gregorian).date(from: components)!
    }

    /// Builds a completed `Exercise` (planned targets + nested recorded
    /// `workout` actuals) for the encode/round-trip tests. The recorded
    /// metrics mirror the supplied values so the existing CSV assertions hold,
    /// and the date lives on the exercise.
    private func makeExercise(
        name: String = "Morning 5K",
        type: ExerciseType = .run,
        durationSeconds: Int = 1800,
        distanceMiles: Double = 3.1,
        notes: String = "",
        feltRating: Int = 7,
        date: Date? = nil
    ) -> Exercise {
        Exercise(
            name: name,
            type: type,
            durationSeconds: durationSeconds,
            distanceMiles: distanceMiles,
            notes: notes,
            date: date ?? referenceDate,
            workout: Workout(
                durationSeconds: durationSeconds,
                distanceMiles: distanceMiles,
                notes: notes,
                feltRating: feltRating
            )
        )
    }

    // MARK: Encoding

    @Test func encodeProducesHeaderAndOneRowPerWorkout() {
        let exercises = [
            makeExercise(name: "A", distanceMiles: 1.0),
            makeExercise(name: "B", distanceMiles: 2.0),
            makeExercise(name: "C", distanceMiles: 3.0)
        ]
        let csv = WorkoutCSV.encode(exercises: exercises, unit: .miles)
        let lines = csv.split(separator: "\n", omittingEmptySubsequences: false)
        #expect(lines.first.map(String.init) == WorkoutCSV.header)
        // 1 header + 3 data + trailing empty from final newline
        #expect(lines.count == 5)
    }

    @Test func encodeQuotesFieldsContainingCommasQuotesAndNewlines() {
        let exercise = makeExercise(
            name: "5K, easy",
            notes: "He said \"go\"\nthen left"
        )
        let csv = WorkoutCSV.encode(exercises: [exercise], unit: .miles)
        #expect(csv.contains("\"5K, easy\""))
        // Embedded quote doubled.
        #expect(csv.contains("\"He said \"\"go\"\"\nthen left\""))
    }

    @Test func encodeUsesFixedTwoDecimalDistance() {
        let exercise = makeExercise(distanceMiles: 3.14159)
        let csv = WorkoutCSV.encode(exercises: [exercise], unit: .miles)
        #expect(csv.contains(",3.14,"))
    }

    @Test func encodeOnlyEmitsCompletedExercises() {
        // Planned-only exercises (workout == nil) are skipped on export.
        let completed = makeExercise(name: "Completed", distanceMiles: 3.0)
        let planned = Exercise(
            name: "Planned Only", type: .run,
            durationSeconds: 1800, distanceMiles: 3.0, date: referenceDate
        )
        let csv = WorkoutCSV.encode(exercises: [completed, planned], unit: .miles)
        #expect(csv.contains("Completed"))
        #expect(!csv.contains("Planned Only"))
    }

    @Test func encodeConvertsMilesToKilometersForKilometerUnit() {
        let exercise = makeExercise(distanceMiles: 1.0)
        let milesCSV = WorkoutCSV.encode(exercises: [exercise], unit: .miles)
        let kmCSV = WorkoutCSV.encode(exercises: [exercise], unit: .kilometers)
        #expect(milesCSV.contains(",1.00,"))
        // 1 mi ≈ 1.60934 km → formatted as 1.61
        #expect(kmCSV.contains(",1.61,"))
    }

    // MARK: Parsing

    @Test func parseEmptyFileThrows() {
        #expect(throws: WorkoutCSVError.empty) {
            _ = try WorkoutCSV.parse("")
        }
        #expect(throws: WorkoutCSVError.empty) {
            _ = try WorkoutCSV.parse("   \n  \n")
        }
    }

    @Test func parseHeaderOnlyReturnsZeroRows() throws {
        let result = try WorkoutCSV.parse(WorkoutCSV.header + "\n")
        #expect(result.rows.isEmpty)
        #expect(result.skipped.isEmpty)
    }

    @Test func parseRoundTripPreservesAllFields() throws {
        let original = makeExercise(
            name: "Tempo Day",
            type: .tempoRun,
            durationSeconds: 2400,
            distanceMiles: 6.25,
            notes: "Felt strong",
            feltRating: 9
        )
        let csv = WorkoutCSV.encode(exercises: [original], unit: .miles)
        let result = try WorkoutCSV.parse(csv)
        #expect(result.rows.count == 1)
        #expect(result.skipped.isEmpty)

        let row = result.rows[0]
        #expect(row.name == "Tempo Day")
        #expect(row.type == .tempoRun)
        #expect(row.durationSeconds == 2400)
        #expect(abs(row.distance - 6.25) < 0.01)
        #expect(row.notes == "Felt strong")
        #expect(row.feltRating == 9)
        // Parsed dates are normalized to local midnight (CSV dates are calendar
        // days), so compare against start-of-day rather than the exact reference.
        let expectedDay = Calendar.current.startOfDay(for: referenceDate)
        #expect(abs(row.date.timeIntervalSince(expectedDay)) < 1.0)
    }

    @Test func parseHandlesQuotedFieldsAndEmbeddedNewlines() throws {
        let csv = """
        \(WorkoutCSV.header)
        2026-04-09T07:30:00Z,"5K, easy",Run,1800,3.10,"line one\nline two",7
        """
        let result = try WorkoutCSV.parse(csv)
        #expect(result.skipped.isEmpty)
        #expect(result.rows.count == 1)
        #expect(result.rows[0].name == "5K, easy")
        #expect(result.rows[0].notes == "line one\nline two")
    }

    @Test func parseSkipsRowsWithInvalidDateOrDistance() throws {
        let csv = """
        \(WorkoutCSV.header)
        2026-04-09T07:30:00Z,Good,Run,1800,3.10,ok,7
        not-a-date,Bad Date,Run,1800,3.10,nope,7
        2026-04-09T07:30:00Z,Bad Distance,Run,1800,abc,nope,7
        """
        let result = try WorkoutCSV.parse(csv)
        #expect(result.rows.count == 1)
        #expect(result.rows[0].name == "Good")
        #expect(result.skipped.count == 2)
    }

    @Test func parseUnknownExerciseTypeFallsBackToOther() throws {
        let csv = """
        \(WorkoutCSV.header)
        2026-04-09T07:30:00Z,Martian Jog,Teleport,1800,3.10,,5
        """
        let result = try WorkoutCSV.parse(csv)
        #expect(result.rows.count == 1)
        #expect(result.rows[0].type == .other)
    }

    @Test func parseAppliesKilometersToMilesConversion() throws {
        // Row has distance=5.0 in km → 5 / 1.60934 ≈ 3.10686 mi.
        let csv = """
        \(WorkoutCSV.header)
        2026-04-09T07:30:00Z,Metric Run,Run,1800,5.00,,6
        """
        let result = try WorkoutCSV.parse(csv)
        let exercise = WorkoutCSV.toExercise(result.rows[0], unit: .kilometers)
        #expect(abs(exercise.workout!.distanceMiles - 3.10686) < 0.001)
    }

    @Test func toExercisePreservesMilesWhenUnitIsMiles() throws {
        let csv = """
        \(WorkoutCSV.header)
        2026-04-09T07:30:00Z,Imperial Run,Run,1800,4.25,,6
        """
        let result = try WorkoutCSV.parse(csv)
        let exercise = WorkoutCSV.toExercise(result.rows[0], unit: .miles)
        #expect(abs(exercise.workout!.distanceMiles - 4.25) < 0.001)
    }

    // MARK: Integration with SwiftData

    @Test func parsedRowsCanBeInsertedIntoModelContext() throws {
        let container = ModelContainerFactory.makePreviewContainer()
        let context = ModelContext(container)
        // Clear any seeded exercises so the assertion is exact.
        let existing = try context.fetch(FetchDescriptor<Exercise>())
        for exercise in existing { context.delete(exercise) }
        try context.save()

        let csv = """
        \(WorkoutCSV.header)
        2026-04-09T07:30:00Z,Alpha,Run,1800,3.00,,6
        2026-04-09T07:30:00Z,Bravo,Bike,3600,10.00,commute,5
        """
        let result = try WorkoutCSV.parse(csv)
        for row in result.rows {
            context.insert(WorkoutCSV.toExercise(row, unit: .miles))
        }
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Exercise>())
        #expect(fetched.count == 2)
        #expect(fetched.contains(where: { $0.name == "Alpha" && $0.type == .run && $0.isCompleted }))
        #expect(fetched.contains(where: { $0.name == "Bravo" && $0.type == .bike && $0.isCompleted }))
    }

    @Test func csvImportsBuildCompletedExerciseTaggedWithCsvSource() throws {
        let csv = """
        \(WorkoutCSV.header)
        2026-04-09T07:30:00Z,Alpha,Run,1800,3.00,,6
        """
        let result = try WorkoutCSV.parse(csv)
        let exercise = WorkoutCSV.toExercise(result.rows[0], unit: .miles)
        // toExercise builds a completed exercise dated to the row.
        #expect(exercise.isCompleted == true)
        #expect(exercise.date == result.rows[0].date)
        let workout = try #require(exercise.workout)
        #expect(workout.source == WorkoutSource.csv.rawValue)
        #expect(workout.workoutSource == .csv)
        // CSV imports don't populate externalID (no stable row identifier yet).
        #expect(workout.externalID == nil)
    }

    // MARK: Duration Parsing

    @Test func parseDurationPlainIntegerTreatedAsSeconds() {
        #expect(WorkoutCSV.parseDuration("1800") == 1800)
    }

    @Test func parseDurationOnlyMinutes() {
        #expect(WorkoutCSV.parseDuration("40m") == 2400)
    }

    @Test func parseDurationOnlySeconds() {
        #expect(WorkoutCSV.parseDuration("120s") == 120)
    }

    @Test func parseDurationOnlyHours() {
        #expect(WorkoutCSV.parseDuration("2h") == 7200)
    }

    @Test func parseDurationHoursAndMinutes() {
        #expect(WorkoutCSV.parseDuration("2h 30m") == 9000)
    }

    @Test func parseDurationAllUnits() {
        #expect(WorkoutCSV.parseDuration("1h 30m 45s") == 5445)
    }

    @Test func parseDurationMinutesAndSeconds() {
        #expect(WorkoutCSV.parseDuration("45m 30s") == 2730)
    }

    @Test func parseDurationUnitsOutOfOrder() {
        #expect(WorkoutCSV.parseDuration("30m 2h") == 9000)
    }

    @Test func parseDurationLargeValues() {
        #expect(WorkoutCSV.parseDuration("160m") == 9600)
    }

    @Test func parseDurationDecimalFloored() {
        // 40.5m → floor(40.5) = 40 minutes = 2400 seconds
        #expect(WorkoutCSV.parseDuration("40.5m") == 2400)
    }

    @Test func parseDurationInvalidReturnsNil() {
        #expect(WorkoutCSV.parseDuration("abc") == nil)
        #expect(WorkoutCSV.parseDuration("") == nil)
    }

    @Test func parseDurationMixedLargeUnbounded() {
        // "2h 160m 0s" = 2*3600 + 160*60 + 0 = 16800
        #expect(WorkoutCSV.parseDuration("2h 160m 0s") == 16800)
    }

    @Test func parseDurationDecimalSeconds() {
        // "60.5s" → floor(60.5) = 60 seconds
        #expect(WorkoutCSV.parseDuration("60.5s") == 60)
    }

    // MARK: Duration Formatting

    @Test func formatDurationHumanReadable() {
        #expect(WorkoutCSV.formatDuration(5400) == "1h 30m")
        #expect(WorkoutCSV.formatDuration(0) == "0s")
        #expect(WorkoutCSV.formatDuration(90) == "1m 30s")
        #expect(WorkoutCSV.formatDuration(3600) == "1h")
        #expect(WorkoutCSV.formatDuration(45) == "45s")
    }

    @Test func encodeHeaderUsesDurationNotDurationSeconds() {
        #expect(WorkoutCSV.header.contains("duration"))
        #expect(!WorkoutCSV.header.contains("duration_seconds"))
    }

    @Test func encodeDurationUsesHumanReadableFormat() {
        // 2400 seconds = 40 minutes → "40m" in output
        let exercise = makeExercise(durationSeconds: 2400)
        let csv = WorkoutCSV.encode(exercises: [exercise], unit: .miles)
        #expect(csv.contains(",40m,"))
    }

    @Test func encodeDateUsesSlashFormat() {
        let exercise = makeExercise()
        let csv = WorkoutCSV.encode(exercises: [exercise], unit: .miles)
        // referenceDate is April 9, 2026 — should appear as 4/9/2026
        #expect(csv.contains("4/9/2026"))
        #expect(!csv.contains("2026-04-09"))
    }

    @Test func encodeSortsRowsByDateAscending() {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let yesterday = cal.date(byAdding: .day, value: -1, to: today)!
        let tomorrow = cal.date(byAdding: .day, value: 1, to: today)!

        // Create exercises in non-chronological order.
        let e1 = makeExercise(name: "Tomorrow", durationSeconds: 1800, distanceMiles: 3.0, feltRating: 5, date: tomorrow)
        let e2 = makeExercise(name: "Yesterday", durationSeconds: 1800, distanceMiles: 3.0, feltRating: 5, date: yesterday)
        let e3 = makeExercise(name: "Today", durationSeconds: 1800, distanceMiles: 3.0, feltRating: 5, date: today)

        let csv = WorkoutCSV.encode(exercises: [e1, e2, e3], unit: .miles)
        let lines = csv.split(separator: "\n", omittingEmptySubsequences: true)
        // Header + 3 data rows.
        #expect(lines.count == 4)
        #expect(lines[1].contains("Yesterday"))
        #expect(lines[2].contains("Today"))
        #expect(lines[3].contains("Tomorrow"))
    }

    // MARK: Date Formats

    @Test func parseDateISO8601Format() throws {
        let csv = """
        \(WorkoutCSV.header)
        2025-08-04T07:30:00Z,Run,run,1800,4,,
        """
        let result = try WorkoutCSV.parse(csv)
        #expect(result.rows.count == 1)
    }

    @Test func parseDateYYYYMMDDFormat() throws {
        let csv = """
        \(WorkoutCSV.header)
        2025-08-04,Run,run,1800,4,,
        """
        let result = try WorkoutCSV.parse(csv)
        #expect(result.rows.count == 1)
        #expect(result.skipped.isEmpty)
    }

    @Test func parseDateMMDDYYYYFormat() throws {
        let csv = """
        \(WorkoutCSV.header)
        8/4/2025,Run,run,40m,4,,
        """
        let result = try WorkoutCSV.parse(csv)
        #expect(result.rows.count == 1)
        #expect(result.skipped.isEmpty)
    }

    @Test func parseDateMMDDYYYYDoubleDigits() throws {
        let csv = """
        \(WorkoutCSV.header)
        12/25/2025,Run,run,40m,4,,
        """
        let result = try WorkoutCSV.parse(csv)
        #expect(result.rows.count == 1)
        #expect(result.skipped.isEmpty)
    }

    // MARK: Optional Fields

    @Test func parseEmptyFeltRatingDefaultsToZero() throws {
        let csv = """
        \(WorkoutCSV.header)
        2026-04-09T07:30:00Z,Run,run,1800,3.00,,
        """
        let result = try WorkoutCSV.parse(csv)
        #expect(result.rows.count == 1)
        #expect(result.rows[0].feltRating == 0)
    }

    @Test func parseEmptyNotesDefaultsToEmptyString() throws {
        let csv = """
        \(WorkoutCSV.header)
        2026-04-09T07:30:00Z,Run,run,1800,3.00,,6
        """
        let result = try WorkoutCSV.parse(csv)
        #expect(result.rows.count == 1)
        #expect(result.rows[0].notes == "")
    }

    @Test func parseRowWithFiveFields() throws {
        let csv = """
        \(WorkoutCSV.header)
        2026-04-09T07:30:00Z,Run,run,1800,3.00
        """
        let result = try WorkoutCSV.parse(csv)
        #expect(result.rows.count == 1)
        #expect(result.rows[0].notes == "")
        #expect(result.rows[0].feltRating == 0)
    }

    @Test func parseRowWithSixFields() throws {
        let csv = """
        \(WorkoutCSV.header)
        2026-04-09T07:30:00Z,Run,run,1800,3.00,good effort
        """
        let result = try WorkoutCSV.parse(csv)
        #expect(result.rows.count == 1)
        #expect(result.rows[0].notes == "good effort")
        #expect(result.rows[0].feltRating == 0)
    }

    // MARK: Type Parsing

    @Test func parseCSVKeyMatchesExerciseType() throws {
        let csv = """
        \(WorkoutCSV.header)
        2026-04-09T07:30:00Z,Run,easy,1800,3.00,,
        """
        let result = try WorkoutCSV.parse(csv)
        #expect(result.rows[0].type == .easyRun)
    }

    @Test func parseCSVKeyCaseInsensitive() throws {
        let csv = """
        \(WorkoutCSV.header)
        2026-04-09T07:30:00Z,Run,Easy,1800,3.00,,
        """
        let result = try WorkoutCSV.parse(csv)
        #expect(result.rows[0].type == .easyRun)
    }

    @Test func parseDisplayNameStillWorks() throws {
        let csv = """
        \(WorkoutCSV.header)
        2026-04-09T07:30:00Z,Run,Easy Run,1800,3.00,,
        """
        let result = try WorkoutCSV.parse(csv)
        #expect(result.rows[0].type == .easyRun)
    }

    @Test func parseCrossAliasMapsToOther() throws {
        let csv = """
        \(WorkoutCSV.header)
        2026-04-09T07:30:00Z,Incline Walk,cross,1800,3.00,,
        """
        let result = try WorkoutCSV.parse(csv)
        #expect(result.rows[0].type == .other)
    }

    @Test func parseRaceType() throws {
        let csv = """
        \(WorkoutCSV.header)
        2026-04-09T07:30:00Z,5k,race,22m,3.5,,
        """
        let result = try WorkoutCSV.parse(csv)
        #expect(result.rows[0].type == .race)
    }

    // MARK: Name Inference

    @Test func parseEmptyNameInferredFromType() throws {
        let csv = """
        \(WorkoutCSV.header)
        2026-04-09T07:30:00Z,,easy,1800,3.00,,
        """
        let result = try WorkoutCSV.parse(csv)
        #expect(result.rows[0].name == "Easy Run")
    }

    @Test func parseNonEmptyNamePreserved() throws {
        let csv = """
        \(WorkoutCSV.header)
        2026-04-09T07:30:00Z,My Custom Name,easy,1800,3.00,,
        """
        let result = try WorkoutCSV.parse(csv)
        #expect(result.rows[0].name == "My Custom Name")
    }

    // MARK: Exercise Creation

    @Test func toExerciseCreatesCompletedExercise() {
        let row = WorkoutCSVRow(
            date: referenceDate,
            name: "Test Run",
            type: .easyRun,
            durationSeconds: 2400,
            distance: 4.0,
            notes: "good",
            feltRating: 6
        )
        let exercise = WorkoutCSV.toExercise(row, unit: .miles)
        #expect(exercise.name == "Test Run")
        #expect(exercise.type == .easyRun)
        #expect(exercise.durationSeconds == 2400)
        #expect(abs(exercise.distanceMiles - 4.0) < 0.001)
        #expect(exercise.isRepeating == false)
        #expect(exercise.date == referenceDate)
        #expect(exercise.isCompleted == true)

        let workout = exercise.workout!
        #expect(workout.durationSeconds == 2400)
        #expect(abs(workout.distanceMiles - 4.0) < 0.001)
        #expect(workout.notes == "good")
        #expect(workout.feltRating == 6)
        #expect(workout.source == WorkoutSource.csv.rawValue)
        #expect(workout.externalID == nil)
    }

    @Test func toExerciseCanBePersisted() throws {
        let container = ModelContainerFactory.makePreviewContainer()
        let context = ModelContext(container)
        let existing = try context.fetch(FetchDescriptor<Exercise>())
        for e in existing { context.delete(e) }
        try context.save()

        let row = WorkoutCSVRow(
            date: referenceDate,
            name: "Persisted Run",
            type: .run,
            durationSeconds: 1800,
            distance: 3.0,
            notes: "",
            feltRating: 5
        )
        context.insert(WorkoutCSV.toExercise(row, unit: .miles))
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Exercise>())
        #expect(fetched.count == 1)
        #expect(fetched[0].name == "Persisted Run")
        #expect(fetched[0].workout?.source == WorkoutSource.csv.rawValue)
    }

    // MARK: ExerciseType CSV Key

    @Test func exerciseTypeFromCSVMatchesAllKeys() {
        for type in ExerciseType.allCases {
            let resolved = ExerciseType.fromCSV(type.csvKey)
            #expect(resolved == type, "csvKey '\(type.csvKey)' should resolve to \(type)")
        }
    }

    @Test func exerciseTypeFromCSVCrossAlias() {
        #expect(ExerciseType.fromCSV("cross") == .other)
    }

    @Test func exerciseTypeRaceHasExpectedProperties() {
        #expect(ExerciseType.race.rawValue == "Race")
        #expect(ExerciseType.race.csvKey == "race")
        #expect(ExerciseType.fromCSV("race") == .race)
    }

    // MARK: CRLF line endings

    @Test func parseCRLFLineEndings() throws {
        let csv = "date,name,type,duration,distance,notes,felt_rating\r\n" +
                  "8/4/2025,Easy Run,easy,40m,4,,\r\n" +
                  "8/5/2025,Tempo Run,tempo,45m,5,,\r\n"
        let result = try WorkoutCSV.parse(csv)
        #expect(result.rows.count == 2)
        #expect(result.skipped.isEmpty)
        #expect(result.rows[0].name == "Easy Run")
        #expect(result.rows[1].name == "Tempo Run")
    }

    @Test func parseCRLFWithoutTrailingNewline() throws {
        let csv = "date,name,type,duration,distance,notes,felt_rating\r\n" +
                  "8/4/2025,Easy Run,easy,40m,4,,"
        let result = try WorkoutCSV.parse(csv)
        #expect(result.rows.count == 1)
        #expect(result.rows[0].name == "Easy Run")
    }

    // MARK: Example CSV integration

    @Test func parseExampleCSVFile() throws {
        let csv = """
            date,name,type,duration,distance,notes,felt_rating
            8/4/2025,Easy Run,easy,40m,4,,
            8/5/2025,Easy Run,easy,40m,4,,
            8/7/2025,Easy Run,easy,30m,3,,
            8/7/2025,Tempo Run,tempo,45m,5,,
            8/8/2025,Easy Run,easy,40m,4,,
            8/11/2025,Easy Run,easy,40m,4,,
            8/13/2025,Interval Run,interval,45m,5,,
            8/14/2025,Easy Run,easy,40m,4,,
            8/16/2025,Long Run,long,83m,9,,
            8/18/2025,Walking On Incline,cross,50m,2.5,,
            8/19/2025,Easy Run,easy,40m,4,,
            8/20/2025,Easy Run,easy,40m,4,,
            8/21/2025,Tempo Run,tempo,45m,5,,
            8/23/2025,Long Run,long,86m,9,,
            8/25/2025,Tempo Run,tempo,35m,4,,
            8/26/2025,Walking On Incline,cross,40m,2,,
            8/27/2025,Tempo Run,tempo,43m,5,,
            8/28/2025,Easy Run,easy,37m 20s,4,,
            8/29/2025,Hill Workout,interval,50m,5,,
            8/30/2025,Easy Run,easy,39m,4,,
            9/1/2025,Easy Run,easy,52m 45s,5,,
            9/2/2025,Walking On Incline,cross,40m,2,,
            9/3/2025,Tempo Run,tempo,42m 30s,5,,
            9/4/2025,Easy Run,easy,40m,4,,
            9/5/2025,Practice 5k,tempo,60.5m,6,,
            9/7/2025,Easy Run,easy,38m 40s,4,,
            9/8/2025,Walking On Incline,cross,90m,4.5,,
            9/9/2025,Hill Workout,interval,64m,6.5,,
            9/10/2025,Easy Run,easy,40m,4,,
            9/11/2025,Easy Run,easy,35m,3.5,,
            9/12/2025,Easy Run,easy,38m 30s,4,,
            9/14/2025,5k,race,22m,3.5,,
            9/16/2025,Easy Run,easy,50m,5,,
            9/17/2025,Easy Run,easy,40m,4,,
            9/18/2025,Easy Run,easy,42m,4,,
            9/19/2025,Medium-Long Run,run,74m,8,,
            9/21/2025,Easy Run,easy,40m,4,,
            9/22/2025,Walking On Incline,cross,30m,1.5,,
            9/22/2025,Easy Run,easy,22m 30s,2,,
            9/23/2025,Easy Run,easy,30m,3,,
            9/24/2025,Tempo Run,tempo,51m 20s,6,,
            9/25/2025,Easy Run,easy,40m,4,,
            9/26/2025,Easy Run,easy,42m 30s,4.25,,
            9/27/2025,Long Run,long,71m 15s,8,,
            9/29/2025,Walking On Incline,cross,50m,2.5,,
            9/30/2025,Easy Run,easy,40m 30s,5,,
            10/1/2025,Easy Run,easy,40m,4,,
            10/2/2025,Tempo Run,tempo,55m,6,,
            10/3/2025,Easy Run,easy,52m,5,,
            10/4/2025,Long Run,long,72m,8,,
            10/7/2025,Easy Run,easy,48m 30s,5,,
            10/8/2025,Tempo Run,tempo,49m,6,,
            10/9/2025,Easy Run,easy,40m,4,,
            10/10/2025,Easy Run,easy,50m,5,,
            10/12/2025,Long Run,long,90m,10,,
            10/13/2025,Hiking,cross,70m,2.5,,
            10/14/2025,Easy Run,easy,40m,4,,
            10/15/2025,Easy Run,easy,62m 30s,6,,
            10/16/2025,Easy Run,easy,60m,6,,
            10/17/2025,Easy Run,easy,40m,4,,
            10/18/2025,Easy Run,easy,50m,5,,
            10/20/2025,Walking On Incline,cross,40m,2,,
            10/21/2025,Easy Run,easy,48m,5,,
            10/22/2025,Tempo Run,tempo,52m,6,,
            10/23/2025,Easy Run,easy,45m,5,,
            10/24/2025,Easy Run,easy,50m,5,,
            10/25/2025,Long Run,long,90m,9,,
            10/28/2025,Easy Run,easy,50m,5,,
            10/29/2025,Easy Run,easy,50m,5,,
            10/30/2025,Tempo Run,tempo,54m,6,,
            10/31/2025,Easy Run,easy,45m,5,,
            11/1/2025,Long Run,long,90m,9,,
            11/4/2025,Walking On Incline,cross,40m,2,,
            11/4/2025,Easy Run,easy,50m,5,,
            11/5/2025,Tempo Run,tempo,50m,6,,
            11/6/2025,Easy Run,easy,50m,5,,
            11/8/2025,Long Run,long,90m,9,,
            11/9/2025,Easy Run,easy,42m 40s,5,,
            11/11/2025,Tempo Run,tempo,51m,6,,
            11/12/2025,Easy Run,easy,30m,3,,
            11/13/2025,Tempo Run,tempo,52m 40s,6,,
            11/14/2025,Easy Run,easy,50m,5,,
            11/15/2025,Long Run,long,87m,10,,
            11/17/2025,Easy Run,easy,60m,6,,
            11/18/2025,Easy Run,easy,56m 45s,6,,
            11/23/2025,Tempo Run,tempo,53m 40s,6,,
            11/24/2025,Hiking,cross,120m,4.3,,
            11/28/2025,Easy Run,easy,50m,5,,
            11/29/2025,Long Run,long,89m 20s,10,,
            12/2/2025,Easy Run,easy,50m,5,,
            12/4/2025,Easy Run,easy,60m,6,,
            12/5/2025,Easy Run,easy,50m,5,,
            12/6/2025,Long Run,long,82m,9.25,,
            12/9/2025,Easy Run,easy,50m,5,,
            12/10/2025,Tempo Run,tempo,50m,6,,
            12/11/2025,Easy Run,easy,50m,5,,
            12/12/2025,Easy Run,easy,50m,5,,
            12/13/2025,Long Run,long,84m,9,,
            12/16/2025,Easy Run,easy,50m,5,,
            12/17/2025,Easy Run,easy,50m,5,,
            12/18/2025,Tempo Run,tempo,51m,6,,
            12/19/2025,Easy Run,easy,50m,5,,
            12/20/2025,Long Run,long,90m,9,,
            12/22/2025,Easy Run,easy,50m,5,,
            12/23/2025,Easy Run,easy,50m,5,,
            12/24/2025,Tempo Run,tempo,52m 30s,6,,
            12/27/2025,Long Run,long,80m,9,,
            12/30/2025,Easy Run,easy,50m,5,,
            12/31/2025,Tempo Run,tempo,50m,6,,
            1/1/2026,Easy Run,easy,50m,5,,
            1/2/2026,Easy Run,easy,50m,5,,
            1/3/2026,Long Run,long,85m,9,,
            1/5/2026,Tempo Run,tempo,52m,6,,
            1/6/2026,Easy Run,easy,40m,4,,
            1/9/2026,Easy Run,easy,60m,6,,
            1/10/2026,Long Run,long,90m,10,,
            1/11/2026,Easy Run,easy,40m,4,,
            1/13/2026,Easy Run,easy,36m 40s,4,,
            1/14/2026,Tempo Run,tempo,42m 30s,5,,
            1/15/2026,Easy Run,easy,56m,6,,
            1/17/2026,Easy Run,easy,50m,5,,
            1/18/2026,Long Run,long,77m,9,,
            1/20/2026,Easy Run,easy,50m,5,,
            1/21/2026,Hill Workout,interval,55m 30s,6,,
            1/22/2026,Easy Run,easy,50m,5,,
            1/23/2026,Easy Run,easy,50m,5,,
            1/25/2026,Long Run,long,77m 30s,9,,
            1/27/2026,Tempo Run,tempo,50m,6,,
            1/28/2026,Easy Run,easy,50m,5,,
            1/29/2026,Easy Run,easy,40m,4,,
            1/30/2026,Easy Run,easy,60m,6,,
            2/1/2026,Long Run,long,88m 30s,9,,
            2/3/2026,Easy Run,easy,50m,5,,
            2/4/2026,Tempo Run,tempo,52m 30s,6,,
            2/6/2026,Easy Run,easy,50m,5,,
            2/7/2026,Long Run,long,90m,9,,
            2/8/2026,Easy Run,easy,49m,5,,
            2/10/2026,Easy Run,easy,47m,5,,
            2/11/2026,Easy Run,easy,46m,5,,
            2/14/2026,Long Run,long,111m 30s,13.1,,
            2/15/2026,Easy Run,easy,50m,5,,
            2/17/2026,Easy Run,easy,60m 30s,7,,
            2/18/2026,Easy Run,easy,36m 30s,4,,
            2/19/2026,Tempo Run,tempo,49m 30s,6,,
            2/21/2026,Long Run,long,2h 2m 30s,14,,
            2/22/2026,Easy Run,easy,40m,4,,
            2/24/2026,Easy Run,easy,56m,6,,
            2/25/2026,Easy Run,easy,50m,5,,
            2/26/2026,Easy Run,easy,74m 15s,8.1,,
            2/27/2026,Easy Run,easy,40m,4,,
            2/28/2026,Long Run,long,140m 20s,15.3,,
            3/3/2026,Tempo Run,tempo,60m,7,,
            3/4/2026,Easy Run,easy,46m,5,,
            3/5/2026,Easy Run,easy,74m,8,,
            3/6/2026,Easy Run,easy,50m,5,,
            3/8/2026,Long Run,long,141m 20s,16,,
            3/10/2026,Easy Run,easy,50m,5,,
            3/11/2026,Easy Run,easy,55m 45s,6,,
            3/12/2026,Easy Run,easy,74m 20s,8,,
            3/13/2026,Easy Run,easy,35m 20s,4,,
            3/16/2026,Tempo Run,tempo,71m 30s,8,,
            3/19/2026,Medium-Long Run,run,82m 15s,9,,
            3/19/2026,Easy Run,easy,40m,4,,
            3/20/2026,Easy Run,easy,60m,6,,
            3/21/2026,Long Run,long,167m 30s,18.07,,
            3/24/2026,Easy Run,easy,68m 30s,8,,
            3/25/2026,Easy Run,easy,54m,6,,
            3/26/2026,Medium-Long Run,run,97m,10,,
            3/27/2026,Easy Run,easy,47m,5,,
            3/29/2026,Long Run,long,3h 2m 30s,20,,
            4/3/2026,Medium-Long Run,run,106m,12,,
            4/5/2026,Medium-Long Run,run,80m,8,,
            4/7/2026,Interval Run,interval,61m,7,,
            4/8/2026,Easy Run,easy,75m 30s,8,,
            4/9/2026,Tempo Run,tempo,54m,6,,
            4/10/2026,Easy Run,easy,62m 15s,7,,
            4/11/2026,Long Run,long,192m,20,,
            4/21/2026,Easy Run,easy,64m 40s,7,,
            4/22/2026,Tempo Run,tempo,60m,7,,
            """
        let result = try WorkoutCSV.parse(csv)

        #expect(result.rows.count == 179, "All 179 data rows should parse")
        #expect(result.skipped.isEmpty, "No rows should be skipped")

        // Verify first row
        #expect(result.rows[0].name == "Easy Run")
        #expect(result.rows[0].type == .easyRun)
        #expect(result.rows[0].durationSeconds == 2400) // 40m
        #expect(result.rows[0].distance == 4.0)

        // Verify "cross" alias maps to .other
        let crossRows = result.rows.filter { $0.type == .other }
        #expect(crossRows.count == 10, "cross alias rows map to .other")
        #expect(crossRows[0].name == "Walking On Incline")

        // Verify race type
        let raceRows = result.rows.filter { $0.type == .race }
        #expect(raceRows.count == 1)
        #expect(raceRows[0].name == "5k")
        #expect(raceRows[0].durationSeconds == 1320) // 22m

        // Verify multi-unit durations
        let longRun2h = result.rows.first { $0.durationSeconds == 7350 } // 2h 2m 30s
        #expect(longRun2h != nil, "2h 2m 30s should parse to 7350s")
        #expect(longRun2h?.distance == 14.0)

        let longRun3h = result.rows.first { $0.durationSeconds == 10950 } // 3h 2m 30s
        #expect(longRun3h != nil, "3h 2m 30s should parse to 10950s")
        #expect(longRun3h?.distance == 20.0)

        // Verify decimal duration is floored
        let practice5k = result.rows.first { $0.name == "Practice 5k" }
        #expect(practice5k?.durationSeconds == 3600) // 60.5m → floor(60.5)*60 = 3600

        // Verify last row
        #expect(result.rows[178].name == "Tempo Run")
        #expect(result.rows[178].type == .tempoRun)
        #expect(result.rows[178].durationSeconds == 3600) // 60m
        #expect(result.rows[178].distance == 7.0)
    }
}

// MARK: - WorkoutSource Tests

struct WorkoutSourceTests {

    @Test func defaultWorkoutSourceIsManual() {
        let workout = Workout(
            durationSeconds: 1800,
            distanceMiles: 3.0
        )
        #expect(workout.source == "Manual")
        #expect(workout.workoutSource == .manual)
        #expect(workout.externalID == nil)
    }

    @Test func explicitSourceIsHonored() {
        let workout = Workout(
            durationSeconds: 1800,
            distanceMiles: 3.0,
            source: WorkoutSource.appleHealth.rawValue,
            externalID: "abc-123"
        )
        #expect(workout.source == "Apple Exercise App")
        #expect(workout.workoutSource == .appleHealth)
        #expect(workout.externalID == "abc-123")
    }

    @Test func unknownSourceStringMapsToUnknownCase() {
        let workout = Workout(
            durationSeconds: 1800,
            distanceMiles: 3.0,
            source: "SomeFutureIntegration"
        )
        #expect(workout.workoutSource == .unknown)
    }
}

// MARK: - HealthKit Import Tests

import HealthKit

struct HealthKitImportTests {

    // MARK: Activity type mapping

    @Test func mapsRunningActivityTypeToRun() {
        #expect(HealthKitWorkoutMapper.exerciseType(for: .running) == .run)
    }

    @Test func mapsWalkingActivityTypeToWalk() {
        #expect(HealthKitWorkoutMapper.exerciseType(for: .walking) == .walk)
    }

    @Test func mapsCyclingActivityTypeToBike() {
        #expect(HealthKitWorkoutMapper.exerciseType(for: .cycling) == .bike)
    }

    @Test func mapsSwimmingActivityTypeToSwim() {
        #expect(HealthKitWorkoutMapper.exerciseType(for: .swimming) == .swim)
    }

    @Test func mapsHikingActivityTypeToHike() {
        #expect(HealthKitWorkoutMapper.exerciseType(for: .hiking) == .hike)
    }

    @Test func mapsEllipticalActivityTypeToElliptical() {
        #expect(HealthKitWorkoutMapper.exerciseType(for: .elliptical) == .elliptical)
    }

    @Test func mapsUnknownActivityTypeToOther() {
        #expect(HealthKitWorkoutMapper.exerciseType(for: .americanFootball) == .other)
        #expect(HealthKitWorkoutMapper.exerciseType(for: .yoga) == .other)
        #expect(HealthKitWorkoutMapper.exerciseType(for: .traditionalStrengthTraining) == .other)
    }

    // MARK: DTO → Exercise

    /// Builds a canonical DTO for the mapping tests so assertions aren't
    /// polluted with boilerplate.
    private func makeDTO(
        id: String = "dto-1",
        activityType: HKWorkoutActivityType = .running,
        startDate: Date = Date(timeIntervalSince1970: 1_700_000_000),
        duration: TimeInterval = 1800,
        distanceMiles: Double? = 3.1
    ) -> HealthKitWorkout {
        HealthKitWorkout(
            id: id,
            activityType: activityType,
            startDate: startDate,
            duration: duration,
            distanceMiles: distanceMiles
        )
    }

    @Test func toExerciseSetsAppleHealthSource() {
        let exercise = HealthKitWorkoutMapper.toExercise(makeDTO())
        #expect(exercise.isCompleted == true)
        #expect(exercise.workout?.source == "Apple Exercise App")
        #expect(exercise.workout?.workoutSource == .appleHealth)
    }

    @Test func toExercisePreservesExternalID() {
        let exercise = HealthKitWorkoutMapper.toExercise(makeDTO(id: "hk-uuid-xyz"))
        #expect(exercise.workout?.externalID == "hk-uuid-xyz")
    }

    @Test func toExerciseHandlesNilDistance() {
        let exercise = HealthKitWorkoutMapper.toExercise(
            makeDTO(activityType: .elliptical, distanceMiles: nil)
        )
        #expect(exercise.workout?.distanceMiles == 0.0)
        #expect(exercise.type == .elliptical)
    }

    @Test func toExerciseCopiesDateAndDuration() {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let exercise = HealthKitWorkoutMapper.toExercise(
            makeDTO(startDate: start, duration: 2700.5)
        )
        #expect(exercise.date == start)
        #expect(exercise.workout?.durationSeconds == 2700)
    }

    @Test func toExerciseNamesExerciseAfterExerciseType() {
        let exercise = HealthKitWorkoutMapper.toExercise(makeDTO(activityType: .cycling))
        #expect(exercise.name == ExerciseType.bike.rawValue)
    }

    @Test func toExerciseCopiesDistanceFromDTO() {
        let exercise = HealthKitWorkoutMapper.toExercise(makeDTO(distanceMiles: 5.25))
        #expect(exercise.workout?.distanceMiles == 5.25)
    }

    // MARK: Stub service

    @Test func stubServiceReturnsFixtures() async throws {
        let stub = StubHealthKitImportService()
        try await stub.requestAuthorization()
        let fetched = try await stub.fetchRecentWorkouts(
            since: Date.distantPast,
            limit: 100
        )
        #expect(fetched.count == stub.fixtures.count)
        #expect(!fetched.isEmpty)
    }

    @Test func stubServiceRespectsLimit() async throws {
        let stub = StubHealthKitImportService()
        let fetched = try await stub.fetchRecentWorkouts(
            since: Date.distantPast,
            limit: 2
        )
        #expect(fetched.count == 2)
    }

    @Test func stubServiceFiltersBySinceDate() async throws {
        let stub = StubHealthKitImportService()
        // Fixtures span roughly the last 10 days; filter to last 2 days.
        let fetched = try await stub.fetchRecentWorkouts(
            since: Date().addingTimeInterval(-2 * 86400),
            limit: 100
        )
        // At least the -1 day run fixture should survive; the 10-day elliptical should not.
        #expect(fetched.contains(where: { $0.id == "stub-run-1" }))
        #expect(!fetched.contains(where: { $0.id == "stub-elliptical-1" }))
    }

    @Test func stubServiceReturnsNewestFirst() async throws {
        let stub = StubHealthKitImportService()
        let fetched = try await stub.fetchRecentWorkouts(
            since: Date.distantPast,
            limit: 100
        )
        let dates = fetched.map { $0.startDate }
        #expect(dates == dates.sorted(by: >))
    }
}

// MARK: - Pace Formatting Tests

struct PaceFormattingTests {

    @Test func imperialSixMinuteMile() {
        // 5 miles in 30 min → 6:00 /mi
        #expect(1800.formattedPace(distanceMiles: 5.0, metric: false) == "6:00 /mi")
    }

    @Test func metricConvertsCorrectly() {
        // 5 miles = 8.0467 km; 1800 / 8.0467 ≈ 223.69 s/km → 3:43 /km
        let result = 1800.formattedPace(distanceMiles: 5.0, metric: true)
        #expect(result == "3:43 /km")
    }

    @Test func zeroDistanceReturnsDash() {
        #expect(1800.formattedPace(distanceMiles: 0.0, metric: false) == "--")
        #expect(1800.formattedPace(distanceMiles: 0.0, metric: true) == "--")
    }

    @Test func negativeDistanceReturnsDash() {
        #expect(1800.formattedPace(distanceMiles: -1.0, metric: false) == "--")
    }

    @Test func slowPaceTwoDigitMinutes() {
        // 1 mile in 720 seconds → 12:00 /mi
        #expect(720.formattedPace(distanceMiles: 1.0, metric: false) == "12:00 /mi")
    }

    @Test func fractionalSecondsTruncateDownward() {
        // 1 mile in 365 seconds → 6:05 /mi (not 6:06 — floor, not round)
        #expect(365.formattedPace(distanceMiles: 1.0, metric: false) == "6:05 /mi")
    }

    @Test func paddingIsTwoDigits() {
        // 2 miles in 720 seconds → 6:00 /mi (zero padded seconds)
        #expect(720.formattedPace(distanceMiles: 2.0, metric: false) == "6:00 /mi")
        // 1 mile in 365s → 6:05 — validates leading zero on seconds
        #expect(365.formattedPace(distanceMiles: 1.0, metric: false) == "6:05 /mi")
    }
}

// MARK: - Workout List Pagination Tests

struct WorkoutListPaginationTests {

    @Test func pageIndexForFirstItemIsZero() {
        #expect(WorkoutListPagination.pageIndex(forItemAt: 0, pageSize: 10) == 0)
    }

    @Test func pageIndexBoundaryAtPageSize() {
        // Index 10 is the first item of the second page (zero-indexed: page 1).
        #expect(WorkoutListPagination.pageIndex(forItemAt: 10, pageSize: 10) == 1)
    }

    @Test func pageIndexLastItemOnFirstPage() {
        #expect(WorkoutListPagination.pageIndex(forItemAt: 9, pageSize: 10) == 0)
    }

    @Test func pageIndexDeepPage() {
        // Index 57, pageSize 10 → page 5 (items 50-59).
        #expect(WorkoutListPagination.pageIndex(forItemAt: 57, pageSize: 10) == 5)
    }

    @Test func pageIndexDefensiveNegative() {
        // Defensive: negative index floors to page 0.
        #expect(WorkoutListPagination.pageIndex(forItemAt: -3, pageSize: 10) == 0)
    }

    @Test func totalPagesEmpty() {
        // Empty state still renders as one page.
        #expect(WorkoutListPagination.totalPages(count: 0, pageSize: 10) == 1)
    }

    @Test func totalPagesExactMultiple() {
        #expect(WorkoutListPagination.totalPages(count: 20, pageSize: 10) == 2)
    }

    @Test func totalPagesRemainder() {
        #expect(WorkoutListPagination.totalPages(count: 23, pageSize: 10) == 3)
    }

    @Test func totalPagesSmallerThanPage() {
        #expect(WorkoutListPagination.totalPages(count: 3, pageSize: 10) == 1)
    }

    @Test func totalPagesSingleFullPage() {
        #expect(WorkoutListPagination.totalPages(count: 10, pageSize: 10) == 1)
    }
}

// MARK: - Workout Detail Edit Tests

struct WorkoutDetailEditTests {

    /// Creates a fresh in-memory context for each test. Follows the same
    /// pattern as `ExerciseModelTests` — a detached `ModelContext` so tests
    /// don't touch `container.mainContext` (which is `@MainActor`-isolated
    /// and incompatible with Swift Testing's parallel execution).
    private func makeContext() -> ModelContext {
        let container = ModelContainerFactory.makePreviewContainer()
        return ModelContext(container)
    }

    @Test func applyRewritesAllMutableFields() throws {
        let context = makeContext()
        let exercise = Exercise(
            name: "Original",
            type: .run,
            durationSeconds: 1800,
            distanceMiles: 3.0,
            notes: "planned notes",
            date: Date(timeIntervalSince1970: 1_700_000_000),
            workout: Workout(
                durationSeconds: 1800,
                distanceMiles: 3.0,
                notes: "original notes",
                feltRating: 4
            )
        )
        context.insert(exercise)

        let newDate = Date(timeIntervalSince1970: 1_710_000_000)
        let edits = WorkoutEditor.EditedValues(
            name: "Edited Name",
            type: .tempoRun,
            durationSeconds: 2700,
            distanceMiles: 6.2,
            plannedDurationSeconds: 2400,
            plannedDistanceMiles: 5.0,
            date: newDate,
            notes: "edited notes",
            feltRating: 9
        )
        WorkoutEditor.apply(edits, to: exercise)

        // Identity fields rewritten on the exercise.
        #expect(exercise.name == "Edited Name")
        #expect(exercise.type == .tempoRun)
        #expect(exercise.date == newDate)
        // Recorded actuals rebuilt on the nested workout.
        #expect(exercise.workout?.durationSeconds == 2700)
        #expect(exercise.workout?.distanceMiles == 6.2)
        #expect(exercise.workout?.notes == "edited notes")
        #expect(exercise.workout?.feltRating == 9)
        // Planned target metrics rewritten on the exercise (unified editor).
        #expect(exercise.durationSeconds == 2400)
        #expect(exercise.distanceMiles == 5.0)
    }

    @Test func applyWritesPlannedTargetsIndependentlyOfActuals() throws {
        let context = makeContext()
        let exercise = Exercise(
            name: "Run",
            type: .run,
            durationSeconds: 1800,
            distanceMiles: 3.0,
            date: Date(timeIntervalSince1970: 1_700_000_000),
            workout: Workout(durationSeconds: 1750, distanceMiles: 3.4, notes: "n", feltRating: 5)
        )
        context.insert(exercise)

        // Only the planned targets change; actuals repeat their current values.
        let edits = WorkoutEditor.EditedValues(
            name: exercise.name,
            type: exercise.type,
            durationSeconds: 1750,
            distanceMiles: 3.4,
            plannedDurationSeconds: 3600,
            plannedDistanceMiles: 6.0,
            date: exercise.date,
            notes: "n",
            feltRating: 5
        )
        WorkoutEditor.apply(edits, to: exercise)

        #expect(exercise.durationSeconds == 3600)
        #expect(exercise.distanceMiles == 6.0)
        #expect(exercise.workout?.durationSeconds == 1750)
        #expect(exercise.workout?.distanceMiles == 3.4)
        #expect(exercise.workout?.notes == "n")
        #expect(exercise.workout?.feltRating == 5)
    }

    @Test func applyWritesCountsTowardMileage() throws {
        let context = makeContext()
        let exercise = Exercise(
            name: "Walk",
            type: .other,
            durationSeconds: 1800,
            distanceMiles: 1.5,
            date: Date(timeIntervalSince1970: 1_700_000_000),
            workout: Workout(durationSeconds: 1800, distanceMiles: 1.5)
        )
        context.insert(exercise)
        #expect(exercise.countsTowardMileage == true)

        var edits = WorkoutEditor.EditedValues(
            name: exercise.name,
            type: exercise.type,
            durationSeconds: 1800,
            distanceMiles: 1.5,
            plannedDurationSeconds: 1800,
            plannedDistanceMiles: 1.5,
            date: exercise.date,
            notes: "",
            feltRating: 0,
            countsTowardMileage: false
        )
        WorkoutEditor.apply(edits, to: exercise)
        #expect(exercise.countsTowardMileage == false)

        // Toggling back on through another edit restores counting.
        edits.countsTowardMileage = true
        WorkoutEditor.apply(edits, to: exercise)
        #expect(exercise.countsTowardMileage == true)
    }

    @Test func removeRecordingClearsWorkoutAndKeepsPlan() throws {
        let context = makeContext()
        let exercise = Exercise(
            name: "Recorded Run",
            type: .tempoRun,
            durationSeconds: 1800,
            distanceMiles: 3.0,
            date: Date(timeIntervalSince1970: 1_700_000_000),
            workout: Workout(durationSeconds: 2000, distanceMiles: 4.0, feltRating: 7)
        )
        context.insert(exercise)
        let originalID = exercise.id
        let originalDate = exercise.date

        WorkoutEditor.removeRecording(from: exercise)

        #expect(exercise.workout == nil)
        #expect(exercise.isCompleted == false)
        // Identity and planned targets untouched.
        #expect(exercise.id == originalID)
        #expect(exercise.name == "Recorded Run")
        #expect(exercise.type == .tempoRun)
        #expect(exercise.date == originalDate)
        #expect(exercise.durationSeconds == 1800)
        #expect(exercise.distanceMiles == 3.0)
    }

    @Test func applyPreservesIdAndImportMetadata() throws {
        let context = makeContext()
        let exercise = Exercise(
            name: "Imported",
            type: .run,
            durationSeconds: 1800,
            distanceMiles: 3.0,
            date: Date(),
            workout: Workout(
                durationSeconds: 1800,
                distanceMiles: 3.0,
                source: WorkoutSource.appleHealth.rawValue,
                externalID: "hk-abc-123"
            )
        )
        context.insert(exercise)
        let originalID = exercise.id

        let edits = WorkoutEditor.EditedValues(
            name: "Renamed",
            type: .easyRun,
            durationSeconds: 2400,
            distanceMiles: 4.0,
            plannedDurationSeconds: 1800,
            plannedDistanceMiles: 3.0,
            date: Date(),
            notes: "",
            feltRating: 6
        )
        WorkoutEditor.apply(edits, to: exercise)

        #expect(exercise.id == originalID)
        // source / externalID survive the edit (import provenance preserved).
        #expect(exercise.workout?.source == WorkoutSource.appleHealth.rawValue)
        #expect(exercise.workout?.externalID == "hk-abc-123")
    }

    @Test func applyPreservesCsvSourceAndExternalID() throws {
        let context = makeContext()
        let exercise = Exercise(
            name: "From CSV",
            type: .run,
            durationSeconds: 1800,
            distanceMiles: 3.0,
            date: Date(),
            workout: Workout(
                durationSeconds: 1800,
                distanceMiles: 3.0,
                source: WorkoutSource.csv.rawValue,
                externalID: "csv-row-42"
            )
        )
        context.insert(exercise)

        let edits = WorkoutEditor.EditedValues(
            name: "Edited",
            type: .tempoRun,
            durationSeconds: 2400,
            distanceMiles: 4.0,
            plannedDurationSeconds: 1800,
            plannedDistanceMiles: 3.0,
            date: Date(),
            notes: "edited",
            feltRating: 7
        )
        WorkoutEditor.apply(edits, to: exercise)

        #expect(exercise.workout?.source == WorkoutSource.csv.rawValue)
        #expect(exercise.workout?.externalID == "csv-row-42")
    }

    @Test func deleteRemovesExerciseFromContext() throws {
        let context = makeContext()
        let exercise = Exercise(
            name: "Doomed",
            type: .run,
            durationSeconds: 1800,
            distanceMiles: 3.0,
            date: Date(),
            workout: Workout(durationSeconds: 1800, distanceMiles: 3.0)
        )
        context.insert(exercise)
        try context.save()

        context.delete(exercise)
        try context.save()

        let remaining = try context.fetch(FetchDescriptor<Exercise>())
        #expect(remaining.isEmpty)
    }

    @Test func deleteLeavesOtherExercisesIntact() throws {
        let context = makeContext()
        let keep = Exercise(name: "Keep me", type: .run, durationSeconds: 1800, distanceMiles: 3.0, date: Date(),
                            workout: Workout(durationSeconds: 1800, distanceMiles: 3.0))
        let remove = Exercise(name: "Remove me", type: .bike, durationSeconds: 3600, distanceMiles: 10.0, date: Date(),
                              workout: Workout(durationSeconds: 3600, distanceMiles: 10.0))
        context.insert(keep)
        context.insert(remove)
        try context.save()

        context.delete(remove)
        try context.save()

        let remaining = try context.fetch(FetchDescriptor<Exercise>())
        #expect(remaining.count == 1)
        #expect(remaining.first?.name == "Keep me")
    }

    @Test func metricDistanceConversionRoundTrip() {
        // Simulate what WorkoutDetailSheet.save() does: user entered 10.0 km,
        // we convert to miles for storage, and reading it back via
        // `toDisplayDistance(metric: true)` should give us back ~10.0 km.
        let kmInput = 10.0
        let milesStored = kmInput / 1.60934
        let kmDisplayed = milesStored.toDisplayDistance(metric: true)
        #expect(abs(kmDisplayed - kmInput) < 0.0001)
    }

    @Test func plannedMetricDistanceConversionRoundTrip() throws {
        // The planned distance follows the same display↔storage conversion as
        // the completed distance; verify a km entry round-trips through
        // WorkoutEditor.apply's plannedDistanceMiles path.
        let context = makeContext()
        let exercise = Exercise(
            name: "Metric Plan",
            type: .run,
            durationSeconds: 1800,
            distanceMiles: 3.0,
            date: Date(),
            workout: Workout(durationSeconds: 1800, distanceMiles: 3.0)
        )
        context.insert(exercise)

        let kmInput = 8.0
        let edits = WorkoutEditor.EditedValues(
            name: exercise.name,
            type: exercise.type,
            durationSeconds: 1800,
            distanceMiles: 3.0,
            plannedDurationSeconds: 1800,
            plannedDistanceMiles: kmInput / 1.60934,
            date: exercise.date,
            notes: "",
            feltRating: 0
        )
        WorkoutEditor.apply(edits, to: exercise)

        let kmDisplayed = exercise.distanceMiles.toDisplayDistance(metric: true)
        #expect(abs(kmDisplayed - kmInput) < 0.0001)
    }
}

// MARK: - WorkoutAggregations Tests

struct WorkoutAggregationsTests {

    /// Builds a deterministic date; hour defaults to midday so boundary
    /// tests that need a specific time-of-day can override it explicitly.
    private func makeDate(year: Int, month: Int, day: Int, hour: Int = 12, minute: Int = 0, second: Int = 0) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = second
        return Calendar.current.date(from: components)!
    }

    /// Constructs a completed `Exercise` (no ModelContext) for pure-logic
    /// aggregation tests. The placement date lives on the exercise; the
    /// recorded miles/feltRating live in the nested workout.
    private func makeExercise(date: Date, miles: Double, felt: Int = 0, counts: Bool = true) -> Exercise {
        Exercise(
            name: "test",
            type: .run,
            durationSeconds: 1800,
            distanceMiles: miles,
            date: date,
            countsTowardMileage: counts,
            workout: Workout(
                durationSeconds: 1800,
                distanceMiles: miles,
                feltRating: felt
            )
        )
    }

    // 2026-04-08 is a Wednesday; its week starts Sunday 2026-04-05.
    private var anchorWednesday: Date { makeDate(year: 2026, month: 4, day: 8) }

    @Test func weeklyMileageReturnsAllWeeksEvenWhenEmpty() {
        let points = WorkoutAggregations.weeklyMileage(
            exercises: [],
            weekCount: 4,
            anchor: anchorWednesday
        )
        #expect(points.count == 4)
        #expect(points.allSatisfy { $0.value == 0 })
        // Chronological order: strictly increasing weekStart.
        let starts = points.map(\.weekStart)
        #expect(starts == starts.sorted())
    }

    @Test func weeklyMileageBucketsWorkoutsIntoCorrectWeek() {
        // Current week (Sun Apr 5 – Sat Apr 11): workout on Mon Apr 6 = 5.0 mi
        // Previous week (Mar 29 – Apr 4): workout on Sat Apr 4 = 3.0 mi
        let workouts = [
            makeExercise(date: makeDate(year: 2026, month: 4, day: 6), miles: 5.0),
            makeExercise(date: makeDate(year: 2026, month: 4, day: 4), miles: 3.0)
        ]
        let points = WorkoutAggregations.weeklyMileage(
            exercises: workouts,
            weekCount: 4,
            anchor: anchorWednesday
        )
        #expect(points.count == 4)
        #expect(points.last?.value == 5.0)
        #expect(points[points.count - 2].value == 3.0)
        #expect(points[0].value == 0)
        #expect(points[1].value == 0)
    }

    @Test func weeklyMileageSumsMultipleWorkoutsInSameWeek() {
        // Tue Apr 7 and Thu Apr 9 both in the week containing the Wednesday anchor.
        let workouts = [
            makeExercise(date: makeDate(year: 2026, month: 4, day: 7), miles: 4.0),
            makeExercise(date: makeDate(year: 2026, month: 4, day: 9), miles: 6.5)
        ]
        let points = WorkoutAggregations.weeklyMileage(
            exercises: workouts,
            weekCount: 4,
            anchor: anchorWednesday
        )
        #expect(points.last?.value == 10.5)
    }

    @Test func weeklyMileageIgnoresWorkoutsOutsideWindow() {
        // January workout should not land in April's 4-week window.
        let workouts = [
            makeExercise(date: makeDate(year: 2026, month: 1, day: 15), miles: 99.0)
        ]
        let points = WorkoutAggregations.weeklyMileage(
            exercises: workouts,
            weekCount: 4,
            anchor: anchorWednesday
        )
        #expect(points.allSatisfy { $0.value == 0 })
    }

    @Test func weeklyMileageExcludesOptedOutExercises() {
        // A 5-mile run and a 2-mile walk (opted out) in the current week —
        // only the run counts toward the weekly total.
        let workouts = [
            makeExercise(date: makeDate(year: 2026, month: 4, day: 6), miles: 5.0),
            makeExercise(date: makeDate(year: 2026, month: 4, day: 7), miles: 2.0, counts: false)
        ]
        let points = WorkoutAggregations.weeklyMileage(
            exercises: workouts,
            weekCount: 4,
            anchor: anchorWednesday
        )
        #expect(points.last?.value == 5.0)
    }

    @Test func weeklyMileageWeekWithOnlyOptedOutIsZero() {
        let workouts = [
            makeExercise(date: makeDate(year: 2026, month: 4, day: 7), miles: 2.0, counts: false)
        ]
        let points = WorkoutAggregations.weeklyMileage(
            exercises: workouts,
            weekCount: 4,
            anchor: anchorWednesday
        )
        #expect(points.allSatisfy { $0.value == 0 })
    }

    @Test func weeklyAverageFeltRatingIncludesOptedOutExercises() {
        // Opting out of mileage only affects distance totals; effort ratings
        // still contribute to the weekly average.
        let workouts = [
            makeExercise(date: makeDate(year: 2026, month: 4, day: 6), miles: 3.0, felt: 6),
            makeExercise(date: makeDate(year: 2026, month: 4, day: 7), miles: 2.0, felt: 8, counts: false)
        ]
        let points = WorkoutAggregations.weeklyAverageFeltRating(
            exercises: workouts,
            weekCount: 4,
            anchor: anchorWednesday
        )
        #expect(points.last?.value == 7.0)
    }

    @Test func weeklyAverageFeltRatingExcludesZeroRatings() {
        // Three workouts in the current week rated 6, 8, 0 → avg = 7.0 (not 4.67).
        let workouts = [
            makeExercise(date: makeDate(year: 2026, month: 4, day: 6), miles: 3.0, felt: 6),
            makeExercise(date: makeDate(year: 2026, month: 4, day: 7), miles: 3.0, felt: 8),
            makeExercise(date: makeDate(year: 2026, month: 4, day: 8), miles: 3.0, felt: 0)
        ]
        let points = WorkoutAggregations.weeklyAverageFeltRating(
            exercises: workouts,
            weekCount: 4,
            anchor: anchorWednesday
        )
        #expect(points.last?.value == 7.0)
    }

    @Test func weeklyAverageFeltRatingEmptyWeekIsZero() {
        let points = WorkoutAggregations.weeklyAverageFeltRating(
            exercises: [],
            weekCount: 4,
            anchor: anchorWednesday
        )
        #expect(points.count == 4)
        #expect(points.allSatisfy { $0.value == 0 })
    }

    @Test func weeklyAverageFeltRatingWeekWithOnlyUnratedIsZero() {
        // Two workouts in the current week, both feltRating = 0 — must not NaN or crash.
        let workouts = [
            makeExercise(date: makeDate(year: 2026, month: 4, day: 7), miles: 3.0, felt: 0),
            makeExercise(date: makeDate(year: 2026, month: 4, day: 8), miles: 3.0, felt: 0)
        ]
        let points = WorkoutAggregations.weeklyAverageFeltRating(
            exercises: workouts,
            weekCount: 4,
            anchor: anchorWednesday
        )
        #expect(points.last?.value == 0)
    }

    @Test func currentWeekMileageSumsWorkoutsInAnchorWeek() {
        // Mon + Tue + Wed of the current week plus a workout on prior Sat (must be excluded).
        let workouts = [
            makeExercise(date: makeDate(year: 2026, month: 4, day: 6), miles: 2.0),
            makeExercise(date: makeDate(year: 2026, month: 4, day: 7), miles: 3.0),
            makeExercise(date: makeDate(year: 2026, month: 4, day: 8), miles: 4.0),
            makeExercise(date: makeDate(year: 2026, month: 4, day: 4), miles: 99.0) // previous Saturday
        ]
        let total = WorkoutAggregations.currentWeekMileage(
            exercises: workouts,
            anchor: anchorWednesday
        )
        #expect(total == 9.0)
    }

    @Test func currentWeekMileageExcludesOptedOutExercises() {
        let workouts = [
            makeExercise(date: makeDate(year: 2026, month: 4, day: 6), miles: 4.0),
            makeExercise(date: makeDate(year: 2026, month: 4, day: 7), miles: 2.5, counts: false)
        ]
        let total = WorkoutAggregations.currentWeekMileage(
            exercises: workouts,
            anchor: anchorWednesday
        )
        #expect(total == 4.0)
    }

    @Test func currentWeekMileageBoundarySundayStart() {
        // Anchor Sunday at 00:00:00, workout at same instant — must count.
        let sunday = makeDate(year: 2026, month: 4, day: 5, hour: 0, minute: 0, second: 0)
        let workouts = [makeExercise(date: sunday, miles: 5.0)]
        let total = WorkoutAggregations.currentWeekMileage(
            exercises: workouts,
            anchor: sunday
        )
        #expect(total == 5.0)
    }

    @Test func currentWeekMileageBoundarySaturdayEnd() {
        // Saturday 23:59:59 workout is in the same week; Sun 00:00 of next week is not.
        let saturdayNight = makeDate(year: 2026, month: 4, day: 11, hour: 23, minute: 59, second: 59)
        let nextSundayStart = makeDate(year: 2026, month: 4, day: 12, hour: 0, minute: 0, second: 0)
        let workouts = [
            makeExercise(date: saturdayNight, miles: 5.0),
            makeExercise(date: nextSundayStart, miles: 99.0)
        ]
        let total = WorkoutAggregations.currentWeekMileage(
            exercises: workouts,
            anchor: saturdayNight
        )
        #expect(total == 5.0)
    }

    @Test func currentWeekAverageFeltRatingReturnsNilWhenNoRated() {
        let workouts = [
            makeExercise(date: makeDate(year: 2026, month: 4, day: 7), miles: 3.0, felt: 0),
            makeExercise(date: makeDate(year: 2026, month: 4, day: 8), miles: 3.0, felt: 0)
        ]
        let avg = WorkoutAggregations.currentWeekAverageFeltRating(
            exercises: workouts,
            anchor: anchorWednesday
        )
        #expect(avg == nil)
    }

    @Test func currentWeekAverageFeltRatingAveragesOnlyRated() {
        // 5, 7, 0 → 6.0, not 4.0.
        let workouts = [
            makeExercise(date: makeDate(year: 2026, month: 4, day: 6), miles: 3.0, felt: 5),
            makeExercise(date: makeDate(year: 2026, month: 4, day: 7), miles: 3.0, felt: 7),
            makeExercise(date: makeDate(year: 2026, month: 4, day: 8), miles: 3.0, felt: 0)
        ]
        let avg = WorkoutAggregations.currentWeekAverageFeltRating(
            exercises: workouts,
            anchor: anchorWednesday
        )
        #expect(avg == 6.0)
    }

    @Test func weeklyBucketsOrderingIsChronological() {
        let buckets = WorkoutAggregations.weeklyBuckets(
            exercises: [],
            weekCount: 6,
            anchor: anchorWednesday
        )
        #expect(buckets.count == 6)
        let starts = buckets.map(\.weekStart)
        for i in 1..<starts.count {
            #expect(starts[i] > starts[i - 1])
        }
    }

    // MARK: Configurable week start (firstWeekday)

    @Test func weeklyMileageMondayStartPutsSundayInPreviousWeek() {
        // Sunday Apr 5 belongs to the Monday-start week of Mar 30, i.e. the
        // bucket BEFORE the anchor's (Mon Apr 6 – Sun Apr 12) tail week.
        let workouts = [makeExercise(date: makeDate(year: 2026, month: 4, day: 5), miles: 5.0)]
        let points = WorkoutAggregations.weeklyMileage(
            exercises: workouts,
            weekCount: 4,
            anchor: anchorWednesday,
            firstWeekday: 2
        )
        #expect(points.last?.value == 0)
        #expect(points[points.count - 2].value == 5.0)
    }

    @Test func weeklyMileageMondayStartTailBucketStartsMonday() {
        let points = WorkoutAggregations.weeklyMileage(
            exercises: [],
            weekCount: 4,
            anchor: anchorWednesday,
            firstWeekday: 2
        )
        #expect(points.last?.weekStart == makeDate(year: 2026, month: 4, day: 6, hour: 0))
    }

    @Test func weeklyMileageDefaultRemainsSundayStart() {
        let points = WorkoutAggregations.weeklyMileage(
            exercises: [],
            weekCount: 4,
            anchor: anchorWednesday
        )
        #expect(points.last?.weekStart == makeDate(year: 2026, month: 4, day: 5, hour: 0))
    }

    @Test func currentWeekMileageMondayStartExcludesSunday() {
        // Sunday Apr 5 counts toward the anchor week with the default Sunday
        // start, but toward the previous week with a Monday start.
        let workouts = [makeExercise(date: makeDate(year: 2026, month: 4, day: 5), miles: 5.0)]
        let sundayStart = WorkoutAggregations.currentWeekMileage(
            exercises: workouts,
            anchor: anchorWednesday
        )
        #expect(sundayStart == 5.0)
        let mondayStart = WorkoutAggregations.currentWeekMileage(
            exercises: workouts,
            anchor: anchorWednesday,
            firstWeekday: 2
        )
        #expect(mondayStart == 0)
    }

    @Test func currentWeekAverageFeltRatingMondayStartExcludesSunday() {
        let workouts = [makeExercise(date: makeDate(year: 2026, month: 4, day: 5), miles: 5.0, felt: 8)]
        let sundayStart = WorkoutAggregations.currentWeekAverageFeltRating(
            exercises: workouts,
            anchor: anchorWednesday
        )
        #expect(sundayStart == 8.0)
        let mondayStart = WorkoutAggregations.currentWeekAverageFeltRating(
            exercises: workouts,
            anchor: anchorWednesday,
            firstWeekday: 2
        )
        #expect(mondayStart == nil)
    }

    @Test func weeklyAverageFeltRatingHonorsFirstWeekday() {
        // Sunday-rated workout lands in the previous Monday-start bucket.
        let workouts = [makeExercise(date: makeDate(year: 2026, month: 4, day: 5), miles: 5.0, felt: 6)]
        let points = WorkoutAggregations.weeklyAverageFeltRating(
            exercises: workouts,
            weekCount: 4,
            anchor: anchorWednesday,
            firstWeekday: 2
        )
        #expect(points.last?.value == 0)
        #expect(points[points.count - 2].value == 6.0)
    }
}

// MARK: - CalendarDisplayable Tests

struct CalendarDisplayableTests {

    @Test func exerciseDisplayDateIsDate() {
        let date = Date()
        let exercise = Exercise(
            name: "Run",
            type: .run,
            durationSeconds: 1800,
            distanceMiles: 3.0,
            date: date
        )
        #expect(exercise.displayDate == exercise.date)
    }

    @Test func calendarDotPreservesFields() {
        let date = Date()
        let dot = CalendarDot(displayDate: date, type: .longRun)
        #expect(dot.displayDate == date)
        #expect(dot.type == .longRun)
    }
}

// MARK: - ExerciseNavigationRequest Tests

struct ExerciseNavigationRequestTests {

    @Test func twoRequestsWithSameDateHaveDifferentIDs() {
        let date = Date()
        let r1 = ExerciseNavigationRequest(targetDate: date)
        let r2 = ExerciseNavigationRequest(targetDate: date)
        #expect(r1.id != r2.id)
    }

    @Test func equatableComparesAllFields() {
        let date = Date()
        let r1 = ExerciseNavigationRequest(targetDate: date)
        let r2 = ExerciseNavigationRequest(targetDate: date)
        #expect(r1 != r2, "Different ids should make requests not equal")
        #expect(r1 == r1, "Same instance should be equal to itself")
    }
}

// MARK: - ExerciseVirtualExpansion Tests

struct ExerciseVirtualExpansionTests {

    private let calendar = Calendar.current

    /// Helper to create a date at midnight.
    private func makeDate(year: Int, month: Int, day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    @Test func monthWithNoRepeatingReturnsOnlyConcrete() {
        let april = makeDate(year: 2026, month: 4, day: 1)
        let ex1 = Exercise(
            name: "Run",
            type: .run,
            durationSeconds: 1800,
            distanceMiles: 3.0,
            date: makeDate(year: 2026, month: 4, day: 10),
            isRepeating: false
        )
        let ex2 = Exercise(
            name: "Swim",
            type: .swim,
            durationSeconds: 2400,
            distanceMiles: 1.0,
            date: makeDate(year: 2026, month: 4, day: 15),
            isRepeating: false
        )
        let items = ExerciseVirtualExpansion.monthItems(
            allExercises: [ex1, ex2],
            month: april
        )
        #expect(items.count == 2)
    }

    @Test func repeatingExerciseProducesDotsForAllMatchingWeekdays() {
        let april = makeDate(year: 2026, month: 4, day: 1)
        // April 6 2026 is a Monday; April has 4 Mondays (6, 13, 20, 27)
        let mondayExercise = Exercise(
            name: "Monday Run",
            type: .run,
            durationSeconds: 1800,
            distanceMiles: 3.0,
            date: makeDate(year: 2026, month: 3, day: 2), // a Monday in March
            isRepeating: true
        )
        let items = ExerciseVirtualExpansion.monthItems(
            allExercises: [mondayExercise],
            month: april
        )
        // Should produce dots for each Monday in April
        let targetIndex = mondayExercise.date.weekdayIndex
        let mondays = april.daysInMonth().filter { $0.weekdayIndex == targetIndex }
        #expect(items.count == mondays.count)
        for item in items {
            #expect(item.type == .run)
            #expect(item.displayDate.weekdayIndex == targetIndex)
        }
    }

    @Test func concreteExerciseSuppressesVirtualDot() {
        let april = makeDate(year: 2026, month: 4, day: 1)
        // Repeating run on Mondays from March
        let repeating = Exercise(
            name: "Monday Run",
            type: .run,
            durationSeconds: 1800,
            distanceMiles: 3.0,
            date: makeDate(year: 2026, month: 3, day: 2),
            isRepeating: true
        )
        // Concrete instance on April 6 (a Monday) with same name/type
        let concrete = Exercise(
            name: "Monday Run",
            type: .run,
            durationSeconds: 2000,
            distanceMiles: 4.0,
            date: makeDate(year: 2026, month: 4, day: 6),
            isRepeating: false
        )
        let items = ExerciseVirtualExpansion.monthItems(
            allExercises: [repeating, concrete],
            month: april
        )
        // Concrete should count + remaining Mondays get virtual dots
        let mondays = april.daysInMonth().filter { $0.weekdayIndex == repeating.date.weekdayIndex }
        #expect(items.count == mondays.count, "One concrete + (N-1) virtual = N total Mondays")
        // Verify the April 6 item is the concrete exercise, not a CalendarDot
        let april6Items = items.filter { $0.displayDate.isSameDay(as: makeDate(year: 2026, month: 4, day: 6)) }
        #expect(april6Items.count == 1)
        #expect(april6Items.first is Exercise)
    }

    @Test func exerciseOutsideMonthExcludedFromConcrete() {
        let april = makeDate(year: 2026, month: 4, day: 1)
        let marchExercise = Exercise(
            name: "March Run",
            type: .run,
            durationSeconds: 1800,
            distanceMiles: 3.0,
            date: makeDate(year: 2026, month: 3, day: 15),
            isRepeating: false
        )
        let items = ExerciseVirtualExpansion.monthItems(
            allExercises: [marchExercise],
            month: april
        )
        #expect(items.isEmpty)
    }

    @Test func sameMonthRepeatingExerciseExpandsToFutureWeekdaysOnly() {
        let april = makeDate(year: 2026, month: 4, day: 1)
        // April 14, 2026 is a Tuesday; April has Tuesdays on 7, 14, 21, 28
        let tuesdayExercise = Exercise(
            name: "Tuesday Run",
            type: .run,
            durationSeconds: 1800,
            distanceMiles: 3.0,
            date: makeDate(year: 2026, month: 4, day: 14),
            isRepeating: true
        )
        let items = ExerciseVirtualExpansion.monthItems(
            allExercises: [tuesdayExercise],
            month: april
        )
        // Should produce items for April 14 (concrete), 21, 28 (dots) — NOT April 7
        #expect(items.count == 3)
        // April 7 (before scheduled date) should have no item
        let april7Items = items.filter {
            $0.displayDate.isSameDay(as: makeDate(year: 2026, month: 4, day: 7))
        }
        #expect(april7Items.isEmpty)
        // The original date (April 14) should be the concrete Exercise
        let april14Items = items.filter {
            $0.displayDate.isSameDay(as: makeDate(year: 2026, month: 4, day: 14))
        }
        #expect(april14Items.count == 1)
        #expect(april14Items.first is Exercise)
        // Later Tuesdays should be CalendarDots
        let april21Items = items.filter {
            $0.displayDate.isSameDay(as: makeDate(year: 2026, month: 4, day: 21))
        }
        #expect(april21Items.count == 1)
        #expect(april21Items.first is CalendarDot)
    }
}

// MARK: - Exercise Reschedule Tests

struct ExerciseRescheduleTests {

    private func makeContext() throws -> ModelContext {
        let container = ModelContainerFactory.makePreviewContainer()
        return ModelContext(container)
    }

    @Test func rescheduleUpdatesExerciseDate() throws {
        // With the merged model the recorded data is inline, so rescheduling
        // is just a write to the exercise's single `date`.
        let context = try makeContext()
        let weekStart = Date().startOfWeek
        let exercise = Exercise(
            name: "Easy Run",
            type: .run,
            durationSeconds: 1800,
            distanceMiles: 3.0,
            date: weekStart,
            workout: Workout(durationSeconds: 1800, distanceMiles: 3.0, feltRating: 6)
        )
        context.insert(exercise)
        try context.save()

        let wednesday = Calendar.current.date(byAdding: .day, value: 2, to: weekStart)!.startOfDay
        exercise.date = wednesday
        try context.save()

        #expect(exercise.date == wednesday)
        // The recorded workout rides along on the exercise — its single date
        // moved with it.
        #expect(exercise.workout != nil)
    }

    @Test func repeatingExerciseShouldNotBeRescheduled() throws {
        let context = try makeContext()
        let weekStart = Date().startOfWeek
        let exercise = Exercise(
            name: "Repeating Run",
            type: .run,
            durationSeconds: 1800,
            distanceMiles: 3.0,
            date: weekStart,
            isRepeating: true
        )
        context.insert(exercise)
        try context.save()

        // Simulate the guard: repeating exercises are blocked
        #expect(exercise.isRepeating)
        // The view's rescheduleExercise returns early; date is unchanged.
        // The init no longer normalizes to midnight, so compare against the
        // exact stored value.
        #expect(exercise.date == weekStart)
    }
}

// MARK: - Exercise Cascade Delete Tests

struct ExerciseCascadeDeleteTests {

    private func makeContext() throws -> ModelContext {
        let container = ModelContainerFactory.makePreviewContainer()
        return ModelContext(container)
    }

    @Test func deleteCompletedExerciseRemovesItAndItsInlineWorkout() throws {
        // The recorded workout is inline on the exercise (no second table), so
        // deleting the exercise removes its recorded data in one step.
        let context = try makeContext()
        let exercise = Exercise(
            name: "Tempo Run",
            type: .tempoRun,
            durationSeconds: 2400,
            distanceMiles: 5.0,
            date: Date(),
            workout: Workout(durationSeconds: 2400, distanceMiles: 5.0, feltRating: 7)
        )
        context.insert(exercise)
        try context.save()

        #expect(exercise.isCompleted)

        context.delete(exercise)
        try context.save()

        let exercises = try context.fetch(FetchDescriptor<Exercise>())
        #expect(exercises.isEmpty)
    }

    @Test func deletePlannedOnlyExercise() throws {
        let context = try makeContext()
        let exercise = Exercise(
            name: "Easy Run",
            type: .run,
            durationSeconds: 1800,
            distanceMiles: 3.0,
            date: Date()
        )
        context.insert(exercise)
        try context.save()

        #expect(exercise.workout == nil)

        context.delete(exercise)
        try context.save()

        let exercises = try context.fetch(FetchDescriptor<Exercise>())
        #expect(exercises.isEmpty)
    }

    @Test func clearingWorkoutRevertsToPlannedOnly() throws {
        // Equivalent of "un-recording" — drop the inline workout while keeping
        // the planned exercise.
        let context = try makeContext()
        let exercise = Exercise(
            name: "Long Run",
            type: .longRun,
            durationSeconds: 3600,
            distanceMiles: 8.0,
            date: Date(),
            workout: Workout(durationSeconds: 3600, distanceMiles: 8.0, feltRating: 8)
        )
        context.insert(exercise)
        try context.save()
        #expect(exercise.isCompleted)

        exercise.workout = nil
        try context.save()

        let exercises = try context.fetch(FetchDescriptor<Exercise>())
        #expect(exercises.count == 1, "Exercise itself is preserved")
        #expect(exercises.first?.isCompleted == false, "Recorded workout cleared")
    }

    @Test func deleteVirtualRepeatingStopsRecurrence() throws {
        let context = try makeContext()
        let exercise = Exercise(
            name: "Weekly Run",
            type: .run,
            durationSeconds: 1800,
            distanceMiles: 3.0,
            date: Date(),
            isRepeating: true,
            workout: Workout(durationSeconds: 1800, distanceMiles: 3.0, feltRating: 5)
        )
        context.insert(exercise)
        try context.save()

        #expect(exercise.isRepeating == true)
        #expect(exercise.isCompleted == true)

        // Virtual delete: just stop recurrence, preserve exercise + its workout
        exercise.isRepeating = false
        try context.save()

        let exercises = try context.fetch(FetchDescriptor<Exercise>())
        #expect(exercises.count == 1, "Exercise is preserved")
        #expect(exercises.first?.isRepeating == false, "Recurrence stopped")
        #expect(exercises.first?.workout != nil, "Recorded workout is preserved")
    }

    @Test func deleteTemplateInOwnWeekRemovesExercise() throws {
        let context = try makeContext()
        let exercise = Exercise(
            name: "Weekly Tempo",
            type: .tempoRun,
            durationSeconds: 2400,
            distanceMiles: 5.0,
            date: Date(),
            isRepeating: true,
            workout: Workout(durationSeconds: 2400, distanceMiles: 5.0, feltRating: 7)
        )
        context.insert(exercise)
        try context.save()

        // Non-virtual delete: full removal (template is in its own week).
        context.delete(exercise)
        try context.save()

        let exercises = try context.fetch(FetchDescriptor<Exercise>())
        #expect(exercises.isEmpty, "Template exercise deleted")
    }
}

// MARK: - WorkoutCSV.rows Tests

struct WorkoutCSVRowsTests {

    /// Builds a completed `Exercise` whose recorded metrics mirror the
    /// supplied values, so the row-matrix assertions hold.
    private func makeExercise(
        name: String = "Easy Run",
        type: ExerciseType = .easyRun,
        durationSeconds: Int = 1800,
        distanceMiles: Double = 3.0,
        notes: String = "",
        feltRating: Int = 7,
        date: Date = Date(timeIntervalSince1970: 1_700_000_000)
    ) -> Exercise {
        Exercise(
            name: name,
            type: type,
            durationSeconds: durationSeconds,
            distanceMiles: distanceMiles,
            notes: notes,
            date: date,
            workout: Workout(
                durationSeconds: durationSeconds,
                distanceMiles: distanceMiles,
                notes: notes,
                feltRating: feltRating
            )
        )
    }

    @Test func emptyListProducesHeaderOnly() {
        let rows = WorkoutCSV.rows(exercises: [], unit: .miles)
        #expect(rows.count == 1)
        #expect(rows[0] == WorkoutCSV.headerColumns)
    }

    @Test func headerColumnsMatchCSVHeaderString() {
        let joined = WorkoutCSV.headerColumns.joined(separator: ",")
        #expect(joined == WorkoutCSV.header)
    }

    @Test func singleWorkoutProducesHeaderPlusOneRow() {
        let exercise = makeExercise(distanceMiles: 3.0)
        let rows = WorkoutCSV.rows(exercises: [exercise], unit: .miles)
        #expect(rows.count == 2)
        #expect(rows[0] == WorkoutCSV.headerColumns)
        // Column order: date, name, type, duration, distance, notes, felt_rating
        #expect(rows[1].count == 7)
        #expect(rows[1][1] == "Easy Run")
        #expect(rows[1][2] == ExerciseType.easyRun.rawValue)
        #expect(rows[1][4] == "3.00")
        #expect(rows[1][6] == "7")
    }

    @Test func distanceConvertedToKilometersWhenRequested() {
        let exercise = makeExercise(distanceMiles: 1.0)
        let rowsMiles = WorkoutCSV.rows(exercises: [exercise], unit: .miles)
        let rowsKm = WorkoutCSV.rows(exercises: [exercise], unit: .kilometers)
        #expect(rowsMiles[1][4] == "1.00")
        #expect(rowsKm[1][4] == "1.61")
    }

    @Test func plannedOnlyExercisesAreOmittedFromRows() {
        let completed = makeExercise(name: "Done")
        let planned = Exercise(
            name: "Planned", type: .run, durationSeconds: 1800,
            distanceMiles: 3.0, date: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let rows = WorkoutCSV.rows(exercises: [completed, planned], unit: .miles)
        // Header + one completed row only.
        #expect(rows.count == 2)
        #expect(rows[1][1] == "Done")
    }

    @Test func sortedOldestFirstRegardlessOfInputOrder() {
        let cal = Calendar(identifier: .gregorian)
        let day1 = cal.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let day2 = cal.date(from: DateComponents(year: 2026, month: 1, day: 2))!
        let day3 = cal.date(from: DateComponents(year: 2026, month: 1, day: 3))!
        let e1 = makeExercise(name: "first", date: day1)
        let e2 = makeExercise(name: "second", date: day2)
        let e3 = makeExercise(name: "third", date: day3)
        let rows = WorkoutCSV.rows(exercises: [e3, e1, e2], unit: .miles)
        #expect(rows[1][1] == "first")
        #expect(rows[2][1] == "second")
        #expect(rows[3][1] == "third")
    }

    @Test func notesAndCommasNotEscapedInRowsOutput() {
        // Sheets API takes raw strings — escaping is only for CSV. The
        // `rows` matrix must preserve original commas, quotes, newlines.
        let exercise = makeExercise(notes: "felt great, legs heavy\n\"interval 4\"")
        let rows = WorkoutCSV.rows(exercises: [exercise], unit: .miles)
        #expect(rows[1][5] == "felt great, legs heavy\n\"interval 4\"")
    }

    @Test func encodeStringStillProducesEscapedCSV() {
        // Refactor regression check: the CSV consumer still gets quoted
        // commas/quotes via `escape`, even though `rows` is now the
        // shared underlying producer.
        let exercise = makeExercise(notes: "comma, here")
        let csv = WorkoutCSV.encode(exercises: [exercise], unit: .miles)
        #expect(csv.contains("\"comma, here\""))
    }
}

// MARK: - GoogleSheetsSyncCoordinator Tests

@MainActor
struct GoogleSheetsSyncCoordinatorTests {

    private func makeContainerWithConfig(
        enabled: Bool = false,
        spreadsheetID: String = ""
    ) -> ModelContainer {
        let container = ModelContainerFactory.makePreviewContainer()
        let context = ModelContext(container)
        let config = AppConfiguration(
            useMetricUnits: false,
            googleSheetsSyncEnabled: enabled,
            googleSheetsSpreadsheetID: spreadsheetID
        )
        context.insert(config)
        try? context.save()
        return container
    }

    /// Inserts a single completed exercise (planned + recorded inline) so the
    /// sync emits exactly one data row.
    private func insertWorkout(in container: ModelContainer, name: String = "Run") {
        let context = ModelContext(container)
        context.insert(Exercise(
            name: name,
            type: .run,
            durationSeconds: 1800,
            distanceMiles: 3.0,
            date: Date(),
            workout: Workout(durationSeconds: 1800, distanceMiles: 3.0, feltRating: 6)
        ))
        try? context.save()
    }

    @Test func attachReadsDisabledStateAsIdle() async {
        let container = makeContainerWithConfig(enabled: false)
        let api = StubGoogleSheetsAPI(isAuthorized: false)
        let coordinator = GoogleSheetsSyncCoordinator(api: api, debounceSeconds: 1)

        await coordinator.attach(modelContainer: container)

        #expect(coordinator.isEnabled == false)
        #expect(coordinator.spreadsheetID == nil)
        #expect(coordinator.status == .idle)
    }

    @Test func attachWithEnabledAndAuthorizedStaysIdle() async {
        let container = makeContainerWithConfig(enabled: true, spreadsheetID: "sheet-A")
        let api = StubGoogleSheetsAPI(isAuthorized: true)
        let coordinator = GoogleSheetsSyncCoordinator(api: api, debounceSeconds: 1)

        await coordinator.attach(modelContainer: container)

        #expect(coordinator.isEnabled == true)
        #expect(coordinator.spreadsheetID == "sheet-A")
        #expect(coordinator.status == .idle)
    }

    @Test func attachWithEnabledButUnauthorizedSurfacesNeedsAuth() async {
        let container = makeContainerWithConfig(enabled: true, spreadsheetID: "sheet-A")
        let api = StubGoogleSheetsAPI(isAuthorized: false)
        let coordinator = GoogleSheetsSyncCoordinator(api: api, debounceSeconds: 1)

        await coordinator.attach(modelContainer: container)

        #expect(coordinator.status == .needsAuth)
    }

    @Test func enableCreatesSpreadsheetAndSyncsImmediately() async throws {
        let container = makeContainerWithConfig(enabled: false)
        insertWorkout(in: container, name: "Initial")
        let api = StubGoogleSheetsAPI(isAuthorized: false)
        let coordinator = GoogleSheetsSyncCoordinator(api: api, debounceSeconds: 1)
        await coordinator.attach(modelContainer: container)

        try await coordinator.enable()

        #expect(coordinator.isEnabled == true)
        #expect(coordinator.spreadsheetID != nil)
        #expect(api.createdSpreadsheetIDs.count == 1)
        #expect(api.overwriteCount == 1)
        // First row is header, second row is the inserted workout.
        #expect(api.lastWrittenRows?.count == 2)
        if case .success = coordinator.status {
            // ok
        } else {
            Issue.record("expected status .success after enable, got \(coordinator.status)")
        }

        // Persisted state should reflect enable so a fresh container/process
        // restores correctly via `attach`.
        let context = ModelContext(container)
        let config = try context.fetch(FetchDescriptor<AppConfiguration>()).first
        #expect(config?.googleSheetsSyncEnabled == true)
        #expect(config?.googleSheetsSpreadsheetID == coordinator.spreadsheetID)
    }

    @Test func reauthorizeRunsAuthorizeAndImmediateSync() async throws {
        // Simulates a CloudKit-restored device: enabled=true and
        // spreadsheetID set in AppConfiguration, but the API starts
        // unauthorized (no Keychain token). The user taps the
        // "Sign in to resume" menu item which calls `reauthorize`.
        let container = makeContainerWithConfig(enabled: true, spreadsheetID: "sheet-restored")
        insertWorkout(in: container)
        let api = StubGoogleSheetsAPI(isAuthorized: false)
        let coordinator = GoogleSheetsSyncCoordinator(api: api, debounceSeconds: 1)
        await coordinator.attach(modelContainer: container)
        #expect(coordinator.status == .needsAuth)

        try await coordinator.reauthorize()

        #expect(api.isAuthorized == true)
        #expect(api.overwriteCount == 1)
        #expect(api.lastSpreadsheetID == "sheet-restored",
                "reauthorize must reuse the existing spreadsheet, not create a new one")
        #expect(api.createdSpreadsheetIDs.isEmpty,
                "reauthorize must not create a new spreadsheet")
        if case .success = coordinator.status {
            // ok
        } else {
            Issue.record("expected status .success after reauthorize, got \(coordinator.status)")
        }
    }

    @Test func reauthorizeThrowsWhenSyncNotEnabled() async {
        let container = makeContainerWithConfig(enabled: false)
        let api = StubGoogleSheetsAPI(isAuthorized: false)
        let coordinator = GoogleSheetsSyncCoordinator(api: api, debounceSeconds: 1)
        await coordinator.attach(modelContainer: container)

        do {
            try await coordinator.reauthorize()
            Issue.record("expected reauthorize to throw when not enabled")
        } catch {
            // expected
        }
    }

    @Test func disableClearsStateAndSignsOut() async throws {
        let container = makeContainerWithConfig(enabled: true, spreadsheetID: "sheet-A")
        let api = StubGoogleSheetsAPI(isAuthorized: true)
        let coordinator = GoogleSheetsSyncCoordinator(api: api, debounceSeconds: 1)
        await coordinator.attach(modelContainer: container)

        coordinator.disable()

        #expect(coordinator.isEnabled == false)
        #expect(coordinator.spreadsheetID == nil)
        #expect(coordinator.status == .idle)
        #expect(api.isAuthorized == false)

        // Persisted state cleared.
        let context = ModelContext(container)
        let config = try context.fetch(FetchDescriptor<AppConfiguration>()).first
        #expect(config?.googleSheetsSyncEnabled == false)
        #expect(config?.googleSheetsSpreadsheetID == "")
    }

    @Test func requestSyncIsNoOpWhenDisabled() async {
        let container = makeContainerWithConfig(enabled: false)
        let api = StubGoogleSheetsAPI(isAuthorized: true)
        let coordinator = GoogleSheetsSyncCoordinator(api: api, debounceSeconds: 1)
        await coordinator.attach(modelContainer: container)

        coordinator.requestSync()
        try? await Task.sleep(nanoseconds: 1_500_000_000)

        #expect(api.overwriteCount == 0)
    }

    @Test func requestSyncSetsSyncingImmediately() async throws {
        let container = makeContainerWithConfig(enabled: true, spreadsheetID: "sheet-A")
        insertWorkout(in: container)
        let api = StubGoogleSheetsAPI(isAuthorized: true)
        let coordinator = GoogleSheetsSyncCoordinator(api: api, debounceSeconds: 1)
        await coordinator.attach(modelContainer: container)

        coordinator.requestSync()

        // Pending state should be visible immediately, before the debounce
        // sleep elapses, so the History tab can render the yellow dot +
        // "syncing…" indicator during the wait.
        #expect(coordinator.status == .syncing)

        try? await Task.sleep(nanoseconds: 1_400_000_000)

        if case .success = coordinator.status {
            // ok
        } else {
            Issue.record("expected status .success after debounce + upload, got \(coordinator.status)")
        }
        #expect(api.overwriteCount == 1)
    }

    @Test func multipleRequestSyncCallsCollapseToOneSync() async throws {
        let container = makeContainerWithConfig(enabled: true, spreadsheetID: "sheet-A")
        insertWorkout(in: container)
        let api = StubGoogleSheetsAPI(isAuthorized: true)
        // Use a 1-second debounce so the test runs in ~1.5 seconds rather than 30.
        let coordinator = GoogleSheetsSyncCoordinator(api: api, debounceSeconds: 1)
        await coordinator.attach(modelContainer: container)

        coordinator.requestSync()
        coordinator.requestSync()
        coordinator.requestSync()
        // Wait past the debounce window plus a small safety margin.
        try? await Task.sleep(nanoseconds: 1_400_000_000)

        #expect(api.overwriteCount == 1, "3 rapid requestSync calls should produce 1 upload")
    }

    @Test func syncNowBypassesDebounce() async throws {
        let container = makeContainerWithConfig(enabled: true, spreadsheetID: "sheet-A")
        insertWorkout(in: container)
        let api = StubGoogleSheetsAPI(isAuthorized: true)
        let coordinator = GoogleSheetsSyncCoordinator(api: api, debounceSeconds: 30)
        await coordinator.attach(modelContainer: container)

        await coordinator.syncNow()

        #expect(api.overwriteCount == 1)
        if case .success = coordinator.status {
            // ok
        } else {
            Issue.record("expected status .success after syncNow")
        }
    }

    @Test func syncNowFailureSurfacesAsFailedStatus() async throws {
        let container = makeContainerWithConfig(enabled: true, spreadsheetID: "sheet-A")
        insertWorkout(in: container)
        let api = StubGoogleSheetsAPI(isAuthorized: true)
        api.nextOverwriteError = GoogleSheetsSyncError.invalidResponse("test failure")
        let coordinator = GoogleSheetsSyncCoordinator(api: api, debounceSeconds: 1)
        await coordinator.attach(modelContainer: container)

        await coordinator.syncNow()

        if case .failed = coordinator.status {
            // ok
        } else {
            Issue.record("expected .failed status after API error, got \(coordinator.status)")
        }
    }

    @Test func syncNowSurfacesNeedsAuthWhenAPIDeauthorized() async {
        let container = makeContainerWithConfig(enabled: true, spreadsheetID: "sheet-A")
        let api = StubGoogleSheetsAPI(isAuthorized: false)
        let coordinator = GoogleSheetsSyncCoordinator(api: api, debounceSeconds: 1)
        await coordinator.attach(modelContainer: container)

        await coordinator.syncNow()

        #expect(coordinator.status == .needsAuth)
        #expect(api.overwriteCount == 0)
    }

    @Test func syncNowMapsNotAuthorizedMidSyncToNeedsAuth() async {
        // Token expired *after* `isAuthorized` passed (the API layer's refresh
        // attempt throws `.notAuthorized` from inside `overwriteSheet`). This
        // must surface as `.needsAuth` so the menu offers "Sign in to resume",
        // not a "Retry" that would just fail again.
        let container = makeContainerWithConfig(enabled: true, spreadsheetID: "sheet-A")
        insertWorkout(in: container)
        let api = StubGoogleSheetsAPI(isAuthorized: true)
        api.nextOverwriteError = GoogleSheetsSyncError.notAuthorized
        let coordinator = GoogleSheetsSyncCoordinator(api: api, debounceSeconds: 1)
        await coordinator.attach(modelContainer: container)

        await coordinator.syncNow()

        #expect(coordinator.status == .needsAuth)
    }

    @Test func syncNowMaps401And403ToNeedsAuth() async {
        for status in [401, 403] {
            let container = makeContainerWithConfig(enabled: true, spreadsheetID: "sheet-A")
            insertWorkout(in: container)
            let api = StubGoogleSheetsAPI(isAuthorized: true)
            api.nextOverwriteError = GoogleSheetsSyncError.httpError(status: status, body: "unauthorized")
            let coordinator = GoogleSheetsSyncCoordinator(api: api, debounceSeconds: 1)
            await coordinator.attach(modelContainer: container)

            await coordinator.syncNow()

            #expect(coordinator.status == .needsAuth, "HTTP \(status) should map to .needsAuth")
        }
    }

    @Test func syncNowKeepsNonAuthHttpErrorAsFailed() async {
        // A server-side 500 is transient, not an auth problem — it must stay
        // `.failed` so the menu offers "Retry", not a pointless re-sign-in.
        let container = makeContainerWithConfig(enabled: true, spreadsheetID: "sheet-A")
        insertWorkout(in: container)
        let api = StubGoogleSheetsAPI(isAuthorized: true)
        api.nextOverwriteError = GoogleSheetsSyncError.httpError(status: 500, body: "server error")
        let coordinator = GoogleSheetsSyncCoordinator(api: api, debounceSeconds: 1)
        await coordinator.attach(modelContainer: container)

        await coordinator.syncNow()

        if case .failed = coordinator.status {
            // ok
        } else {
            Issue.record("expected .failed for HTTP 500, got \(coordinator.status)")
        }
    }

    @Test func reauthorizeForcesInteractiveEvenWhenSessionLooksAuthorized() async throws {
        // Simulates a server-side revoke where the local session still *looks*
        // authorized (isAuthorized == true) because the access token hasn't
        // expired yet. Reconnect must force a fresh interactive sign-in, not
        // silently trust the cached session (which would 401 and loop back to
        // .needsAuth without ever prompting).
        let container = makeContainerWithConfig(enabled: true, spreadsheetID: "sheet-A")
        insertWorkout(in: container)
        let api = StubGoogleSheetsAPI(isAuthorized: true)
        let coordinator = GoogleSheetsSyncCoordinator(api: api, debounceSeconds: 1)
        await coordinator.attach(modelContainer: container)

        try await coordinator.reauthorize()

        #expect(api.reauthorizeInteractivelyCount == 1,
                "reconnect must force interactive sign-in, not reuse the cached session")
        #expect(api.lastSpreadsheetID == "sheet-A")
        #expect(api.createdSpreadsheetIDs.isEmpty)
    }

    @Test func reconnectAfterMidSyncExpiryReusesExistingSheet() async throws {
        // Full reconnect flow: a sync fails mid-flight with an expired token
        // (→ .needsAuth), then the user re-auths via `reauthorize`, which must
        // resume syncing to the *existing* spreadsheet rather than create a
        // new one (the original duplicate-file bug).
        let container = makeContainerWithConfig(enabled: true, spreadsheetID: "sheet-existing")
        insertWorkout(in: container)
        let api = StubGoogleSheetsAPI(isAuthorized: true)
        api.nextOverwriteError = GoogleSheetsSyncError.notAuthorized
        let coordinator = GoogleSheetsSyncCoordinator(api: api, debounceSeconds: 1)
        await coordinator.attach(modelContainer: container)

        await coordinator.syncNow()
        #expect(coordinator.status == .needsAuth)

        try await coordinator.reauthorize()

        #expect(api.lastSpreadsheetID == "sheet-existing",
                "reconnect must reuse the existing spreadsheet, not create a new one")
        #expect(api.createdSpreadsheetIDs.isEmpty,
                "reconnect must not create a new spreadsheet")
        if case .success = coordinator.status {
            // ok
        } else {
            Issue.record("expected .success after reconnect, got \(coordinator.status)")
        }
    }
}

// MARK: - AppConfiguration Sheets Sync Defaults

struct AppConfigurationSheetsSyncDefaultsTests {

    @Test func defaultsHaveSyncDisabledAndEmptyID() {
        let config = AppConfiguration()
        #expect(config.googleSheetsSyncEnabled == false)
        #expect(config.googleSheetsSpreadsheetID == "")
    }

    @Test func explicitInitPreservesValues() {
        let config = AppConfiguration(
            useMetricUnits: true,
            googleSheetsSyncEnabled: true,
            googleSheetsSpreadsheetID: "abc-123"
        )
        #expect(config.useMetricUnits == true)
        #expect(config.googleSheetsSyncEnabled == true)
        #expect(config.googleSheetsSpreadsheetID == "abc-123")
    }
}

// MARK: - WeightRecordingType Tests

struct WeightRecordingTypeTests {

    @Test func hasAllFiveRecordingTypes() {
        #expect(WeightRecordingType.allCases.count == 5)
        #expect(WeightRecordingType.allCases.contains(.maxWeight))
        #expect(WeightRecordingType.allCases.contains(.averageWeight))
        #expect(WeightRecordingType.allCases.contains(.firstSetWeight))
        #expect(WeightRecordingType.allCases.contains(.lastSetWeight))
        #expect(WeightRecordingType.allCases.contains(.minWeight))
    }

    @Test func allCasesHaveShortLabels() {
        for type in WeightRecordingType.allCases {
            #expect(!type.shortLabel.isEmpty, "\(type) should have a shortLabel")
        }
    }

    @Test func codableRoundTrip() throws {
        for type in WeightRecordingType.allCases {
            let data = try JSONEncoder().encode(type)
            let decoded = try JSONDecoder().decode(WeightRecordingType.self, from: data)
            #expect(decoded == type)
        }
    }
}

// MARK: - MuscleGroup Tests

struct MuscleGroupTests {

    @Test func codableRoundTrip() throws {
        for group in MuscleGroup.allCases {
            let data = try JSONEncoder().encode(group)
            let decoded = try JSONDecoder().decode(MuscleGroup.self, from: data)
            #expect(decoded == group)
        }
    }

    @Test func unknownRawValueDecodesAsOther() throws {
        let data = Data("\"Neck\"".utf8)
        let decoded = try JSONDecoder().decode(MuscleGroup.self, from: data)
        #expect(decoded == .other)
    }
}

// MARK: - StrengthWorkout Tests

struct StrengthWorkoutTests {

    @Test func defaultValues() {
        let workout = StrengthWorkout()
        #expect(workout.weightPounds == 0.0)
        #expect(workout.recordingType == .maxWeight)
        #expect(workout.notes == "")
    }

    @Test func explicitInitPreservesValues() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let workout = StrengthWorkout(
            date: date,
            weightPounds: 225.0,
            recordingType: .averageWeight,
            notes: "Felt strong"
        )
        #expect(workout.date == date)
        #expect(workout.weightPounds == 225.0)
        #expect(workout.recordingType == .averageWeight)
        #expect(workout.notes == "Felt strong")
    }

    @Test func codableRoundTrip() throws {
        let workout = StrengthWorkout(weightPounds: 135.5, recordingType: .firstSetWeight, notes: "warmup")
        let data = try JSONEncoder().encode(workout)
        let decoded = try JSONDecoder().decode(StrengthWorkout.self, from: data)
        #expect(decoded == workout)
    }
}

// MARK: - StrengthExercise Tests

struct StrengthExerciseTests {

    @Test func defaultValues() {
        let exercise = StrengthExercise(name: "Bench Press")
        #expect(exercise.name == "Bench Press")
        #expect(exercise.libraryExerciseID == nil)
        #expect(exercise.muscleGroup == .other)
        #expect(exercise.weekdayIndex == 0)
        #expect(exercise.isOffloaded == false)
        #expect(exercise.sortOrder == 0)
        #expect(exercise.notes == "")
        #expect(exercise.plannedSets == nil)
        #expect(exercise.plannedReps == nil)
        #expect(exercise.plannedSummary == nil)
        #expect(exercise.workouts.isEmpty)
        #expect(exercise.latestWorkout == nil)
    }

    @Test func plannedSummaryFormatsSetsByReps() {
        let exercise = StrengthExercise(name: "Bench Press", plannedSets: 3, plannedReps: 8)
        #expect(exercise.plannedSummary == "3×8")
    }

    @Test func plannedSummaryNilWhenEitherFieldMissing() {
        let setsOnly = StrengthExercise(name: "A", plannedSets: 3)
        #expect(setsOnly.plannedSummary == nil)
        let repsOnly = StrengthExercise(name: "B", plannedReps: 8)
        #expect(repsOnly.plannedSummary == nil)
    }

    @Test func plannedFieldsPersistInModelContainer() throws {
        let container = ModelContainerFactory.makePreviewContainer()
        let context = ModelContext(container)
        context.insert(StrengthExercise(name: "Front Squat", plannedSets: 5, plannedReps: 5))
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<StrengthExercise>())
        #expect(fetched.first?.plannedSets == 5)
        #expect(fetched.first?.plannedReps == 5)
        #expect(fetched.first?.plannedSummary == "5×5")
    }

    @Test func explicitInitPreservesValues() {
        let exercise = StrengthExercise(
            name: "Back Squat",
            libraryExerciseID: "back-squat",
            muscleGroup: .quads,
            weekdayIndex: 3,
            isOffloaded: true,
            sortOrder: 2,
            notes: "pause reps"
        )
        #expect(exercise.libraryExerciseID == "back-squat")
        #expect(exercise.muscleGroup == .quads)
        #expect(exercise.weekdayIndex == 3)
        #expect(exercise.isOffloaded == true)
        #expect(exercise.sortOrder == 2)
        #expect(exercise.notes == "pause reps")
    }

    @Test func workoutsRoundTripThroughBackingData() {
        let exercise = StrengthExercise(name: "Deadlift", muscleGroup: .back)
        let first = StrengthWorkout(weightPounds: 315, recordingType: .maxWeight)
        let second = StrengthWorkout(weightPounds: 275, recordingType: .averageWeight)
        exercise.workouts = [first, second]
        #expect(exercise.workouts == [first, second])
        exercise.workouts = []
        #expect(exercise.workouts.isEmpty)
    }

    @Test func latestWorkoutReturnsMostRecentByDate() {
        let exercise = StrengthExercise(name: "Overhead Press", muscleGroup: .shoulders)
        let older = StrengthWorkout(date: Date(timeIntervalSince1970: 1_000), weightPounds: 95)
        let newer = StrengthWorkout(date: Date(timeIntervalSince1970: 2_000), weightPounds: 105)
        exercise.workouts = [newer, older]
        #expect(exercise.latestWorkout == newer)
    }

    @Test func persistsInModelContainer() throws {
        let container = ModelContainerFactory.makePreviewContainer()
        let context = ModelContext(container)
        let exercise = StrengthExercise(
            name: "Barbell Row",
            libraryExerciseID: "barbell-row",
            muscleGroup: .back,
            weekdayIndex: 5,
            sortOrder: 1,
            workouts: [StrengthWorkout(weightPounds: 185, recordingType: .lastSetWeight)]
        )
        context.insert(exercise)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<StrengthExercise>())
        #expect(fetched.count == 1)
        #expect(fetched.first?.name == "Barbell Row")
        #expect(fetched.first?.weekdayIndex == 5)
        #expect(fetched.first?.workouts.first?.weightPounds == 185)
        #expect(fetched.first?.workouts.first?.recordingType == .lastSetWeight)
    }
}

// MARK: - Double+Weight Tests

struct DoubleWeightTests {

    @Test func imperialDisplayIsUnchanged() {
        #expect(185.0.toDisplayWeight(metric: false) == 185.0)
        #expect(185.0.fromDisplayWeight(metric: false) == 185.0)
    }

    @Test func metricConversionRoundTrips() {
        let pounds = 225.0
        let kg = pounds.toDisplayWeight(metric: true)
        #expect(abs(kg - 102.058) < 0.01)
        #expect(abs(kg.fromDisplayWeight(metric: true) - pounds) < 0.0001)
    }

    @Test func formattedWeightDropsDecimalForWholeNumbers() {
        #expect(185.0.formattedWeight(metric: false) == "185 lb")
    }

    @Test func formattedWeightShowsOneDecimalOtherwise() {
        #expect(185.0.formattedWeight(metric: true) == "83.9 kg")
    }
}

// MARK: - LibraryExercise Tests

struct LibraryExerciseTests {

    @Test func decodesFullEntry() throws {
        let json = """
        {
            "id": "test-press",
            "name": "Test Press",
            "description": "A test movement.",
            "muscleGroup": "Chest",
            "secondaryMuscleGroups": ["Triceps", "Shoulders"],
            "equipment": "Barbell",
            "difficulty": "Intermediate"
        }
        """
        let entry = try JSONDecoder().decode(LibraryExercise.self, from: Data(json.utf8))
        #expect(entry.id == "test-press")
        #expect(entry.name == "Test Press")
        #expect(entry.details == "A test movement.")
        #expect(entry.muscleGroup == .chest)
        #expect(entry.secondaryMuscleGroups == [.triceps, .shoulders])
        #expect(entry.equipment == "Barbell")
        #expect(entry.difficulty == "Intermediate")
    }

    @Test func secondaryMuscleGroupsDefaultsToEmpty() throws {
        let json = """
        {
            "id": "test-curl",
            "name": "Test Curl",
            "description": "A test curl.",
            "muscleGroup": "Biceps",
            "equipment": "Dumbbells",
            "difficulty": "Beginner"
        }
        """
        let entry = try JSONDecoder().decode(LibraryExercise.self, from: Data(json.utf8))
        #expect(entry.secondaryMuscleGroups.isEmpty)
    }

    @Test func unknownMuscleGroupDecodesAsOther() throws {
        let json = """
        {
            "id": "future-move",
            "name": "Future Move",
            "description": "From a newer server catalog.",
            "muscleGroup": "Neck",
            "equipment": "Machine",
            "difficulty": "Beginner"
        }
        """
        let entry = try JSONDecoder().decode(LibraryExercise.self, from: Data(json.utf8))
        #expect(entry.muscleGroup == .other)
    }
}

// MARK: - UserLibraryExercise Tests

struct UserLibraryExerciseTests {

    @Test func defaultValues() {
        let exercise = UserLibraryExercise(name: "Weighted Dips")
        #expect(exercise.id.hasPrefix(UserLibraryExercise.idPrefix))
        #expect(exercise.name == "Weighted Dips")
        #expect(exercise.details == "")
        #expect(exercise.muscleGroup == .other)
        #expect(exercise.secondaryMuscleGroups.isEmpty)
        #expect(exercise.equipment == "")
        #expect(exercise.difficulty == "Beginner")
    }

    @Test func generatedIDsAreUnique() {
        let first = UserLibraryExercise(name: "A")
        let second = UserLibraryExercise(name: "A")
        #expect(first.id != second.id)
    }

    @Test func explicitInitPreservesValues() {
        let exercise = UserLibraryExercise(
            name: "Landmine Press",
            details: "Press the barbell end from the shoulder.",
            muscleGroup: .shoulders,
            secondaryMuscleGroups: [.triceps, .core],
            equipment: "Barbell",
            difficulty: "Intermediate"
        )
        #expect(exercise.name == "Landmine Press")
        #expect(exercise.details == "Press the barbell end from the shoulder.")
        #expect(exercise.muscleGroup == .shoulders)
        #expect(exercise.secondaryMuscleGroups == [.triceps, .core])
        #expect(exercise.equipment == "Barbell")
        #expect(exercise.difficulty == "Intermediate")
    }

    @Test func secondaryMuscleGroupsRoundTripThroughBackingData() {
        let exercise = UserLibraryExercise(name: "Zercher Squat")
        exercise.secondaryMuscleGroups = [.core, .glutes]
        #expect(exercise.secondaryMuscleGroups == [.core, .glutes])
        exercise.secondaryMuscleGroups = []
        #expect(exercise.secondaryMuscleGroups.isEmpty)
    }

    @Test func libraryEntryMapsAllFields() {
        let exercise = UserLibraryExercise(
            name: "Landmine Press",
            details: "Press the barbell end from the shoulder.",
            muscleGroup: .shoulders,
            secondaryMuscleGroups: [.triceps],
            equipment: "Barbell",
            difficulty: "Advanced"
        )
        let entry = exercise.libraryEntry
        #expect(entry.id == exercise.id)
        #expect(entry.name == "Landmine Press")
        #expect(entry.details == "Press the barbell end from the shoulder.")
        #expect(entry.muscleGroup == .shoulders)
        #expect(entry.secondaryMuscleGroups == [.triceps])
        #expect(entry.equipment == "Barbell")
        #expect(entry.difficulty == "Advanced")
    }

    @Test func persistsInModelContainer() throws {
        let container = ModelContainerFactory.makePreviewContainer()
        let context = ModelContext(container)
        let exercise = UserLibraryExercise(
            name: "Sled Push",
            details: "Drive the sled forward.",
            muscleGroup: .quads,
            secondaryMuscleGroups: [.glutes, .calves],
            equipment: "Sled",
            difficulty: "Intermediate"
        )
        context.insert(exercise)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<UserLibraryExercise>())
        #expect(fetched.count == 1)
        #expect(fetched.first?.name == "Sled Push")
        #expect(fetched.first?.muscleGroup == .quads)
        #expect(fetched.first?.secondaryMuscleGroups == [.glutes, .calves])
        #expect(fetched.first?.equipment == "Sled")
    }

    @Test func isUserCreatedDetectsPrefix() {
        let user = UserLibraryExercise(name: "Custom Move")
        #expect(user.libraryEntry.isUserCreated)
        let bundled = LibraryExercise(
            id: "barbell-bench-press", name: "Barbell Bench Press", details: "d",
            muscleGroup: .chest, equipment: "Barbell", difficulty: "Intermediate"
        )
        #expect(!bundled.isUserCreated)
    }
}

// MARK: - Exercise Library Provider Tests

/// Test double returning a fixed list of entries, or throwing.
private struct FixedLibraryProvider: ExerciseLibraryProvider {
    let entries: [LibraryExercise]
    var shouldThrow = false

    func loadExercises() async throws -> [LibraryExercise] {
        if shouldThrow { throw ExerciseLibraryError.missingBundledCatalog }
        return entries
    }
}

struct ExerciseLibraryProviderTests {

    /// Helper building a minimal library entry.
    private func entry(id: String, name: String) -> LibraryExercise {
        LibraryExercise(
            id: id, name: name, details: "d",
            muscleGroup: .chest, equipment: "Barbell", difficulty: "Beginner"
        )
    }

    @Test func bundledCatalogLoadsAtLeastOneHundredUniqueExercises() async throws {
        let provider = BundledExerciseLibraryProvider()
        let exercises = try await provider.loadExercises()
        #expect(exercises.count >= 100)
        let ids = Set(exercises.map(\.id))
        #expect(ids.count == exercises.count, "library ids must be unique")
        for exercise in exercises {
            #expect(!exercise.name.isEmpty)
            #expect(!exercise.details.isEmpty)
            #expect(exercise.muscleGroup != .other, "bundled entries should have a known muscle group")
            #expect(!exercise.id.hasPrefix(UserLibraryExercise.idPrefix), "bundled ids must never collide with user entries")
        }
    }

    @Test func missingBundledCatalogThrows() async {
        let provider = BundledExerciseLibraryProvider(resourceName: "DoesNotExist")
        await #expect(throws: ExerciseLibraryError.missingBundledCatalog) {
            _ = try await provider.loadExercises()
        }
    }

    @Test func compositeMergesLaterProvidersOverEarlier() async throws {
        let bundled = FixedLibraryProvider(entries: [
            entry(id: "a", name: "Bundled A"),
            entry(id: "b", name: "Bundled B"),
        ])
        let server = FixedLibraryProvider(entries: [
            entry(id: "b", name: "Server B Override"),
            entry(id: "c", name: "Server C"),
        ])
        let composite = CompositeExerciseLibraryProvider(providers: [bundled, server])
        let merged = try await composite.loadExercises()
        #expect(merged.count == 3)
        #expect(merged.first(where: { $0.id == "b" })?.name == "Server B Override")
    }

    @Test func compositeSkipsFailingProviders() async throws {
        let good = FixedLibraryProvider(entries: [entry(id: "a", name: "A")])
        let bad = FixedLibraryProvider(entries: [], shouldThrow: true)
        let composite = CompositeExerciseLibraryProvider(providers: [good, bad])
        let merged = try await composite.loadExercises()
        #expect(merged.count == 1)
    }

    @Test func userLocalProviderReturnsEmptyForFreshStore() async throws {
        let container = ModelContainerFactory.makePreviewContainer()
        let provider = UserLocalExerciseLibraryProvider(container: container)
        let exercises = try await provider.loadExercises()
        #expect(exercises.isEmpty)
    }

    @Test func userLocalProviderReturnsMappedEntries() async throws {
        let container = ModelContainerFactory.makePreviewContainer()
        let context = ModelContext(container)
        context.insert(UserLibraryExercise(name: "Sled Push", muscleGroup: .quads, equipment: "Sled"))
        context.insert(UserLibraryExercise(name: "Landmine Press", muscleGroup: .shoulders))
        try context.save()

        let provider = UserLocalExerciseLibraryProvider(container: container)
        let exercises = try await provider.loadExercises()
        #expect(exercises.count == 2)
        let names = Set(exercises.map(\.name))
        #expect(names == ["Sled Push", "Landmine Press"])
        let allUserCreated = exercises.allSatisfy(\.isUserCreated)
        #expect(allUserCreated)
        let sledPush = exercises.first(where: { $0.name == "Sled Push" })
        #expect(sledPush?.muscleGroup == .quads)
        #expect(sledPush?.equipment == "Sled")
    }

    @Test func compositeMergesBundledAndUserEntries() async throws {
        let container = ModelContainerFactory.makePreviewContainer()
        let context = ModelContext(container)
        context.insert(UserLibraryExercise(name: "Custom Carry", muscleGroup: .forearms))
        try context.save()

        let bundled = FixedLibraryProvider(entries: [entry(id: "a", name: "Bundled A")])
        let composite = CompositeExerciseLibraryProvider(providers: [
            bundled,
            UserLocalExerciseLibraryProvider(container: container),
        ])
        let merged = try await composite.loadExercises()
        let names = merged.map(\.name)
        #expect(names == ["Bundled A", "Custom Carry"], "merged entries sort by name")
    }
}

// MARK: - UserLibraryEditor Tests

struct UserLibraryEditorTests {

    @Test func makeExerciseTrimsAndPreservesFields() throws {
        let exercise = try #require(UserLibraryEditor.makeExercise(
            name: "  Landmine Press  ",
            details: " Press the barbell end. ",
            muscleGroup: .shoulders,
            secondaryMuscleGroups: [.triceps, .core],
            equipment: " Barbell ",
            difficulty: "Intermediate"
        ))
        #expect(exercise.name == "Landmine Press")
        #expect(exercise.details == "Press the barbell end.")
        #expect(exercise.muscleGroup == .shoulders)
        #expect(exercise.secondaryMuscleGroups == [.triceps, .core])
        #expect(exercise.equipment == "Barbell")
        #expect(exercise.difficulty == "Intermediate")
    }

    @Test func makeExerciseRejectsBlankName() {
        let exercise = UserLibraryEditor.makeExercise(
            name: "   \n ",
            details: "d",
            muscleGroup: .chest,
            secondaryMuscleGroups: [],
            equipment: "",
            difficulty: "Beginner"
        )
        #expect(exercise == nil)
    }

    @Test func deleteRemovesOnlyMatchingUserEntry() throws {
        let container = ModelContainerFactory.makePreviewContainer()
        let context = ModelContext(container)
        let keep = UserLibraryExercise(name: "Keep Me")
        let remove = UserLibraryExercise(name: "Remove Me")
        context.insert(keep)
        context.insert(remove)
        try context.save()

        try UserLibraryEditor.delete(entryID: remove.id, in: context)

        let fetched = try context.fetch(FetchDescriptor<UserLibraryExercise>())
        #expect(fetched.count == 1)
        #expect(fetched.first?.name == "Keep Me")
    }

    @Test func deleteIgnoresBundledIDs() throws {
        let container = ModelContainerFactory.makePreviewContainer()
        let context = ModelContext(container)
        context.insert(UserLibraryExercise(name: "Untouched"))
        try context.save()

        try UserLibraryEditor.delete(entryID: "barbell-bench-press", in: context)

        let fetched = try context.fetch(FetchDescriptor<UserLibraryExercise>())
        #expect(fetched.count == 1)
    }

    @Test func madeExerciseSurfacesThroughProviderAfterSave() async throws {
        let container = ModelContainerFactory.makePreviewContainer()
        let context = ModelContext(container)
        let exercise = try #require(UserLibraryEditor.makeExercise(
            name: "Sled Push",
            details: "Drive forward.",
            muscleGroup: .quads,
            secondaryMuscleGroups: [.glutes],
            equipment: "Sled",
            difficulty: "Intermediate"
        ))
        context.insert(exercise)
        try context.save()

        let provider = UserLocalExerciseLibraryProvider(container: container)
        let loaded = try await provider.loadExercises()
        #expect(loaded.count == 1)
        #expect(loaded.first?.name == "Sled Push")
        #expect(loaded.first?.secondaryMuscleGroups == [.glutes])
        #expect(loaded.first?.isUserCreated == true)
    }
}

// MARK: - StrengthBoardPlanner Tests

struct StrengthBoardPlannerTests {

    /// Builds a board exercise in a specific lane position.
    private func exercise(_ name: String, day: Int, offloaded: Bool = false, order: Int) -> StrengthExercise {
        StrengthExercise(name: name, weekdayIndex: day, isOffloaded: offloaded, sortOrder: order)
    }

    @Test func laneFiltersAndSortsByOrder() {
        let a = exercise("A", day: 1, order: 1)
        let b = exercise("B", day: 1, order: 0)
        let other = exercise("C", day: 2, order: 0)
        let offloaded = exercise("D", day: 1, offloaded: true, order: 0)
        let lane = StrengthBoardPlanner.lane([a, b, other, offloaded], day: 1, offloaded: false)
        #expect(lane.map(\.name) == ["B", "A"])
    }

    @Test func nextSortOrderAppendsAfterLast() {
        let a = exercise("A", day: 1, order: 0)
        let b = exercise("B", day: 1, order: 1)
        #expect(StrengthBoardPlanner.nextSortOrder([a, b], day: 1, offloaded: false) == 2)
        #expect(StrengthBoardPlanner.nextSortOrder([a, b], day: 4, offloaded: false) == 0)
    }

    @Test func reorderWithinLaneInsertsBeforeTarget() {
        let a = exercise("A", day: 1, order: 0)
        let b = exercise("B", day: 1, order: 1)
        let c = exercise("C", day: 1, order: 2)
        let all = [a, b, c]
        // Move C before A: expect C, A, B
        StrengthBoardPlanner.move(c, toDay: 1, offloaded: false, before: a, in: all)
        let lane = StrengthBoardPlanner.lane(all, day: 1, offloaded: false)
        #expect(lane.map(\.name) == ["C", "A", "B"])
        #expect(lane.map(\.sortOrder) == [0, 1, 2])
    }

    @Test func moveWithoutTargetAppendsAtEnd() {
        let a = exercise("A", day: 1, order: 0)
        let b = exercise("B", day: 1, order: 1)
        let all = [a, b]
        StrengthBoardPlanner.move(a, toDay: 1, offloaded: false, before: nil, in: all)
        let lane = StrengthBoardPlanner.lane(all, day: 1, offloaded: false)
        #expect(lane.map(\.name) == ["B", "A"])
    }

    @Test func moveAcrossDaysUpdatesWeekdayIndex() {
        let a = exercise("A", day: 1, order: 0)
        let b = exercise("B", day: 3, order: 0)
        let all = [a, b]
        StrengthBoardPlanner.move(a, toDay: 3, offloaded: false, before: b, in: all)
        #expect(a.weekdayIndex == 3)
        let lane = StrengthBoardPlanner.lane(all, day: 3, offloaded: false)
        #expect(lane.map(\.name) == ["A", "B"])
        #expect(StrengthBoardPlanner.lane(all, day: 1, offloaded: false).isEmpty)
    }

    @Test func moveToOffloadedSectionSetsFlag() {
        let a = exercise("A", day: 2, order: 0)
        let held = exercise("H", day: 2, offloaded: true, order: 0)
        let all = [a, held]
        StrengthBoardPlanner.move(a, toDay: 2, offloaded: true, before: nil, in: all)
        #expect(a.isOffloaded == true)
        let lane = StrengthBoardPlanner.lane(all, day: 2, offloaded: true)
        #expect(lane.map(\.name) == ["H", "A"])
        #expect(StrengthBoardPlanner.lane(all, day: 2, offloaded: false).isEmpty)
    }

    @Test func moveBackToActiveFromOffloaded() {
        let a = exercise("A", day: 2, offloaded: true, order: 0)
        let all = [a]
        StrengthBoardPlanner.move(a, toDay: 2, offloaded: false, before: nil, in: all)
        #expect(a.isOffloaded == false)
        #expect(StrengthBoardPlanner.lane(all, day: 2, offloaded: false).map(\.name) == ["A"])
    }
}

// MARK: - StrengthCoachExporter Tests

struct StrengthCoachExporterTests {

    @Test func snapshotCapturesExerciseFields() {
        let exercise = StrengthExercise(
            name: "Back Squat",
            muscleGroup: .quads,
            weekdayIndex: 2,
            isOffloaded: true,
            notes: "belt on top sets",
            workouts: [StrengthWorkout(weightPounds: 315, recordingType: .maxWeight)]
        )
        let snapshot = CoachStrengthExercise(from: exercise)
        #expect(snapshot.name == "Back Squat")
        #expect(snapshot.muscleGroup == "Quads")
        #expect(snapshot.weekdayIndex == 2)
        #expect(snapshot.isOffloaded == true)
        #expect(snapshot.notes == "belt on top sets")
        #expect(snapshot.workouts.count == 1)
        #expect(snapshot.workouts.first?.weightPounds == 315)
        #expect(snapshot.workouts.first?.recordingType == "Max Weight")
    }

    @Test func emptyNotesAreOmitted() {
        let exercise = StrengthExercise(
            name: "Curl",
            muscleGroup: .biceps,
            workouts: [StrengthWorkout(weightPounds: 30)]
        )
        let snapshot = CoachStrengthExercise(from: exercise)
        #expect(snapshot.notes == nil)
        #expect(snapshot.workouts.first?.notes == nil)
    }

    @Test func snapshotCapturesPlannedSetsAndReps() {
        let exercise = StrengthExercise(name: "Bench", plannedSets: 3, plannedReps: 8)
        let snapshot = CoachStrengthExercise(from: exercise)
        #expect(snapshot.plannedSets == 3)
        #expect(snapshot.plannedReps == 8)
    }

    @Test func jsonIncludesPlannedFieldsOnlyWhenSet() throws {
        let planned = StrengthExercise(name: "Bench", plannedSets: 3, plannedReps: 8)
        let plannedJSON = try StrengthCoachExporter.jsonString(from: [planned])
        #expect(plannedJSON.contains("\"plannedSets\":3"))
        #expect(plannedJSON.contains("\"plannedReps\":8"))

        let unplanned = StrengthExercise(name: "Curl")
        let unplannedJSON = try StrengthCoachExporter.jsonString(from: [unplanned])
        #expect(!unplannedJSON.contains("plannedSets"))
        #expect(!unplannedJSON.contains("plannedReps"))
    }

    @Test func workoutsAreSortedOldestFirst() {
        let older = StrengthWorkout(date: Date(timeIntervalSince1970: 1_000), weightPounds: 100)
        let newer = StrengthWorkout(date: Date(timeIntervalSince1970: 2_000), weightPounds: 110)
        let exercise = StrengthExercise(name: "Press", workouts: [newer, older])
        let snapshot = CoachStrengthExercise(from: exercise)
        #expect(snapshot.workouts.map(\.weightPounds) == [100, 110])
    }

    @Test func snapshotsFollowBoardOrder() {
        let mondayFirst = StrengthExercise(name: "Mon-0", weekdayIndex: 1, sortOrder: 0)
        let mondaySecond = StrengthExercise(name: "Mon-1", weekdayIndex: 1, sortOrder: 1)
        let mondayOffloaded = StrengthExercise(name: "Mon-Off", weekdayIndex: 1, isOffloaded: true, sortOrder: 0)
        let sunday = StrengthExercise(name: "Sun-0", weekdayIndex: 0, sortOrder: 0)
        let snapshots = StrengthCoachExporter.snapshots(
            from: [mondayOffloaded, mondaySecond, sunday, mondayFirst]
        )
        #expect(snapshots.map(\.name) == ["Sun-0", "Mon-0", "Mon-1", "Mon-Off"])
    }

    @Test func jsonStringSerializesISO8601DatesAndFields() throws {
        let workout = StrengthWorkout(
            date: Date(timeIntervalSince1970: 0),
            weightPounds: 135,
            recordingType: .averageWeight
        )
        let exercise = StrengthExercise(name: "Bench", muscleGroup: .chest, workouts: [workout])
        let json = try StrengthCoachExporter.jsonString(from: [exercise])
        #expect(json.contains("\"name\":\"Bench\""))
        #expect(json.contains("\"muscleGroup\":\"Chest\""))
        #expect(json.contains("\"recordingType\":\"Average Weight\""))
        #expect(json.contains("1970-01-01T00:00:00Z"))
    }
}

// MARK: - PlanPerformance Tests

struct PlanPerformanceTests {

    @Test func exactMatchIsAtPlan() {
        #expect(PlanPerformance.classify(completedMiles: 3.0, plannedMiles: 3.0) == .atPlan)
    }

    @Test func nilCompletedReturnsNil() {
        #expect(PlanPerformance.classify(completedMiles: nil, plannedMiles: 3.0) == nil)
    }

    @Test func clearlyUnderIsBelowPlan() {
        #expect(PlanPerformance.classify(completedMiles: 2.0, plannedMiles: 3.0) == .belowPlan)
    }

    @Test func clearlyOverIsAbovePlan() {
        #expect(PlanPerformance.classify(completedMiles: 4.0, plannedMiles: 3.0) == .abovePlan)
    }

    @Test func toleranceBoundaryIsInclusive() {
        #expect(PlanPerformance.classify(completedMiles: 3.05, plannedMiles: 3.0) == .atPlan)
        #expect(PlanPerformance.classify(completedMiles: 2.95, plannedMiles: 3.0) == .atPlan)
    }

    @Test func justOutsideToleranceClassifies() {
        #expect(PlanPerformance.classify(completedMiles: 3.051, plannedMiles: 3.0) == .abovePlan)
        #expect(PlanPerformance.classify(completedMiles: 2.949, plannedMiles: 3.0) == .belowPlan)
    }

    @Test func metricRoundTripDriftIsAtPlan() {
        // Simulates RecordWorkoutSheet pre-filling km then converting back to miles.
        let planned = 5.0 / 1.60934
        let completed = (planned * 1.60934) / 1.60934
        #expect(PlanPerformance.classify(completedMiles: completed, plannedMiles: planned) == .atPlan)
    }

    @Test func zeroPlannedDistance() {
        #expect(PlanPerformance.classify(completedMiles: 0, plannedMiles: 0) == .atPlan)
        #expect(PlanPerformance.classify(completedMiles: 3.0, plannedMiles: 0) == .abovePlan)
        #expect(PlanPerformance.classify(completedMiles: 0, plannedMiles: 3.0) == .belowPlan)
    }

    @Test func customToleranceIsRespected() {
        #expect(PlanPerformance.classify(completedMiles: 3.4, plannedMiles: 3.0, toleranceMiles: 0.5) == .atPlan)
        #expect(PlanPerformance.classify(completedMiles: 3.4, plannedMiles: 3.0, toleranceMiles: 0.1) == .abovePlan)
    }

    @Test func defaultToleranceValue() {
        #expect(PlanPerformance.defaultToleranceMiles == 0.05)
    }

    @Test func colorMappingNeverRed() {
        #expect(PlanPerformance.belowPlan.color == .yellow)
        #expect(PlanPerformance.atPlan.color == .green)
        #expect(PlanPerformance.abovePlan.color == .performanceGold)
        for performance in [PlanPerformance.belowPlan, .atPlan, .abovePlan] {
            #expect(performance.color != .red)
        }
    }
}
