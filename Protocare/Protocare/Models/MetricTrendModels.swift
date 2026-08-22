import Foundation

// MARK: - Metric Trend Response

public struct MetricTrendResponse: Codable, Sendable {
    public let protocolId: String
    public let days: Int
    public let series: [MetricTrendSeries]

    enum CodingKeys: String, CodingKey {
        case protocolId = "protocol_id"
        case days, series
    }
}

public struct MetricTrendSeries: Codable, Identifiable, Sendable {
    public var id: String { key }
    public let key: String
    public let label: String
    public let icon: String
    public let points: [MetricTrendPoint]
    public let latestValue: Double?
    public let changeVsPrev: Double?

    enum CodingKeys: String, CodingKey {
        case key, label, icon, points
        case latestValue = "latest_value"
        case changeVsPrev = "change_vs_prev"
    }
}

public struct MetricTrendPoint: Codable, Identifiable, Sendable {
    public var id: String { date }
    public let date: String
    public let value: Double
}
