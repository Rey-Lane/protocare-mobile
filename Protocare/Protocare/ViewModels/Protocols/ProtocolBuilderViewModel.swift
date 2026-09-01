import SwiftUI
import Combine

@MainActor
final class ProtocolBuilderViewModel: ObservableObject {
    @Published var draft = ProtocolDraft()
    @Published var availableActions: [ActionItem] = []
    @Published var userActions: [UserAction] = []
    @Published var selectedTab: Tab = .library
    @Published var searchQuery: String = ""
    @Published var selectedCategory: ActionsCategory? = nil
    @Published var isLoading: Bool = false
    @Published var isSaving: Bool = false
    @Published var errorMessage: String? = nil
    @Published var imageUploadFailed: Bool = false

    let api: AuthAPI
    let authStore: AuthStore
    private var selectedImageData: Data?
    private var lastCreatedProtocolId: String?

    enum Tab: String, CaseIterable, Identifiable {
        case library = "Library"
        case custom = "Custom"
        var id: String { rawValue }
    }

    enum ActionsCategory: String, CaseIterable, Identifiable {
        case all = "All"
        case topical = "Topical"
        case oral = "Oral"
        case device = "Device"
        case hygiene = "Hygiene"
        var id: String { rawValue }
    }

    private var allActions: [ActionItem] = []

    var filteredActions: [ActionItem] {
        var result = allActions
        if let category = selectedCategory, category != .all {
            result = result.filter { $0.substance?.type.rawValue == category.rawValue }
        }
        if !searchQuery.isEmpty {
            let query = searchQuery.lowercased()
            result = result.filter { $0.name.lowercased().contains(query) }
        }
        return result
    }

    init(api: AuthAPI, authStore: AuthStore) {
        self.api = api
        self.authStore = authStore
    }

    var canSave: Bool {
        !draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && !draft.actions.isEmpty
        && !isSaving
    }

    var customActionItems: [ActionItem] {
        userActions.filter { $0.isActive }.map { action in
            ActionItem(
                id: action.id.uuidString,
                name: action.name,
                category: action.category
            )
        }
    }

    func loadActions() async {
        guard let token = authStore.accessToken else {
            errorMessage = "User not authenticated."
            availableActions = []
            draft.actions = []
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            async let fetchedActions = api.fetchActions(token: token, query: nil)
            async let fetchedSubstances = api.fetchSubstances(token: token, query: nil)
            async let fetchedUserActions = api.fetchUserActions(token: token, category: nil, isActive: nil, page: nil, pageSize: nil)

            let (actions, substances, userActionsPage) = try await (fetchedActions, fetchedSubstances, fetchedUserActions)
            availableActions = actions.toActionItems(using: substances)
            allActions = availableActions
            userActions = userActionsPage.items
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Не удалось загрузить действия."
        }
    }

    func addPredefinedAction(_ action: ActionItem) {
        guard draft.actions.contains(where: { $0.id == action.id }) == false else { return }
        draft.actions.append(action)
    }

    func addUserAction(_ userAction: UserAction) {
        let actionItemId = userAction.id.uuidString
        guard draft.actions.contains(where: { $0.id == actionItemId }) == false else { return }
        let item = ActionItem(
            id: actionItemId,
            name: userAction.name,
            category: userAction.category
        )
        draft.actions.append(item)
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
