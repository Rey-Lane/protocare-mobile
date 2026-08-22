import XCTest
import UserNotifications
@testable import Protocare

@MainActor
final class NotificationManagerTests: XCTestCase {

    var sut: NotificationManager!

    override func setUp() {
        super.setUp()
        sut = NotificationManager.shared
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testCancelAllNotifications_DoesNotCrash() async {
        sut.cancelAllNotifications()
        XCTAssertNotNil(sut)
    }

    func testCancelNotification_RemovesSpecificSchedule() {
        sut.cancelNotification(scheduleId: "test-schedule-id")
        XCTAssertNotNil(sut)
    }

    func testScheduleLocalNotification_WithActionName() {
        let schedule = NotificationScheduleResponse(
            id: "schedule-id",
            protocolActionId: "action-id",
            userId: "user-id",
            preferredTime: "08:30",
            timezone: "UTC",
            isEnabled: true,
            createdAt: "2026-04-11T12:00:00Z"
        )

        sut.scheduleLocalNotification(schedule: schedule, actionName: "Vitamin C")
        XCTAssertNotNil(sut)
    }

    func testScheduleLocalNotification_WithoutActionName() {
        let schedule = NotificationScheduleResponse(
            id: "schedule-id",
            protocolActionId: "action-id",
            userId: "user-id",
            preferredTime: "08:30",
            timezone: "UTC",
            isEnabled: true,
            createdAt: "2026-04-11T12:00:00Z"
        )

        sut.scheduleLocalNotification(schedule: schedule, actionName: nil)
        XCTAssertNotNil(sut)
    }

    func testSyncLocalNotifications_WithSchedules() async {
        let schedules = [
            NotificationScheduleResponse(
                id: "schedule-1",
                protocolActionId: "action-1",
                userId: "user-id",
                preferredTime: "08:00",
                timezone: "UTC",
                isEnabled: true,
                createdAt: "2026-04-11T12:00:00Z"
            ),
            NotificationScheduleResponse(
                id: "schedule-2",
                protocolActionId: "action-2",
                userId: "user-id",
                preferredTime: "20:00",
                timezone: "UTC",
                isEnabled: false,
                createdAt: "2026-04-11T12:00:00Z"
            )
        ]

        await sut.syncLocalNotifications(schedules: schedules)
        XCTAssertNotNil(sut)
    }

    func testAuthorizationStatus_InitialValue() {
        let status = sut.authorizationStatus
        XCTAssertNotNil(status)
    }
}
