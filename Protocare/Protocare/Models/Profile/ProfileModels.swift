import Foundation

// MARK: - Profile Update Request

struct ProfileUpdateRequest: Encodable {
    let name: String?
    let timezone: String?

    init(name: String? = nil, timezone: String? = nil) {
        self.name = name
        self.timezone = timezone
    }
}

// MARK: - Streak Info

public struct StreakInfo: Codable, Equatable, Sendable {
    let currentStreak: Int
    let longestStreak: Int

    enum CodingKeys: String, CodingKey {
        case currentStreak = "current_streak"
        case longestStreak = "longest_streak"
    }
}

// MARK: - API Response

struct UserMeResponse: Decodable, Equatable {
    let id: String
    let email: String
    let name: String?
    let avatarURL: String?
    let isActive: Bool
    let role: String
    let timezone: String?
    let protocolsCount: Int
    let streak: StreakInfo
    let totalCheckins: Int

    enum CodingKeys: String, CodingKey {
        case id, email, name, role, timezone, streak
        case avatarURL = "avatar_url"
        case isActive = "is_active"
        case protocolsCount = "protocols_count"
        case totalCheckins = "total_checkins"
    }
}

// MARK: - View Model State

struct UserProfileStats: Equatable {
    let protocolsCount: Int
    let streak: Int
    let checkinsCount: Int
}

struct UserProfile: Equatable {
    let name: String
    let email: String
    let avatarURL: String?
    let initials: String
    let stats: UserProfileStats

    init(name: String, email: String, avatarURL: String? = nil, initials: String, stats: UserProfileStats) {
        self.name = name
        self.email = email
        self.avatarURL = avatarURL
        self.initials = initials
        self.stats = stats
    }

    init(from response: UserMeResponse) {
        self.name = response.name ?? response.email.components(separatedBy: "@").first?.capitalized ?? response.email
        self.email = response.email
        self.avatarURL = response.avatarURL
        self.initials = Self.computeInitials(from: response.name ?? response.email)
        self.stats = UserProfileStats(
            protocolsCount: response.protocolsCount,
            streak: response.streak.currentStreak,
            checkinsCount: response.totalCheckins
        )
    }

    private static func computeInitials(from input: String) -> String {
        let localPart = input.components(separatedBy: "@").first ?? ""
        let parts = localPart.components(separatedBy: CharacterSet(charactersIn: "._- "))
        let initials = parts.compactMap { $0.first }.map { String($0).uppercased() }
        return initials.prefix(2).joined()
    }
}
