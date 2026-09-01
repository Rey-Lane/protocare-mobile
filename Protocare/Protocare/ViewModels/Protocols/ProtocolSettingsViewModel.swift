import Combine
import Foundation
import SwiftUI

@MainActor
final class ProtocolSettingsViewModel: ObservableObject {
    let item: ProtocolItem
    let actionsLookup: [String: ActionItem]
    let api: AuthAPI
    let authStore: AuthStore

    // MARK: - Edit State

    @Published var editName = ""
    @Published var editIcon: String?
    @Published var editCategory: ProtocolCategory?
    @Published var editMetricKeys: [MetricKey]?
    @Published var editIsActive = true
    @Published var editStartedAt = Date()
    @Published var editEndedAt: Date?
    @Published var hasEditEndedAt = false

    // Image
    @Published var protocolImageURL: String?
    @Published var protocolImageId: String?
    @Published var editSelectedImage: UIImage?
    @Published var editImageData: Data?
    @Published var editImageChanged = false
    @Published var editImageRemoved = false
    @Published var isShowingEditImagePicker = false

    // Actions
    @Published var editActions: [ActionItem] = []
    @Published var scheduleAction: ActionItem?
    @Published var isShowingActionPicker = false

    /// Maps ActionItem.id to the corresponding ProtocolAction.id (the link-table row ID).
    /// Needed to call DELETE /protocols/{id}/actions/{protocol_action_id} when removing actions.
    private var actionItemToProtocolActionId: [String: String] = [:]

    // Status
    @Published var isUpdating = false
    @Published var editError: String?
    @Published var showDeleteConfirmation = false

    // Library loading (for action picker)
    @Published var availableActions: [ActionItem] = []
    @Published var isLoadingActions = false

    var currentProtocol: ProtocolItem { item }

    var canSave: Bool {
        !editName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && !editActions.isEmpty
        && !isUpdating
    }

    init(
        item: ProtocolItem,
        actionsLookup: [String: ActionItem],
        api: AuthAPI,
        authStore: AuthStore,
        protocolImageURL: String? = nil,
        protocolImageId: String? = nil
    ) {
        self.item = item
        self.actionsLookup = actionsLookup
        self.api = api
        self.authStore = authStore
        self.protocolImageURL = protocolImageURL
        self.protocolImageId = protocolImageId

        // Populate edit state from item
        editName = item.name
        editCategory = item.category
        editIsActive = item.isActive ?? true
        editIcon = nil // Protocol has no icon on backend — local only

        // Parse metric keys
        if let keys = item.metricKeys {
            editMetricKeys = keys.compactMap { MetricKey(rawValue: $0) }
        }

        // Parse dates
        if let startedAt = item.startedAt {
            editStartedAt = ISO8601DateFormatter().date(from: startedAt) ?? Date()
        }
        if let endedAt = item.endedAt {
            editEndedAt = ISO8601DateFormatter().date(from: endedAt)
            hasEditEndedAt = true
        }

        // Build action items from protocol actions.
        // Unified model (Step 23): every ProtocolAction carries a single
        // non-optional `action_id`; resolve names straight from actionsLookup.
        editActions = item.actions.sorted(by: { ($0.position ?? 0) < ($1.position ?? 0) }).compactMap { pa in
            guard var item = actionsLookup[pa.actionId] else { return nil }
            item.schedule = ActionSchedule.fromRRule(pa.rrule)
            item.userParameters = pa.userParameters
            actionItemToProtocolActionId[item.id] = pa.id
            // Restore slots from notification schedule so ScheduleActionSheet
            // shows the previously saved time instead of defaulting to 8:00
            if item.slots.isEmpty, let notifSchedule = pa.notificationSchedule {
                let parts = notifSchedule.preferredTime.split(separator: ":")
                let hour = parts.count >= 1 ? Int(parts[0]) ?? 8 : 8
                let minute = parts.count >= 2 ? Int(parts[1]) ?? 0 : 0
                let snappedMinute = (minute / 5) * 5
                item.slots = [
                    ScheduleSlot(
                        hour: hour,
                        minute: snappedMinute,
                        isReminderOn: notifSchedule.isEnabled,
                        reminderOffsetMinutes: 0
                    )
                ]
            }
            return item
        }
    }

