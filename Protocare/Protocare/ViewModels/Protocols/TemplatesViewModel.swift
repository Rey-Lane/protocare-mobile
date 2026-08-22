import Foundation
import Combine

@MainActor
final class TemplatesViewModel: ObservableObject {
    @Published private(set) var templates: [ProtocolTemplate] = []
    @Published private(set) var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var isCreating: Bool = false
    @Published var creationErrorMessage: String? = nil

    private let api: AuthAPI
    private let authStore: AuthStore

    var groupedByCategory: [(category: TemplateCategory, templates: [ProtocolTemplate])] {
        let groups = Dictionary(grouping: templates) { template in
            template.category
        }
        return TemplateCategory.allCases
            .filter { groups[$0] != nil }
            .map { ($0, groups[$0] ?? []) }
    }

    init(api: AuthAPI, authStore: AuthStore) {
        self.api = api
        self.authStore = authStore
    }

    func loadTemplates() async {
        guard let token = authStore.accessToken else {
            errorMessage = "User not authenticated."
            templates = []
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            templates = try await api.fetchTemplates(token: token)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Failed to load templates."
        }
    }

    func createProtocol(from template: ProtocolTemplate) async -> Bool {
        guard let token = authStore.accessToken else {
            creationErrorMessage = "User not authenticated."
            return false
        }
        isCreating = true
        creationErrorMessage = nil
        defer { isCreating = false }

        do {
            _ = try await api.createProtocolFromTemplate(token: token, templateId: template.id)
            return true
        } catch {
            creationErrorMessage = (error as? LocalizedError)?.errorDescription ?? "Failed to create protocol from template."
            return false
        }
    }
}
