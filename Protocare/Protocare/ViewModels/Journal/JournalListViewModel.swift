import Combine
import Foundation

@MainActor
final class JournalListViewModel: ObservableObject {
    @Published var protocols: [ProtocolItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let api: AuthAPI
    private let authStore: AuthStore

    init(api: AuthAPI, authStore: AuthStore) {
        self.api = api
        self.authStore = authStore
    }

    func load() async {
        guard let token = authStore.accessToken else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            protocols = try await api.fetchProtocols(token: token, category: nil)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
