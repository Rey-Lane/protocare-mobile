import Foundation
import SwiftUI

// MARK: - Enums

public enum SubstanceType: String, Codable, Hashable, Sendable, CaseIterable {
    case topical = "topical"
    case oral = "oral"
    case device = "device"
    case hygiene = "hygiene"
}

public enum SubstanceUnit: String, Codable, Hashable, Sendable, CaseIterable {
    case ml = "ml"
    case mg = "mg"
    case g = "g"
    case durationSeconds = "duration_seconds"
    case drop = "drop"
    case capsule = "capsule"
    case tablet = "tablet"
    case spray = "spray"
}

public enum TemplateCategory: String, CaseIterable, Identifiable, Codable, Hashable, Sendable {
    case morningRoutine = "morning_routine"
    case skincare = "skincare"
    case supplement = "supplement"
    case hair = "hair"
    case wellness = "wellness"
    case sleep = "sleep"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .morningRoutine: return "Morning Routine"
        case .skincare: return "Skincare"
        case .supplement: return "Supplements"
        case .hair: return "Hair"
        case .wellness: return "Wellness"
        case .sleep: return "Sleep"
        }
    }

    public var icon: String {
        switch self {
        case .morningRoutine: return "sunrise.fill"
        case .skincare: return "drop.fill"
        case .supplement: return "pill.fill"
        case .hair: return "sparkles"
        case .wellness: return "heart.fill"
        case .sleep: return "moon.fill"
        }
    }
}

public enum ProtocolCategory: String, CaseIterable, Codable, Hashable, Sendable, Identifiable {
    case skincare = "skincare"
    case biohacking = "biohacking"
    case yoga = "yoga"
    case fitness = "fitness"
    case nutrition = "nutrition"
    case mindfulness = "mindfulness"
    case medical = "medical"
    case other = "other"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .skincare: return "Skincare"
        case .biohacking: return "Biohacking"
        case .yoga: return "Yoga"
        case .fitness: return "Fitness"
        case .nutrition: return "Nutrition"
        case .mindfulness: return "Mindfulness"
        case .medical: return "Medical"
        case .other: return "Other"
        }
    }

    public var tagColor: Color {
        switch self {
        case .skincare: return Color(red: 1.0, green: 0.56, blue: 0.64)
        case .biohacking: return Color(red: 0.49, green: 0.74, blue: 0.81)
        case .yoga: return Color(red: 0.72, green: 0.58, blue: 0.96)
        case .fitness: return Color(red: 0.96, green: 0.68, blue: 0.33)
        case .nutrition: return Color(red: 0.34, green: 0.78, blue: 0.46)
        case .mindfulness: return Color(red: 0.45, green: 0.45, blue: 0.82)
        case .medical: return Color(red: 0.94, green: 0.33, blue: 0.31)
        case .other: return Color(.systemGray)
        }
    }

    public var tagIcon: String {
        switch self {
        case .skincare: return "drop.fill"
        case .biohacking: return "brain.head.profile.fill"
        case .yoga: return "figure.yoga"
        case .fitness: return "figure.run"
        case .nutrition: return "fork.knife"
        case .mindfulness: return "moon.fill"
        case .medical: return "stethoscope"
        case .other: return "circle.fill"
        }
    }
}

// MARK: - Auth Types

public struct TokenPair: Codable, Hashable, Sendable, Identifiable {
    public var id: String { userId }
    public var userId: String
    public var accessToken: String
    public var refreshToken: String
    public var tokenType: String?

    public init(userId: String, accessToken: String, refreshToken: String, tokenType: String? = nil) {
        self.userId = userId
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.tokenType = tokenType
    }

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case tokenType = "token_type"
    }
}

public struct RefreshTokenRequest: Codable, Hashable, Sendable {
    public var refreshToken: String

    public init(refreshToken: String) {
        self.refreshToken = refreshToken
    }

    enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
    }
}

public struct UserCreate: Codable, Hashable, Sendable {
    public var email: String
    public var password: String
    public var name: String

    public init(email: String, password: String, name: String) {
        self.email = email
        self.password = password
        self.name = name
    }
}

public struct UserLogin: Codable, Hashable, Sendable {
    public var email: String
    public var password: String

    public init(email: String, password: String) {
        self.email = email
        self.password = password
    }
}

// MARK: - Quantity Types

public struct QuantityOutput: Codable, Hashable, Sendable {
    public var amount: Double
    public var unit: SubstanceUnit

    public init(amount: Double, unit: SubstanceUnit) {
        self.amount = amount
        self.unit = unit
    }
}

public struct QuantityInput: Codable, Hashable, Sendable {
    public var amount: String?
    public var unit: SubstanceUnit

    public init(amount: String? = nil, unit: SubstanceUnit) {
        self.amount = amount
        self.unit = unit
    }
}

// MARK: - Action Types

public struct Action: Codable, Hashable, Sendable, Identifiable {
    public var id: String
    public var substanceId: String
    public var volume: QuantityOutput?
    public var durationSeconds: Int?

