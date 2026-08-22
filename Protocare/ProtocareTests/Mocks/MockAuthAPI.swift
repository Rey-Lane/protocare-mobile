//
//  MockAuthAPI.swift
//  ProtocareTests
//
//  Mock implementation of AuthAPI for testing
//

import Foundation
@testable import Protocare

class MockAuthAPI: AuthAPI {
    // MARK: - Results
    var registerResult: Result<AccessToken, Error> = .success(
        AccessToken(userId: "test-user-id", accessToken: "test_token", refreshToken: "test_refresh", tokenType: "Bearer")
    )
    var loginResult: Result<AccessToken, Error> = .success(
        AccessToken(userId: "test-user-id", accessToken: "test_token", refreshToken: "test_refresh", tokenType: "Bearer")
    )
    var fetchProtocolsResult: Result<[ProtocolItem], Error> = .success([])
    var fetchActionsResult: Result<[Action], Error> = .success([])
    var fetchSubstancesResult: Result<[Substance], Error> = .success([])
    var createProtocolResult: Result<ProtocolItem, Error> = .success(
        ProtocolItem(
            id: "test-protocol-id",
            userId: "test-user-id",
            name: "Test Protocol",
            actions: [],
            isActive: true
        )
    )
    var deleteProtocolResult: Result<Void, Error> = .success(())
    var createProtocolWithImageResult: Result<ProtocolItem, Error> = .success(
        ProtocolItem(
            id: "test-protocol-id",
            userId: "test-user-id",
            name: "Test Protocol",
            actions: [],
            isActive: true
        )
    )
    var lastCreateProtocolPayload: ProtocolCreateRequest?
    var updateProtocolResult: Result<ProtocolItem, Error> = .success(
        ProtocolItem(
            id: "test-protocol-id",
            userId: "test-user-id",
            name: "Updated Protocol",
            actions: [],
            isActive: true
        )
    )
    var createCheckinResult: Result<CheckIn, Error> = .success(
        CheckIn(
            protocolActionId: "test-action-id",
            ts: "2024-01-01T12:00:00Z",
            id: "test-checkin-id",
            userId: nil
        )
    )
    var uploadProtocolImageResult: Result<ImageAttachmentCreate, Error> = .success(
        ImageAttachmentCreate(
            id: "test-image-id",
            filename: "test.jpg",
            contentType: "image/jpeg",
            fileSize: 1024,
            width: 100,
            height: 100,
            url: "https://example.com/test.jpg"
        )
    )
    var fetchProtocolImageResult: Result<ImageAttachment, Error> = .success(
        ImageAttachment(
            id: "test-image-id",
            ownerId: "test-owner-id",
            attachableType: "protocol",
            attachableId: "test-protocol-id",
            filename: "test.jpg",
            contentType: "image/jpeg",
            fileSize: 1024,
            createdAt: "2024-01-01T12:00:00Z"
        )
    )
    var deleteImageResult: Result<Void, Error> = .success(())

    // MARK: - Templates
    var fetchTemplatesResult: Result<[ProtocolTemplate], Error> = .success([])
    var fetchTemplateResult: Result<ProtocolTemplate, Error> = .success(
        ProtocolTemplate(
            id: "test-template-id",
            name: "Test Template",
            description: "A test template",
            category: .morningRoutine,
            actionDrafts: []
        )
    )
    var createProtocolFromTemplateResult: Result<ProtocolItem, Error> = .success(
        ProtocolItem(
            id: "test-protocol-id",
            userId: "test-user-id",
            name: "Test Protocol From Template",
            actions: [],
            isActive: true
        )
    )
    var fetchTemplateImageResult: Result<ImageAttachment, Error> = .success(
        ImageAttachment(
            id: "test-image-id",
            ownerId: "test-owner-id",
            attachableType: "template",
            attachableId: "test-template-id",
            filename: "test.jpg",
            contentType: "image/jpeg",
            fileSize: 1024,
            createdAt: "2024-01-01T12:00:00Z"
        )
    )