    // MARK: - Load Actions (for picker)

    func loadAvailableActions() async {
        guard let token = authStore.accessToken else { return }
        guard availableActions.isEmpty else { return } // Load once
        isLoadingActions = true
        defer { isLoadingActions = false }

        do {
            // Unified action source: GET /actions returns library + user-created
            // actions. No user-actions fetch, no substances needed for display.
            let fetchedActions = try await api.fetchActions(token: token, query: nil)
            availableActions = fetchedActions.toActionItems()
        } catch {
            // Non-critical — picker will show empty state
        }
    }

    // MARK: - Action Management

    func addAction(_ action: ActionItem) {
        guard !editActions.contains(where: { $0.id == action.id }) else { return }
        editActions.append(action)
    }

    func removeAction(_ action: ActionItem) {
        editActions.removeAll { $0.id == action.id }
    }

    func updateSchedule(for action: ActionItem, schedule: ActionSchedule, slots: [ScheduleSlot] = []) {
        guard let index = editActions.firstIndex(where: { $0.id == action.id }) else { return }
        editActions[index].schedule = schedule
        if !slots.isEmpty {
            editActions[index].slots = slots
        }
    }

    // MARK: - Save

    func save() async -> Bool {
        guard canSave else { return false }
        guard let token = authStore.accessToken else {
            editError = "Not authenticated."
            return false
        }

        isUpdating = true
        defer { isUpdating = false }
        editError = nil

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]

        var payload = ProtocolUpdate(
            name: editName.trimmingCharacters(in: .whitespaces),
            isActive: editIsActive,
            startedAt: formatter.string(from: editStartedAt),
            endedAt: nil,
            category: editCategory,
            metricKeys: editMetricKeys?.map(\.rawValue)
        )
        if hasEditEndedAt, let endedAt = editEndedAt {
            payload.endedAt = formatter.string(from: endedAt)
        }

        do {
            // Delete actions that were removed from the protocol
            let currentActionIds = Set(editActions.map { $0.id })
            let originalActionIds = Set(actionItemToProtocolActionId.keys)
            let removedActionIds = originalActionIds.subtracting(currentActionIds)

            for actionId in removedActionIds {
                if let protocolActionId = actionItemToProtocolActionId[actionId] {
                    try await api.removeActionFromProtocol(
                        token: token,
                        protocolId: item.id,
                        protocolActionId: protocolActionId
                    )
                    actionItemToProtocolActionId.removeValue(forKey: actionId)
                }
            }

            _ = try await api.updateProtocol(token: token, protocolId: item.id, payload: payload)

            // Handle image changes
            if editImageChanged {
                if editImageRemoved, let existingImageId = protocolImageId {
                    try? await api.deleteImage(token: token, imageId: existingImageId)
                    protocolImageURL = nil
                    protocolImageId = nil
                }
                if let imageData = editImageData {
                    if let existingImageId = protocolImageId {
                        try? await api.deleteImage(token: token, imageId: existingImageId)
                    }
                    let result = try await api.uploadProtocolImage(token: token, protocolId: item.id, imageData: imageData)
                    if let newUrl = result.url {
                        protocolImageURL = newUrl
                        protocolImageId = result.id
                    }
                }
            }

            return true
        } catch {
            editError = (error as? LocalizedError)?.errorDescription ?? "Failed to update protocol."
            return false
        }
    }

    // MARK: - Delete

    func deleteProtocol(parentVM: ProtocolsViewModel) async {
        await parentVM.deleteProtocol(item)
    }
}
