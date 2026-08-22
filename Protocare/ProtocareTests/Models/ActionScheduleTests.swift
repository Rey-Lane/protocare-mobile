import XCTest
@testable import Protocare

final class ActionScheduleTests: XCTestCase {

    // MARK: - toRRule

    func testToRRule_Daily_GeneratesCorrectString() {
        let schedule = ActionSchedule(
            frequency: .daily,
            days: ScheduleDay.allCases,
            hour: 8,
            minute: 0
        )
        XCTAssertEqual(schedule.toRRule(), "RRULE:FREQ=DAILY;BYHOUR=8;BYMINUTE=0")
    }

    func testToRRule_WeeklySpecificDays_GeneratesCorrectString() {
        let schedule = ActionSchedule(
            frequency: .weekly,
            days: [.monday, .wednesday, .friday],
            hour: 21,
            minute: 30
        )
        XCTAssertEqual(schedule.toRRule(), "RRULE:FREQ=WEEKLY;BYDAY=MO,WE,FR;BYHOUR=21;BYMINUTE=30")
    }

    func testToRRule_Monthly_GeneratesCorrectString() {
        let schedule = ActionSchedule(
            frequency: .monthly,
            days: [],
            hour: 7,
            minute: 0
        )
        XCTAssertEqual(schedule.toRRule(), "RRULE:FREQ=MONTHLY;BYHOUR=7;BYMINUTE=0")
    }

    // MARK: - fromRRule

    func testFromRRule_Daily_ParsesCorrectly() {
        let schedule = ActionSchedule.fromRRule("RRULE:FREQ=DAILY;BYHOUR=8;BYMINUTE=0")
        XCTAssertNotNil(schedule)
        XCTAssertEqual(schedule?.frequency, .daily)
        XCTAssertEqual(schedule?.hour, 8)
        XCTAssertEqual(schedule?.minute, 0)
    }

    func testFromRRule_Daily_NoPrefix_ParsesCorrectly() {
        let schedule = ActionSchedule.fromRRule("FREQ=DAILY;BYHOUR=8;BYMINUTE=0")
        XCTAssertNotNil(schedule)
        XCTAssertEqual(schedule?.frequency, .daily)
        XCTAssertEqual(schedule?.hour, 8)
        XCTAssertEqual(schedule?.minute, 0)
    }

    func testFromRRule_WeeklyWithDays_ParsesCorrectly() {
        let schedule = ActionSchedule.fromRRule("RRULE:FREQ=WEEKLY;BYDAY=MO,WE,FR;BYHOUR=21;BYMINUTE=30")
        XCTAssertNotNil(schedule)
        XCTAssertEqual(schedule?.frequency, .weekly)
        XCTAssertEqual(schedule?.days, [.monday, .wednesday, .friday])
        XCTAssertEqual(schedule?.hour, 21)
        XCTAssertEqual(schedule?.minute, 30)
    }

    func testFromRRule_BareFreqDaily_NoHourMinute_DefaultsTo8AM() {
        let schedule = ActionSchedule.fromRRule("RRULE:FREQ=DAILY")
        XCTAssertNotNil(schedule)
        XCTAssertEqual(schedule?.frequency, .daily)
        XCTAssertEqual(schedule?.hour, 8)
        XCTAssertEqual(schedule?.minute, 0)
    }

    func testFromRRule_InvalidString_ReturnsNil() {
        let schedule = ActionSchedule.fromRRule("not-a-valid-rrule")
        XCTAssertNil(schedule)
    }

    func testFromRRule_EmptyString_ReturnsNil() {
        let schedule = ActionSchedule.fromRRule("")
        XCTAssertNil(schedule)
    }

    func testFromRRule_PrefixOnly_ReturnsNil() {
        let schedule = ActionSchedule.fromRRule("RRULE:")
        XCTAssertNil(schedule)
    }