    public init(id: String, substanceId: String, volume: QuantityOutput? = nil, durationSeconds: Int? = nil) {
        self.id = id
        self.substanceId = substanceId
        self.volume = volume
        self.durationSeconds = durationSeconds
    }

    enum CodingKeys: String, CodingKey {
        case id
        case substanceId = "substance_id"
        case volume
        case durationSeconds = "duration_seconds"
    }
}

// MARK: - Substance

public struct Substance: Codable, Hashable, Sendable, Identifiable {
    public var id: String
    public var name: String
    public var type: SubstanceType
    public var unit: SubstanceUnit
    public var notes: String?

    public init(id: String, name: String, type: SubstanceType, unit: SubstanceUnit, notes: String? = nil) {
        self.id = id
        self.name = name
        self.type = type
        self.unit = unit
        self.notes = notes
    }

    enum CodingKeys: String, CodingKey {
        case id, name, type, unit, notes
    }
}

// MARK: - Protocol Types

public struct ProtocolItem: Codable, Hashable, Sendable, Identifiable {
    public var id: String
    public var userId: String
    public var name: String
    public var actions: [ProtocolAction]
    public var isActive: Bool?
    public var startedAt: String?
    public var endedAt: String?
    public var category: ProtocolCategory?
    public var streak: Int
    public var metricKeys: [String]?

    public init(id: String, userId: String, name: String, actions: [ProtocolAction], isActive: Bool? = nil, startedAt: String? = nil, endedAt: String? = nil, category: ProtocolCategory? = nil, streak: Int = 0, metricKeys: [String]? = nil) {
        self.id = id
        self.userId = userId
        self.name = name
        self.actions = actions
        self.isActive = isActive
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.category = category
        self.streak = streak
        self.metricKeys = metricKeys
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name, actions
        case isActive = "is_active"
        case startedAt = "started_at"
        case endedAt = "ended_at"
        case category
        case streak
        case metricKeys = "metric_keys"
    }
}

public struct ProtocolAction: Codable, Hashable, Sendable, Identifiable {
    public var id: String
    public var actionId: String?
    public var userActionId: UUID?
    public var rrule: String
    public var position: Int?
    public var checkins: [CheckIn]?
    public var notificationSchedule: NotificationScheduleResponse?

    public init(id: String, actionId: String? = nil, userActionId: UUID? = nil, rrule: String, position: Int? = nil, checkins: [CheckIn]? = nil, notificationSchedule: NotificationScheduleResponse? = nil) {
        self.id = id
        self.actionId = actionId
        self.userActionId = userActionId
        self.rrule = rrule
        self.position = position
        self.checkins = checkins
        self.notificationSchedule = notificationSchedule
    }

    enum CodingKeys: String, CodingKey {
        case id
        case actionId = "action_id"
        case userActionId = "user_action_id"
        case rrule, position, checkins
        case notificationSchedule = "notification_schedule"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        actionId = try container.decodeIfPresent(String.self, forKey: .actionId)
        userActionId = try container.decodeIfPresent(UUID.self, forKey: .userActionId)
        rrule = try container.decode(String.self, forKey: .rrule)
        position = try container.decodeIfPresent(Int.self, forKey: .position)
        checkins = try container.decodeIfPresent([CheckIn].self, forKey: .checkins)
        notificationSchedule = try container.decodeIfPresent(NotificationScheduleResponse.self, forKey: .notificationSchedule)
    }
}

public struct ProtocolActionCreate: Codable, Hashable, Sendable {
    public var actionId: String?
    public var userActionId: UUID?
    public var rrule: String
    public var position: Int?
    public var notificationTime: String?
    public var notificationTimezone: String?

    public init(actionId: String? = nil, userActionId: UUID? = nil, rrule: String, position: Int? = nil, notificationTime: String? = nil, notificationTimezone: String? = nil) {
        self.actionId = actionId
        self.userActionId = userActionId
        self.rrule = rrule
        self.position = position
        self.notificationTime = notificationTime
        self.notificationTimezone = notificationTimezone
    }

    enum CodingKeys: String, CodingKey {
        case actionId = "action_id"
        case userActionId = "user_action_id"
        case rrule, position
        case notificationTime = "notification_time"
        case notificationTimezone = "notification_timezone"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        actionId = try container.decodeIfPresent(String.self, forKey: .actionId)
        userActionId = try container.decodeIfPresent(UUID.self, forKey: .userActionId)
        rrule = try container.decode(String.self, forKey: .rrule)
        position = try container.decodeIfPresent(Int.self, forKey: .position)
        notificationTime = try container.decodeIfPresent(String.self, forKey: .notificationTime)
        notificationTimezone = try container.decodeIfPresent(String.self, forKey: .notificationTimezone)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(actionId, forKey: .actionId)
        try container.encodeIfPresent(userActionId, forKey: .userActionId)
        try container.encode(rrule, forKey: .rrule)
        try container.encodeIfPresent(position, forKey: .position)
        try container.encodeIfPresent(notificationTime, forKey: .notificationTime)
        try container.encodeIfPresent(notificationTimezone, forKey: .notificationTimezone)
    }
}

