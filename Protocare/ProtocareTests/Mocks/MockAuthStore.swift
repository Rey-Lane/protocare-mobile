//
//  MockAuthStore.swift
//  ProtocareTests
//
//  Mock implementation of AuthStore for testing
//

import Foundation
import Combine
@testable import Protocare

class MockAuthStore: AuthStore {
    var mockAccessToken: String?
    var mockRefreshToken: String?
    var mockUserId: String?
    var logoutCalled = false

    // Tracking for updateTokens calls
    var updateTokensCallCount = 0
    var lastUpdatedAccess: String?
    var lastUpdatedRefresh: String?

    override init() {
        super.init()
    }

    override var accessToken: String? {
        get { mockAccessToken }
    }

    override var refreshToken: String? {
        get { mockRefreshToken }
    }

    override var userId: String? {
        get { mockUserId }
    }

    override func logout() {
        logoutCalled = true
        mockAccessToken = nil
        mockRefreshToken = nil
        mockUserId = nil
    }

    override func setAuth(tokens: TokenPair) {
        mockAccessToken = tokens.accessToken
        mockRefreshToken = tokens.refreshToken
        mockUserId = tokens.userId
    }

    override func updateTokens(access: String, refresh: String) {
        updateTokensCallCount += 1
        lastUpdatedAccess = access
        lastUpdatedRefresh = refresh
    }
}
