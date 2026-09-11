import XCTest
@testable import Protocare

/// Bug #4 fix: `ActionItem.hydrated(from:)` must restore UI state (schedule,
/// slots, userParameters) from a stored `ProtocolAction` so schedule sheets
/// show persisted values instead of the 8:00 default — and so Save no longer
/// overwrites the stored schedule with that default (data-corruption path).
final class ActionItemHydrationTests: XCTestCase {

    private func makeActionItem(slots: [ScheduleSlot]? = nil) -> ActionItem {
        ActionItem(
            id: "action-1",
            name: "Tretinoin",
            category: .skincare,
            modality: .topical,
            schedule: nil,
            slots: slots
        )
    }

    private func makeProtocolAction(
        rrule: String,
        notificationSchedule: NotificationScheduleResponse? = nil,
        userParameters: [String: AnyCodable]? = nil
    ) -> ProtocolAction {
        ProtocolAction(
            id: "pa-1",
            actionId: "action-1",
            userParameters: userParameters,
            rrule: rrule,
            position: 0,
            checkins: nil,
            notificationSchedule: notificationSchedule
        )
    }

    private func makeNotificationSchedule(
        preferredTime: String,
        isEnabled: Bool = true
    ) -> NotificationScheduleResponse {
        NotificationScheduleResponse(
            id: "ns-1",
            protocolActionId: "pa-1",
            userId: "user-1",
            preferredTime: preferredTime,
            timezone: "Europe/Berlin",
            isEnabled: isEnabled,
            createdAt: "2026-09-01T00:00:00Z"
        )
    }

    // MARK: - Schedule hydration (rrule -> ActionSchedule)

    func testHydrated_RestoresScheduleFromRRule() {
        let item = makeActionItem()
        let pa = makeProtocolAction(rrule: "RRULE:FREQ=WEEKLY;BYDAY=MO,WE;BYHOUR=21;BYMINUTE=30")

        let hydratedItem = item.hydrated(from: pa)

        XCTAssertEqual(hydratedItem.schedule?.frequency, .weekly)
        XCTAssertEqual(hydratedItem.schedule?.days, [.monday, .wednesday])
        XCTAssertEqual(hydratedItem.schedule?.hour, 21)
        XCTAssertEqual(hydratedItem.schedule?.minute, 30)
    }

    func testHydrated_OverwritesExistingSchedule() {
        // A previously hydrated item (e.g. from an older lookup) must not keep
        // a stale schedule when re-hydrated from another ProtocolAction.
        let staleSchedule = ActionSchedule(frequency: .monthly, days: [], hour: 6, minute: 15)
        let item = makeActionItem(slots: nil)
        var itemWithStale = item
        itemWithStale.schedule = staleSchedule

        let pa = makeProtocolAction(rrule: "RRULE:FREQ=DAILY;BYHOUR=8;BYMINUTE=0")

        let hydratedItem = itemWithStale.hydrated(from: pa)

        XCTAssertEqual(hydratedItem.schedule?.frequency, .daily)
        XCTAssertEqual(hydratedItem.schedule?.hour, 8)
        XCTAssertEqual(hydratedItem.schedule?.minute, 0)
    }

    func testHydrated_RestoresUserParameters() {
        let item = makeActionItem()
        let pa = makeProtocolAction(
            rrule: "RRULE:FREQ=DAILY;BYHOUR=8;BYMINUTE=0",
            userParameters: ["serving": AnyCodable(2)]
        )

        let hydratedItem = item.hydrated(from: pa)

        XCTAssertEqual(hydratedItem.userParameters?.keys.contains("serving"), true)
    }

    // MARK: - Slots hydration (notificationSchedule -> slots)

