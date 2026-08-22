//
//  TokenRefreshManagerTests.swift
//  ProtocareTests
//
//  Tests for TokenRefreshManager actor
//

import XCTest
@testable import Protocare

@MainActor
final class TokenRefreshManagerTests: XCTestCase {

    private var mockAPI: MockAuthAPI!
    private var mockAuthStore: MockAuthStore!

    override func setUp() {
        super.setUp()
        mockAPI = MockAuthAPI()
        mockAuthStore = MockAuthStore()
    }

    override func tearDown() {
        mockAPI = nil
        mockAuthStore = nil
        super.tearDown()
    }

    // MARK: - Successful Refresh

    func testRefreshTokens_SuccessReturnsTrue() async {
        mockAuthStore.mockRefreshToken = "valid_refresh_token"
        mockAPI.refreshResult = .success(
            TokenPair(userId: "user-1", accessToken: "new_access", refreshToken: "new_refresh")
        )

        let sut = TokenRefreshManager(api: mockAPI, authStore: mockAuthStore)
        let result = await sut.refreshTokens()

        XCTAssertTrue(result)
        XCTAssertEqual(mockAuthStore.lastUpdatedAccess, "new_access")
        XCTAssertEqual(mockAuthStore.lastUpdatedRefresh, "new_refresh")
        XCTAssertEqual(mockAPI.refreshCallCount, 1)
    }

    // MARK: - Nil Refresh Token

    func testRefreshTokens_NilRefreshTokenReturnsFalse() async {
        mockAuthStore.mockRefreshToken = nil

        let sut = TokenRefreshManager(api: mockAPI, authStore: mockAuthStore)
        let result = await sut.refreshTokens()

        XCTAssertFalse(result)
        XCTAssertEqual(mockAPI.refreshCallCount, 0, "Should not call API when refresh token is nil")
    }

    // MARK: - Concurrent Refresh Calls

    func testRefreshTokens_ConcurrentCallsOnlyOneActualRefresh() async {
        mockAuthStore.mockRefreshToken = "valid_refresh_token"
        mockAPI.refreshResult = .success(
            TokenPair(userId: "user-1", accessToken: "new_access", refreshToken: "new_refresh")
        )

        let sut = TokenRefreshManager(api: mockAPI, authStore: mockAuthStore)

        // Fire multiple concurrent refresh calls
        async let r1: Bool = sut.refreshTokens()
        async let r2: Bool = sut.refreshTokens()
        async let r3: Bool = sut.refreshTokens()

        let results = await [r1, r2, r3]

        // All should succeed
        XCTAssertTrue(results.allSatisfy { $0 == true })

        // Only one actual API call should have been made
        XCTAssertEqual(mockAPI.refreshCallCount, 1, "Concurrent calls should coalesce into a single API refresh")
    }

    // MARK: - API Error

    func testRefreshTokens_APIErrorReturnsFalse() async {
        mockAuthStore.mockRefreshToken = "valid_refresh_token"
        mockAPI.refreshResult = .failure(NSError(domain: "test", code: -1))

        let sut = TokenRefreshManager(api: mockAPI, authStore: mockAuthStore)
        let result = await sut.refreshTokens()

        XCTAssertFalse(result)
        XCTAssertEqual(mockAPI.refreshCallCount, 1)
    }
}
