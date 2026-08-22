import Foundation

actor TokenRefreshManager {
    private var isRefreshing = false
    private var waitingContinuations: [CheckedContinuation<Bool, Never>] = []
    private let api: AuthAPI
    private let authStore: AuthStore

    init(api: AuthAPI, authStore: AuthStore) {
        self.api = api
        self.authStore = authStore
    }

    func refreshTokens() async -> Bool {
        if isRefreshing {
            return await withCheckedContinuation { continuation in
                waitingContinuations.append(continuation)
            }
        }

        isRefreshing = true

        guard let currentRefresh = await authStore.refreshToken else {
            isRefreshing = false
            notifyWaiters(result: false)
            return false
        }

        do {
            let request = RefreshTokenRequest(refreshToken: currentRefresh)
            let tokens = try await api.refresh(request: request)
            await authStore.updateTokens(access: tokens.accessToken, refresh: tokens.refreshToken)
            isRefreshing = false
            notifyWaiters(result: true)
            return true
        } catch {
            isRefreshing = false
            notifyWaiters(result: false)
            return false
        }
    }

    private func notifyWaiters(result: Bool) {
        for continuation in waitingContinuations {
            continuation.resume(returning: result)
        }
        waitingContinuations.removeAll()
    }
}
