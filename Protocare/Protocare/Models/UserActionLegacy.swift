import Foundation

// LEGACY — unified action model migration (Step 20).
// `Models/UserActionModels.swift` and `Stores/UserActionsStore.swift` were
// deleted; the types below survive ONLY so existing call sites keep compiling
// until their steps land:
//
//  - UserAction and its API payload types are used only by APIClient's
//    /user-actions methods (plus their mocks and preview stubs).
//    TODO(Step 31): delete together with the APIClient user-action methods.
//
//  ActionField / ActionFieldType / ActionParameters were deleted at Step 25d
//  together with the ActionCreatorView rewrite to POST /actions.
//
// Do not use these types in new code — everything is a unified `Action` now.

// MARK: - User Action (legacy API shape)

public struct UserAction: Codable, Hashable, Sendable, Identifiable {
    public let id: UUID
    public let userId: UUID
    public let name: String
    public let description: String?
    public let category: ActionCategory
    public let parameters: [String: AnyCodable]?
    public let iconKey: String?
    public let color: String?
    public let isTemplate: Bool
    public let templateSourceId: UUID?
    public let protocolCount: Int
    public let sortOrder: Int
    public let isActive: Bool
    public let createdAt: Date
    public let updatedAt: Date

    public init(
        id: UUID,
        userId: UUID,
        name: String,
        description: String? = nil,
        category: ActionCategory,
        parameters: [String: AnyCodable]? = nil,
        iconKey: String? = nil,
        color: String? = nil,
        isTemplate: Bool = false,
        templateSourceId: UUID? = nil,
        protocolCount: Int = 0,
        sortOrder: Int = 0,
        isActive: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.description = description
        self.category = category
        self.parameters = parameters
        self.iconKey = iconKey
        self.color = color
        self.isTemplate = isTemplate
        self.templateSourceId = templateSourceId
        self.protocolCount = protocolCount
        self.sortOrder = sortOrder
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case id, name, description, category, parameters
        case iconKey = "icon_key"
        case color
        case isTemplate = "is_template"
        case templateSourceId = "template_source_id"
        case protocolCount = "protocol_count"
        case sortOrder = "sort_order"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case userId = "user_id"
    }
}

// MARK: - User Action Create

public struct UserActionCreate: Codable, Hashable, Sendable {
    public var name: String
    public var description: String?
    public var category: ActionCategory
    public var parameters: [String: AnyCodable]?
    public var iconKey: String?
    public var color: String?
    public var sortOrder: Int?

    public init(
        name: String,
        description: String? = nil,
        category: ActionCategory,
        parameters: [String: AnyCodable]? = nil,
        iconKey: String? = nil,
        color: String? = nil,
        sortOrder: Int? = nil
    ) {
        self.name = name
        self.description = description
        self.category = category
        self.parameters = parameters
        self.iconKey = iconKey
        self.color = color
        self.sortOrder = sortOrder
    }

    enum CodingKeys: String, CodingKey {
        case name, description, category, parameters
        case iconKey = "icon_key"
        case color
        case sortOrder = "sort_order"
    }
}

// MARK: - User Action Update

public struct UserActionUpdate: Codable, Hashable, Sendable {
    public var name: String?
    public var description: String?
    public var category: ActionCategory?
    public var parameters: [String: AnyCodable]?
    public var iconKey: String?
    public var color: String?
    public var sortOrder: Int?
    public var isActive: Bool?

    public init(
        name: String? = nil,
        description: String? = nil,
        category: ActionCategory? = nil,
        parameters: [String: AnyCodable]? = nil,
        iconKey: String? = nil,
        color: String? = nil,
        sortOrder: Int? = nil,
        isActive: Bool? = nil
    ) {
        self.name = name
        self.description = description
        self.category = category
        self.parameters = parameters
        self.iconKey = iconKey
        self.color = color
        self.sortOrder = sortOrder
        self.isActive = isActive
    }

    enum CodingKeys: String, CodingKey {
        case name, description, category, parameters
        case iconKey = "icon_key"
        case color
        case sortOrder = "sort_order"
        case isActive = "is_active"
    }
}

// MARK: - User Action Usage

public struct UserActionUsageEntry: Codable, Hashable, Sendable, Identifiable {
    public let protocolId: UUID
    public let protocolName: String
    public let protocolActionId: UUID

    public var id: UUID { protocolId }

    public init(protocolId: UUID, protocolName: String, protocolActionId: UUID) {
        self.protocolId = protocolId
        self.protocolName = protocolName
        self.protocolActionId = protocolActionId
    }

    enum CodingKeys: String, CodingKey {
        case protocolId = "protocol_id"
        case protocolName = "protocol_name"
        case protocolActionId = "protocol_action_id"
    }
}

public typealias UserActionUsage = [UserActionUsageEntry]

// MARK: - Paginated User Actions

public struct PaginatedUserActions: Codable, Hashable, Sendable {
    public let items: [UserAction]
    public let total: Int
    public let page: Int
    public let pageSize: Int

    public init(items: [UserAction], total: Int, page: Int, pageSize: Int) {
        self.items = items
        self.total = total
        self.page = page
        self.pageSize = pageSize
    }

    enum CodingKeys: String, CodingKey {
        case items, total, page
        case pageSize = "page_size"
    }
}

// MARK: - User Action + UI Helpers

extension UserAction {
    public var displayIcon: String {
        iconKey ?? category.tagIcon
    }

    public var displayColor: String {
        color ?? "#6B9E7A"
    }

    public var fieldCountLabel: String {
        let count = parameters?.count ?? 0
        return count == 0 ? "No parameters" : (count == 1 ? "1 parameter" : "\(count) parameters")
    }
}
