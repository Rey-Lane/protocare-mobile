//
//  TestFixtures.swift
//  ProtocareTests
//
//  Test data fixtures based on OpenAPI schema
//

import Foundation
@testable import Protocare

enum TestFixtures {
    // MARK: - Auth

    static let validAuthTokens = AuthTokens(
        userId: "550e8400-e29b-41d4-a716-446655440000",
        accessToken: "test_access_token",
        refreshToken: "test_refresh_token",
        tokenType: "Bearer"
    )

    static let validRegisterResponse = RegisterResponse(
        userId: "550e8400-e29b-41d4-a716-446655440000",
        accessToken: "test_access_token",
        refreshToken: "test_refresh_token",
        tokenType: "Bearer"
    )

    static let validLoginResponse = LoginResponse(
        userId: "550e8400-e29b-41d4-a716-446655440000",
        accessToken: "test_access_token",
        refreshToken: "test_refresh_token",
        tokenType: "Bearer"
    )

    // MARK: - Substances

    static let vitaminC = Substance(
        id: "660e8400-e29b-41d4-a716-446655440001",
        name: "Vitamin C",
        type: .oral,
        unit: .capsule,
        notes: "Antioxidant vitamin"
    )

    static let hyaluronicAcid = Substance(
        id: "660e8400-e29b-41d4-a716-446655440002",
        name: "Hyaluronic Acid",
        type: .topical,
        unit: .ml,
        notes: "Moisturizing agent"
    )

    static let retinol = Substance(
        id: "660e8400-e29b-41d4-a716-446655440003",
        name: "Retinol",
        type: .topical,
        unit: .mg,
        notes: "Vitamin A derivative"
    )

    static let testSubstances = [vitaminC, hyaluronicAcid, retinol]

    // MARK: - Actions

    static let morningCleanse = ActionItem(
        id: "770e8400-e29b-41d4-a716-446655440001",
        name: "Morning Cleanse",
        scheduleLabel: "Daily",
        timeLabel: "08:00",
        modeLabel: "Gentle"
    )

    static let eveningSerum = ActionItem(
        id: "770e8400-e29b-41d4-a716-446655440002",
        name: "Evening Serum",
        scheduleLabel: "Daily",
        timeLabel: "21:00",
        modeLabel: "Treatment"
    )

    static let testActions = [morningCleanse, eveningSerum]

    // MARK: - Protocols

    static let morningRoutine = ProtocolItem(
        id: "880e8400-e29b-41d4-a716-446655440001",
        userId: "550e8400-e29b-41d4-a716-446655440000",
        name: "Morning Skincare Routine",
        actions: [],
        isActive: true
    )

    static let eveningRoutine = ProtocolItem(
        id: "880e8400-e29b-41d4-a716-446655440002",
        userId: "550e8400-e29b-41d4-a716-446655440000",
        name: "Evening Treatment Protocol",
        actions: [],
        isActive: true
    )

    static let testProtocols = [morningRoutine, eveningRoutine]

    // MARK: - Validation Errors

    static let validationError = APIError.server(
        status: 422,
        message: "{\"detail\": [{\"loc\": [\"body\", \"email\"], \"msg\": \"invalid email format\", \"type\": \"value_error\"}]}"
    )

    static let unauthorizedError = APIError.server(
        status: 401,
        message: "Unauthorized"
    )

    static let notFoundError = APIError.server(
        status: 404,
        message: "Not found"
    )

    // MARK: - Checkins

    static func makeCheckinCreate(
        protocolId: String = "test-protocol-id",
        protocolActionId: String = "test-action-id",
        ts: String = "2024-01-01T12:00:00Z",
        quantity: Double? = nil,
        unit: SubstanceUnit? = nil,
        durationSeconds: Int? = nil,
        completed: Bool = true
    ) -> ProtocolCheckinCreate {
        ProtocolCheckinCreate(
            protocolId: protocolId,
            protocolActionId: protocolActionId,
            ts: ts,
            quantity: quantity,
            unit: unit,
            durationSeconds: durationSeconds,
            completed: completed
        )
    }

    // MARK: - Notification Schedules