public struct ProtocolCreate: Codable, Hashable, Sendable {
    public var userId: String
    public var name: String
    public var actions: [ProtocolActionCreate]
    public var isActive: Bool?
    public var startedAt: String?
    public var endedAt: String?
    public var category: ProtocolCategory?
    public var metricKeys: [String]?

    public init(userId: String, name: String, actions: [ProtocolActionCreate], isActive: Bool? = nil, startedAt: String? = nil, endedAt: String? = nil, category: ProtocolCategory? = nil, metricKeys: [String]? = nil) {
        self.userId = userId
        self.name = name
        self.actions = actions
        self.isActive = isActive
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.category = category
        self.metricKeys = metricKeys
    }

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case name, actions
        case isActive = "is_active"
        case startedAt = "started_at"
        case endedAt = "ended_at"
        case category
        case metricKeys = "metric_keys"
    }
}

// MARK: - CheckIn Types

public struct CheckIn: Codable, Hashable, Sendable, Identifiable {
    public var protocolActionId: String
    public var ts: String
    public var appliedVolume: QuantityOutput?
    public var appliedDurationSeconds: Int?
    public var id: String
    public var userId: String?

    public init(protocolActionId: String, ts: String, appliedVolume: QuantityOutput? = nil, appliedDurationSeconds: Int? = nil, id: String, userId: String? = nil) {
        self.protocolActionId = protocolActionId
        self.ts = ts
        self.appliedVolume = appliedVolume
        self.appliedDurationSeconds = appliedDurationSeconds
        self.id = id
        self.userId = userId
    }

    enum CodingKeys: String, CodingKey {
        case protocolActionId = "protocol_action_id"
        case ts
        case appliedVolume = "applied_volume"
        case appliedDurationSeconds = "applied_duration_seconds"
        case id
        case userId = "user_id"
    }
}

public struct CheckInCreate: Encodable {
    public let protocolActionId: String
    public let ts: String
    public let appliedVolume: QuantityOutput?
    public let appliedDurationSeconds: Int?

    public init(protocolActionId: String, ts: String, appliedVolume: QuantityOutput? = nil, appliedDurationSeconds: Int? = nil) {
        self.protocolActionId = protocolActionId
        self.ts = ts
        self.appliedVolume = appliedVolume
        self.appliedDurationSeconds = appliedDurationSeconds
    }

    enum CodingKeys: String, CodingKey {
        case protocolActionId = "protocol_action_id"
        case ts
        case appliedVolume = "applied_volume"
        case appliedDurationSeconds = "applied_duration_seconds"
    }
}

public struct ProtocolCheckinCreate: Encodable {
    public let protocolId: String
    public let protocolActionId: String
    public let ts: String
    public let appliedVolume: QuantityOutput?
    public let appliedDurationSeconds: Int?

    public init(protocolId: String, protocolActionId: String, ts: String, appliedVolume: QuantityOutput? = nil, appliedDurationSeconds: Int? = nil) {
        self.protocolId = protocolId
        self.protocolActionId = protocolActionId
        self.ts = ts
        self.appliedVolume = appliedVolume
        self.appliedDurationSeconds = appliedDurationSeconds
    }

    enum CodingKeys: String, CodingKey {
        case protocolId = "protocol_id"
        case protocolActionId = "protocol_action_id"
        case ts
        case appliedVolume = "applied_volume"
        case appliedDurationSeconds = "applied_duration_seconds"
    }
}

// MARK: - ActionCheckinStatus

public struct ActionCheckinStatus: Codable, Hashable, Sendable, Identifiable {
    public var id: String { protocolActionId }
    public var protocolActionId: String
    public var actionId: String?
    public var userActionId: UUID?
    public var actionName: String
    public var position: Int
    public var scheduledTime: String?
    public var isCompleted: Bool
    public var completedAt: String?
    public var checkinId: String?
    public var appliedVolume: QuantityOutput?
    public var appliedDurationSeconds: Int?

    public init(protocolActionId: String, actionId: String? = nil, userActionId: UUID? = nil, actionName: String, position: Int, scheduledTime: String? = nil, isCompleted: Bool, completedAt: String? = nil, checkinId: String? = nil, appliedVolume: QuantityOutput? = nil, appliedDurationSeconds: Int? = nil) {
        self.protocolActionId = protocolActionId
        self.actionId = actionId
        self.userActionId = userActionId
        self.actionName = actionName
        self.position = position
        self.scheduledTime = scheduledTime
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.checkinId = checkinId
        self.appliedVolume = appliedVolume
        self.appliedDurationSeconds = appliedDurationSeconds
    }

