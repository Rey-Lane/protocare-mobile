import Foundation
import Combine

@MainActor
final class ActionCheckinViewModel: ObservableObject {
    @Published var isSaving = false
    @Published var errorMessage: String?

    private let api: AuthAPI
    private let authStore: AuthStore
    private let protocolId: String
    private let protocolActionId: String

    init(api: AuthAPI, authStore: AuthStore, protocolId: String, protocolActionId: String) {
        self.api = api
        self.authStore = authStore
        self.protocolId = protocolId
        self.protocolActionId = protocolActionId
    }

    func submit(payload: ProtocolCheckinCreate) async -> Bool {
        guard let token = authStore.accessToken else {
            errorMessage = "Пользователь не авторизован."
            return false
        }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            _ = try await api.createCheckin(token: token, payload: payload)
            return true
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Не удалось отправить чек-ин."
            return false
        }
    }
}
