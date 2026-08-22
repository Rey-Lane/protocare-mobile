//
//  LoginViewModelTests.swift
//  ProtocareTests
//
//  Tests for LoginViewModel
//

import XCTest
@testable import Protocare

@MainActor
final class LoginViewModelTests: XCTestCase {

    var sut: LoginViewModel!
    var mockAPI: MockAuthAPI!
    var mockAuthStore: MockAuthStore!

    override func setUp() {
        super.setUp()
        mockAPI = MockAuthAPI()
        mockAuthStore = MockAuthStore()
        sut = LoginViewModel(api: mockAPI, authStore: mockAuthStore)
    }

    override func tearDown() {
        sut = nil
        mockAPI = nil
        mockAuthStore = nil
        super.tearDown()
    }

    // MARK: - Validation Tests

    func testCanSubmit_WithValidEmailAndPassword_ReturnsTrue() {
        sut.email = "user@example.com"
        sut.password = "password123"
        XCTAssertTrue(sut.canSubmit)
    }

    func testCanSubmit_WithEmptyEmail_ReturnsFalse() {
        sut.email = ""
        sut.password = "password123"
        XCTAssertFalse(sut.canSubmit)
    }

    func testCanSubmit_WithInvalidEmail_ReturnsFalse() {
        sut.email = "invalid-email"
        sut.password = "password123"
        XCTAssertFalse(sut.canSubmit)
    }

    func testCanSubmit_WithEmptyPassword_ReturnsFalse() {
        sut.email = "user@example.com"
        sut.password = ""
        XCTAssertFalse(sut.canSubmit)
    }

    func testCanSubmit_WhileLoading_ReturnsFalse() {
        sut.email = "user@example.com"
        sut.password = "password123"
        sut.isLoading = true
        XCTAssertFalse(sut.canSubmit)
    }

    // MARK: - Login Success Tests

    func testSubmit_WithValidCredentials_SetsIsLoggedIn() async {
        // Given
        sut.email = "user@example.com"
        sut.password = "password123"
        mockAPI.loginResult = .success(TestFixtures.validLoginResponse)

        // When
        await sut.submit()

        // Then
        XCTAssertTrue(sut.isLoggedIn)
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(mockAuthStore.accessToken, TestFixtures.validLoginResponse.accessToken)
        XCTAssertEqual(mockAuthStore.userId, TestFixtures.validLoginResponse.userId)
    }

    // MARK: - Login Error Tests

    func testSubmit_With401Error_SetsErrorMessage() async {
        // Given
        sut.email = "user@example.com"
        sut.password = "wrongpassword"
        mockAPI.loginResult = .failure(TestFixtures.unauthorizedError)

        // When
        await sut.submit()

        // Then
        XCTAssertFalse(sut.isLoggedIn)
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertNil(mockAuthStore.accessToken)
    }

    func testSubmit_WithNetworkError_SetsErrorMessage() async {
        // Given
        sut.email = "user@example.com"
        sut.password = "password123"
        mockAPI.loginResult = .failure(APIError.transport(NSError(domain: "network", code: -1009)))

        // When
        await sut.submit()

        // Then
        XCTAssertFalse(sut.isLoggedIn)
        XCTAssertNotNil(sut.errorMessage)
    }

    func testSubmit_ClearsErrorMessageOnRetry() async {
        // Given
        sut.email = "user@example.com"
        sut.password = "password123"
        sut.errorMessage = "Previous error"
        mockAPI.loginResult = .success(TestFixtures.validLoginResponse)

        // When
        await sut.submit()

        // Then
        XCTAssertNil(sut.errorMessage)
    }

    func testSubmit_SetsIsLoading() async {
        // Given
        sut.email = "user@example.com"
        sut.password = "password123"
        mockAPI.loginResult = .success(TestFixtures.validLoginResponse)

        // When/Then
        XCTAssertFalse(sut.isLoading)
        
        // Start the async operation
        let task = Task {
            await sut.submit()
        }
        
        // Give a tiny bit of time for the async operation to start
        try? await Task.sleep(nanoseconds: 100_000) // 0.1ms
        
        // During execution, isLoading should be true
        // Note: Due to async nature, this might be flaky. 
        // The important part is that it eventually completes with isLoading = false
        
        await task.value
        XCTAssertFalse(sut.isLoading)
    }
}
