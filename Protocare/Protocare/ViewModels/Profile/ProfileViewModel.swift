import Combine
import Foundation
import os.log

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published private(set) var profile: UserProfile
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published var isSaving = false
    @Published var isDeleting = false

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

    func updateProfile(name: String) async {
        guard let token = authStore.accessToken else {
            errorMessage = "Not authenticated"
            return
        }

        isSaving = true
        errorMessage = nil

        do {
            let payload = ProfileUpdateRequest(name: name)
            let response = try await api.updateProfile(token: token, payload: payload)
            profile = UserProfile(from: response)
        } catch {
            logger.error("Failed to update profile: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }

        isSaving = false
    }

    func uploadProfileImage(imageData: Data) async {
        guard let token = authStore.accessToken else {
            errorMessage = "Not authenticated"
            return
        }

        isSaving = true
        errorMessage = nil

        do {
            let response = try await api.uploadProfileImage(token: token, imageData: imageData)
            profile = UserProfile(from: response)
        } catch {
            logger.error("Failed to upload profile image: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }

        isSaving = false
    }

    func deleteAccount() async {
        guard let token = authStore.accessToken else {
            errorMessage = "Not authenticated"
            return
        }

        isDeleting = true
        errorMessage = nil

        do {
            try await api.deleteAccount(token: token)
            authStore.logout()
        } catch {
            logger.error("Failed to delete account: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }

        isDeleting = false
    }

    func logout() {
        authStore.logout()
    }
}
