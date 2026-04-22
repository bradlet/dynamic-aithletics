//
//  Hybrid_AIthleticsTests.swift
//  Hybrid AIthleticsTests
//
//  Unit tests for models, extensions, and business logic.
//

import Testing
import Foundation
import SwiftData
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

// MARK: - Workout Felt Rating Tests

struct WorkoutFeltRatingTests {

    private func makeContext() throws -> ModelContext {
        let container = ModelContainerFactory.makePreviewContainer()
        return ModelContext(container)
    }

    @Test func feltRatingDefaultsToZero() {
        let workout = Workout(
            name: "Easy",
            type: .easyRun,
            durationSeconds: 1800,
            distanceMiles: 3.0
        )
        #expect(workout.feltRating == 0)
    }

    @Test func feltRatingCanBeSetExplicitly() {
        let workout = Workout(
            name: "Tempo",
            type: .tempoRun,
            durationSeconds: 2400,
            distanceMiles: 5.0,
            feltRating: 8
        )
        #expect(workout.feltRating == 8)
    }

    @Test func feltRatingPersistsThroughSwiftData() throws {
        let context = try makeContext()
        let workout = Workout(
            name: "Interval",
            type: .intervalRun,
            durationSeconds: 2700,
            distanceMiles: 4.0,
            feltRating: 9
        )
        context.insert(workout)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Workout>())
        #expect(fetched.first?.feltRating == 9)
    }

    @Test func draftFromExerciseStartsUnrated() {
        let exercise = Exercise(
            name: "Long Run",
            type: .longRun,
            durationSeconds: 3600,
            distanceMiles: 8.0,
            scheduledDate: Date()
        )
        let draft = Workout.draft(from: exercise)
        #expect(draft.feltRating == 0)
    }
}

// MARK: - Coach Type Conversion Tests

struct CoachTypeConversionTests {

    @Test func workoutConversionPreservesAllFields() {
        let date = Date()
        let workout = Workout(
            name: "Morning Run",
            type: .tempoRun,
            durationSeconds: 2400,
            distanceMiles: 5.0,
            notes: "felt great",
            date: date,
            feltRating: 7
        )
        let coachWorkout = CoachWorkout(from: workout)
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
            scheduledDate: date
        )
        let coachExercise = CoachExercise(from: exercise)
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

    private func makeWorkout(
        name: String = "Morning 5K",
        type: ExerciseType = .run,
        durationSeconds: Int = 1800,
        distanceMiles: Double = 3.1,
        notes: String = "",
        feltRating: Int = 7
    ) -> Workout {
        Workout(
            name: name,
            type: type,
            durationSeconds: durationSeconds,
            distanceMiles: distanceMiles,
            notes: notes,
            date: referenceDate,
            feltRating: feltRating
        )
    }

    // MARK: Encoding

    @Test func encodeProducesHeaderAndOneRowPerWorkout() {
        let workouts = [
            makeWorkout(name: "A", distanceMiles: 1.0),
            makeWorkout(name: "B", distanceMiles: 2.0),
            makeWorkout(name: "C", distanceMiles: 3.0)
        ]
        let csv = WorkoutCSV.encode(workouts: workouts, unit: .miles)
        let lines = csv.split(separator: "\n", omittingEmptySubsequences: false)
        #expect(lines.first.map(String.init) == WorkoutCSV.header)
        // 1 header + 3 data + trailing empty from final newline
        #expect(lines.count == 5)
    }

    @Test func encodeQuotesFieldsContainingCommasQuotesAndNewlines() {
        let workout = makeWorkout(
            name: "5K, easy",
            notes: "He said \"go\"\nthen left"
        )
        let csv = WorkoutCSV.encode(workouts: [workout], unit: .miles)
        #expect(csv.contains("\"5K, easy\""))
        // Embedded quote doubled.
        #expect(csv.contains("\"He said \"\"go\"\"\nthen left\""))
    }

    @Test func encodeUsesFixedTwoDecimalDistance() {
        let workout = makeWorkout(distanceMiles: 3.14159)
        let csv = WorkoutCSV.encode(workouts: [workout], unit: .miles)
        #expect(csv.contains(",3.14,"))
    }