    // MARK: - Notification Schedules
    var fetchNotificationSchedulesResult: Result<[NotificationScheduleResponse], Error> = .success([])
    var fetchNotificationScheduleResult: Result<NotificationScheduleResponse, Error> = .success(
        NotificationScheduleResponse(
            id: "test-schedule-id",
            protocolActionId: "test-action-id",
            userId: "test-user-id",
            preferredTime: "08:00",
            timezone: "Europe/Amsterdam",
            isEnabled: true,
            createdAt: "2024-01-01T12:00:00Z"
        )
    )
    var createNotificationScheduleResult: Result<NotificationScheduleResponse, Error> = .success(
        NotificationScheduleResponse(
            id: "test-schedule-id",
            protocolActionId: "test-action-id",
            userId: "test-user-id",
            preferredTime: "08:00",
            timezone: "Europe/Amsterdam",
            isEnabled: true,
            createdAt: "2024-01-01T12:00:00Z"
        )
    )
    var updateNotificationScheduleResult: Result<NotificationScheduleResponse, Error> = .success(
        NotificationScheduleResponse(
            id: "test-schedule-id",
            protocolActionId: "test-action-id",
            userId: "test-user-id",
            preferredTime: "09:00",
            timezone: "Europe/Amsterdam",
            isEnabled: false,
            createdAt: "2024-01-01T12:00:00Z"
        )
    )
    var deleteNotificationScheduleResult: Result<Void, Error> = .success(())
    var upsertNotificationScheduleResult: Result<NotificationScheduleResponse, Error> = .success(
        NotificationScheduleResponse(
            id: "test-schedule-id",
            protocolActionId: "test-action-id",
            userId: "test-user-id",
            preferredTime: "08:00",
            timezone: "Europe/Amsterdam",
            isEnabled: true,
            createdAt: "2024-01-01T12:00:00Z"
        )
    )

    // MARK: - Daily Status
    var fetchDailyStatusResult: Result<DailyStatusResponse, Error> = .success(
        DailyStatusResponse(date: "", streak: StreakInfo(currentStreak: 0, longestStreak: 0), dailyProgressPercentage: 0, totalActions: 0, completedActions: 0, protocols: [])
    )
    var fetchProtocolDailyStatusResult: Result<ProtocolDailyStatus, Error> = .success(
        ProtocolDailyStatus(
            protocolId: "test-protocol-id",
            date: "2024-01-01",
            totalActions: 0,
            completedActions: 0,
            completionPercentage: 0,
            actions: []
        )
    )
    var fetchProtocolWithCheckinsResult: Result<ProtocolWithCheckins, Error> = .success(
        ProtocolWithCheckins(
            id: "test-protocol-id",
            userId: "test-user-id",
            name: "Test",
            actions: [],
            isActive: true
        )
    )
    var fetchProtocolCheckinsResult: Result<[CheckIn], Error> = .success([])


    // MARK: - User Actions
    var fetchUserActionsResult: Result<PaginatedUserActions, Error> = .success(
        PaginatedUserActions(items: [], total: 0, page: 1, pageSize: 20)
    )
    var createUserActionResult: Result<UserAction, Error> = .success(TestFixtures.testUserAction)
    var fetchUserActionResult: Result<UserAction, Error> = .success(TestFixtures.testUserAction)
    var updateUserActionResult: Result<UserAction, Error> = .success(TestFixtures.testUserAction)
    var deleteUserActionResult: Result<Void, Error> = .success(())
    var fetchUserActionTemplatesResult: Result<[UserAction], Error> = .success([])
    var duplicateUserActionResult: Result<UserAction, Error> = .success(TestFixtures.testUserAction)
    var fetchUserActionUsageResult: Result<UserActionUsage, Error> = .success(TestFixtures.testUserActionUsage)

    var addActionToProtocolResult: Result<ProtocolItem, Error> = .success(
        ProtocolItem(
            id: "test-protocol-id",
            userId: "test-user-id",
            name: "Test Protocol",
            actions: [],
            isActive: true
        )
    )



    // MARK: - Auth Methods
    func register(email: String, password: String) async throws -> AccessToken {
        switch registerResult {
        case .success(let response):
            return response
        case .failure(let error):
            throw error
        }
    }

    func login(email: String, password: String) async throws -> AccessToken {
        switch loginResult {
        case .success(let response):
            return response
        case .failure(let error):
            throw error
        }
    }

    var refreshCallCount = 0
    var refreshResult: Result<TokenPair, Error> = .success(
        TokenPair(userId: "test-user-id", accessToken: "new_access_token", refreshToken: "new_refresh_token")
    )

    func refresh(request: RefreshTokenRequest) async throws -> TokenPair {
        refreshCallCount += 1
        switch refreshResult {
        case .success(let tokens):
            return tokens
        case .failure(let error):
            throw error
        }
    }

    func logout(refreshToken: String) async throws {}

    // MARK: - Data Fetching
    func fetchProtocols(token: String, category: ProtocolCategory? = nil) async throws -> [ProtocolItem] {
        switch fetchProtocolsResult {
        case .success(let protocols):
            return protocols
        case .failure(let error):
            throw error
        }
    }

    func fetchActions(token: String, query: String? = nil) async throws -> [Action] {
        switch fetchActionsResult {
        case .success(let actions):
            return actions
        case .failure(let error):
            throw error
        }
    }

    func fetchSubstances(token: String, query: String? = nil) async throws -> [Substance] {
        switch fetchSubstancesResult {
        case .success(let substances):
            return substances
        case .failure(let error):
            throw error
        }
    }

