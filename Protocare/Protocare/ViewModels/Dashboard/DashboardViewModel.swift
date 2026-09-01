import Foundation
import Combine

@MainActor
final class DailyDashboardViewModel: ObservableObject {
    @Published var selectedDate: Date = Date() {
        didSet {
            guard !Calendar.current.isDate(oldValue, inSameDayAs: selectedDate) else { return }
            loadTask?.cancel()
            loadTask = Task { await load() }
        }
    }
    @Published private(set) var dailyStatus: DailyStatusResponse?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let api: AuthAPI
    private let authStore: AuthStore
    private var loadTask: Task<Void, Never>?

    init(api: AuthAPI, authStore: AuthStore) {
        self.api = api
        self.authStore = authStore
    }

    func load() async {
        guard let token = authStore.accessToken else {
            errorMessage = "Not authenticated."
            return
        }
        loadTask?.cancel()
        errorMessage = nil

        loadTask = Task { [weak self] in
            guard let self else { return }
            self.isLoading = true
            defer { self.isLoading = false }
            do {
                let status = try await self.api.fetchDailyStatus(token: token, date: self.selectedDate)
                guard !Task.isCancelled else { return }
                self.dailyStatus = status
                self.errorMessage = nil
            } catch is CancellationError {
                // Swallow — a newer request superseded this one
            } catch {
                guard !Task.isCancelled else { return }
                self.errorMessage = (error as? LocalizedError)?.errorDescription ?? "Failed to load daily status."
            }
        }

        await loadTask?.value
    }

    var isViewingToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    func toggleAction(protocolId: String, action: DailyActionStatus) async {
        guard let token = authStore.accessToken else { return }

        errorMessage = nil

        if action.isCompleted {
            await undoCheckin(protocolId: protocolId, action: action, token: token)
        } else {
            await performCheckin(protocolId: protocolId, action: action)
        }
    }

    func performCheckin(
        protocolId: String,
        action: DailyActionStatus,
        quantity: Double? = nil,
        unit: SubstanceUnit? = nil,
        durationSeconds: Int? = nil
    ) async {
        guard let token = authStore.accessToken else { return }

        guard let status = dailyStatus,
              let protoIndex = status.protocols.firstIndex(where: { $0.protocolId == protocolId }),
              let actionIndex = status.protocols[protoIndex].actions.firstIndex(where: { $0.id == action.id })
        else { return }

        let originalStatus = dailyStatus
        applyOptimisticUpdate(
            protoIndex: protoIndex,
            actionIndex: actionIndex,
            quantity: quantity,
            unit: unit,
            durationSeconds: durationSeconds
        )

        let payload = ProtocolCheckinCreate(
            protocolId: protocolId,
            protocolActionId: action.protocolActionId,
            ts: ISO8601DateFormatter().string(from: Date()),
            quantity: quantity ?? action.defaultQuantity?.amount,
            unit: unit ?? action.defaultQuantity?.unit,
            durationSeconds: durationSeconds ?? action.defaultDurationSeconds
        )

        do {
            let checkin = try await api.createCheckin(token: token, payload: payload)
            updateCheckinId(protoIndex: protoIndex, actionIndex: actionIndex, checkinId: checkin.id)
            errorMessage = nil
        } catch {
            dailyStatus = originalStatus
            errorMessage = "Failed to check in. Please try again."
        }
    }

    private func undoCheckin(protocolId: String, action: DailyActionStatus, token: String) async {
        guard let checkinId = action.checkinId else {
            errorMessage = "Cannot undo: check-in ID missing. Refresh and try again."
            return
        }

        guard let status = dailyStatus,
              let protoIndex = status.protocols.firstIndex(where: { $0.protocolId == protocolId }),
              let actionIndex = status.protocols[protoIndex].actions.firstIndex(where: { $0.id == action.id })
        else { return }

        let originalStatus = dailyStatus
        applyOptimisticUndo(protoIndex: protoIndex, actionIndex: actionIndex)

        do {
            try await api.deleteCheckin(token: token, protocolId: protocolId, checkinId: checkinId)
            errorMessage = nil
        } catch {
            dailyStatus = originalStatus
            errorMessage = "Failed to undo check-in. Please try again."
        }
    }

