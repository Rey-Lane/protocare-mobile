import Combine
import Foundation
import os.log

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published private(set) var profile: UserProfile
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let api: AuthAPI
    private let authStore: AuthStore
    private let logger = Logger(subsystem: "com.protocare", category: "ProfileVM")

    init(api: AuthAPI, authStore: AuthStore) {
        self.api = api
        self.authStore = authStore

        // Placeholder until API data loads
        self.profile = UserProfile(
            name: "—",
            email: "—",
            initials: "—",
            stats: UserProfileStats(protocolsCount: 0, streak: 0, checkinsCount: 0)
        )
    }

    func loadProfile() async {
        guard let token = authStore.accessToken else {
            errorMessage = "Not authenticated"
            return
        }
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        do {
            let response = try await api.fetchCurrentUser(token: token)
            profile = UserProfile(from: response)
        } catch {
            logger.error("Failed to load profile: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func logout() {
        authStore.logout()
    }
}