    enum CodingKeys: String, CodingKey {
        case protocolActionId = "protocol_action_id"
        case actionId = "action_id"
        case userActionId = "user_action_id"
        case actionName = "action_name"
        case position
        case scheduledTime = "scheduled_time"
        case isCompleted = "is_completed"
        case completedAt = "completed_at"
        case checkinId = "checkin_id"
        case appliedVolume = "applied_volume"
        case appliedDurationSeconds = "applied_duration_seconds"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        protocolActionId = try container.decode(String.self, forKey: .protocolActionId)
        actionId = try container.decodeIfPresent(String.self, forKey: .actionId)
        userActionId = try container.decodeIfPresent(UUID.self, forKey: .userActionId)
        actionName = try container.decode(String.self, forKey: .actionName)
        position = try container.decode(Int.self, forKey: .position)
        scheduledTime = try container.decodeIfPresent(String.self, forKey: .scheduledTime)
        isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        completedAt = try container.decodeIfPresent(String.self, forKey: .completedAt)
        checkinId = try container.decodeIfPresent(String.self, forKey: .checkinId)
        appliedVolume = try container.decodeIfPresent(QuantityOutput.self, forKey: .appliedVolume)
        appliedDurationSeconds = try container.decodeIfPresent(Int.self, forKey: .appliedDurationSeconds)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(protocolActionId, forKey: .protocolActionId)
        try container.encodeIfPresent(actionId, forKey: .actionId)
        try container.encodeIfPresent(userActionId, forKey: .userActionId)
        try container.encode(actionName, forKey: .actionName)
        try container.encode(position, forKey: .position)
        try container.encodeIfPresent(scheduledTime, forKey: .scheduledTime)
        try container.encode(isCompleted, forKey: .isCompleted)
        try container.encodeIfPresent(completedAt, forKey: .completedAt)
        try container.encodeIfPresent(checkinId, forKey: .checkinId)
        try container.encodeIfPresent(appliedVolume, forKey: .appliedVolume)
        try container.encodeIfPresent(appliedDurationSeconds, forKey: .appliedDurationSeconds)
    }
}

// MARK: - Protocol Daily Status

public struct ProtocolDailyStatus: Codable, Hashable, Sendable {
    public var protocolId: String
    public var date: String
    public var totalActions: Int
    public var completedActions: Int
    public var completionPercentage: Int
    public var actions: [ActionCheckinStatus]

    public init(protocolId: String, date: String, totalActions: Int, completedActions: Int, completionPercentage: Int, actions: [ActionCheckinStatus]) {
        self.protocolId = protocolId
        self.date = date
        self.totalActions = totalActions
        self.completedActions = completedActions
        self.completionPercentage = completionPercentage
        self.actions = actions
    }

    enum CodingKeys: String, CodingKey {
        case protocolId = "protocol_id"
        case date
        case totalActions = "total_actions"
        case completedActions = "completed_actions"
        case completionPercentage = "completion_percentage"
        case actions
    }
}

// MARK: - Protocol With Checkins

public struct ProtocolWithCheckins: Codable, Hashable, Sendable, Identifiable {
    public var id: String
    public var userId: String
    public var name: String
    public var actions: [ProtocolAction]
    public var isActive: Bool?
    public var startedAt: String?
    public var endedAt: String?

    public init(id: String, userId: String, name: String, actions: [ProtocolAction], isActive: Bool? = nil, startedAt: String? = nil, endedAt: String? = nil) {
        self.id = id
        self.userId = userId
        self.name = name
        self.actions = actions
        self.isActive = isActive
        self.startedAt = startedAt
        self.endedAt = endedAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name, actions
        case isActive = "is_active"
        case startedAt = "started_at"
        case endedAt = "ended_at"
    }
}

// MARK: - Image Types

public struct ImageAttachment: Codable, Hashable, Sendable, Identifiable {
    public var id: String
    public var ownerId: String
    public var attachableType: String
    public var attachableId: String
    public var filename: String
    public var contentType: String
    public var fileSize: Int
    public var width: Int?
    public var height: Int?
    public var url: String?
    public var createdAt: String

    public init(id: String, ownerId: String, attachableType: String, attachableId: String, filename: String, contentType: String, fileSize: Int, width: Int? = nil, height: Int? = nil, url: String? = nil, createdAt: String) {
        self.id = id
        self.ownerId = ownerId
        self.attachableType = attachableType
        self.attachableId = attachableId
        self.filename = filename
        self.contentType = contentType
        self.fileSize = fileSize
        self.width = width
        self.height = height
        self.url = url
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case ownerId = "owner_id"
        case attachableType = "attachable_type"
        case attachableId = "attachable_id"
        case filename
        case contentType = "content_type"
        case fileSize = "file_size"
        case width, height, url
        case createdAt = "created_at"
    }
}

public struct ImageAttachmentCreate: Codable, Hashable, Sendable, Identifiable {
    public var id: String
    public var filename: String
    public var contentType: String
    public var fileSize: Int
    public var width: Int?
    public var height: Int?
    public var url: String?

    public init(id: String, filename: String, contentType: String, fileSize: Int, width: Int? = nil, height: Int? = nil, url: String? = nil) {
        self.id = id
        self.filename = filename
        self.contentType = contentType
        self.fileSize = fileSize
        self.width = width
        self.height = height
        self.url = url
    }

