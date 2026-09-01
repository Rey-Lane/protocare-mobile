import Foundation

public enum MetricKey: String, Codable, CaseIterable, Identifiable, Sendable {
    case skinQuality = "skin_quality"
    case redness = "redness"
    case energy = "energy"
    case focus = "focus"
    case flexibility = "flexibility"
    case stress = "stress"
    case muscleSoreness = "muscle_soreness"
    case digestion = "digestion"
    case sleepQuality = "sleep_quality"
    case painLevel = "pain_level"
    case symptomSeverity = "symptom_severity"

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .skinQuality: return "Skin Quality"
        case .redness: return "Redness"
        case .energy: return "Energy"
        case .focus: return "Focus"
        case .flexibility: return "Flexibility"
        case .stress: return "Stress"
        case .muscleSoreness: return "Muscle Soreness"
        case .digestion: return "Digestion"
        case .sleepQuality: return "Sleep Quality"
        case .painLevel: return "Pain Level"
        case .symptomSeverity: return "Symptom Severity"
        }
    }

    public var icon: String {
        switch self {
        case .skinQuality: return "hand.raised.fill"
        case .redness: return "flame.fill"
        case .energy: return "bolt.fill"
        case .focus: return "brain.head.profile.fill"
        case .flexibility: return "figure.yoga"
        case .stress: return "waveform.path.ecg"
        case .muscleSoreness: return "figure.run"
        case .digestion: return "fork.knife"
        case .sleepQuality: return "moon.fill"
        case .painLevel: return "bandage.fill"
        case .symptomSeverity: return "exclamationmark.triangle.fill"
        }
    }

    public var description: String {
        switch self {
        case .skinQuality: return "Overall skin texture and appearance"
        case .redness: return "Level of skin redness or inflammation"
        case .energy: return "Daily energy and vitality level"
        case .focus: return "Mental clarity and concentration"
        case .flexibility: return "Physical flexibility and mobility"
        case .stress: return "Perceived stress level"
        case .muscleSoreness: return "Muscle soreness or tension"
        case .digestion: return "Digestive comfort and regularity"
        case .sleepQuality: return "Quality and restfulness of sleep"
        case .painLevel: return "General pain or discomfort level"
        case .symptomSeverity: return "Severity of tracked symptoms"
        }
    }

    /// Default metrics per protocol category — mirrors the backend
    /// `CATEGORY_DEFAULT_METRICS` map (journal_service.get_available_metrics).
    /// `ProtocolCategory` is gone (unified action model); protocols now carry
    /// an `ActionCategory`.
    public static func defaults(for category: ActionCategory) -> [MetricKey] {
        switch category {
        case .skincare: return [.skinQuality, .redness]
        case .exercise: return [.energy, .muscleSoreness]
        case .supplement: return [.energy, .focus]
        case .hair: return [.skinQuality, .stress]
        case .nutrition: return [.energy, .digestion]
        case .mindfulness: return [.stress, .sleepQuality]
        case .sleep: return [.stress, .sleepQuality]
        case .medical: return [.painLevel, .symptomSeverity]
        case .measurement: return [.energy]
        case .custom: return [.energy]
        }
    }

    /// LEGACY — dies with the `ProtocolCategory` removal (Step 28).
    /// Kept so ProtocolBuilder/Settings category pickers keep compiling until
    /// `ProtocolDraft.category` / `editCategory` switch to `ActionCategory`.
    public static func defaults(for category: ProtocolCategory) -> [MetricKey] {
        switch category {
        case .skincare: return [.skinQuality, .redness]
        case .fitness: return [.energy, .muscleSoreness, .flexibility]
        case .nutrition: return [.digestion, .energy]
        case .mindfulness: return [.stress, .sleepQuality, .focus]
        case .biohacking: return [.energy, .focus, .sleepQuality]
        case .yoga: return [.flexibility, .stress, .energy]
        case .medical: return [.painLevel, .symptomSeverity]
        case .other: return [.energy, .stress]
        }
    }
}

public struct MetricDefinition: Codable, Hashable, Sendable, Identifiable {
    public var id: String { key.rawValue }
    public var key: MetricKey
    public var label: String
    public var icon: String
    public var description: String

    public init(key: MetricKey) {
        self.key = key
        self.label = key.label
        self.icon = key.icon
        self.description = key.description
    }
}

/// Summary of one protocol action's check-in state for a journal entry
/// (unified action model, Step 25e — mirrors backend `JournalCheckinSummary`).
public struct JournalCheckinSummary: Decodable, Hashable, Sendable, Identifiable {
    public var id: String { protocolActionId }
    public var protocolActionId: String
    public var actionName: String
    public var isCompleted: Bool
    /// Actual values from the day's check-in, if any.
    /// Backend `Decimal` quantity arrives as a JSON string — decoded tolerantly.
    public var quantity: Double?
    public var unit: SubstanceUnit?
    public var durationSeconds: Int?
    public var completed: Bool
    /// `default_parameters` from the unified Action (JSONB).
    public var defaultParameters: [String: AnyCodable]?
    /// Per-protocol override (`user_parameters` on the ProtocolAction).
    public var userParameters: [String: AnyCodable]?

    public var effectiveParameters: [String: AnyCodable] {
        mergeParams(defaultParameters, overriding: userParameters)
    }