    // MARK: - Protocol Management
    func createProtocol(token: String, payload: ProtocolCreateRequest) async throws -> ProtocolItem {
        lastCreateProtocolPayload = payload
        switch createProtocolResult {
        case .success(let protocolItem):
            return protocolItem
        case .failure(let error):
            throw error
        }
    }

    func deleteProtocol(token: String, protocolId: String) async throws {
        switch deleteProtocolResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }

    func createProtocolWithImage(token: String, payload: ProtocolCreateRequest, imageData: Data?) async throws -> ProtocolItem {
        lastCreateProtocolPayload = payload
        switch createProtocolWithImageResult {
        case .success(let protocolItem):
            return protocolItem
        case .failure(let error):
            throw error
        }
    }

    func updateProtocol(token: String, protocolId: String, payload: ProtocolUpdate) async throws -> ProtocolItem {
        switch updateProtocolResult {
        case .success(let protocolItem):
            return protocolItem
        case .failure(let error):
            throw error
        }
    }

    // MARK: - Checkins
    func createCheckin(token: String, payload: ProtocolCheckinCreate) async throws -> CheckIn {
        switch createCheckinResult {
        case .success(let checkin):
            return checkin
        case .failure(let error):
            throw error
        }
    }

    func deleteCheckin(token: String, protocolId: String, checkinId: String) async throws {
    }

    // MARK: - Image Management
    func uploadProtocolImage(token: String, protocolId: String, imageData: Data) async throws -> ImageAttachmentCreate {
        switch uploadProtocolImageResult {
        case .success(let response):
            return response
        case .failure(let error):
            throw error
        }
    }

    func fetchProtocolImage(token: String, protocolId: String) async throws -> ImageAttachment {
        switch fetchProtocolImageResult {
        case .success(let response):
            return response
        case .failure(let error):
            throw error
        }
    }

    func deleteImage(token: String, imageId: String) async throws {
        switch deleteImageResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }

    // MARK: - Daily Status
    func fetchDailyStatus(token: String, date: Date?) async throws -> DailyStatusResponse {
        switch fetchDailyStatusResult {
        case .success(let status):
            return status
        case .failure(let error):
            throw error
        }
    }

    func fetchProtocolDailyStatus(token: String, protocolId: String, date: Date?) async throws -> ProtocolDailyStatus {
        switch fetchProtocolDailyStatusResult {
        case .success(let status):
            return status
        case .failure(let error):
            throw error
        }
    }

    func fetchProtocolWithCheckins(token: String, protocolId: String) async throws -> ProtocolWithCheckins {
        switch fetchProtocolWithCheckinsResult {
        case .success(let protocolWithCheckins):
            return protocolWithCheckins
        case .failure(let error):
            throw error
        }
    }

    func fetchProtocolCheckins(token: String, protocolId: String, dateFrom: Date?, dateTo: Date?) async throws -> [CheckIn] {
        switch fetchProtocolCheckinsResult {
        case .success(let checkins):
            return checkins
        case .failure(let error):
            throw error
        }
    }

    // MARK: - Templates
    func fetchTemplates(token: String) async throws -> [ProtocolTemplate] {
        switch fetchTemplatesResult {
        case .success(let templates):
            return templates
        case .failure(let error):
            throw error
        }
    }

    func fetchTemplate(token: String, templateId: String) async throws -> ProtocolTemplate {
        switch fetchTemplateResult {
        case .success(let template):
            return template
        case .failure(let error):
            throw error
        }
    }

    func createProtocolFromTemplate(token: String, templateId: String) async throws -> ProtocolItem {
        switch createProtocolFromTemplateResult {
        case .success(let protocolItem):
            return protocolItem
        case .failure(let error):
            throw error
        }
    }

    func fetchTemplateImage(token: String, templateId: String) async throws -> ImageAttachment {
        switch fetchTemplateImageResult {
        case .success(let response):
            return response
        case .failure(let error):
            throw error
        }
    }

    // MARK: - Notification Schedules
    func fetchNotificationSchedules(token: String, protocolActionId: String?) async throws -> [NotificationScheduleResponse] {
        switch fetchNotificationSchedulesResult {
        case .success(let schedules):
            return schedules
        case .failure(let error):
            throw error
        }
    }

    func fetchNotificationSchedule(token: String, scheduleId: String) async throws -> NotificationScheduleResponse {
        switch fetchNotificationScheduleResult {
        case .success(let schedule):
            return schedule
        case .failure(let error):
            throw error
        }
    }

    func createNotificationSchedule(token: String, payload: NotificationScheduleCreate) async throws -> NotificationScheduleResponse {
        switch createNotificationScheduleResult {
        case .success(let schedule):
            return schedule
        case .failure(let error):
            throw error
        }
    }