    enum CodingKeys: String, CodingKey {
        case id, filename
        case contentType = "content_type"
        case fileSize = "file_size"
        case width, height, url
    }
}

// MARK: - Error Types

public struct HTTPValidationError: Codable, Hashable, Sendable {
    public var detail: [ValidationError]?

    public init(detail: [ValidationError]? = nil) {
        self.detail = detail
    }
}

public struct ValidationError: Codable, Hashable, Sendable {
    public var loc: [Int?]
    public var msg: String
    public var type: String

    public init(loc: [Int?], msg: String, type: String) {
        self.loc = loc
        self.msg = msg
        self.type = type
    }

    enum CodingKeys: String, CodingKey {
        case loc, msg, type
    }
}

// MARK: - Protocol Update

public struct ProtocolUpdate: Codable, Hashable, Sendable {
    public var name: String?
    public var isActive: Bool?
    public var startedAt: String?
    public var endedAt: String?
    public var category: ProtocolCategory?
    public var metricKeys: [String]?

    public init(name: String? = nil, isActive: Bool? = nil, startedAt: String? = nil, endedAt: String? = nil, category: ProtocolCategory? = nil, metricKeys: [String]? = nil) {
        self.name = name
        self.isActive = isActive
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.category = category
        self.metricKeys = metricKeys
    }

    enum CodingKeys: String, CodingKey {
        case name
        case isActive = "is_active"
        case startedAt = "started_at"
        case endedAt = "ended_at"
        case category
        case metricKeys = "metric_keys"
    }
}

// MARK: - Template Types

public struct ProtocolTemplateCreate: Codable, Hashable, Sendable {
    public var name: String
    public var description: String?
    public var category: TemplateCategory
    public var actionDrafts: [TemplateActionDraftCreate]

    public init(name: String, description: String? = nil, category: TemplateCategory, actionDrafts: [TemplateActionDraftCreate]) {
        self.name = name
        self.description = description
        self.category = category
        self.actionDrafts = actionDrafts
    }

    enum CodingKeys: String, CodingKey {
        case name, description, category
        case actionDrafts = "action_drafts"
    }
}

public struct ProtocolTemplateResponse: Codable, Hashable, Sendable, Identifiable {
    public var id: String
    public var name: String
    public var description: String?
    public var category: TemplateCategory
    public var actionDrafts: [TemplateActionDraftResponse]?
    public var imageUrl: String?

    public init(id: String, name: String, description: String? = nil, category: TemplateCategory, actionDrafts: [TemplateActionDraftResponse]? = nil, imageUrl: String? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.actionDrafts = actionDrafts
        self.imageUrl = imageUrl
    }

    enum CodingKeys: String, CodingKey {
        case id, name, description, category
        case actionDrafts = "action_drafts"
        case imageUrl = "image_url"
    }
}

public struct TemplateActionDraftCreate: Codable, Hashable, Sendable {
    public var substanceName: String
    public var substanceType: SubstanceType
    public var volume: QuantityInput?
    public var durationSeconds: Int?
    public var rrule: String
    public var position: Int?

    public init(substanceName: String, substanceType: SubstanceType, volume: QuantityInput? = nil, durationSeconds: Int? = nil, rrule: String, position: Int? = nil) {
        self.substanceName = substanceName
        self.substanceType = substanceType
        self.volume = volume
        self.durationSeconds = durationSeconds
        self.rrule = rrule
        self.position = position
    }

    enum CodingKeys: String, CodingKey {
        case substanceName = "substance_name"
        case substanceType = "substance_type"
        case volume
        case durationSeconds = "duration_seconds"
        case rrule, position
    }
}

public struct TemplateActionDraftResponse: Codable, Hashable, Sendable {
    public var id: String
    public var substanceName: String
    public var substanceType: SubstanceType
    public var volume: QuantityOutput?
    public var durationSeconds: Int?
    public var rrule: String
    public var position: Int?

    public init(id: String, substanceName: String, substanceType: SubstanceType, volume: QuantityOutput? = nil, durationSeconds: Int? = nil, rrule: String, position: Int? = nil) {
        self.id = id
        self.substanceName = substanceName
        self.substanceType = substanceType
        self.volume = volume
        self.durationSeconds = durationSeconds
        self.rrule = rrule
        self.position = position
    }

    enum CodingKeys: String, CodingKey {
        case id
        case substanceName = "substance_name"
        case substanceType = "substance_type"
        case volume
        case durationSeconds = "duration_seconds"
        case rrule, position
    }
}

// MARK: - Notification Schedule Types

public struct NotificationScheduleCreate: Codable, Hashable, Sendable {
    public var protocolActionId: String
    public var preferredTime: String
    public var timezone: String
    public var isEnabled: Bool?

    public init(protocolActionId: String, preferredTime: String, timezone: String, isEnabled: Bool? = nil) {
        self.protocolActionId = protocolActionId
        self.preferredTime = preferredTime
        self.timezone = timezone
        self.isEnabled = isEnabled
    }