    /// Which check-in form this action renders (substance / timed activity / binary).
    public var checkInFormKind: CheckInFormKind {
        CheckInFormResolver.formKind(for: effectiveParameters)
    }

    /// Pre-fill amount + unit for the substance form, from effective parameters.
    public var defaultQuantity: (amount: Double, unit: SubstanceUnit)? {
        CheckInFormResolver.defaultQuantity(in: effectiveParameters)
    }

    /// Pre-fill duration for the timed-activity form.
    public var defaultDurationSeconds: Int? {
        CheckInFormResolver.defaultDurationSeconds(in: effectiveParameters)
    }

    public var hasVolume: Bool { defaultQuantity != nil }
    public var hasDuration: Bool { defaultDurationSeconds != nil }

    public var volumeUpperBound: Double { max((defaultQuantity?.amount ?? 1) * 3, 1) }
    public var durationUpperBound: Double { Double(min((defaultDurationSeconds ?? 60) * 3, 3600)) }

    public var completedSummary: String? {
        guard isCompleted else { return nil }
        var parts: [String] = []
        if let quantity {
            parts.append("\(quantity.roundedString(maxFractionDigits: 1))\(unit.map { " \($0.displayName)" } ?? "")")
        }
        if let durationSeconds {
            if durationSeconds >= 60 {
                let mins = Double(durationSeconds) / 60.0
                parts.append("\(mins.roundedString(maxFractionDigits: 1)) min")
            } else {
                parts.append("\(durationSeconds)s")
            }
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    enum CodingKeys: String, CodingKey {
        case protocolActionId = "protocol_action_id"
        case actionName = "action_name"
        case isCompleted = "is_completed"
        case quantity, unit
        case durationSeconds = "duration_seconds"
        case completed
        case defaultParameters = "default_parameters"
        case userParameters = "user_parameters"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        protocolActionId = try container.decode(String.self, forKey: .protocolActionId)
        actionName = try container.decode(String.self, forKey: .actionName)
        isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        quantity = container.decodeFlexibleDouble(forKey: .quantity)
        unit = try container.decodeIfPresent(SubstanceUnit.self, forKey: .unit)
        durationSeconds = try container.decodeIfPresent(Int.self, forKey: .durationSeconds)
        completed = try container.decodeIfPresent(Bool.self, forKey: .completed) ?? true
        defaultParameters = try container.decodeIfPresent([String: AnyCodable].self, forKey: .defaultParameters)
        userParameters = try container.decodeIfPresent([String: AnyCodable].self, forKey: .userParameters)
    }
}

public struct JournalEntry: Codable, Hashable, Sendable, Identifiable {
    public var id: String
    public var protocolId: String
    public var date: String
    public var dayNumber: Int
    public var metrics: [String: Int]
    public var notes: String?
    public var photoUrl: String?

    public var avgScore: Double? {
        let values = metrics.values
        guard !values.isEmpty else { return nil }
        return Double(values.reduce(0, +)) / Double(values.count)
    }

    public init(
        id: String,
        protocolId: String,
        date: String,
        dayNumber: Int,
        metrics: [String: Int],
        notes: String? = nil,
        photoUrl: String? = nil
    ) {
        self.id = id
        self.protocolId = protocolId
        self.date = date
        self.dayNumber = dayNumber
        self.metrics = metrics
        self.notes = notes
        self.photoUrl = photoUrl
    }

    enum CodingKeys: String, CodingKey {
        case id
        case protocolId = "protocol_id"
        case date
        case dayNumber = "day_number"
        case metrics, notes
        case photoUrl = "photo_url"
    }
}

public struct JournalEntryDetail: Decodable, Hashable, Sendable, Identifiable {
    public var id: String
    public var protocolId: String
    public var date: String
    public var dayNumber: Int
    public var metrics: [String: Int]
    public var availableMetrics: [MetricDefinition]
    public var notes: String?
    public var photoUrl: String?
    public var baselinePhotoUrl: String?
    public var checkins: [JournalCheckinSummary]
    public var createdAt: String?
    public var updatedAt: String?

    public var isNew: Bool {
        guard let created = createdAt,
              let date = ISO8601DateFormatter().date(from: created) else { return true }
        return Date().timeIntervalSince(date) < 300
    }

    public init(
        id: String,
        protocolId: String,
        date: String,
        dayNumber: Int,
        metrics: [String: Int],
        availableMetrics: [MetricDefinition],
        notes: String? = nil,
        photoUrl: String? = nil,
        baselinePhotoUrl: String? = nil,
        checkins: [JournalCheckinSummary],
        createdAt: String? = nil,
        updatedAt: String? = nil
    ) {
        self.id = id
        self.protocolId = protocolId
        self.date = date
        self.dayNumber = dayNumber
        self.metrics = metrics
        self.availableMetrics = availableMetrics
        self.notes = notes
        self.photoUrl = photoUrl
        self.baselinePhotoUrl = baselinePhotoUrl
        self.checkins = checkins
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case protocolId = "protocol_id"
        case date
        case dayNumber = "day_number"
        case metrics
        case availableMetrics = "available_metrics"
        case notes
        case photoUrl = "photo_url"
        case baselinePhotoUrl = "baseline_photo_url"
        case checkins
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
