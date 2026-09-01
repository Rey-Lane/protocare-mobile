import SwiftUI
import Combine

@MainActor
final class ProtocolBuilderViewModel: ObservableObject {
    @Published var draft = ProtocolDraft()
    @Published var availableActions: [ActionItem] = []
    @Published var isLoading: Bool = false
    @Published var isSaving: Bool = false
    @Published var errorMessage: String? = nil
    @Published var imageUploadFailed: Bool = false

    let api: AuthAPI
    let authStore: AuthStore
    private var selectedImageData: Data?
    private var lastCreatedProtocolId: String?

    private var allActions: [ActionItem] = []

    init(api: AuthAPI, authStore: AuthStore) {
        self.api = api
        self.authStore = authStore
    }

    var canSave: Bool {
        !draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && !draft.actions.isEmpty
        && !isSaving
    }

    /// Unified action source (Step 22): library + user-created actions come
    /// from the single `GET /actions` endpoint. No more dual lists.
    func loadActions() async {
        guard let token = authStore.accessToken else {
            errorMessage = "User not authenticated."
            availableActions = []
            allActions = []
            draft.actions = []
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let fetchedActions = try await api.fetchActions(token: token, query: nil)
            availableActions = fetchedActions.toActionItems()
            allActions = availableActions
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Не удалось загрузить действия."
        }
    }

    /// Single unified add (Step 22): replaces the former
    /// addPredefinedAction/addUserAction pair — every action now comes
    /// from the unified ActionPickerView with one ID space.
    func addAction(_ action: ActionItem) {
        guard draft.actions.contains(where: { $0.id == action.id }) == false else { return }
        draft.actions.append(action)
    }

    func removeAction(_ action: ActionItem) {
        draft.actions.removeAll { $0.id == action.id }
    }

    func moveAction(from source: IndexSet, to destination: Int) {
        draft.actions.move(fromOffsets: source, toOffset: destination)
    }

    func save() async -> Bool {
        errorMessage = nil
        imageUploadFailed = false
        guard canSave else { return false }
        isSaving = true
        defer { isSaving = false }

        guard let token = authStore.accessToken else {
            errorMessage = "User not authenticated."
            return false
        }

        guard let userId = authStore.userId else {
            errorMessage = "Не удалось определить пользователя."
            return false
        }

        // Unified payload (Step 22): single actionId + per-protocol user_parameters.
        let actionsPayload: [ProtocolActionCreate] = draft.actions.enumerated().map { index, action in
            let defaultSchedule = ActionSchedule(frequency: .daily, days: ScheduleDay.allCases, hour: 8, minute: 0)
            let rrule = action.schedule?.toRRule() ?? defaultSchedule.toRRule()
            let firstReminderSlot = action.slots.first { $0.isReminderOn }
            return ProtocolActionCreate(
                actionId: action.id,
                userParameters: action.userParameters,
                rrule: rrule,
                position: index,
                notificationTime: firstReminderSlot?.timeLabel,
                notificationTimezone: firstReminderSlot != nil ? TimeZone.current.identifier : nil
            )
        }

        let payload = ProtocolCreateRequest(
            userId: userId,
            name: draft.name,
            actions: actionsPayload,
            isActive: true,
            startedAt: nil,
            endedAt: nil,
            category: draft.category,
            metricKeys: draft.metricKeys?.map(\.rawValue)
        )

        do {
            let createdProtocol = try await api.createProtocolWithImage(
                token: token,
                payload: payload,
                imageData: selectedImageData
            )
            lastCreatedProtocolId = createdProtocol.id
            await upsertNotificationSchedules(for: createdProtocol, token: token)
            await requestNotificationsAndSync(token: token)
            return true
        } catch {
            if selectedImageData != nil {
                do {
                    let createdProtocol = try await api.createProtocol(token: token, payload: payload)
                    lastCreatedProtocolId = createdProtocol.id
                    do {
                        _ = try await api.uploadProtocolImage(
                            token: token,
                            protocolId: createdProtocol.id,
                            imageData: selectedImageData!
                        )
                    } catch {
                        imageUploadFailed = true
                        errorMessage = "Protocol created, but image upload failed. Tap Retry to try again."
                        await upsertNotificationSchedules(for: createdProtocol, token: token)
                        return false
                    }
                    await upsertNotificationSchedules(for: createdProtocol, token: token)
                    await requestNotificationsAndSync(token: token)
                    return true
                } catch {
                    errorMessage = (error as? LocalizedError)?.errorDescription ?? "Не удалось сохранить протокол."
                    return false
                }
            }
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Не удалось сохранить протокол."
            return false
        }
    }

    func retryImageUpload() async -> Bool {
        errorMessage = nil
        guard let token = authStore.accessToken,
              let protocolId = lastCreatedProtocolId,
              let imageData = selectedImageData else {
            errorMessage = "Unable to retry image upload."
            return false
        }
        isSaving = true
        defer { isSaving = false }

        do {
            _ = try await api.uploadProtocolImage(
                token: token,
                protocolId: protocolId,
                imageData: imageData
            )
            imageUploadFailed = false
            return true
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Image upload failed again."
            return false
        }
    }

    func selectImage(_ imageData: Data) {
        selectedImageData = imageData
    }

    func removeSelectedImage() {
        selectedImageData = nil
    }

    // MARK: - Notification Preferences

    /// Updates notification preferences for a specific action in the draft
    func updateNotificationPreferences(for action: ActionItem, preferences: DraftNotificationPreferences) {
        guard let index = draft.actions.firstIndex(where: { $0.id == action.id }) else { return }
        draft.actions[index].notificationPreferences = preferences
    }

    func updateSchedule(for action: ActionItem, schedule: ActionSchedule, slots: [ScheduleSlot] = []) {
        guard let index = draft.actions.firstIndex(where: { $0.id == action.id }) else { return }
        draft.actions[index].schedule = schedule
        if !slots.isEmpty {
            draft.actions[index].slots = slots
        }
    }

    private func requestNotificationsAndSync(token: String) async {
        let granted = await NotificationManager.shared.requestAuthorization()
        guard granted else { return }

        do {
            let schedules = try await api.fetchNotificationSchedules(token: token, protocolActionId: nil)
            await NotificationManager.shared.syncLocalNotifications(schedules: schedules)
        } catch {
            // Non-critical: notification sync failure shouldn't block save
        }
    }

    func upsertNotificationSchedules(for protocolItem: ProtocolItem, token: String) async {
        let granted = await NotificationManager.shared.requestAuthorization()
        guard granted else { return }

        for action in draft.actions {
            let reminderSlots = action.slots.filter { $0.isReminderOn }
            guard !reminderSlots.isEmpty else { continue }
            // Single-ID model: match the protocol action by its unified action id.
            let protocolAction = protocolItem.actions.first { $0.actionId == action.id }
            guard let protocolAction else { continue }

            for slot in reminderSlots {
                let payload = NotificationScheduleCreate(
                    protocolActionId: protocolAction.id,
                    preferredTime: slot.timeLabel,
                    timezone: TimeZone.current.identifier,
                    isEnabled: true
                )

                do {
                    let schedule = try await api.upsertNotificationSchedule(token: token, actionId: protocolAction.id, payload: payload)
                    NotificationManager.shared.scheduleLocalNotification(schedule: schedule, actionName: action.name)
                } catch {
                    // Non-critical: per-slot upsert failure shouldn't block save
                }
            }
        }
    }
}
