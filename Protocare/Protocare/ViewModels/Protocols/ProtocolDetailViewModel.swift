import Combine
import Foundation
import SwiftUI

@MainActor
final class ProtocolDetailViewModel: ObservableObject {
    let item: ProtocolItem
    let actionsLookup: [String: ActionItem]
    let userActionsLookup: [String: ActionItem]
    let api: AuthAPI
    let authStore: AuthStore
    let parentViewModel: ProtocolsViewModel
    var autoOpenEdit: Bool = false

    @Published var selectedAction: ProtocolAction?
    @Published var selectedActionForSchedule: ProtocolAction?
    @Published var protocolImageURL: String?
    @Published var showDeleteConfirmation = false
    @Published var isDeleting = false
    @Published var dailyStatus: ProtocolDailyStatus?
    @Published var isLoadingStatus = false
    @Published var statusError: String?
    @Published var updatedProtocol: ProtocolItem?
    @Published var protocolImageId: String?
    @Published var isShowingActionPicker = false
    @Published var isAddingAction = false
    @Published var addActionError: String?

    @Published var isReordering = false

    var currentProtocol: ProtocolItem {
        updatedProtocol ?? item
    }

    init(
        item: ProtocolItem,
        actionsLookup: [String: ActionItem],
        userActionsLookup: [String: ActionItem],
        api: AuthAPI,
        authStore: AuthStore,
        parentViewModel: ProtocolsViewModel,
        initialProtocolImageURL: String? = nil,
        autoOpenEdit: Bool = false
    ) {
        self.item = item
        self.actionsLookup = actionsLookup
        self.userActionsLookup = userActionsLookup
        self.api = api
        self.authStore = authStore
        self.parentViewModel = parentViewModel
        self.protocolImageURL = initialProtocolImageURL
        self.autoOpenEdit = autoOpenEdit
    }

    func loadInitialData() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadProtocolImage() }
            group.addTask { await self.loadDailyStatus() }
        }
    }

    func loadProtocolImage() async {
        guard let token = authStore.accessToken else {
            protocolImageURL = nil
            protocolImageId = nil
            return
        }

        do {
            let image = try await api.fetchProtocolImage(token: token, protocolId: item.id)
            if let url = image.url, !url.isEmpty {
                protocolImageURL = url
                protocolImageId = image.id
            } else {
                protocolImageURL = nil
                protocolImageId = nil
            }
        } catch APIError.server(let status, _) where status == 404 {
            protocolImageURL = nil
            protocolImageId = nil
        } catch {
            protocolImageURL = nil
            protocolImageId = nil
        }
    }

    func loadDailyStatus() async {
        guard let token = authStore.accessToken else {
            statusError = "Not authenticated"
            return
        }

        isLoadingStatus = true
        statusError = nil

        do {
            dailyStatus = try await api.fetchProtocolDailyStatus(token: token, protocolId: item.id, date: nil)
        } catch {
            statusError = error.localizedDescription
        }

        isLoadingStatus = false
    }

    func deleteProtocol() async {
        isDeleting = true
        await parentViewModel.deleteProtocol(currentProtocol)
        isDeleting = false
    }

    func addActionToProtocol(actionItem: ActionItem) async {
        guard let token = authStore.accessToken else {
            addActionError = "Not authenticated"
            return
        }
        isAddingAction = true
        defer { isAddingAction = false }

        let nextPosition = (currentProtocol.actions.map { $0.position ?? 0 }.max() ?? -1) + 1
        // Use actionId for predefined (library) actions, userActionId for custom
        let payload = ProtocolActionCreate(
            actionId: actionItem.userActionId == nil ? actionItem.id : nil,
            userActionId: actionItem.userActionId,
            rrule: "FREQ=DAILY",
            position: nextPosition
        )

        do {
            let result = try await api.addActionToProtocol(
                token: token,
                protocolId: currentProtocol.id,
                payload: payload
            )
            self.updatedProtocol = result
            await loadDailyStatus()
            isShowingActionPicker = false
        } catch {
            addActionError = (error as? LocalizedError)?.errorDescription ?? "Failed to add action."
        }
    }

    func reorderActions(from source: IndexSet, to destination: Int) async {
        guard let actions = dailyStatus?.actions.sorted(by: { $0.position < $1.position }) else { return }
        let originalStatus = dailyStatus
        var reorderedActions = actions
        reorderedActions.move(fromOffsets: source, toOffset: destination)
        for (i, action) in reorderedActions.enumerated() {
            var mutated = action
            mutated.position = i
            reorderedActions[i] = mutated
        }
        dailyStatus?.actions = reorderedActions

        let mutableIds = reorderedActions.map(\.protocolActionId)
        guard let token = authStore.accessToken else { return }
        isReordering = true
        do {
            try await api.reorderProtocolActions(token: token, protocolId: item.id, actionIds: mutableIds)
        } catch {
            dailyStatus = originalStatus
        }
        isReordering = false
    }

    func refresh() async {
        await loadDailyStatus()
    }
}