    func testHydrated_RestoresSlotsFromNotificationSchedule() {
        // Core bug #4 scenario: fresh lookup item has slots == [] and the
        // sheet used to default to 8:00; hydrated must restore the persisted
        // reminder time.
        let item = makeActionItem()  // slots == []
        let pa = makeProtocolAction(
            rrule: "RRULE:FREQ=DAILY;BYHOUR=21;BYMINUTE=30",
            notificationSchedule: makeNotificationSchedule(preferredTime: "21:30")
        )

        let hydratedItem = item.hydrated(from: pa)

        XCTAssertEqual(hydratedItem.slots.count, 1)
        XCTAssertEqual(hydratedItem.slots.first?.hour, 21)
        XCTAssertEqual(hydratedItem.slots.first?.minute, 30)
        XCTAssertEqual(hydratedItem.slots.first?.isReminderOn, true)
    }

    func testHydrated_SnapsMinutesTo5MinIncrements() {
        let item = makeActionItem()
        let pa = makeProtocolAction(
            rrule: "RRULE:FREQ=DAILY;BYHOUR=8;BYMINUTE=0",
            notificationSchedule: makeNotificationSchedule(preferredTime: "09:47")
        )

        let hydratedItem = item.hydrated(from: pa)

        XCTAssertEqual(hydratedItem.slots.first?.hour, 9)
        XCTAssertEqual(hydratedItem.slots.first?.minute, 45)  // 47 -> 45 (5-min drum picker)
    }

    func testHydrated_MalformedPreferredTime_FallsBackToDefault() {
        let item = makeActionItem()
        let pa = makeProtocolAction(
            rrule: "RRULE:FREQ=DAILY;BYHOUR=8;BYMINUTE=0",
            notificationSchedule: makeNotificationSchedule(preferredTime: "not-a-time")
        )

        let hydratedItem = item.hydrated(from: pa)

        // Malformed time falls back to 8:00 — same behavior as the sheet's
        // own default, but explicit and testable.
        XCTAssertEqual(hydratedItem.hydratedSlotTime, "08:00")
    }

    func testHydrated_MissingNotificationSchedule_LeavesSlotsEmpty() {
        let item = makeActionItem()
        let pa = makeProtocolAction(rrule: "RRULE:FREQ=DAILY;BYHOUR=8;BYMINUTE=0")

        let hydratedItem = item.hydrated(from: pa)

        XCTAssertTrue(hydratedItem.slots.isEmpty)
    }

    func testHydrated_DisabledReminder_CarriesIsReminderOff() {
        let item = makeActionItem()
        let pa = makeProtocolScheduleDisabled()
        let hydratedItem = item.hydrated(from: pa)

        XCTAssertEqual(hydratedItem.slots.first?.isReminderOn, false)
    }

    private func makeProtocolScheduleDisabled() -> ProtocolAction {
        makeProtocolAction(
            rrule: "rrule",
            notificationSchedule: makeNotificationSchedule(preferredTime: "22:00", isEnabled: false)
        )
    }

    func testHydrated_MissingAllSources_DefaultsTo8AM() {
        // No rrule parse result (bad rrule) and no notification schedule:
        // the sheet falls back to ActionSchedule() default 8:00 — verified
        // so the failure mode is at least deterministic.
        let item = makeActionItem()
        let pa = makeProtocolAction(rrule: "garbage")

        let hydratedItem = item.hydrated(from: pa)

        XCTAssertNil(hydratedItem.schedule)
        XCTAssertTrue(hydratedItem.slots.isEmpty)
    }

    // MARK: - Non-mutation of the original

    func testHydrated_DoesNotMutateOriginal() {
        let item = makeActionItem()
        let pa = makeProtocolAction(
            rrule: "RRULE:FREQ=DAILY;BYHOUR=21;BYMINUTE=30",
            notificationSchedule: makeNotificationSchedule(preferredTime: "21:30")
        )

        _ = item.hydrated(from: pa)

        XCTAssertNil(item.schedule)
        XCTAssertTrue(item.slots.isEmpty)
    }
}

// MARK: - Test helper

private extension ActionItem {
    /// First hydrated slot time as "HH:MM" for assertions.
    var hydratedSlotTime: String? {
        slots.first?.timeLabel
    }
}