    private func applyOptimisticUpdate(
        protoIndex: Int,
        actionIndex: Int,
        quantity: Double? = nil,
        unit: SubstanceUnit? = nil,
        durationSeconds: Int? = nil
    ) {
        guard let status = dailyStatus else { return }
        var protocols = status.protocols
        var proto = protocols[protoIndex]
        var actions = proto.actions
        let old = actions[actionIndex]

        actions[actionIndex] = DailyActionStatus(
            protocolActionId: old.protocolActionId,
            actionId: old.actionId,
            actionName: old.actionName,
            description: old.description,
            scheduledTime: old.scheduledTime,
            isCompleted: true,
            completedAt: ISO8601DateFormatter().string(from: Date()),
            checkinId: nil,
            quantity: quantity ?? old.defaultQuantity?.amount,
            unit: unit ?? old.defaultQuantity?.unit,
            durationSeconds: durationSeconds ?? old.defaultDurationSeconds,
            completed: true,
            defaultParameters: old.defaultParameters,
            userParameters: old.userParameters
        )

        let newCompleted = actions.filter(\.isCompleted).count
        proto = DailyProtocolStatus(
            protocolId: proto.protocolId,
            protocolName: proto.protocolName,
            completedActions: newCompleted,
            totalActions: proto.totalActions,
            actions: actions
        )
        protocols[protoIndex] = proto

        let totalCompleted = protocols.reduce(0) { $0 + $1.completedActions }
        let totalActions = protocols.reduce(0) { $0 + $1.totalActions }
        let progress = totalActions > 0 ? Int(round(Double(totalCompleted) / Double(totalActions) * 100)) : 0

        dailyStatus = DailyStatusResponse(
            date: status.date,
            streak: status.streak,
            dailyProgressPercentage: progress,
            totalActions: totalActions,
            completedActions: totalCompleted,
            protocols: protocols
        )
    }

    private func updateCheckinId(protoIndex: Int, actionIndex: Int, checkinId: String) {
        guard let status = dailyStatus else { return }
        var protocols = status.protocols
        var proto = protocols[protoIndex]
        var actions = proto.actions
        let old = actions[actionIndex]

        actions[actionIndex] = DailyActionStatus(
            protocolActionId: old.protocolActionId,
            actionId: old.actionId,
            actionName: old.actionName,
            description: old.description,
            scheduledTime: old.scheduledTime,
            isCompleted: old.isCompleted,
            completedAt: old.completedAt,
            checkinId: checkinId,
            quantity: old.quantity,
            unit: old.unit,
            durationSeconds: old.durationSeconds,
            completed: old.completed,
            defaultParameters: old.defaultParameters,
            userParameters: old.userParameters
        )

        proto = DailyProtocolStatus(
            protocolId: proto.protocolId,
            protocolName: proto.protocolName,
            completedActions: proto.completedActions,
            totalActions: proto.totalActions,
            actions: actions
        )
        protocols[protoIndex] = proto

        dailyStatus = DailyStatusResponse(
            date: status.date,
            streak: status.streak,
            dailyProgressPercentage: status.dailyProgressPercentage,
            totalActions: status.totalActions,
            completedActions: status.completedActions,
            protocols: protocols
        )
    }

    private func applyOptimisticUndo(protoIndex: Int, actionIndex: Int) {
        guard let status = dailyStatus else { return }
        var protocols = status.protocols
        var proto = protocols[protoIndex]
        var actions = proto.actions
        let old = actions[actionIndex]

        actions[actionIndex] = DailyActionStatus(
            protocolActionId: old.protocolActionId,
            actionId: old.actionId,
            actionName: old.actionName,
            description: old.description,
            scheduledTime: old.scheduledTime,
            isCompleted: false,
            completedAt: nil,
            checkinId: nil,
            quantity: nil,
            unit: nil,
            durationSeconds: nil,
            completed: true,
            defaultParameters: old.defaultParameters,
            userParameters: old.userParameters
        )

        let newCompleted = actions.filter(\.isCompleted).count
        proto = DailyProtocolStatus(
            protocolId: proto.protocolId,
            protocolName: proto.protocolName,
            completedActions: newCompleted,
            totalActions: proto.totalActions,
            actions: actions
        )
        protocols[protoIndex] = proto

        let totalCompleted = protocols.reduce(0) { $0 + $1.completedActions }
        let totalActions = protocols.reduce(0) { $0 + $1.totalActions }
        let progress = totalActions > 0 ? Int(round(Double(totalCompleted) / Double(totalActions) * 100)) : 0

        dailyStatus = DailyStatusResponse(
            date: status.date,
            streak: status.streak,
            dailyProgressPercentage: progress,
            totalActions: totalActions,
            completedActions: totalCompleted,
            protocols: protocols
        )
    }
}
