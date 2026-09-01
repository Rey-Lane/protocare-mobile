import XCTest
@testable import Protocare

@MainActor
final class ProtocolBuilderScheduleTests: XCTestCase {

    var sut: ProtocolBuilderViewModel!
    var mockAPI: MockAuthAPI!
    var mockAuthStore: MockAuthStore!

    override func setUp() {
        super.setUp()
        mockAPI = MockAuthAPI()
        mockAuthStore = MockAuthStore()
        mockAuthStore.mockAccessToken = "test-token"
        mockAuthStore.mockUserId = "test-user-id"
        sut = ProtocolBuilderViewModel(api: mockAPI, authStore: mockAuthStore)
    }

    override func tearDown() {
        sut = nil
        mockAPI = nil
        mockAuthStore = nil
        super.tearDown()
    }

    func testActionItem_ScheduleSummaryText_WithSchedule() {
        let schedule = ActionSchedule(frequency: .weekly, days: [.monday, .wednesday, .friday], hour: 21, minute: 30)
        let action = ActionItem(
            id: "test-1",
            name: "Tretinoin",
            schedule: schedule
        )
        // No slots, so summary uses schedule.timeLabel and shows "Log only"
        let summary = action.scheduleSummaryText
        XCTAssertTrue(summary.contains("Mon, Wed, Fri"))
        XCTAssertTrue(summary.contains("21:30"))
        XCTAssertTrue(summary.contains("Log only"))
    }

    func testActionItem_ScheduleSummaryText_WithSlotsAndReminders() {
        let schedule = ActionSchedule(frequency: .daily, days: ScheduleDay.allCases, hour: 8, minute: 0)
        let slots = [
            ScheduleSlot(hour: 8, minute: 0, isReminderOn: true, reminderOffsetMinutes: 0),
        ]
        let action = ActionItem(
            id: "test-2",
            name: "Vitamin C Serum",
            schedule: schedule,
            slots: slots
        )
        let summary = action.scheduleSummaryText
        XCTAssertTrue(summary.contains("Daily"))
        XCTAssertTrue(summary.contains("🔔 1 reminder"))
    }

    func testActionItem_ScheduleSummaryText_WithSlotsNoReminders() {
        let schedule = ActionSchedule(frequency: .daily, days: ScheduleDay.allCases, hour: 7, minute: 0)
        let slots = [
            ScheduleSlot(hour: 7, minute: 0, isReminderOn: false, reminderOffsetMinutes: 0),
        ]
        let action = ActionItem(
            id: "test-3",
            name: "Collagen Mix",
            schedule: schedule,
            slots: slots
        )
        let summary = action.scheduleSummaryText
        XCTAssertTrue(summary.contains("Daily"))
        XCTAssertTrue(summary.contains("Log only"))
    }

    func testActionItem_ScheduleSummaryText_NoSchedule() {
        let action = ActionItem(name: "No Schedule")
        XCTAssertEqual(action.scheduleSummaryText, "")
    }

    func testUpdateSchedule_UpdatesActionScheduleAndSlots() {
        let action = ActionItem(id: "a1", name: "Test Action")
        sut.addAction(action)

        let schedule = ActionSchedule(frequency: .weekly, days: [.tuesday, .thursday], hour: 10, minute: 0)
        let slots = [ScheduleSlot(hour: 10, minute: 0, isReminderOn: true, reminderOffsetMinutes: 5)]
        sut.updateSchedule(for: action, schedule: schedule, slots: slots)

        XCTAssertEqual(sut.draft.actions.first?.schedule?.frequency, .weekly)
        XCTAssertEqual(sut.draft.actions.first?.schedule?.hour, 10)
        XCTAssertEqual(sut.draft.actions.first?.slots.count, 1)
        XCTAssertEqual(sut.draft.actions.first?.slots.first?.reminderOffsetMinutes, 5)
    }

    func testSave_UsesScheduleRRule() async {
        sut.draft.name = "Test Protocol"
        let action = ActionItem(id: "action-1", name: "Test")
        sut.addAction(action)

        let schedule = ActionSchedule(frequency: .weekly, days: [.monday, .wednesday, .friday], hour: 21, minute: 30)
        sut.updateSchedule(for: action, schedule: schedule)

        mockAPI.createProtocolWithImageResult = .success(
            ProtocolItem(id: "new-protocol", userId: "test-user-id", name: "Test Protocol", actions: [], isActive: true)
        )

        _ = await sut.save()

        let payload = mockAPI.lastCreateProtocolPayload
        XCTAssertNotNil(payload)
        XCTAssertEqual(payload?.actions.first?.rrule, "RRULE:FREQ=WEEKLY;BYDAY=MO,WE,FR;BYHOUR=21;BYMINUTE=30")
    }

