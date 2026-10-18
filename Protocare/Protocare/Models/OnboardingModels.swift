//
//  OnboardingModels.swift
//  Protocare
//
//  Onboarding wizard state (spec: docs/onboarding-spec-v2.md §3.4 wire shape).
//  Server is the source of truth; the client is a stateless wizard driver.
//

import Foundation

// MARK: - Enums

public enum OnboardingStep: String, Codable, CaseIterable, Sendable {
    case welcome = "welcome"
    case category = "category"
    case firstProtocol = "first_protocol"
    case firstAction = "first_action"
    case notifications = "notifications"
    case done = "done"

    /// Index of the step in the wizard order (`STEP_ORDER` in the backend service).
    public var index: Int {
        Self.allCases.firstIndex(of: self) ?? 0
    }

    public init(index: Int) {
        self = Self.allCases[min(max(index, 0), Self.allCases.count - 1)]
    }
}

public enum OnboardingStatus: String, Codable, Sendable {
    case notStarted = "not_started"
    case inProgress = "in_progress"
    case completed = "completed"
    case skipped = "skipped"
}

// MARK: - Context

/// Per-step collected data (spec §3.3). Soft schema — decoding is tolerant of
/// missing keys, and unknown keys on the wire are ignored.
public struct OnboardingContextData: Codable, Hashable, Sendable {
    public var selectedCategories: [String]?
    public var firstProtocolId: String?
    public var firstProtocolName: String?
    public var actionsAdded: Int?
    public var firstReminderTime: String?
    public var notificationsEnabled: Bool?

    public init(
        selectedCategories: [String]? = nil,
        firstProtocolId: String? = nil,
        firstProtocolName: String? = nil,
        actionsAdded: Int? = nil,
        firstReminderTime: String? = nil,
        notificationsEnabled: Bool? = nil
    ) {
        self.selectedCategories = selectedCategories
        self.firstProtocolId = firstProtocolId
        self.firstProtocolName = firstProtocolName
        self.actionsAdded = actionsAdded
        self.firstReminderTime = firstReminderTime
        self.notificationsEnabled = notificationsEnabled
    }

    enum CodingKeys: String, CodingKey {
        case selectedCategories = "selected_categories"
        case firstProtocolId = "first_protocol_id"
        case firstProtocolName = "first_protocol_name"
        case actionsAdded = "actions_added"
        case firstReminderTime = "first_reminder_time"
        case notificationsEnabled = "notifications_enabled"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        selectedCategories = try container.decodeIfPresent([String].self, forKey: .selectedCategories)
        firstProtocolId = try container.decodeIfPresent(String.self, forKey: .firstProtocolId)
        firstProtocolName = try container.decodeIfPresent(String.self, forKey: .firstProtocolName)
        actionsAdded = try container.decodeIfPresent(Int.self, forKey: .actionsAdded)
        firstReminderTime = try container.decodeIfPresent(String.self, forKey: .firstReminderTime)
        notificationsEnabled = try container.decodeIfPresent(Bool.self, forKey: .notificationsEnabled)
    }
}

// MARK: - State

public struct OnboardingState: Codable, Hashable, Sendable {
    /// Zero UUID is the server's synthetic default for "no row yet" (spec §4 GET).
    public static let syntheticId = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!

    public var id: UUID
    public var userId: UUID
    public var step: OnboardingStep
    public var status: OnboardingStatus
    public var context: OnboardingContextData
    public var completedSteps: [String]
    public var schemaVersion: Int
    public var createdAt: Date
    public var updatedAt: Date
    public var completedAt: Date?

    public var isSyntheticDefault: Bool { id == Self.syntheticId }

    /// Wizard should be presented while the server says the flow is unfinished.
    public var shouldShow: Bool {
        status == .notStarted || status == .inProgress
    }

    public init(
        id: UUID = Self.syntheticId,
        userId: UUID = Self.syntheticId,
        step: OnboardingStep = .welcome,
        status: OnboardingStatus = .notStarted,
        context: OnboardingContextData = OnboardingContextData(),
        completedSteps: [String] = [],
        schemaVersion: Int = 1,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        completedAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.step = step
        self.status = status
        self.context = context
        self.completedSteps = completedSteps
        self.schemaVersion = schemaVersion
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.completedAt = completedAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case step, status, context
        case completedSteps = "completed_steps"
        case schemaVersion = "schema_version"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case completedAt = "completed_at"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? Self.syntheticId
        userId = try container.decodeIfPresent(UUID.self, forKey: .userId) ?? Self.syntheticId
        step = try container.decodeIfPresent(OnboardingStep.self, forKey: .step) ?? .welcome
        status = try container.decodeIfPresent(OnboardingStatus.self, forKey: .status) ?? .notStarted
        context = try container.decodeIfPresent(OnboardingContextData.self, forKey: .context) ?? OnboardingContextData()
        completedSteps = try container.decodeIfPresent([String].self, forKey: .completedSteps) ?? []
        schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
        completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
    }
}

// MARK: - PATCH Request

/// `PATCH /onboarding` body (spec §4 `OnboardingStepUpdate`). All fields optional;
/// `context` is merged server-side, never replaced.
public struct OnboardingUpdateRequest: Encodable, Hashable, Sendable {
    public var step: OnboardingStep?
    public var status: OnboardingStatus?
    public var context: [String: AnyCodable]?

    public init(
        step: OnboardingStep? = nil,
        status: OnboardingStatus? = nil,
        context: [String: AnyCodable]? = nil
    ) {
        self.step = step
        self.status = status
        self.context = context
    }

    enum CodingKeys: String, CodingKey {
        case step, status, context
    }
}
