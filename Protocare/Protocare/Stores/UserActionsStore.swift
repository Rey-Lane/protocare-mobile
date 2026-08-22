import Foundation
import Combine

@MainActor
final class UserActionsStore: ObservableObject {
    @Published private(set) var userActions: [UserAction] = []
    @Published private(set) var templates: [UserAction] = []
    @Published private(set) var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    let api: AuthAPI
    let authStore: AuthStore

    init(api: AuthAPI, authStore: AuthStore) {
        self.api = api
        self.authStore = authStore
    }

    var activeActions: [UserAction] {
        userActions.filter { $0.isActive }
    }

    func loadUserActions() async {
        guard let token = authStore.accessToken else {
            errorMessage = "User not authenticated."
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            async let actionsPage = api.fetchUserActions(token: token, category: nil, isActive: nil, page: nil, pageSize: nil)
            async let templatesList = api.fetchUserActionTemplates(token: token)
            let (page, templatesResult) = try await (actionsPage, templatesList)
            userActions = page.items
            templates = templatesResult
        } catch {
            // Try to load at least user actions if templates fail
            do {
                let page = try await api.fetchUserActions(token: token, category: nil, isActive: nil, page: nil, pageSize: nil)
                userActions = page.items
            } catch {
                errorMessage = (error as? LocalizedError)?.errorDescription ?? "Failed to load user actions."
            }
        }
    }

    func createUserAction(_ payload: UserActionCreate) async -> UserAction? {
        guard let token = authStore.accessToken else {
            errorMessage = "User not authenticated."
            return nil
        }
        errorMessage = nil

        do {
            let created = try await api.createUserAction(token: token, payload: payload)
            userActions.append(created)
            return created
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Failed to create action."
            return nil
        }
    }

    func updateUserAction(id: UUID, payload: UserActionUpdate) async -> UserAction? {
        guard let token = authStore.accessToken else {
            errorMessage = "User not authenticated."
            return nil
        }
        errorMessage = nil

        do {
            let updated = try await api.updateUserAction(token: token, actionId: id, payload: payload)
            if let index = userActions.firstIndex(where: { $0.id == id }) {
                userActions[index] = updated
            }
            return updated
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Failed to update action."
            return nil
        }
    }

    func deleteUserAction(id: UUID) async -> Bool {
        guard let token = authStore.accessToken else {
            errorMessage = "User not authenticated."
            return false
        }
        errorMessage = nil

        do {
            try await api.deleteUserAction(token: token, actionId: id)
            userActions.removeAll { $0.id == id }
            return true
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Failed to delete action."
            return false
        }
    }

    func duplicateAction(id: UUID) async -> UserAction? {
        guard let token = authStore.accessToken else {
            errorMessage = "User not authenticated."
            return nil
        }
        errorMessage = nil

        do {
            let duplicated = try await api.duplicateUserAction(token: token, actionId: id)
            userActions.append(duplicated)
            return duplicated
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Failed to duplicate action."
            return nil
        }
    }

    func action(withId id: UUID) -> UserAction? {
        userActions.first { $0.id == id }
    }
}