    func updateNotificationSchedule(token: String, scheduleId: String, payload: NotificationScheduleUpdate) async throws -> NotificationScheduleResponse {
        switch updateNotificationScheduleResult {
        case .success(let schedule):
            return schedule
        case .failure(let error):
            throw error
        }
    }

    func deleteNotificationSchedule(token: String, scheduleId: String) async throws {
        switch deleteNotificationScheduleResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }

    func upsertNotificationSchedule(token: String, actionId: String, payload: NotificationScheduleCreate) async throws -> NotificationScheduleResponse {
        switch upsertNotificationScheduleResult {
        case .success(let schedule):
            return schedule
        case .failure(let error):
            throw error
        }
    }

    // MARK: - User Actions
    func fetchUserActions(token: String, category: ActionCategory?, isActive: Bool?, page: Int?, pageSize: Int?) async throws -> PaginatedUserActions {
        switch fetchUserActionsResult {
        case .success(let result):
            return result
        case .failure(let error):
            throw error
        }
    }

    func createUserAction(token: String, payload: UserActionCreate) async throws -> UserAction {
        switch createUserActionResult {
        case .success(let action):
            return action
        case .failure(let error):
            throw error
        }
    }

    func fetchUserAction(token: String, actionId: UUID) async throws -> UserAction {
        switch fetchUserActionResult {
        case .success(let action):
            return action
        case .failure(let error):
            throw error
        }
    }

    func updateUserAction(token: String, actionId: UUID, payload: UserActionUpdate) async throws -> UserAction {
        switch updateUserActionResult {
        case .success(let action):
            return action
        case .failure(let error):
            throw error
        }
    }

    func deleteUserAction(token: String, actionId: UUID) async throws {
        switch deleteUserActionResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }

    func fetchUserActionTemplates(token: String) async throws -> [UserAction] {
        switch fetchUserActionTemplatesResult {
        case .success(let templates):
            return templates
        case .failure(let error):
            throw error
        }
    }

    func duplicateUserAction(token: String, actionId: UUID) async throws -> UserAction {
        switch duplicateUserActionResult {
        case .success(let action):
            return action
        case .failure(let error):
            throw error
        }
    }

    func fetchUserActionUsage(token: String, actionId: UUID) async throws -> UserActionUsage {
        switch fetchUserActionUsageResult {
        case .success(let usage):
            return usage
        case .failure(let error):
            throw error
        }
    }

    // MARK: - User Profile

    var fetchCurrentUserResult: Result<UserMeResponse, Error> = .success(
        UserMeResponse(id: UUID().uuidString, email: "mock@protocare.app", isActive: true, role: "user", timezone: nil, protocolsCount: 1, streak: StreakInfo(currentStreak: 3, longestStreak: 5), totalCheckins: 10)
    )

    func fetchCurrentUser(token: String) async throws -> UserMeResponse {
        switch fetchCurrentUserResult {
        case .success(let response):
            return response
        case .failure(let error):
            throw error
        }
    }

    func addActionToProtocol(token: String, protocolId: String, payload: ProtocolActionCreate) async throws -> ProtocolItem {
        switch addActionToProtocolResult {
        case .success(let protocolItem):
            return protocolItem
        case .failure(let error):
            throw error
        }
    }

    func removeActionFromProtocol(token: String, protocolId: String, protocolActionId: String) async throws {
        // No-op in mock
    }

    // MARK: - Journal

    func fetchJournalEntries(token: String, protocolId: String, dateFrom: String?, dateTo: String?) async throws -> [JournalEntry] {
        []
    }

    func fetchJournalEntry(token: String, protocolId: String, date: String) async throws -> JournalEntryDetail {
        JournalEntryDetail(id: "", protocolId: protocolId, date: date, dayNumber: 1, metrics: [:], availableMetrics: [], checkins: [], createdAt: "", updatedAt: "")
    }

    func saveJournalEntry(token: String, protocolId: String, date: String, metrics: [String: Int], notes: String?) async throws -> JournalEntry {
        JournalEntry(id: "", protocolId: protocolId, date: date, dayNumber: 1, metrics: metrics, notes: notes)
    }

    func uploadJournalPhoto(token: String, protocolId: String, date: String, imageData: Data) async throws -> JournalEntry {
        JournalEntry(id: "", protocolId: protocolId, date: date, dayNumber: 1, metrics: [:])
    }

    // MARK: - Metrics Trend

    func fetchMetricsTrend(token: String, protocolId: String, days: Int?) async throws -> MetricTrendResponse {
        MetricTrendResponse(protocolId: protocolId, days: 14, series: [])
    }

    // MARK: - Reorder

    func reorderProtocolActions(token: String, protocolId: String, actionIds: [String]) async throws {}

    // MARK: - Protocol Notification Schedules

    func fetchProtocolNotificationSchedules(token: String, protocolId: String) async throws -> [String: NotificationScheduleResponse] {
        [:]
    }
}
