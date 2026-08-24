//
//  ProfileViewModelTests.swift
//  ProtocareTests
//
//  Tests for ProfileViewModel — loadProfile, updateProfile, uploadProfileImage, deleteAccount
//

import XCTest
@testable import Protocare

@MainActor
final class ProfileViewModelTests: XCTestCase {

    var sut: ProfileViewModel!
    var mockAPI: MockAuthAPI!
    var mockAuthStore: MockAuthStore!

    override func setUp() {
        super.setUp()
        mockAPI = MockAuthAPI()
        mockAuthStore = MockAuthStore()
        sut = ProfileViewModel(api: mockAPI, authStore: mockAuthStore)
    }

    override func tearDown() {
        sut = nil
        mockAPI = nil
        mockAuthStore = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func setAuthenticated() {
        mockAuthStore.setAuth(tokens: TestFixtures.validAuthTokens)
    }

    private func makeUserMeResponse(
        name: String? = "Alex",
        avatarURL: String? = nil
    ) -> UserMeResponse {
        UserMeResponse(
            id: UUID().uuidString,
            email: "alex@protocare.app",
            name: name,
            avatarURL: avatarURL,
            isActive: true,
            role: "user",
            timezone: nil,
            protocolsCount: 3,
            streak: StreakInfo(currentStreak: 7, longestStreak: 14),
            totalCheckins: 42
        )
    }

    // MARK: - Initial State

    func testInitialState_HasPlaceholderProfile() {
        XCTAssertEqual(sut.profile.name, "—")
        XCTAssertEqual(sut.profile.email, "—")
        XCTAssertFalse(sut.isLoading)
        XCTAssertFalse(sut.isSaving)
        XCTAssertFalse(sut.isDeleting)
        XCTAssertNil(sut.errorMessage)
    }

    // MARK: - Load Profile

    func testLoadProfile_WhenAuthenticated_UpdatesProfile() async {
        setAuthenticated()
        let expected = makeUserMeResponse(name: "Alex")
        mockAPI.fetchCurrentUserResult = .success(expected)

        await sut.loadProfile()

        XCTAssertEqual(sut.profile.name, "Alex")
        XCTAssertEqual(sut.profile.email, "alex@protocare.app")
        XCTAssertEqual(sut.profile.stats.protocolsCount, 3)
        XCTAssertEqual(sut.profile.stats.streak, 7)
        XCTAssertEqual(sut.profile.stats.checkinsCount, 42)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
    }

    func testLoadProfile_WhenNotAuthenticated_SetsError() async {
        // authStore has no token by default
        await sut.loadProfile()

        XCTAssertEqual(sut.errorMessage, "Not authenticated")
        XCTAssertFalse(sut.isLoading)
    }

    func testLoadProfile_WhenServerError_SetsErrorMessage() async {
        setAuthenticated()
        mockAPI.fetchCurrentUserResult = .failure(APIError.server(status: 500, message: "Internal error"))

        await sut.loadProfile()

        XCTAssertNotNil(sut.errorMessage)
        XCTAssertFalse(sut.isLoading)
    }

    func testLoadProfile_WithNullName_FallsBackToEmailPrefix() async {
        setAuthenticated()
        let response = makeUserMeResponse(name: nil)
        mockAPI.fetchCurrentUserResult = .success(response)

        await sut.loadProfile()

        // Name fallback: email local part capitalized
        XCTAssertEqual(sut.profile.name, "Alex")
    }

    func testLoadProfile_WithAvatarURL_StoresAvatarURL() async {
        setAuthenticated()
        let response = makeUserMeResponse(avatarURL: "https://cdn.example.com/avatar.jpg")
        mockAPI.fetchCurrentUserResult = .success(response)

        await sut.loadProfile()

        XCTAssertEqual(sut.profile.avatarURL, "https://cdn.example.com/avatar.jpg")
    }

    // MARK: - Update Profile

    func testUpdateProfile_WhenAuthenticated_UpdatesName() async {
        setAuthenticated()
        let updated = makeUserMeResponse(name: "New Name")
        mockAPI.updateProfileResult = .success(updated)

        await sut.updateProfile(name: "New Name")

        XCTAssertEqual(sut.profile.name, "New Name")
        XCTAssertFalse(sut.isSaving)
        XCTAssertNil(sut.errorMessage)
    }

    func testUpdateProfile_WhenNotAuthenticated_SetsError() async {
        await sut.updateProfile(name: "New Name")

        XCTAssertEqual(sut.errorMessage, "Not authenticated")
    }

    func testUpdateProfile_WhenServerError_SetsErrorMessage() async {
        setAuthenticated()
        mockAPI.updateProfileResult = .failure(APIError.server(status: 400, message: "Bad request"))

        await sut.updateProfile(name: "Invalid")

        XCTAssertNotNil(sut.errorMessage)
        XCTAssertFalse(sut.isSaving)
    }

    // MARK: - Upload Profile Image

    func testUploadProfileImage_WhenAuthenticated_UpdatesProfile() async {
        setAuthenticated()
        let updated = makeUserMeResponse(avatarURL: "https://cdn.example.com/new-avatar.jpg")
        mockAPI.uploadProfileImageResult = .success(updated)

        let imageData = Data(repeating: 0xFF, count: 100)
        await sut.uploadProfileImage(imageData: imageData)

        XCTAssertEqual(sut.profile.avatarURL, "https://cdn.example.com/new-avatar.jpg")
        XCTAssertFalse(sut.isSaving)
        XCTAssertNil(sut.errorMessage)
    }

    func testUploadProfileImage_WhenNotAuthenticated_SetsError() async {
        await sut.uploadProfileImage(imageData: Data())

        XCTAssertEqual(sut.errorMessage, "Not authenticated")
    }

    func testUploadProfileImage_WhenUploadFails_SetsErrorMessage() async {
        setAuthenticated()
        mockAPI.uploadProfileImageResult = .failure(APIError.server(status: 413, message: "File too large"))

        await sut.uploadProfileImage(imageData: Data(repeating: 0xFF, count: 6_000_000))

        XCTAssertNotNil(sut.errorMessage)
        XCTAssertFalse(sut.isSaving)
    }

    // MARK: - Delete Account

    func testDeleteAccount_WhenAuthenticated_CallsLogout() async {
        setAuthenticated()
        mockAPI.deleteAccountResult = .success(())

        await sut.deleteAccount()

        // logout is called after successful deletion
        XCTAssertFalse(sut.isDeleting)
        // The auth store should have been logged out
        XCTAssertNil(mockAuthStore.accessToken)
    }

    func testDeleteAccount_WhenNotAuthenticated_SetsError() async {
        await sut.deleteAccount()

        XCTAssertEqual(sut.errorMessage, "Not authenticated")
    }

    func testDeleteAccount_WhenServerError_SetsErrorMessage() async {
        setAuthenticated()
        mockAPI.deleteAccountResult = .failure(APIError.server(status: 500, message: "Internal error"))

        await sut.deleteAccount()

        XCTAssertNotNil(sut.errorMessage)
        XCTAssertFalse(sut.isDeleting)
    }

    // MARK: - Logout

    func testLogout_ClearsAuthStore() {
        setAuthenticated()
        XCTAssertNotNil(mockAuthStore.accessToken)

        sut.logout()

        XCTAssertNil(mockAuthStore.accessToken)
    }
}
