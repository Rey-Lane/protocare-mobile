import Foundation
import Combine
import UserNotifications

@MainActor
final class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()

    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private let center = UNUserNotificationCenter.current()

    private override init() {
        super.init()
        center.delegate = self
    }

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await refreshAuthorizationStatus()
            return granted
        } catch {
            return false
        }
    }

    func refreshAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    // MARK: - Slot-Based Scheduling (New)

    /// Schedule a local notification from a ScheduleSlot + ActionSchedule (rrule pattern).
    /// The trigger fires on the rrule's day pattern at the slot's time minus the slot's offset.
    func scheduleLocalNotification(
        slot: ScheduleSlot,
        schedule: ActionSchedule,
        actionName: String,
        protocolActionId: String
    ) {
        let content = UNMutableNotificationContent()
        content.title = "Protocol Reminder"
        content.body = "Time for: \(actionName)"
        content.sound = .default
        content.userInfo = [
            "slotId": slot.id.uuidString,
            "protocolActionId": protocolActionId
        ]

        // Compute the trigger time: slot time minus offset
        let triggerHour = slot.hour
        let triggerMinute = slot.minute
        // Calculate the effective reminder time
        let totalSlotMinutes = triggerHour * 60 + triggerMinute
        let effectiveMinutes = max(0, totalSlotMinutes - slot.reminderOffsetMinutes)
        let effectiveHour = effectiveMinutes / 60
        let effectiveMinute = effectiveMinutes % 60

        var dateComponents = DateComponents(hour: effectiveHour, minute: effectiveMinute)

        // For weekly schedules, add the day-of-week matching
        if schedule.frequency == .weekly && !schedule.days.isEmpty {
            // Schedule one notification per day in the rrule
            for day in schedule.days {
                var dayComponents = dateComponents
                dayComponents.weekday = day.calendarIndex + 1  // Calendar weekday is 1-based (1=Sun)
                let request = UNNotificationRequest(
                    identifier: "\(protocolActionId)_\(slot.id.uuidString)_\(day.rawValue)",
                    content: content,
                    trigger: UNCalendarNotificationTrigger(dateMatching: dayComponents, repeats: true)
                )
                center.add(request) { error in
                    if let error = error {
                        print("Failed to schedule notification for \(day.rawValue): \(error.localizedDescription)")
                    }
                }
            }
            return
        }

        // Daily / Monthly: single trigger
        let request = UNNotificationRequest(
            identifier: "\(protocolActionId)_\(slot.id.uuidString)",
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        )
        center.add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Legacy Scheduling (kept for API compatibility with existing backend sync)

    func scheduleLocalNotification(schedule: NotificationScheduleResponse, actionName: String? = nil) {
        let content = UNMutableNotificationContent()
        content.title = "Protocol Reminder"
        if let actionName {
            content.body = "Time for: \(actionName)"
        } else {
            content.body = "Time for your scheduled action"
        }
        content.sound = .default
        content.userInfo = [
            "scheduleId": schedule.id,
            "protocolActionId": schedule.protocolActionId
        ]

        let dateComponents = timeStringToDateComponents(schedule.preferredTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(
            identifier: schedule.id,
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                print("Failed to schedule notification \(schedule.id): \(error.localizedDescription)")
            }
        }
    }

    func syncLocalNotifications(schedules: [NotificationScheduleResponse]) async {
        await center.removeAllPendingNotificationRequests()

        for schedule in schedules where schedule.isEnabled {
            scheduleLocalNotification(schedule: schedule)
        }
    }

    func cancelNotification(scheduleId: String) {
        center.removePendingNotificationRequests(withIdentifiers: [scheduleId])
    }

    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
    }

    /// Cancel all notifications for a specific slot across all days
    func cancelNotificationsForSlot(slotId: UUID, protocolActionId: String) {
        // We need to remove all identifiers that start with "{protocolActionId}_{slotId}"
        let prefix = "\(protocolActionId)_\(slotId.uuidString)"
        center.getPendingNotificationRequests { requests in
            let idsToRemove = requests.filter { $0.identifier.hasPrefix(prefix) }.map { $0.identifier }
            self.center.removePendingNotificationRequests(withIdentifiers: idsToRemove)
        }
    }

    private func timeStringToDateComponents(_ timeString: String) -> DateComponents {
        let parts = timeString.split(separator: ":")
        guard parts.count == 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]) else {
            return DateComponents(hour: 8, minute: 0)
        }
        return DateComponents(hour: hour, minute: minute)
    }
}

extension NotificationManager: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        guard let scheduleId = userInfo["scheduleId"] as? String ?? userInfo["slotId"] as? String else { return }
        await MainActor.run {
            NotificationCenter.default.post(
                name: .notificationTapped,
                object: nil,
                userInfo: ["scheduleId": scheduleId]
            )
        }
    }
}

extension Notification.Name {
    static let notificationTapped = Notification.Name("notificationTapped")
    /// Posted by Profile after "Replay onboarding" resets the server state;
    /// RootView re-fetches onboarding state and re-presents the wizard.
    static let replayOnboardingRequested = Notification.Name("replayOnboardingRequested")
}