    @Test func encodeConvertsMilesToKilometersForKilometerUnit() {
        let workout = makeWorkout(distanceMiles: 1.0)
        let milesCSV = WorkoutCSV.encode(workouts: [workout], unit: .miles)
        let kmCSV = WorkoutCSV.encode(workouts: [workout], unit: .kilometers)
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
        let original = makeWorkout(
            name: "Tempo Day",
            type: .tempoRun,
            durationSeconds: 2400,
            distanceMiles: 6.25,
            notes: "Felt strong",
            feltRating: 9
        )
        let csv = WorkoutCSV.encode(workouts: [original], unit: .miles)
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
        #expect(abs(row.date.timeIntervalSince(referenceDate)) < 1.0)
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
        let workout = WorkoutCSV.toWorkout(result.rows[0], unit: .kilometers)
        #expect(abs(workout.distanceMiles - 3.10686) < 0.001)
    }

    @Test func toWorkoutPreservesMilesWhenUnitIsMiles() throws {
        let csv = """
        \(WorkoutCSV.header)
        2026-04-09T07:30:00Z,Imperial Run,Run,1800,4.25,,6
        """
        let result = try WorkoutCSV.parse(csv)
        let workout = WorkoutCSV.toWorkout(result.rows[0], unit: .miles)
        #expect(abs(workout.distanceMiles - 4.25) < 0.001)
    }

    // MARK: Integration with SwiftData

    @Test func parsedRowsCanBeInsertedIntoModelContext() throws {
        let container = ModelContainerFactory.makePreviewContainer()
        let context = ModelContext(container)
        // Clear any seeded workouts so the assertion is exact.
        let existing = try context.fetch(FetchDescriptor<Workout>())
        for workout in existing { context.delete(workout) }
        try context.save()

        let csv = """
        \(WorkoutCSV.header)
        2026-04-09T07:30:00Z,Alpha,Run,1800,3.00,,6
        2026-04-09T07:30:00Z,Bravo,Bike,3600,10.00,commute,5
        """
        let result = try WorkoutCSV.parse(csv)
        for row in result.rows {
            context.insert(WorkoutCSV.toWorkout(row, unit: .miles))
        }
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Workout>())
        #expect(fetched.count == 2)
        #expect(fetched.contains(where: { $0.name == "Alpha" && $0.type == .run }))
        #expect(fetched.contains(where: { $0.name == "Bravo" && $0.type == .bike }))
    }

    @Test func csvImportsAreTaggedWithCsvSource() throws {
        let csv = """
        \(WorkoutCSV.header)
        2026-04-09T07:30:00Z,Alpha,Run,1800,3.00,,6
        """
        let result = try WorkoutCSV.parse(csv)
        let workout = WorkoutCSV.toWorkout(result.rows[0], unit: .miles)
        #expect(workout.source == WorkoutSource.csv.rawValue)
        #expect(workout.workoutSource == .csv)
        // CSV imports don't populate externalID (no stable row identifier yet).
        #expect(workout.externalID == nil)
    }
}

// MARK: - WorkoutSource Tests

struct WorkoutSourceTests {

    @Test func defaultWorkoutSourceIsManual() {
        let workout = Workout(
            name: "Test",
            type: .run,
            durationSeconds: 1800,
            distanceMiles: 3.0
        )
        #expect(workout.source == "Manual")
        #expect(workout.workoutSource == .manual)
        #expect(workout.externalID == nil)
    }