    enum CodingKeys: String, CodingKey {
        case protocolActionId = "protocol_action_id"
        case preferredTime = "preferred_time"
        case timezone
        case isEnabled = "is_enabled"
    }
}

public struct NotificationScheduleResponse: Codable, Hashable, Sendable, Identifiable {
    public var id: String
    public var protocolActionId: String
    public var userId: String
    public var preferredTime: String
    public var timezone: String
    public var isEnabled: Bool
    public var createdAt: String

    public init(id: String, protocolActionId: String, userId: String, preferredTime: String, timezone: String, isEnabled: Bool, createdAt: String) {
        self.id = id
        self.protocolActionId = protocolActionId
        self.userId = userId
        self.preferredTime = preferredTime
        self.timezone = timezone
        self.isEnabled = isEnabled
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case protocolActionId = "protocol_action_id"
        case userId = "user_id"
        case preferredTime = "preferred_time"
        case timezone
        case isEnabled = "is_enabled"
        case createdAt = "created_at"
    }
}

public struct NotificationScheduleUpdate: Codable, Hashable, Sendable {
    public var preferredTime: String?
    public var timezone: String?
    public var isEnabled: Bool?

    public init(preferredTime: String? = nil, timezone: String? = nil, isEnabled: Bool? = nil) {
        self.preferredTime = preferredTime
        self.timezone = timezone
        self.isEnabled = isEnabled
    }

    enum CodingKeys: String, CodingKey {
        case preferredTime = "preferred_time"
        case timezone
        case isEnabled = "is_enabled"
    }
}

// MARK: - UI-Specific Models

public struct ActionItem: Decodable, Identifiable, Equatable {
    public let id: String
    public let name: String
    public let scheduleLabel: String?
    public let timeLabel: String?
    public let modeLabel: String?
    public let substanceId: String?
    public let substance: Substance?
    public let volume: QuantityOutput?
    public let durationSeconds: Int?
    public let userActionId: UUID?
    public let userActionCategory: ActionCategory?

    public var notificationTime: String?
    public var notificationTimezone: String?
    public var notificationPreferences: DraftNotificationPreferences?
    public var schedule: ActionSchedule?
    public var slots: [ScheduleSlot]

    // schedule is iOS-only UI state, not decoded from API; omitted from CodingKeys intentionally

    private enum CodingKeys: String, CodingKey {
        case id, name
        case scheduleLabel = "schedule_label"
        case timeLabel = "time_label"
        case modeLabel = "mode_label"
        case substanceId = "substance_id"
        case substance, volume
        case durationSeconds = "duration_seconds"
        case userActionId = "user_action_id"
        case userActionCategory = "user_action_category"
        case notificationTime = "notification_time"
        case notificationTimezone = "notification_timezone"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        scheduleLabel = try container.decodeIfPresent(String.self, forKey: .scheduleLabel)
        timeLabel = try container.decodeIfPresent(String.self, forKey: .timeLabel)
        modeLabel = try container.decodeIfPresent(String.self, forKey: .modeLabel)
        substanceId = try container.decodeIfPresent(String.self, forKey: .substanceId)
        substance = try container.decodeIfPresent(Substance.self, forKey: .substance)
        volume = try container.decodeIfPresent(QuantityOutput.self, forKey: .volume)
        durationSeconds = try container.decodeIfPresent(Int.self, forKey: .durationSeconds)
        userActionId = try container.decodeIfPresent(UUID.self, forKey: .userActionId)
        userActionCategory = try container.decodeIfPresent(ActionCategory.self, forKey: .userActionCategory)
        notificationTime = try container.decodeIfPresent(String.self, forKey: .notificationTime)
        notificationTimezone = try container.decodeIfPresent(String.self, forKey: .notificationTimezone)
        notificationPreferences = nil
        schedule = nil
        slots = []
    }

    public var volumeLabel: String? {
        guard let volume else { return nil }
        return volume.displayString
    }

    public var durationLabel: String? {
        guard let durationSeconds else { return nil }
        if durationSeconds >= 60 {
            let minutes = Double(durationSeconds) / 60.0
            let minStr = minutes.roundedString(maxFractionDigits: 1)
            return "\(minStr) min"
        } else {
            return "\(durationSeconds)s"
        }
    }

    public var tagLabel: String {
        volumeLabel ?? durationLabel ?? scheduleLabel ?? "—"
    }

    public var detailLabel: String {
        let parts: [String] = [
            displayNameFallback,
            timeLabel,
            modeLabel,
            durationLabel
        ].compactMap { $0 }.filter { !$0.isEmpty }
        return parts.joined(separator: " • ")
    }

    public var displayName: String {
        substance?.name ?? name
    }

    private var displayNameFallback: String? {
        substance?.name ?? nil
    }

    public var notificationTimeLabel: String? {
        let reminderSlots = slots.filter { $0.isReminderOn }
        guard !reminderSlots.isEmpty else { return nil }
        return reminderSlots.map { $0.timeLabel }.joined(separator: ", ")
    }