    func testFromRRule_WeeklyNoByDay_DefaultsToAllDays() {
        let schedule = ActionSchedule.fromRRule("RRULE:FREQ=WEEKLY;BYHOUR=8;BYMINUTE=0")
        XCTAssertNotNil(schedule)
        XCTAssertEqual(schedule?.frequency, .weekly)
        XCTAssertEqual(schedule?.days, ScheduleDay.allCases)
    }

    func testFromRRule_UnknownFreq_ReturnsNil() {
        let schedule = ActionSchedule.fromRRule("RRULE:FREQ=YEARLY;BYHOUR=8;BYMINUTE=0")
        XCTAssertNil(schedule)
    }

    // MARK: - summaryLabel

    func testSummaryLabel_Daily() {
        let schedule = ActionSchedule(frequency: .daily, days: ScheduleDay.allCases, hour: 8, minute: 0)
        XCTAssertEqual(schedule.summaryLabel, "Daily")
    }

    func testSummaryLabel_WeeklySpecificDays() {
        let schedule = ActionSchedule(frequency: .weekly, days: [.monday, .wednesday, .friday], hour: 21, minute: 30)
        XCTAssertEqual(schedule.summaryLabel, "Mon, Wed, Fri")
    }

    func testSummaryLabel_Monthly() {
        let schedule = ActionSchedule(frequency: .monthly, days: [], hour: 7, minute: 0)
        XCTAssertEqual(schedule.summaryLabel, "Monthly")
    }

    // MARK: - timeLabel

    func testTimeLabel_AM() {
        let schedule = ActionSchedule(frequency: .daily, days: [], hour: 8, minute: 0)
        XCTAssertEqual(schedule.timeLabel, "08:00")
    }

    func testTimeLabel_PM() {
        let schedule = ActionSchedule(frequency: .daily, days: [], hour: 21, minute: 30)
        XCTAssertEqual(schedule.timeLabel, "21:30")
    }

    func testTimeLabel_Midnight() {
        let schedule = ActionSchedule(frequency: .daily, days: [], hour: 0, minute: 0)
        XCTAssertEqual(schedule.timeLabel, "00:00")
    }

    func testTimeLabel_Noon() {
        let schedule = ActionSchedule(frequency: .daily, days: [], hour: 12, minute: 0)
        XCTAssertEqual(schedule.timeLabel, "12:00")
    }

    // MARK: - Round-trip

    func testRoundTrip_Daily() {
        let original = ActionSchedule(frequency: .daily, days: ScheduleDay.allCases, hour: 8, minute: 0)
        let rrule = original.toRRule()
        let parsed = ActionSchedule.fromRRule(rrule)
        XCTAssertNotNil(parsed)
        XCTAssertEqual(parsed?.frequency, original.frequency)
        XCTAssertEqual(parsed?.days, original.days)
        XCTAssertEqual(parsed?.hour, original.hour)
        XCTAssertEqual(parsed?.minute, original.minute)
    }

    func testRoundTrip_Weekly() {
        let original = ActionSchedule(frequency: .weekly, days: [.monday, .wednesday, .friday], hour: 21, minute: 30)
        let rrule = original.toRRule()
        let parsed = ActionSchedule.fromRRule(rrule)
        XCTAssertNotNil(parsed)
        XCTAssertEqual(parsed?.frequency, original.frequency)
        XCTAssertEqual(parsed?.days, original.days)
        XCTAssertEqual(parsed?.hour, original.hour)
        XCTAssertEqual(parsed?.minute, original.minute)
    }

    func testRoundTrip_BackendSeedFormat() {
        let rrule = "RRULE:FREQ=DAILY;BYHOUR=8;BYMINUTE=0"
        let parsed = ActionSchedule.fromRRule(rrule)
        XCTAssertNotNil(parsed)
        XCTAssertEqual(parsed?.frequency, .daily)
        XCTAssertEqual(parsed?.hour, 8)
        XCTAssertEqual(parsed?.minute, 0)
        XCTAssertEqual(parsed?.days, ScheduleDay.allCases)
    }
}
