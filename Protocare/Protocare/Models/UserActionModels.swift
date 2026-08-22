import Foundation

// MARK: - Action Category

public enum ActionCategory: String, Codable, Hashable, Sendable, CaseIterable {
    case supplement = "supplement"
    case skincare = "skincare"
    case hair = "hair"
    case exercise = "exercise"
    case nutrition = "nutrition"
    case mindfulness = "mindfulness"
    case sleep = "sleep"
    case measurement = "measurement"
    case custom = "custom"

    public var displayName: String {
        switch self {
        case .supplement: return "Supplement"
        case .skincare: return "Skincare"
        case .hair: return "Hair"
        case .exercise: return "Exercise"
        case .nutrition: return "Nutrition"
        case .mindfulness: return "Mindfulness"
        case .sleep: return "Sleep"
        case .measurement: return "Measurement"
        case .custom: return "Custom"
        }
    }

    public var icon: String {
        switch self {
        case .supplement: return "pill.fill"
        case .skincare: return "drop.fill"
        case .hair: return "scissors"
        case .exercise: return "figure.run"
        case .nutrition: return "fork.knife"
        case .mindfulness: return "brain.head.profile.fill"
        case .sleep: return "moon.fill"
        case .measurement: return "ruler"
        case .custom: return "sparkles"
        }
    }
}

// MARK: - Action Field Type

public enum ActionFieldType: String, Codable, Hashable, Sendable, CaseIterable {
    case text
    case number
    case boolean
    case select
    case time
    case duration
}

// MARK: - Action Field

public struct ActionField: Codable, Hashable, Sendable, Identifiable {
    public var id: String { key }
    public let key: String
    public let label: String
    public let type: ActionFieldType
    public let isRequired: Bool
    public let defaultValue: AnyCodable?
    public let options: [String]?
    public let unit: String?
    public let minValue: AnyCodable?
    public let maxValue: AnyCodable?

    public init(
        key: String,
        label: String,
        type: ActionFieldType,
        isRequired: Bool = false,
        defaultValue: AnyCodable? = nil,
        options: [String]? = nil,
        unit: String? = nil,
        minValue: AnyCodable? = nil,
        maxValue: AnyCodable? = nil
    ) {
        self.key = key
        self.label = label
        self.type = type
        self.isRequired = isRequired
        self.defaultValue = defaultValue
        self.options = options
        self.unit = unit
        self.minValue = minValue
        self.maxValue = maxValue
    }

    enum CodingKeys: String, CodingKey {
        case key, label, type
        case isRequired = "required"
        case defaultValue = "default_value"
        case options, unit
        case minValue = "min_value"
        case maxValue = "max_value"
    }
}

// MARK: - Action Parameters

public struct ActionParameters: Codable, Hashable, Sendable {
    public let fields: [ActionField]

    public init(fields: [ActionField] = []) {
        self.fields = fields
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        fields = (try? container.decodeIfPresent([ActionField].self, forKey: .fields)) ?? []
    }
}

// MARK: - User Action

public struct UserAction: Codable, Hashable, Sendable, Identifiable {
    public let id: UUID
    public let userId: UUID
    public let name: String
    public let description: String?
    public let category: ActionCategory
    public let parameters: ActionParameters?
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
        parameters: ActionParameters? = nil,
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
    public var parameters: ActionParameters?
    public var iconKey: String?
    public var color: String?
    public var sortOrder: Int?

    public init(
        name: String,
        description: String? = nil,
        category: ActionCategory,
        parameters: ActionParameters? = nil,
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
    public var parameters: ActionParameters?
    public var iconKey: String?
    public var color: String?
    public var sortOrder: Int?
    public var isActive: Bool?

    public init(
        name: String? = nil,
        description: String? = nil,
        category: ActionCategory? = nil,
        parameters: ActionParameters? = nil,
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

// MARK: - AnyCodable

public struct AnyCodable: Codable, Hashable, Sendable {
    public let value: Any

    public init(_ value: Any) {
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case is NSNull:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }

    public static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        switch (lhs.value, rhs.value) {
        case is (NSNull, NSNull): return true
        case let (l as Bool, r as Bool): return l == r
        case let (l as Int, r as Int): return l == r
        case let (l as Double, r as Double): return l == r
        case let (l as String, r as String): return l == r
        default: return false
        }
    }

    public func hash(into hasher: inout Hasher) {
        switch value {
        case is NSNull: hasher.combine(0)
        case let bool as Bool: hasher.combine(bool)
        case let int as Int: hasher.combine(int)
        case let double as Double: hasher.combine(double)
        case let string as String: hasher.combine(string)
        default: hasher.combine(String(describing: value))
        }
    }
}

// MARK: - User Action + UI Helpers

extension UserAction {
    public var displayIcon: String {
        iconKey ?? category.icon
    }

    public var displayColor: String {
        color ?? "#6B9E7A"
    }

    public var fieldCountLabel: String {
        guard let fields = parameters?.fields, !fields.isEmpty else { return "No parameters" }
        return fields.count == 1 ? "1 parameter" : "\(fields.count) parameters"
    }
}