    func testSave_DefaultScheduleWhenNoneSet_UsesDailyRRule() async {
        sut.draft.name = "Test Protocol"
        let action = ActionItem(id: "action-1", name: "Test")
        sut.addAction(action)

        mockAPI.createProtocolWithImageResult = .success(
            ProtocolItem(id: "new-protocol", userId: "test-user-id", name: "Test Protocol", actions: [], isActive: true)
        )

        _ = await sut.save()

        let payload = mockAPI.lastCreateProtocolPayload
        XCTAssertNotNil(payload)
        XCTAssertEqual(payload?.actions.first?.rrule, "RRULE:FREQ=DAILY;BYHOUR=8;BYMINUTE=0")
    }

    func testSave_PassesUnifiedActionId() async {
        let action = ActionItem(
            id: "a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d",
            name: "Custom Action",
            category: .mindfulness
        )
        sut.draft.name = "Test"
        sut.addAction(action)

        let schedule = ActionSchedule(frequency: .daily, days: ScheduleDay.allCases, hour: 7, minute: 30)
        sut.updateSchedule(for: action, schedule: schedule)

        mockAPI.createProtocolWithImageResult = .success(
            ProtocolItem(id: "new-p", userId: "uid", name: "Test", actions: [])
        )

        _ = await sut.save()

        let payloadAction = mockAPI.lastCreateProtocolPayload?.actions.first
        XCTAssertNotNil(payloadAction)
        // Unified model: single action_id, no dual ID, no user_parameters unless overridden.
        XCTAssertEqual(payloadAction?.actionId, "a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d")
        XCTAssertNil(payloadAction?.userParameters)
        XCTAssertEqual(payloadAction?.rrule, "RRULE:FREQ=DAILY;BYHOUR=7;BYMINUTE=30")
    }

    func testEndToEnd_ScheduleToRRuleToPayloadWithSlots() async {
        sut.draft.name = "Skincare Protocol"
        let action = ActionItem(id: "action-1", name: "Tretinoin")
        sut.addAction(action)

        let schedule = ActionSchedule(frequency: .weekly, days: [.monday, .wednesday, .friday], hour: 21, minute: 30)
        let slots = [
            ScheduleSlot(hour: 21, minute: 30, isReminderOn: true, reminderOffsetMinutes: 0),
        ]
        sut.updateSchedule(for: action, schedule: schedule, slots: slots)

        mockAPI.createProtocolWithImageResult = .success(
            ProtocolItem(id: "new-p", userId: "uid", name: "Skincare Protocol", actions: [], isActive: true)
        )

        let result = await sut.save()
        XCTAssertTrue(result)

        let payload = mockAPI.lastCreateProtocolPayload
        XCTAssertNotNil(payload)
        XCTAssertEqual(payload?.actions.count, 1)
        XCTAssertEqual(payload?.actions.first?.rrule, "RRULE:FREQ=WEEKLY;BYDAY=MO,WE,FR;BYHOUR=21;BYMINUTE=30")
        XCTAssertEqual(payload?.actions.first?.notificationTime, "21:30")
        XCTAssertNotNil(payload?.actions.first?.notificationTimezone)
    }

    func testScheduleSlot_TimeLabel() {
        let slot = ScheduleSlot(hour: 8, minute: 5)
        XCTAssertEqual(slot.timeLabel, "08:05")
    }

    func testScheduleSlot_OffsetLabels() {
        XCTAssertEqual(ScheduleSlot(reminderOffsetMinutes: 0).offsetLabel, "At time")
        XCTAssertEqual(ScheduleSlot(reminderOffsetMinutes: 5).offsetLabel, "5 min before")
        XCTAssertEqual(ScheduleSlot(reminderOffsetMinutes: 15).offsetLabel, "15 min before")
        XCTAssertEqual(ScheduleSlot(reminderOffsetMinutes: 30).offsetLabel, "30 min before")
        XCTAssertEqual(ScheduleSlot(reminderOffsetMinutes: 10).offsetLabel, "10 min before")
    }

    func testActionItem_DefaultSlotsIsEmpty() {
        let action = ActionItem(name: "Test")
        XCTAssertTrue(action.slots.isEmpty)
    }

    func testActionItem_SlotsWithMultipleReminders() {
        let slots = [
            ScheduleSlot(hour: 8, minute: 0, isReminderOn: true, reminderOffsetMinutes: 0),
            ScheduleSlot(hour: 21, minute: 30, isReminderOn: true, reminderOffsetMinutes: 15),
        ]
        let action = ActionItem(name: "Test", slots: slots)
        let summary = action.scheduleSummaryText
        XCTAssertTrue(summary.contains("🔔 2 reminders"))
    }
}