    public var scheduleSummaryText: String {
        guard let schedule else { return "" }
        var parts: [String] = [schedule.summaryLabel]
        let timeLabels = slots.isEmpty
            ? [schedule.timeLabel]
            : slots.map { $0.timeLabel }
        parts.append(timeLabels.joined(separator: ", "))
        let reminderCount = slots.filter { $0.isReminderOn }.count
        if reminderCount > 0 {
            parts.append("🔔 \(reminderCount) reminder\(reminderCount > 1 ? "s" : "")")
        } else if !slots.isEmpty {
            parts.append("Log only")
        } else {
            parts.append("Log only")
        }
        return parts.joined(separator: " • ")
    }

    public var categoryIcon: String {
        if let category = userActionCategory {
            return category.icon
        }
        if let type = substance?.type {
            switch type {
            case .topical: return "drop.fill"
            case .oral: return "pill.fill"
            case .device: return "light.max"
            case .hygiene: return "hands.sparkles.fill"
            @unknown default: return "circle.fill"
            }
        }
        return "circle.fill"
    }

    public var descriptionLabel: String {
        if let volume = volumeLabel { return volume }
        if let duration = durationLabel { return duration }
        if let desc = substance?.notes, !desc.isEmpty { return desc }
        return ""
    }

    public init(
        id: String = UUID().uuidString,
        name: String,
        scheduleLabel: String? = nil,
        timeLabel: String? = nil,
        modeLabel: String? = nil,
        notificationTime: String? = nil,
        notificationTimezone: String? = nil,
        notificationPreferences: DraftNotificationPreferences? = nil,
        schedule: ActionSchedule? = nil,
        slots: [ScheduleSlot]? = nil
    ) {
        self.id = id
        self.name = name
        self.scheduleLabel = scheduleLabel
        self.timeLabel = timeLabel
        self.modeLabel = modeLabel
        self.substanceId = nil
        self.substance = nil
        self.volume = nil
        self.durationSeconds = nil
        self.userActionId = nil
        self.userActionCategory = nil
        self.notificationTime = notificationTime
        self.notificationTimezone = notificationTimezone
        self.notificationPreferences = notificationPreferences
        self.schedule = schedule
        self.slots = slots ?? []
    }

    public init(
        id: String = UUID().uuidString,
        name: String,
        substanceId: String? = nil,
        substance: Substance? = nil,
        volume: QuantityOutput? = nil,
        durationSeconds: Int? = nil,
        userActionId: UUID? = nil,
        userActionCategory: ActionCategory? = nil,
        notificationTime: String? = nil,
        notificationTimezone: String? = nil,
        notificationPreferences: DraftNotificationPreferences? = nil,
        schedule: ActionSchedule? = nil,
        slots: [ScheduleSlot]? = nil
    ) {
        self.id = id
        self.name = name
        self.scheduleLabel = nil
        self.timeLabel = nil
        self.modeLabel = nil
        self.substanceId = substanceId
        self.substance = substance
        self.volume = volume
        self.durationSeconds = durationSeconds
        self.userActionId = userActionId
        self.userActionCategory = userActionCategory
        self.notificationTime = notificationTime
        self.notificationTimezone = notificationTimezone
        self.notificationPreferences = notificationPreferences
        self.schedule = schedule
        self.slots = slots ?? []
    }
}

public struct TemplateActionDraft: Decodable, Identifiable, Equatable {
    public let id: String
    public let substanceName: String
    public let substanceType: String
    public let volume: QuantityOutput?
    public let durationSeconds: Int?
    public let rrule: String
    public let position: Int

    public init(
        id: String,
        substanceName: String,
        substanceType: String,
        volume: QuantityOutput? = nil,
        durationSeconds: Int? = nil,
        rrule: String,
        position: Int
    ) {
        self.id = id
        self.substanceName = substanceName
        self.substanceType = substanceType
        self.volume = volume
        self.durationSeconds = durationSeconds
        self.rrule = rrule
        self.position = position
    }

    public var scheduleLabel: String? {
        let upper = rrule.uppercased()
        var hour: Int?
        var minute = 0
        if let range = upper.range(of: "BYHOUR=") {
            let substring = upper[range.upperBound...]
            let part = substring.split(separator: ";").first?.split(separator: ",").first
            hour = part.flatMap { Int($0) }
        }
        if let range = upper.range(of: "BYMINUTE=") {
            let substring = upper[range.upperBound...]
            let part = substring.split(separator: ";").first?.split(separator: ",").first
            minute = part.flatMap { Int($0) } ?? 0
        }
        if let hour {
            return String(format: "%02d:%02d", hour, minute)
        }
        return nil
    }

    public var dosageLabel: String? {
        if let volume {
            return volume.displayString
        }
        if let durationSeconds {
            if durationSeconds >= 60 {
                let minutes = Double(durationSeconds) / 60.0
                return "\(String(format: "%.1f", minutes)) min"
            }
            return "\(durationSeconds)s"
        }
        return nil
    }

