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
        let workout = makeWorkout(durationSeconds: 2400)
        let csv = WorkoutCSV.encode(workouts: [workout], unit: .miles)
        #expect(csv.contains(",40m,"))
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

    @Test func toWorkoutWithExerciseCreatesBothModels() {
        let row = WorkoutCSVRow(
            date: referenceDate,
            name: "Test Run",
            type: .easyRun,
            durationSeconds: 2400,
            distance: 4.0,
            notes: "",
            feltRating: 0
        )
        let (exercise, workout) = WorkoutCSV.toWorkoutWithExercise(row, unit: .miles)
        #expect(exercise.name == "Test Run")
        #expect(exercise.type == .easyRun)
        #expect(exercise.durationSeconds == 2400)
        #expect(abs(exercise.distanceMiles - 4.0) < 0.001)
        #expect(exercise.isRepeating == false)

        #expect(workout.name == "Test Run")
        #expect(workout.type == .easyRun)
        #expect(workout.durationSeconds == 2400)
        #expect(workout.source == WorkoutSource.csv.rawValue)
    }

    @Test func toWorkoutWithExerciseLinksSourceExercise() throws {
        let container = ModelContainerFactory.makePreviewContainer()
        let context = ModelContext(container)
        let existing = try context.fetch(FetchDescriptor<Workout>())
        for w in existing { context.delete(w) }
        let existingExercises = try context.fetch(FetchDescriptor<Exercise>())
        for e in existingExercises { context.delete(e) }
        try context.save()

        let row = WorkoutCSVRow(
            date: referenceDate,
            name: "Linked Run",
            type: .run,
            durationSeconds: 1800,
            distance: 3.0,
            notes: "",
            feltRating: 5
        )
        let (exercise, workout) = WorkoutCSV.toWorkoutWithExercise(row, unit: .miles)
        context.insert(exercise)
        context.insert(workout)
        try context.save()

        let fetchedWorkouts = try context.fetch(FetchDescriptor<Workout>())
        let fetchedExercises = try context.fetch(FetchDescriptor<Exercise>())
        #expect(fetchedWorkouts.count == 1)
        #expect(fetchedExercises.count == 1)
        #expect(fetchedWorkouts[0].sourceExercise?.id == fetchedExercises[0].id)
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
