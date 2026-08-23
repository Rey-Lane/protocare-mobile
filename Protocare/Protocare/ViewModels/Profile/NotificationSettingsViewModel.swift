import Combine
import Foundation
import SwiftUI

@MainActor
final class NotificationSettingsViewModel: ObservableObject {
    @Published var items: [NotificationScheduleItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    let api: AuthAPI
    let authStore: AuthStore

    var activeCount: Int {
        items.filter(\.isEnabled).count
    }

    var totalCount: Int {
        items.count
    }

    init(api: AuthAPI, authStore: AuthStore) {
        self.api = api
        self.authStore = authStore
    }

    func load() async {
        guard let token = authStore.accessToken else {
            errorMessage = "Not authenticated"
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            async let schedules = api.fetchNotificationSchedules(token: token, protocolActionId: nil)
            async let protocols = api.fetchProtocols(token: token, category: nil)
            async let actions = api.fetchActions(token: token, query: nil)
            async let substances = api.fetchSubstances(token: token, query: nil)
            async let userActions = api.fetchUserActions(token: token, category: nil, isActive: nil, page: nil, pageSize: nil)

            let (schedulesResponse, protocolsResponse, actionsResponse, substancesResponse, userActionsResponse) = try await (
                schedules, protocols, actions, substances, userActions
            )

            // Build action lookups (same pattern as ProtocolsViewModel)
            let enrichedActions = actionsResponse.toActionItems(using: substancesResponse)
            let actionsLookup = Dictionary(uniqueKeysWithValues: enrichedActions.map { ($0.id, $0) })
            let userActionsLookup: [String: ActionItem] = Dictionary(
                uniqueKeysWithValues: userActionsResponse.items.compactMap { ua in
                    (ua.id.uuidString, ActionItem(id: ua.id.uuidString, name: ua.name, userActionId: ua.id, userActionCategory: ua.category))
                }
            )

            // Build lookup: protocolActionId -> (actionName, protocolName)
            var actionLookup: [String: (actionName: String, protocolName: String)] = [:]
            for proto in protocolsResponse {
                for pa in proto.actions {
                    var name: String?
                    if let actionId = pa.actionId, let action = actionsLookup[actionId] {
                        name = action.displayName
                    } else if let uaId = pa.userActionId, let action = userActionsLookup[uaId.uuidString] {
                        name = action.displayName
                    }
                    actionLookup[pa.id] = (actionName: name ?? "Action", protocolName: proto.name)
                }
            }

            items = schedulesResponse.compactMap { schedule -> NotificationScheduleItem? in
                guard let info = actionLookup[schedule.protocolActionId] else { return nil }
                return NotificationScheduleItem(
                    id: schedule.id,
                    preferredTime: schedule.preferredTime,
                    actionName: info.actionName,
                    protocolName: info.protocolName,
                    isEnabled: schedule.isEnabled
                )
            }
            .sorted { $0.preferredTime < $1.preferredTime }

        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Failed to load notifications."
        }
    }

    func toggleItem(_ item: NotificationScheduleItem) {
        guard let token = authStore.accessToken else { return }
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }

        let newValue = !items[index].isEnabled
        items[index].isEnabled = newValue

        let scheduleId = item.id
        Task {
            do {
                let payload = NotificationScheduleUpdate(isEnabled: newValue)
                _ = try await api.updateNotificationSchedule(
                    token: token,
                    scheduleId: scheduleId,
                    payload: payload
                )
            } catch {
                // Revert on failure
                guard let idx = self.items.firstIndex(where: { $0.id == scheduleId }) else { return }
                self.items[idx].isEnabled = !newValue
            }
        }
    }
}

// MARK: - Display Model

struct NotificationScheduleItem: Identifiable {
    let id: String
    let preferredTime: String
    let actionName: String
    let protocolName: String
    var isEnabled: Bool
}