    enum CodingKeys: String, CodingKey {
        case id
        case substanceName = "substance_name"
        case substanceType = "substance_type"
        case volume
        case durationSeconds = "duration_seconds"
        case rrule
        case position
    }
}

public struct ProtocolTemplate: Decodable, Identifiable, Equatable {
    public let id: String
    public let name: String
    public let description: String?
    public let category: TemplateCategory
    public let actionDrafts: [TemplateActionDraft]
    public let imageUrl: String?

    public init(
        id: String,
        name: String,
        description: String? = nil,
        category: TemplateCategory,
        actionDrafts: [TemplateActionDraft],
        imageUrl: String? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.actionDrafts = actionDrafts
        self.imageUrl = imageUrl
    }

    public var stepsLabel: String {
        let count = actionDrafts.count
        return count == 1 ? "1 step" : "\(count) steps"
    }

    enum CodingKeys: String, CodingKey {
        case id, name, description, category
        case actionDrafts = "action_drafts"
        case imageUrl = "image_url"
    }
}

public struct ProtocolDraft {
    public var name: String = ""
    public var actions: [ActionItem] = []
    public var category: ProtocolCategory?
    public var icon: String?
    public var coverImageData: Data?
    public var metricKeys: [MetricKey]?

    public init(
        name: String = "",
        actions: [ActionItem] = [],
        category: ProtocolCategory? = nil,
        icon: String? = nil,
        coverImageData: Data? = nil,
        metricKeys: [MetricKey]? = nil
    ) {
        self.name = name
        self.actions = actions
        self.category = category
        self.icon = icon
        self.coverImageData = coverImageData
        self.metricKeys = metricKeys
    }
}

public struct DraftNotificationPreferences: Codable, Hashable, Equatable {
    public var preferredTime: Date
    public var timezone: String
    public var isEnabled: Bool

    public init(
        preferredTime: Date = Date(),
        timezone: String = TimeZone.current.identifier,
        isEnabled: Bool = true
    ) {
        self.preferredTime = preferredTime
        self.timezone = timezone
        self.isEnabled = isEnabled
    }

    public var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: preferredTime)
    }
}

// MARK: - Backward Compatibility Aliases

public typealias AccessToken = TokenPair
public typealias RegisterRequest = UserCreate
public typealias RegisterResponse = TokenPair
public typealias LoginResponse = TokenPair
public typealias AuthTokens = TokenPair
public typealias ProtocolCreateRequest = ProtocolCreate
public typealias Quantity = QuantityOutput
public typealias ProtocolDailyStatusType = ProtocolDailyStatus

// MARK: - UI Extensions

extension ProtocolItem {
    public var stepsLabel: String {
        let count = actions.count
        return count == 1 ? "1 step" : "\(count) steps"
    }

    public var statusLabel: String {
        isActive == true ? "Active" : "Paused"
    }

    public var streakLabel: String {
        guard streak > 0 else { return "" }
        return streak == 1 ? "1-day streak" : "\(streak)-day streak"
    }
}

extension SubstanceUnit {
    public var displayName: String {
        switch self {
        case .ml: return "ml"
        case .mg: return "mg"
        case .g: return "g"
        case .durationSeconds: return "sec"
        case .drop: return "drop"
        case .capsule: return "capsule"
        case .tablet: return "tablet"
        case .spray: return "spray"
        }
    }
}

extension QuantityOutput {
    public var displayString: String {
        let amountStr = amount.roundedString()
        return "\(amountStr) \(unit.displayName)"
    }
}

extension QuantityInput {
    public var displayString: String {
        let amountStr = amount ?? "—"
        return "\(amountStr) \(unit.displayName)"
    }
}

extension ActionCheckinStatus {
    public var displayTime: String {
        if isCompleted == true, let completedAt = completedAt {
            let formatter = ISO8601DateFormatter()
            if let date = formatter.date(from: completedAt) {
                let timeFormatter = DateFormatter()
                timeFormatter.timeStyle = .short
                return "Done at \(timeFormatter.string(from: date))"
            }
            return "Done"
        } else if let scheduledTime = scheduledTime {
            return "Daily at \(scheduledTime)"
        } else {
            return "Scheduled"
        }
    }

    public var subtitle: String {
        if isCompleted == true {
            var parts: [String] = [displayTime]
            if let volume = appliedVolume {
                parts.append("\(volume.amount.roundedString()) \(volume.unit.displayName) applied")
            } else if let duration = appliedDurationSeconds {
                if duration >= 60 {
                    let minutes = Double(duration) / 60.0
                    parts.append("\(minutes.roundedString(maxFractionDigits: 1)) min session")
                } else {
                    parts.append("\(duration)s session")
                }
            }
            return parts.joined(separator: " • ").uppercased()
        } else {
            return displayTime
        }
    }
}

extension ProtocolDailyStatus {
    public var statusDate: Date? {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.timeZone = TimeZone(identifier: "UTC")
        return fmt.date(from: date)
    }
}
