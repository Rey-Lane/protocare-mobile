import Foundation
import Combine
import os.log

@MainActor
class AuthStore: ObservableObject {
    @Published private(set) var isAuthenticated: Bool = false

    private var _accessToken: String? = nil
    private var _refreshToken: String? = nil
    private var _userId: String? = nil

    /// Read-only access to the current access token.
    var accessToken: String? { _accessToken }
    /// Read-only access to the current refresh token.
    var refreshToken: String? { _refreshToken }
    /// Read-only access to the current user ID.
    var userId: String? { _userId }

    private let keychain = KeychainStore(service: "com.protocare.auth")
    private let tokenKey = "access_token"
    private let refreshTokenKey = "refresh_token"
    private let userIdKey = "user_id"
    private let logger = Logger(subsystem: "com.protocare", category: "AuthStore")

    var api: AuthAPI?

    /// Whether startup token validation is still in progress.
    @Published private(set) var isValidating: Bool = false

    init() {
        self._accessToken = keychain.get(key: tokenKey)
        self._refreshToken = keychain.get(key: refreshTokenKey)
        self._userId = keychain.get(key: userIdKey)
        self.isAuthenticated = _accessToken != nil
    }

    /// Validate stored auth during app launch.
    ///
    /// If an access token exists in Keychain, this tries a lightweight API call
    /// (`fetchCurrentUser`). On 401 it attempts a token refresh. If the refresh
    /// also fails, the session is cleared and the user is sent to the login screen.
    ///
    /// Call this once from the splash screen; it sets `isValidating` while running
    /// so the UI can hold the splash until the result is known.
    func validateStoredAuth() async {
        guard _accessToken != nil else {
            // No stored token — user must log in. isAuthenticated is already false.
            return
        }

        isValidating = true
        defer { isValidating = false }

        // Try a lightweight authenticated request.
        if let api = api as? APIClient, let token = _accessToken {
            do {
                _ = try await api.fetchCurrentUser(token: token)
                // Access token is still valid — nothing to do.
                logger.info("Startup validation: access token still valid")
                return
            } catch {
                logger.info("Startup validation: access token expired, attempting refresh")
            }
        }

        // Access token expired (or missing) — try refresh.
        guard let refreshToken = _refreshToken else {
            logger.warning("Startup validation: no refresh token, clearing session")
            clearSession()
            return
        }

        guard let api = api else {
            logger.warning("Startup validation: no API configured, clearing session")
            clearSession()
            return
        }

        do {
            let request = RefreshTokenRequest(refreshToken: refreshToken)
            let tokens = try await api.refresh(request: request)
            updateTokens(access: tokens.accessToken, refresh: tokens.refreshToken)
            logger.info("Startup validation: refresh successful")
        } catch {
            logger.warning("Startup validation: refresh failed, clearing session — \(error.localizedDescription)")
            clearSession()
        }
    }

    /// Clear in-memory and Keychain tokens without calling the server logout endpoint.
    /// Used when the session is already invalid and we just need to clean up locally.
    private func clearSession() {
        _accessToken = nil
        _refreshToken = nil
        _userId = nil
        isAuthenticated = false

        try? keychain.delete(key: tokenKey)
        try? keychain.delete(key: refreshTokenKey)
        try? keychain.delete(key: userIdKey)
    }

    func setAuth(tokens: TokenPair) {
        _accessToken = tokens.accessToken
        _refreshToken = tokens.refreshToken
        _userId = tokens.userId
        isAuthenticated = _accessToken != nil

        // Write refresh + userId first, then access token.
        // See updateTokens() for rationale on ordering.
        do {
            try keychain.set(tokens.refreshToken, key: refreshTokenKey)
            try keychain.set(tokens.userId, key: userIdKey)
            try keychain.set(tokens.accessToken, key: tokenKey)
        } catch {
            logger.error("Keychain write failed in setAuth: \(error.localizedDescription)")
        }
    }

    func updateTokens(access: String, refresh: String) {
        _accessToken = access
        _refreshToken = refresh
        isAuthenticated = _accessToken != nil

        // Write refresh token FIRST — it is critical for session recovery.
        // If the app crashes between the two writes, having the new refresh token
        // in Keychain allows TokenRefreshManager to obtain a fresh access token
        // on the next launch. Writing access first would leave a stale (revoked)
        // refresh token, making the session unrecoverable.
        do {
            try keychain.set(refresh, key: refreshTokenKey)
        } catch {
            logger.error("Keychain write failed for refresh_token: \(error.localizedDescription)")
        }
        do {
            try keychain.set(access, key: tokenKey)
        } catch {
            logger.error("Keychain write failed for access_token: \(error.localizedDescription)")
        }
    }

    func logout() {
        if let refresh = _refreshToken {
            Task {
                try? await api?.logout(refreshToken: refresh)
            }
        }
        _accessToken = nil
        _refreshToken = nil
        _userId = nil
        isAuthenticated = false

        do {
            try keychain.delete(key: tokenKey)
        } catch {
            logger.warning("Keychain delete failed for access_token: \(error.localizedDescription)")
        }
        do {
            try keychain.delete(key: refreshTokenKey)
        } catch {
            logger.warning("Keychain delete failed for refresh_token: \(error.localizedDescription)")
        }
        do {
            try keychain.delete(key: userIdKey)
        } catch {
            logger.warning("Keychain delete failed for user_id: \(error.localizedDescription)")
        }
    }
}
