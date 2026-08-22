import Foundation

public enum ScheduleFrequency: String, CaseIterable, Identifiable, Sendable {
    case daily
    case weekly
    case monthly

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        }
    }
}

public enum ScheduleDay: String, CaseIterable, Identifiable, Sendable {
    case sunday = "SU"
    case monday = "MO"
    case tuesday = "TU"
    case wednesday = "WE"
    case thursday = "TH"
    case friday = "FR"
    case saturday = "SA"

    public var id: String { rawValue }

    public var shortName: String {
        switch self {
        case .sunday: return "Su"
        case .monday: return "M"
        case .tuesday: return "Tu"
        case .wednesday: return "W"
        case .thursday: return "Th"
        case .friday: return "F"
        case .saturday: return "Sa"
        }
    }

    public var fullName: String {
        switch self {
        case .sunday: return "Sun"
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        }
    }

    public var calendarIndex: Int {
        switch self {
        case .sunday: return 0
        case .monday: return 1
        case .tuesday: return 2
        case .wednesday: return 3
        case .thursday: return 4
        case .friday: return 5
        case .saturday: return 6
        }
    }
}

public struct ScheduleSlot: Hashable, Sendable, Identifiable, Equatable, Codable {
    public var id: UUID
    public var hour: Int
    public var minute: Int
    public var isReminderOn: Bool
    public var reminderOffsetMinutes: Int  // 0 = at time, 5, 15, 30

    public init(
        id: UUID = UUID(),
        hour: Int = 8,
        minute: Int = 0,
        isReminderOn: Bool = true,
        reminderOffsetMinutes: Int = 0
    ) {
        self.id = id
        self.hour = hour
        self.minute = minute
        self.isReminderOn = isReminderOn
        self.reminderOffsetMinutes = reminderOffsetMinutes
    }

    public var timeLabel: String {
        String(format: "%02d:%02d", hour, minute)
    }

    public var offsetLabel: String {
        switch reminderOffsetMinutes {
        case 0: return "At time"
        case 5: return "5 min before"
        case 15: return "15 min before"
        case 30: return "30 min before"
        default: return "\(reminderOffsetMinutes) min before"
        }
    }

    public static let allowedOffsets: [Int] = [0, 5, 15, 30]
}

public struct ActionSchedule: Hashable, Sendable, Equatable {
    public var frequency: ScheduleFrequency
    public var days: [ScheduleDay]
    public var hour: Int
    public var minute: Int

    public init(
        frequency: ScheduleFrequency = .daily,
        days: [ScheduleDay] = ScheduleDay.allCases,
        hour: Int = 8,
        minute: Int = 0
    ) {
        self.frequency = frequency
        self.days = days
        self.hour = hour
        self.minute = minute
    }

    public var summaryLabel: String {
        switch frequency {
        case .daily:
            return "Daily"
        case .weekly:
            if days.isEmpty { return "Weekly" }
            if Set(days) == Set(ScheduleDay.allCases) { return "Daily" }
            let names = days.sorted { $0.calendarIndex < $1.calendarIndex }.map(\.fullName)
            return names.joined(separator: ", ")
        case .monthly:
            return "Monthly"
        }
    }

    public var timeLabel: String {
        String(format: "%02d:%02d", hour, minute)
    }

    public func toRRule() -> String {
        var parts: [String] = ["FREQ=\(frequency.rawValue.uppercased())"]
        if frequency == .weekly && !days.isEmpty {
            let dayStr = days.map(\.rawValue).joined(separator: ",")
            parts.append("BYDAY=\(dayStr)")
        }
        parts.append("BYHOUR=\(hour)")
        parts.append("BYMINUTE=\(minute)")
        return "RRULE:" + parts.joined(separator: ";")
    }

    public static func fromRRule(_ rrule: String) -> ActionSchedule? {
        var content = rrule
        if content.uppercased().hasPrefix("RRULE:") {
            content = String(content.dropFirst(6))
        }
        let upper = content.uppercased()
        var frequency: ScheduleFrequency?
        var days: [ScheduleDay] = []
        var hour: Int?
        var minute: Int?

        for component in upper.split(separator: ";") {
            let keyValue = component.split(separator: "=", maxSplits: 1)
            guard keyValue.count == 2 else { continue }
            let key = String(keyValue[0])
            let value = String(keyValue[1])

            switch key {
            case "FREQ":
                switch value {
                case "DAILY": frequency = .daily
                case "WEEKLY": frequency = .weekly
                case "MONTHLY": frequency = .monthly
                default: break
                }
            case "BYDAY":
                for dayStr in value.split(separator: ",") {
                    if let day = ScheduleDay(rawValue: String(dayStr)) {
                        days.append(day)
                    }
                }
            case "BYHOUR":
                hour = Int(value)
            case "BYMINUTE":
                minute = Int(value)
            default: break
            }
        }

        guard let frequency else { return nil }
        return ActionSchedule(
            frequency: frequency,
            days: days.isEmpty ? ScheduleDay.allCases : days,
            hour: hour ?? 8,
            minute: minute ?? 0
        )
    }
}