    static let testNotificationSchedule = NotificationScheduleResponse(
        id: "sched-001",
        protocolActionId: "test-action-id",
        userId: "test-user-id",
        preferredTime: "08:00",
        timezone: "Europe/Amsterdam",
        isEnabled: true,
        createdAt: "2024-01-01T12:00:00Z"
    )

    // MARK: - User Actions

    static let testUserAction = UserAction(
        id: UUID(uuidString: "a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d")!,
        userId: UUID(uuidString: "550e8400-e29b-41d4-a716-446655440000")!,
        name: "Cold Plunge",
        description: "Cold water immersion therapy",
        category: .mindfulness,
        parameters: nil,
        iconKey: "snowflake",
        color: "#007AFF",
        isTemplate: false,
        protocolCount: 3,
        sortOrder: 0,
        isActive: true,
        createdAt: Date(timeIntervalSince1970: 1700000000),
        updatedAt: Date(timeIntervalSince1970: 1700000000)
    )

    static let testUserActionTemplate = UserAction(
        id: UUID(uuidString: "f1e2d3c4-b5a6-4978-8a7b-6c5d4e3f2a1b")!,
        userId: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!,
        name: "Meditation Session",
        description: "Guided or unguided meditation",
        category: .mindfulness,
        parameters: nil,
        iconKey: "brain.head.profile.fill",
        color: "#AF52DE",
        isTemplate: true,
        protocolCount: 0,
        sortOrder: 0,
        isActive: true,
        createdAt: Date(timeIntervalSince1970: 1700000000),
        updatedAt: Date(timeIntervalSince1970: 1700000000)
    )

    static let testPaginatedUserActions = PaginatedUserActions(
        items: [testUserAction],
        total: 1,
        page: 1,
        pageSize: 20
    )

    static let testUserActionCreate = UserActionCreate(
        name: "Red Light Therapy",
        description: "20 min session",
        category: .mindfulness,
        parameters: nil,
        iconKey: "sunrise.fill",
        color: "#FF9500"
    )

    static let testUserActionUpdate = UserActionUpdate(
        name: "Updated Cold Plunge",
        description: "Updated description"
    )

    // MARK: - Unified Actions (Step 25d)

    static let testAction = Action(
        id: "a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d",
        name: "Cold Plunge",
        description: "Cold water immersion therapy",
        category: .mindfulness,
        modality: .activity,
        defaultParameters: [
            "duration_seconds": AnyCodable(180)
        ],
        isLibrary: false,
        iconKey: "snowflake",
        color: "#007AFF"
    )

    static let testActionCreate = ActionCreate(
        name: "Red Light Therapy",
        description: "20 min session",
        category: .mindfulness,
        modality: .device,
        defaultParameters: ["duration_seconds": AnyCodable(1200)],
        iconKey: "sunrise.fill",
        color: "#FF9500"
    )

    static let testActionUpdate = ActionUpdate(
        name: "Updated Cold Plunge",
        description: "Updated description",
        category: .exercise,
        modality: .activity
    )

    static let testUserActionUsage = UserActionUsage([
        UserActionUsageEntry(
            protocolId: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            protocolName: "Morning Routine",
            protocolActionId: UUID(uuidString: "00000000-0000-0000-0000-000000000010")!
        ),
        UserActionUsageEntry(
            protocolId: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            protocolName: "Evening Wind Down",
            protocolActionId: UUID(uuidString: "00000000-0000-0000-0000-000000000020")!
        )
    ])

    static func makeNotificationScheduleCreate(
        protocolActionId: String = "test-action-id",
        preferredTime: String = "08:00",
        timezone: String = "Europe/Amsterdam",
        isEnabled: Bool = true
    ) -> NotificationScheduleCreate {
        NotificationScheduleCreate(
            protocolActionId: protocolActionId,
            preferredTime: preferredTime,
            timezone: timezone,
            isEnabled: isEnabled
        )
    }

    // MARK: - Schedules

    static let testDailySchedule = ActionSchedule(
        frequency: .daily,
        days: ScheduleDay.allCases,
        hour: 8,
        minute: 0
    )

    static let testMWFSchedule = ActionSchedule(
        frequency: .weekly,
        days: [.monday, .wednesday, .friday],
        hour: 21,
        minute: 30
    )

    static let testMonthlySchedule = ActionSchedule(
        frequency: .monthly,
        days: [],
        hour: 7,
        minute: 0
    )
}
