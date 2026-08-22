import Foundation

public struct DailyActionStatus: Decodable, Equatable, Identifiable, Sendable {
    public var id: String { protocolActionId }
    public let protocolActionId: String
    public let actionId: String?
    public let userActionId: String?
    public let actionName: String
    public let description: String?
    public let scheduledTime: String?
    public let isCompleted: Bool
    public let completedAt: String?
    public let checkinId: String?
    public let appliedVolume: QuantityOutput?
    public let appliedDurationSeconds: Int?
    public let defaultVolume: QuantityOutput?
    public let defaultDurationSeconds: Int?

    public init(
        protocolActionId: String,
        actionId: String?,
        userActionId: String?,
        actionName: String,
        description: String?,
        scheduledTime: String?,
        isCompleted: Bool,
        completedAt: String?,
        checkinId: String?,
        appliedVolume: QuantityOutput?,
        appliedDurationSeconds: Int?,
        defaultVolume: QuantityOutput?,
        defaultDurationSeconds: Int?
    ) {
        self.protocolActionId = protocolActionId
        self.actionId = actionId
        self.userActionId = userActionId
        self.actionName = actionName
        self.description = description
        self.scheduledTime = scheduledTime
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.checkinId = checkinId
        self.appliedVolume = appliedVolume
        self.appliedDurationSeconds = appliedDurationSeconds
        self.defaultVolume = defaultVolume
        self.defaultDurationSeconds = defaultDurationSeconds
    }

    enum CodingKeys: String, CodingKey {
        case protocolActionId = "protocol_action_id"
        case actionId = "action_id"
        case userActionId = "user_action_id"
        case actionName = "action_name"
        case description
        case scheduledTime = "scheduled_time"
        case isCompleted = "is_completed"
        case completedAt = "completed_at"
        case checkinId = "checkin_id"
        case appliedVolume = "applied_volume"
        case appliedDurationSeconds = "applied_duration_seconds"
        case defaultVolume = "default_volume"
        case defaultDurationSeconds = "default_duration_seconds"
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