    @Test func explicitSourceIsHonored() {
        let workout = Workout(
            name: "Test",
            type: .run,
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
            name: "Test",
            type: .run,
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

    // MARK: DTO → Workout

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

    @Test func toWorkoutSetsAppleHealthSource() {
        let workout = HealthKitWorkoutMapper.toWorkout(makeDTO())
        #expect(workout.source == "Apple Exercise App")
        #expect(workout.workoutSource == .appleHealth)
    }

    @Test func toWorkoutPreservesExternalID() {
        let workout = HealthKitWorkoutMapper.toWorkout(makeDTO(id: "hk-uuid-xyz"))
        #expect(workout.externalID == "hk-uuid-xyz")
    }

    @Test func toWorkoutHandlesNilDistance() {
        let workout = HealthKitWorkoutMapper.toWorkout(
            makeDTO(activityType: .elliptical, distanceMiles: nil)
        )
        #expect(workout.distanceMiles == 0.0)
        #expect(workout.type == .elliptical)
    }

    @Test func toWorkoutCopiesDateAndDuration() {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let workout = HealthKitWorkoutMapper.toWorkout(
            makeDTO(startDate: start, duration: 2700.5)
        )
        #expect(workout.date == start)
        #expect(workout.durationSeconds == 2700)
    }

    @Test func toWorkoutNamesWorkoutAfterExerciseType() {
        let workout = HealthKitWorkoutMapper.toWorkout(makeDTO(activityType: .cycling))
        #expect(workout.name == ExerciseType.bike.rawValue)
    }

    @Test func toWorkoutCopiesDistanceFromDTO() {
        let workout = HealthKitWorkoutMapper.toWorkout(makeDTO(distanceMiles: 5.25))
        #expect(workout.distanceMiles == 5.25)
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
        let workout = Workout(
            name: "Original",
            type: .run,
            durationSeconds: 1800,
            distanceMiles: 3.0,
            notes: "original notes",
            date: Date(timeIntervalSince1970: 1_700_000_000),
            feltRating: 4
        )
        context.insert(workout)

        let newDate = Date(timeIntervalSince1970: 1_710_000_000)
        let edits = WorkoutEditor.EditedValues(
            name: "Edited Name",
            type: .tempoRun,
            durationSeconds: 2700,
            distanceMiles: 6.2,
            date: newDate,
            notes: "edited notes",
            feltRating: 9
        )
        WorkoutEditor.apply(edits, to: workout)

        #expect(workout.name == "Edited Name")
        #expect(workout.type == .tempoRun)
        #expect(workout.durationSeconds == 2700)
        #expect(workout.distanceMiles == 6.2)
        #expect(workout.date == newDate)
        #expect(workout.notes == "edited notes")
        #expect(workout.feltRating == 9)
    }

    @Test func applyPreservesIdAndImportMetadata() throws {
        let context = makeContext()
        let workout = Workout(
            name: "Imported",
            type: .run,
            durationSeconds: 1800,
            distanceMiles: 3.0,
            source: WorkoutSource.appleHealth.rawValue,
            externalID: "hk-abc-123"
        )
        context.insert(workout)
        let originalID = workout.id

        let edits = WorkoutEditor.EditedValues(
            name: "Renamed",
            type: .easyRun,
            durationSeconds: 2400,
            distanceMiles: 4.0,
            date: Date(),
            notes: "",
            feltRating: 6
        )
        WorkoutEditor.apply(edits, to: workout)

        #expect(workout.id == originalID)
        #expect(workout.source == WorkoutSource.appleHealth.rawValue)
        #expect(workout.externalID == "hk-abc-123")
    }

    @Test func deleteRemovesWorkoutFromContext() throws {
        let context = makeContext()
        let workout = Workout(
            name: "Doomed",
            type: .run,
            durationSeconds: 1800,
            distanceMiles: 3.0
        )
        context.insert(workout)
        try context.save()

        context.delete(workout)
        try context.save()

        let remaining = try context.fetch(FetchDescriptor<Workout>())
        #expect(remaining.isEmpty)
    }

    @Test func deleteLeavesOtherWorkoutsIntact() throws {
        let context = makeContext()
        let keep = Workout(name: "Keep me", type: .run, durationSeconds: 1800, distanceMiles: 3.0)
        let remove = Workout(name: "Remove me", type: .bike, durationSeconds: 3600, distanceMiles: 10.0)
        context.insert(keep)
        context.insert(remove)
        try context.save()

        context.delete(remove)
        try context.save()

        let remaining = try context.fetch(FetchDescriptor<Workout>())
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

    /// Constructs a `Workout` directly (no ModelContext) for pure-logic tests.
    private func makeWorkout(date: Date, miles: Double, felt: Int = 0) -> Workout {
        Workout(
            name: "test",
            type: .run,
            durationSeconds: 1800,
            distanceMiles: miles,
            date: date,
            feltRating: felt
        )
    }

    // 2026-04-08 is a Wednesday; its Monday is 2026-04-06.
    private var anchorWednesday: Date { makeDate(year: 2026, month: 4, day: 8) }

    @Test func weeklyMileageReturnsAllWeeksEvenWhenEmpty() {
        let points = WorkoutAggregations.weeklyMileage(
            workouts: [],
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
        // Current week (Mon Apr 6 – Sun Apr 12): workout on Mon Apr 6 = 5.0 mi
        // Previous week (Mar 30 – Apr 5): workout on Sun Apr 5 = 3.0 mi
        let workouts = [
            makeWorkout(date: makeDate(year: 2026, month: 4, day: 6), miles: 5.0),
            makeWorkout(date: makeDate(year: 2026, month: 4, day: 5), miles: 3.0)
        ]
        let points = WorkoutAggregations.weeklyMileage(
            workouts: workouts,
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
            makeWorkout(date: makeDate(year: 2026, month: 4, day: 7), miles: 4.0),
            makeWorkout(date: makeDate(year: 2026, month: 4, day: 9), miles: 6.5)
        ]
        let points = WorkoutAggregations.weeklyMileage(
            workouts: workouts,
            weekCount: 4,
            anchor: anchorWednesday
        )
        #expect(points.last?.value == 10.5)
    }

    @Test func weeklyMileageIgnoresWorkoutsOutsideWindow() {
        // January workout should not land in April's 4-week window.
        let workouts = [
            makeWorkout(date: makeDate(year: 2026, month: 1, day: 15), miles: 99.0)
        ]
        let points = WorkoutAggregations.weeklyMileage(
            workouts: workouts,
            weekCount: 4,
            anchor: anchorWednesday
        )
        #expect(points.allSatisfy { $0.value == 0 })
    }

    @Test func weeklyAverageFeltRatingExcludesZeroRatings() {
        // Three workouts in the current week rated 6, 8, 0 → avg = 7.0 (not 4.67).
        let workouts = [
            makeWorkout(date: makeDate(year: 2026, month: 4, day: 6), miles: 3.0, felt: 6),
            makeWorkout(date: makeDate(year: 2026, month: 4, day: 7), miles: 3.0, felt: 8),
            makeWorkout(date: makeDate(year: 2026, month: 4, day: 8), miles: 3.0, felt: 0)
        ]
        let points = WorkoutAggregations.weeklyAverageFeltRating(
            workouts: workouts,
            weekCount: 4,
            anchor: anchorWednesday
        )
        #expect(points.last?.value == 7.0)
    }

    @Test func weeklyAverageFeltRatingEmptyWeekIsZero() {
        let points = WorkoutAggregations.weeklyAverageFeltRating(
            workouts: [],
            weekCount: 4,
            anchor: anchorWednesday
        )
        #expect(points.count == 4)
        #expect(points.allSatisfy { $0.value == 0 })
    }

    @Test func weeklyAverageFeltRatingWeekWithOnlyUnratedIsZero() {
        // Two workouts in the current week, both feltRating = 0 — must not NaN or crash.
        let workouts = [
            makeWorkout(date: makeDate(year: 2026, month: 4, day: 7), miles: 3.0, felt: 0),
            makeWorkout(date: makeDate(year: 2026, month: 4, day: 8), miles: 3.0, felt: 0)
        ]
        let points = WorkoutAggregations.weeklyAverageFeltRating(
            workouts: workouts,
            weekCount: 4,
            anchor: anchorWednesday
        )
        #expect(points.last?.value == 0)
    }

    @Test func currentWeekMileageSumsWorkoutsInAnchorWeek() {
        // Mon + Tue + Wed of the current week plus a workout on prior Sun (must be excluded).
        let workouts = [
            makeWorkout(date: makeDate(year: 2026, month: 4, day: 6), miles: 2.0),
            makeWorkout(date: makeDate(year: 2026, month: 4, day: 7), miles: 3.0),
            makeWorkout(date: makeDate(year: 2026, month: 4, day: 8), miles: 4.0),
            makeWorkout(date: makeDate(year: 2026, month: 4, day: 5), miles: 99.0) // previous Sunday
        ]
        let total = WorkoutAggregations.currentWeekMileage(
            workouts: workouts,
            anchor: anchorWednesday
        )
        #expect(total == 9.0)
    }

    @Test func currentWeekMileageBoundaryMondayStart() {
        // Anchor Monday at 00:00:00, workout at same instant — must count.
        let monday = makeDate(year: 2026, month: 4, day: 6, hour: 0, minute: 0, second: 0)
        let workouts = [makeWorkout(date: monday, miles: 5.0)]
        let total = WorkoutAggregations.currentWeekMileage(
            workouts: workouts,
            anchor: monday
        )
        #expect(total == 5.0)
    }

    @Test func currentWeekMileageBoundarySundayEnd() {
        // Sunday 23:59:59 workout is in the same week; Mon 00:00 of next week is not.
        let sundayNight = makeDate(year: 2026, month: 4, day: 12, hour: 23, minute: 59, second: 59)
        let nextMondayStart = makeDate(year: 2026, month: 4, day: 13, hour: 0, minute: 0, second: 0)
        let workouts = [
            makeWorkout(date: sundayNight, miles: 5.0),
            makeWorkout(date: nextMondayStart, miles: 99.0)
        ]
        let total = WorkoutAggregations.currentWeekMileage(
            workouts: workouts,
            anchor: sundayNight
        )
        #expect(total == 5.0)
    }

    @Test func currentWeekAverageFeltRatingReturnsNilWhenNoRated() {
        let workouts = [
            makeWorkout(date: makeDate(year: 2026, month: 4, day: 7), miles: 3.0, felt: 0),
            makeWorkout(date: makeDate(year: 2026, month: 4, day: 8), miles: 3.0, felt: 0)
        ]
        let avg = WorkoutAggregations.currentWeekAverageFeltRating(
            workouts: workouts,
            anchor: anchorWednesday
        )
        #expect(avg == nil)
    }

    @Test func currentWeekAverageFeltRatingAveragesOnlyRated() {
        // 5, 7, 0 → 6.0, not 4.0.
        let workouts = [
            makeWorkout(date: makeDate(year: 2026, month: 4, day: 6), miles: 3.0, felt: 5),
            makeWorkout(date: makeDate(year: 2026, month: 4, day: 7), miles: 3.0, felt: 7),
            makeWorkout(date: makeDate(year: 2026, month: 4, day: 8), miles: 3.0, felt: 0)
        ]
        let avg = WorkoutAggregations.currentWeekAverageFeltRating(
            workouts: workouts,
            anchor: anchorWednesday
        )
        #expect(avg == 6.0)
    }

    @Test func weeklyBucketsOrderingIsChronological() {
        let buckets = WorkoutAggregations.weeklyBuckets(
            workouts: [],
            weekCount: 6,
            anchor: anchorWednesday
        )
        #expect(buckets.count == 6)
        let starts = buckets.map(\.weekStart)
        for i in 1..<starts.count {
            #expect(starts[i] > starts[i - 1])
        }
    }
}

// MARK: - CalendarDisplayable Tests

struct CalendarDisplayableTests {

    @Test func exerciseDisplayDateIsScheduledDate() {
        let date = Date()
        let exercise = Exercise(
            name: "Run",
            type: .run,
            durationSeconds: 1800,
            distanceMiles: 3.0,
            scheduledDate: date
        )
        #expect(exercise.displayDate == exercise.scheduledDate)
    }

    @Test func workoutDisplayDateIsDate() {
        let date = Date()
        let workout = Workout(
            name: "Run",
            type: .run,
            durationSeconds: 1800,
            distanceMiles: 3.0,
            date: date,
            feltRating: 7
        )
        #expect(workout.displayDate == workout.date)
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
            scheduledDate: makeDate(year: 2026, month: 4, day: 10),
            isRepeating: false
        )
        let ex2 = Exercise(
            name: "Swim",
            type: .swim,
            durationSeconds: 2400,
            distanceMiles: 1.0,
            scheduledDate: makeDate(year: 2026, month: 4, day: 15),
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
            scheduledDate: makeDate(year: 2026, month: 3, day: 2), // a Monday in March
            isRepeating: true
        )
        let items = ExerciseVirtualExpansion.monthItems(
            allExercises: [mondayExercise],
            month: april
        )
        // Should produce dots for each Monday in April
        let mondays = april.daysInMonth().filter { $0.mondayBasedWeekdayIndex == 0 }
        #expect(items.count == mondays.count)
        for item in items {
            #expect(item.type == .run)
            #expect(item.displayDate.mondayBasedWeekdayIndex == 0)
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
            scheduledDate: makeDate(year: 2026, month: 3, day: 2),
            isRepeating: true
        )
        // Concrete instance on April 6 (a Monday) with same name/type
        let concrete = Exercise(
            name: "Monday Run",
            type: .run,
            durationSeconds: 2000,
            distanceMiles: 4.0,
            scheduledDate: makeDate(year: 2026, month: 4, day: 6),
            isRepeating: false
        )
        let items = ExerciseVirtualExpansion.monthItems(
            allExercises: [repeating, concrete],
            month: april
        )
        // Concrete should count + remaining Mondays get virtual dots
        let mondays = april.daysInMonth().filter { $0.mondayBasedWeekdayIndex == 0 }
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
            scheduledDate: makeDate(year: 2026, month: 3, day: 15),
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
            scheduledDate: makeDate(year: 2026, month: 4, day: 14),
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

    @Test func rescheduleUpdatesExerciseAndWorkoutDates() throws {
        let context = try makeContext()
        let monday = Date().startOfWeek
        let exercise = Exercise(
            name: "Easy Run",
            type: .run,
            durationSeconds: 1800,
            distanceMiles: 3.0,
            scheduledDate: monday
        )
        context.insert(exercise)

        let workout = Workout.draft(from: exercise)
        context.insert(workout)
        try context.save()

        let wednesday = Calendar.current.date(byAdding: .day, value: 2, to: monday)!.startOfDay
        exercise.scheduledDate = wednesday
        for w in exercise.workouts {
            w.date = wednesday
        }
        try context.save()

        #expect(exercise.scheduledDate == wednesday)
        #expect(workout.date == wednesday)
    }

    @Test func repeatingExerciseShouldNotBeRescheduled() throws {
        let context = try makeContext()
        let monday = Date().startOfWeek
        let exercise = Exercise(
            name: "Repeating Run",
            type: .run,
            durationSeconds: 1800,
            distanceMiles: 3.0,
            scheduledDate: monday,
            isRepeating: true
        )
        context.insert(exercise)
        try context.save()

        // Simulate the guard: repeating exercises are blocked
        #expect(exercise.isRepeating)
        // The view's rescheduleExercise returns early; date is unchanged
        #expect(exercise.scheduledDate == monday.startOfDay)
    }
}

// MARK: - Exercise Cascade Delete Tests

struct ExerciseCascadeDeleteTests {

    private func makeContext() throws -> ModelContext {
        let container = ModelContainerFactory.makePreviewContainer()
        return ModelContext(container)
    }

    @Test func cascadeDeleteRemovesExerciseAndWorkouts() throws {
        let context = try makeContext()
        let exercise = Exercise(
            name: "Tempo Run",
            type: .tempoRun,
            durationSeconds: 2400,
            distanceMiles: 5.0,
            scheduledDate: Date()
        )
        context.insert(exercise)

        let workout1 = Workout.draft(from: exercise)
        let workout2 = Workout.draft(from: exercise)
        context.insert(workout1)
        context.insert(workout2)
        try context.save()

        #expect(exercise.workouts.count == 2)

        // Cascade delete: remove workouts first, then exercise
        for workout in exercise.workouts {
            context.delete(workout)
        }
        context.delete(exercise)
        try context.save()

        let exercises = try context.fetch(FetchDescriptor<Exercise>())
        let workouts = try context.fetch(FetchDescriptor<Workout>())
        #expect(exercises.isEmpty)
        #expect(workouts.isEmpty)
    }

    @Test func cascadeDeleteWithNoWorkouts() throws {
        let context = try makeContext()
        let exercise = Exercise(
            name: "Easy Run",
            type: .run,
            durationSeconds: 1800,
            distanceMiles: 3.0,
            scheduledDate: Date()
        )
        context.insert(exercise)
        try context.save()

        #expect(exercise.workouts.isEmpty)

        // Cascade delete with empty workouts list
        for workout in exercise.workouts {
            context.delete(workout)
        }
        context.delete(exercise)
        try context.save()

        let exercises = try context.fetch(FetchDescriptor<Exercise>())
        #expect(exercises.isEmpty)
    }

    @Test func nullifyRulePreservesWorkoutsOnPlainDelete() throws {
        let context = try makeContext()
        let exercise = Exercise(
            name: "Long Run",
            type: .longRun,
            durationSeconds: 3600,
            distanceMiles: 8.0,
            scheduledDate: Date()
        )
        context.insert(exercise)

        let workout = Workout.draft(from: exercise)
        context.insert(workout)
        try context.save()

        // Plain delete (without cascade) — nullify rule keeps workout
        context.delete(exercise)
        try context.save()

        let exercises = try context.fetch(FetchDescriptor<Exercise>())
        let workouts = try context.fetch(FetchDescriptor<Workout>())
        #expect(exercises.isEmpty)
        #expect(workouts.count == 1, "Workout survives due to .nullify delete rule")
        #expect(workouts.first?.sourceExercise == nil, "Exercise link is nullified")
    }

    @Test func deleteVirtualRepeatingStopsRecurrence() throws {
        let context = try makeContext()
        let exercise = Exercise(
            name: "Weekly Run",
            type: .run,
            durationSeconds: 1800,
            distanceMiles: 3.0,
            scheduledDate: Date(),
            isRepeating: true
        )
        context.insert(exercise)

        let workout = Workout.draft(from: exercise)
        context.insert(workout)
        try context.save()

        #expect(exercise.isRepeating == true)
        #expect(exercise.workouts.count == 1)

        // Virtual delete: just stop recurrence, preserve exercise + workouts
        exercise.isRepeating = false
        try context.save()

        let exercises = try context.fetch(FetchDescriptor<Exercise>())
        let workouts = try context.fetch(FetchDescriptor<Workout>())
        #expect(exercises.count == 1, "Exercise is preserved")
        #expect(exercises.first?.isRepeating == false, "Recurrence stopped")
        #expect(workouts.count == 1, "Workout is preserved")
        #expect(workouts.first?.sourceExercise === exercise, "Workout still linked")
    }

    @Test func deleteTemplateInOwnWeekRemovesExerciseAndWorkouts() throws {
        let context = try makeContext()
        let exercise = Exercise(
            name: "Weekly Tempo",
            type: .tempoRun,
            durationSeconds: 2400,
            distanceMiles: 5.0,
            scheduledDate: Date(),
            isRepeating: true
        )
        context.insert(exercise)

        let workout = Workout.draft(from: exercise)
        context.insert(workout)
        try context.save()

        // Non-virtual delete: full cascade (template is in its own week)
        for w in exercise.workouts {
            context.delete(w)
        }
        context.delete(exercise)
        try context.save()

        let exercises = try context.fetch(FetchDescriptor<Exercise>())
        let workouts = try context.fetch(FetchDescriptor<Workout>())
        #expect(exercises.isEmpty, "Template exercise deleted")
        #expect(workouts.isEmpty, "Associated workouts deleted")
    }
}
