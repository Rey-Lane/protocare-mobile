import Foundation

public struct DailyActionStatus: Decodable, Equatable, Identifiable, Sendable {
    public var id: String { protocolActionId }
    public let protocolActionId: String
    /// Single unified action reference — `user_action_id` no longer exists (Step 24/25).
    public let actionId: String?
    public let actionName: String
    public let description: String?
    public let scheduledTime: String?
    public let isCompleted: Bool
    public let completedAt: String?
    public let checkinId: String?
    /// Actual values from today's check-in, if any.
    /// Backend `Decimal` quantity arrives as a JSON string — decoded tolerantly.
    public let quantity: Double?
    public let unit: SubstanceUnit?
    public let durationSeconds: Int?
    public let completed: Bool
    /// `default_parameters` from the unified Action (JSONB).
    public let defaultParameters: [String: AnyCodable]?
    /// Per-protocol override (`user_parameters` on the ProtocolAction).
    public let userParameters: [String: AnyCodable]?

    public init(
        protocolActionId: String,
        actionId: String? = nil,
        actionName: String,
        description: String? = nil,
        scheduledTime: String? = nil,
        isCompleted: Bool,
        completedAt: String? = nil,
        checkinId: String? = nil,
        quantity: Double? = nil,
        unit: SubstanceUnit? = nil,
        durationSeconds: Int? = nil,
        completed: Bool = true,
        defaultParameters: [String: AnyCodable]? = nil,
        userParameters: [String: AnyCodable]? = nil
    ) {
        self.protocolActionId = protocolActionId
        self.actionId = actionId
        self.actionName = actionName
        self.description = description
        self.scheduledTime = scheduledTime
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.checkinId = checkinId
        self.quantity = quantity
        self.unit = unit
        self.durationSeconds = durationSeconds
        self.completed = completed
        self.defaultParameters = defaultParameters
        self.userParameters = userParameters
    }

    enum CodingKeys: String, CodingKey {
        case protocolActionId = "protocol_action_id"
        case actionId = "action_id"
        case actionName = "action_name"
        case description
        case scheduledTime = "scheduled_time"
        case isCompleted = "is_completed"
        case completedAt = "completed_at"
        case checkinId = "checkin_id"
        case quantity, unit
        case durationSeconds = "duration_seconds"
        case completed
        case defaultParameters = "default_parameters"
        case userParameters = "user_parameters"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        protocolActionId = try container.decode(String.self, forKey: .protocolActionId)
        actionId = try container.decodeIfPresent(String.self, forKey: .actionId)
        actionName = try container.decode(String.self, forKey: .actionName)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        scheduledTime = try container.decodeIfPresent(String.self, forKey: .scheduledTime)
        isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        completedAt = try container.decodeIfPresent(String.self, forKey: .completedAt)
        checkinId = try container.decodeIfPresent(String.self, forKey: .checkinId)
        quantity = container.decodeFlexibleDouble(forKey: .quantity)
        unit = try container.decodeIfPresent(SubstanceUnit.self, forKey: .unit)
        durationSeconds = try container.decodeIfPresent(Int.self, forKey: .durationSeconds)
        completed = try container.decodeIfPresent(Bool.self, forKey: .completed) ?? true
        defaultParameters = try container.decodeIfPresent([String: AnyCodable].self, forKey: .defaultParameters)
        userParameters = try container.decodeIfPresent([String: AnyCodable].self, forKey: .userParameters)
    }
}

// MARK: - Adaptive check-in helpers (unified action model)

extension DailyActionStatus {
    /// `effective = merge_params(default_parameters, user_parameters)`.
    public var effectiveParameters: [String: AnyCodable] {
        mergeParams(defaultParameters, overriding: userParameters)
    }

    /// Which check-in form this action renders (substance / timed activity / binary).
    public var checkInFormKind: CheckInFormKind {
        CheckInFormResolver.formKind(for: effectiveParameters)
    }

    /// Pre-fill amount + unit for the substance form, merged from effective parameters.
    public var defaultQuantity: (amount: Double, unit: SubstanceUnit)? {
        CheckInFormResolver.defaultQuantity(in: effectiveParameters)
    }

    /// Pre-fill duration for the timed-activity form.
    public var defaultDurationSeconds: Int? {
        CheckInFormResolver.defaultDurationSeconds(in: effectiveParameters)
    }
}

public struct DailyProtocolStatus: Decodable, Equatable, Identifiable, Sendable {
    public var id: String { protocolId }
    public let protocolId: String
    public let protocolName: String
    public let completedActions: Int
    public let totalActions: Int
    public let actions: [DailyActionStatus]

    public init(
        protocolId: String,
        protocolName: String,
        completedActions: Int,
        totalActions: Int,
        actions: [DailyActionStatus]
    ) {
        self.protocolId = protocolId
        self.protocolName = protocolName
        self.completedActions = completedActions
        self.totalActions = totalActions
        self.actions = actions
    }

    enum CodingKeys: String, CodingKey {
        case protocolId = "protocol_id"
        case protocolName = "protocol_name"
        case completedActions = "completed_actions"
        case totalActions = "total_actions"
        case actions
    }
}

public struct DailyStatusResponse: Decodable, Equatable, Sendable {
    public let date: String
    public let streak: StreakInfo
    public let dailyProgressPercentage: Int
    public let totalActions: Int
    public let completedActions: Int
    public let protocols: [DailyProtocolStatus]

    public init(
        date: String,
        streak: StreakInfo,
        dailyProgressPercentage: Int,
        totalActions: Int,
        completedActions: Int,
        protocols: [DailyProtocolStatus]
    ) {
        self.date = date
        self.streak = streak
        self.dailyProgressPercentage = dailyProgressPercentage
        self.totalActions = totalActions
        self.completedActions = completedActions
        self.protocols = protocols
    }

    enum CodingKeys: String, CodingKey {
        case date
        case streak
        case dailyProgressPercentage = "daily_progress_percentage"
        case totalActions = "total_actions"
        case completedActions = "completed_actions"
        case protocols
    }
}
