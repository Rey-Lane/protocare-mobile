//
//  APIClient.swift
//  Protocare
//
//  Created by Alex Gorev on 13.12.2025.
//

import Foundation

// MARK: - API Error

enum APIError: Error, LocalizedError {
    case invalidURL
    case transport(Error)
    case server(status: Int, message: String?)
    case decoding(Error, context: String? = nil)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Некорректный URL сервера."
        case .transport(let err):
            return "Сеть недоступна: \(err.localizedDescription)"
        case .server(status: let status, message: let message):
            return "Сервер вернул статус \(status). \(message ?? "")"
        case .decoding(let error, let context):
            if let context {
                return "Не удалось прочитать ответ сервера: \(error.localizedDescription)\n\(context)"
            }
            return "Не удалось прочитать ответ сервера: \(error.localizedDescription)"
        }
    }
}

// MARK: - Auth API Protocol

protocol AuthAPI {
    func register(email: String, password: String, name: String) async throws -> AccessToken
    func login(email: String, password: String) async throws -> AccessToken
    func refresh(request: RefreshTokenRequest) async throws -> TokenPair
    func logout(refreshToken: String) async throws
    func fetchProtocols(token: String, category: ProtocolCategory?) async throws -> [ProtocolItem]
    func fetchActions(token: String, query: String?) async throws -> [Action]
    func fetchSubstances(token: String, query: String?) async throws -> [Substance]
    func createProtocol(token: String, payload: ProtocolCreateRequest) async throws -> ProtocolItem
    func deleteProtocol(token: String, protocolId: String) async throws
    func createProtocolWithImage(token: String, payload: ProtocolCreateRequest, imageData: Data?) async throws -> ProtocolItem
    func updateProtocol(token: String, protocolId: String, payload: ProtocolUpdate) async throws -> ProtocolItem
    func createCheckin(token: String, payload: ProtocolCheckinCreate) async throws -> CheckIn
    func deleteCheckin(token: String, protocolId: String, checkinId: String) async throws

    // MARK: - Daily Status
    func fetchDailyStatus(token: String, date: Date?) async throws -> DailyStatusResponse
    func fetchProtocolDailyStatus(token: String, protocolId: String, date: Date?) async throws -> ProtocolDailyStatus
    func fetchProtocolWithCheckins(token: String, protocolId: String) async throws -> ProtocolWithCheckins
    func fetchProtocolCheckins(token: String, protocolId: String, dateFrom: Date?, dateTo: Date?) async throws -> [CheckIn]

    // MARK: - Journal
    func fetchJournalEntries(token: String, protocolId: String, dateFrom: String?, dateTo: String?) async throws -> [JournalEntry]
    func fetchJournalEntry(token: String, protocolId: String, date: String) async throws -> JournalEntryDetail
    func saveJournalEntry(token: String, protocolId: String, date: String, metrics: [String: Int], notes: String?) async throws -> JournalEntry
    func uploadJournalPhoto(token: String, protocolId: String, date: String, imageData: Data) async throws -> JournalEntry
    func fetchMetricsTrend(token: String, protocolId: String, days: Int?) async throws -> MetricTrendResponse

    // MARK: - Image Upload
    func uploadProtocolImage(token: String, protocolId: String, imageData: Data) async throws -> ImageAttachmentCreate
    func fetchProtocolImage(token: String, protocolId: String) async throws -> ImageAttachment
    func deleteImage(token: String, imageId: String) async throws

    // MARK: - Protocol Actions
    func addActionToProtocol(token: String, protocolId: String, payload: ProtocolActionCreate) async throws -> ProtocolItem
    func removeActionFromProtocol(token: String, protocolId: String, protocolActionId: String) async throws
    func reorderProtocolActions(token: String, protocolId: String, actionIds: [String]) async throws

    // MARK: - User Actions
    func fetchUserActions(token: String, category: ActionCategory?, isActive: Bool?, page: Int?, pageSize: Int?) async throws -> PaginatedUserActions
    func createUserAction(token: String, payload: UserActionCreate) async throws -> UserAction
    func fetchUserAction(token: String, actionId: UUID) async throws -> UserAction
    func updateUserAction(token: String, actionId: UUID, payload: UserActionUpdate) async throws -> UserAction
    func deleteUserAction(token: String, actionId: UUID) async throws
    func fetchUserActionTemplates(token: String) async throws -> [UserAction]
    func duplicateUserAction(token: String, actionId: UUID) async throws -> UserAction
    func fetchUserActionUsage(token: String, actionId: UUID) async throws -> UserActionUsage

    // MARK: - Notification Schedules
    func fetchNotificationSchedules(token: String, protocolActionId: String?) async throws -> [NotificationScheduleResponse]
    func fetchProtocolNotificationSchedules(token: String, protocolId: String) async throws -> [String: NotificationScheduleResponse]
    func fetchNotificationSchedule(token: String, scheduleId: String) async throws -> NotificationScheduleResponse
    func createNotificationSchedule(token: String, payload: NotificationScheduleCreate) async throws -> NotificationScheduleResponse
    func updateNotificationSchedule(token: String, scheduleId: String, payload: NotificationScheduleUpdate) async throws -> NotificationScheduleResponse
    func upsertNotificationSchedule(token: String, actionId: String, payload: NotificationScheduleCreate) async throws -> NotificationScheduleResponse
    func deleteNotificationSchedule(token: String, scheduleId: String) async throws



    // MARK: - User Profile
    func fetchCurrentUser(token: String) async throws -> UserMeResponse
    func updateProfile(token: String, payload: ProfileUpdateRequest) async throws -> UserMeResponse
    func uploadProfileImage(token: String, imageData: Data) async throws -> UserMeResponse
    func deleteAccount(token: String) async throws
}

// MARK: - API Client Implementation

final class APIClient: AuthAPI, @unchecked Sendable {
    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    // Thread-safe mutable state via NSLock
    private let stateLock = NSLock()
    private var _tokenRefreshManager: TokenRefreshManager?
    private var _authStore: AuthStore?

    private var tokenRefreshManager: TokenRefreshManager? {
        get {
            stateLock.lock()
            defer { stateLock.unlock() }
            return _tokenRefreshManager
        }
        set {
            stateLock.lock()
            defer { stateLock.unlock() }
            _tokenRefreshManager = newValue
        }
    }

    var authStore: AuthStore? {
        get {
            stateLock.lock()
            defer { stateLock.unlock() }
            return _authStore
        }
        set {
            stateLock.lock()
            defer { stateLock.unlock() }
            _authStore = newValue
            if let newValue {
                _tokenRefreshManager = TokenRefreshManager(api: self, authStore: newValue)
            }
        }
    }

    func configure(authStore: AuthStore) {
        self.authStore = authStore
    }

    // MARK: - Retry Configuration

    private static let maxRetryCount = 3
    private static let baseRetryDelay: TimeInterval = 1.0 // seconds; doubles each retry

    init(baseURL: URL, session: URLSession? = nil) {
        self.baseURL = baseURL

        // Configure URLSession with timeouts if no custom session provided
        if let session {
            self.session = session
        } else {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 15  // 15s request timeout
            config.timeoutIntervalForResource = 30  // 30s resource timeout
            self.session = URLSession(configuration: config)
        }

        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: dateString) { return date }
            let fallback = ISO8601DateFormatter()
            fallback.formatOptions = [.withInternetDateTime]
            if let date = fallback.date(from: dateString) { return date }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date: \(dateString)")
        }

        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
    }

    func resolveURL(path: String) -> URL? {
        var pathPart = path
        var queryPart: String?

        if let queryStart = path.firstIndex(of: "?") {
            pathPart = String(path[..<queryStart])
            queryPart = String(path[path.index(after: queryStart)...])
        }

        let trimmed = pathPart.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let base = URL(string: baseURL.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))) else {
            return nil
        }
        var resolved = base.appendingPathComponent(trimmed)

        if let query = queryPart {
            resolved = URL(string: "\(resolved.absoluteString)?\(query)")!
        }

        return resolved
    }

    // MARK: - Authentication

    func register(email: String, password: String, name: String) async throws -> AccessToken {
        let payload = UserCreate(email: email, password: password, name: name)
        return try await post(path: "/auth/register", body: payload)
    }

    func login(email: String, password: String) async throws -> AccessToken {
        let payload = UserLogin(email: email, password: password)
        return try await post(path: "/auth/login", body: payload)
    }

    func refresh(request: RefreshTokenRequest) async throws -> TokenPair {
        try await post(path: "/auth/refresh", body: request)
    }

    func logout(refreshToken: String) async throws {
        let request = RefreshTokenRequest(refreshToken: refreshToken)
        let urlRequest = try makeRequest(path: "/auth/logout", method: "POST", body: request)
        _ = try await performData(request: urlRequest)
    }

    // MARK: - Data Fetching

    func fetchProtocols(token: String, category: ProtocolCategory? = nil) async throws -> [ProtocolItem] {
        var path = "/protocols"
        if let category {
            path += "?category=\(category.rawValue)"
        }
        return try await get(path: path, token: token)
    }

    func fetchActions(token: String, query: String? = nil) async throws -> [Action] {
        var path = "/actions"
        if let query, !query.isEmpty {
            path += "?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query)"
        }
        return try await get(path: path, token: token)
    }

    func fetchSubstances(token: String, query: String? = nil) async throws -> [Substance] {
        var path = "/substances"
        if let query, !query.isEmpty {
            path += "?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query)"
        }
        return try await get(path: path, token: token)
    }

    // MARK: - Data Creation

    func createProtocol(token: String, payload: ProtocolCreateRequest) async throws -> ProtocolItem {
        try await post(path: "/protocols", body: payload, token: token)
    }

    func deleteProtocol(token: String, protocolId: String) async throws {
        try await delete(path: "/protocols/\(protocolId)", token: token)
    }

    func createProtocolWithImage(token: String, payload: ProtocolCreateRequest, imageData: Data?) async throws -> ProtocolItem {
        guard let url = resolveURL(path: "/protocols") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        let jsonData = try encoder.encode(payload)
        let jsonString = String(data: jsonData, encoding: .utf8) ?? ""

        // Safe Data initialization — avoid force-unwrap on .data(using:)
        guard let boundaryData = "--\(boundary)\r\n".data(using: .utf8),
              let dispositionData = "Content-Disposition: form-data; name=\"protocol_data\"\r\n".data(using: .utf8),
              let contentTypeData = "Content-Type: application/json\r\n\r\n".data(using: .utf8),
              let jsonPayloadData = jsonString.data(using: .utf8),
              let crlfData = "\r\n".data(using: .utf8) else {
            throw APIError.server(status: -1, message: "Failed to encode multipart body.")
        }

        body.append(boundaryData)
        body.append(dispositionData)
        body.append(contentTypeData)
        body.append(jsonPayloadData)
        body.append(crlfData)

        if let imageData = imageData {
            guard let imgBoundaryData = "--\(boundary)\r\n".data(using: .utf8),
                  let imgDispositionData = "Content-Disposition: form-data; name=\"file\"; filename=\"image.jpg\"\r\n".data(using: .utf8),
                  let imgContentTypeData = "Content-Type: image/jpeg\r\n\r\n".data(using: .utf8),
                  let imgCrlfData = "\r\n".data(using: .utf8) else {
                throw APIError.server(status: -1, message: "Failed to encode image multipart body.")
            }
            body.append(imgBoundaryData)
            body.append(imgDispositionData)
            body.append(imgContentTypeData)
            body.append(imageData)
            body.append(imgCrlfData)
        }

        guard let closingBoundary = "--\(boundary)--\r\n".data(using: .utf8) else {
            throw APIError.server(status: -1, message: "Failed to encode closing multipart boundary.")
        }
        body.append(closingBoundary)

        request.httpBody = body

        return try await perform(request: request)
    }

    func updateProtocol(token: String, protocolId: String, payload: ProtocolUpdate) async throws -> ProtocolItem {
        let request = try makeRequest(path: "/protocols/\(protocolId)", method: "PATCH", body: payload, token: token)
        return try await perform(request: request)
    }

    func addActionToProtocol(token: String, protocolId: String, payload: ProtocolActionCreate) async throws -> ProtocolItem {
        try await post(path: "/protocols/\(protocolId)/actions", body: payload, token: token)
    }

    func removeActionFromProtocol(token: String, protocolId: String, protocolActionId: String) async throws {
        let request = try makeRequest(path: "/protocols/\(protocolId)/actions/\(protocolActionId)", method: "DELETE", token: token)
        _ = try await performData(request: request)
    }

    func reorderProtocolActions(token: String, protocolId: String, actionIds: [String]) async throws {
        let body = ["action_ids": actionIds]
        let request = try makeRequest(path: "/protocols/\(protocolId)/actions/reorder", method: "PUT", body: body, token: token)
        _ = try await performData(request: request)
    }

    // MARK: - User Actions

    func fetchUserActions(token: String, category: ActionCategory? = nil, isActive: Bool? = nil, page: Int? = nil, pageSize: Int? = nil) async throws -> PaginatedUserActions {
        var path = "/user-actions"
        var queryItems: [String] = []
        if let category { queryItems.append("category=\(category.rawValue)") }
        if let isActive { queryItems.append("is_active=\(isActive)") }
        if let page { queryItems.append("page=\(page)") }
        if let pageSize { queryItems.append("page_size=\(pageSize)") }
        if !queryItems.isEmpty { path += "?" + queryItems.joined(separator: "&") }
        return try await get(path: path, token: token)
    }

    func createUserAction(token: String, payload: UserActionCreate) async throws -> UserAction {
        try await post(path: "/user-actions", body: payload, token: token)
    }

    func fetchUserAction(token: String, actionId: UUID) async throws -> UserAction {
        try await get(path: "/user-actions/\(actionId.uuidString)", token: token)
    }

    func updateUserAction(token: String, actionId: UUID, payload: UserActionUpdate) async throws -> UserAction {
        guard let url = resolveURL(path: "/user-actions/\(actionId.uuidString)") else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(payload)
        return try await perform(request: request)
    }

    func deleteUserAction(token: String, actionId: UUID) async throws {
        try await delete(path: "/user-actions/\(actionId.uuidString)", token: token)
    }

    func fetchUserActionTemplates(token: String) async throws -> [UserAction] {
        let page: PaginatedUserActions = try await get(path: "/user-actions/templates", token: token)
        return page.items
    }

    func duplicateUserAction(token: String, actionId: UUID) async throws -> UserAction {
        try await post(path: "/user-actions/\(actionId.uuidString)/duplicate", body: EmptyBody(), token: token)
    }

    func fetchUserActionUsage(token: String, actionId: UUID) async throws -> UserActionUsage {
        try await get(path: "/user-actions/\(actionId.uuidString)/usage", token: token)
    }

    // MARK: - Daily Status

    func fetchDailyStatus(token: String, date: Date? = nil) async throws -> DailyStatusResponse {
        var path = "/daily-status"
        if let date = date {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withFullDate]
            path += "?date=\(formatter.string(from: date))"
        }
        return try await get(path: path, token: token)
    }

    func fetchProtocolDailyStatus(token: String, protocolId: String, date: Date? = nil) async throws -> ProtocolDailyStatus {
        var path = "/protocols/\(protocolId)/daily-status"
        if let date = date {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withFullDate]
            path += "?date=\(formatter.string(from: date))"
        }
        return try await get(path: path, token: token)
    }

    func fetchProtocolWithCheckins(token: String, protocolId: String) async throws -> ProtocolWithCheckins {
        try await get(path: "/protocols/\(protocolId)/with-checkins", token: token)
    }

    func fetchProtocolCheckins(token: String, protocolId: String, dateFrom: Date? = nil, dateTo: Date? = nil) async throws -> [CheckIn] {
        var path = "/protocols/\(protocolId)/checkins"

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]

        var queryItems: [String] = []
        if let dateFrom = dateFrom {
            queryItems.append("date_from=\(formatter.string(from: dateFrom))")
        }
        if let dateTo = dateTo {
            queryItems.append("date_to=\(formatter.string(from: dateTo))")
        }
        if !queryItems.isEmpty {
            path += "?" + queryItems.joined(separator: "&")
        }

        let request = try makeRequest(path: path, method: "GET", token: token)
        return try await perform(request: request)
    }



    func createCheckin(token: String, payload: ProtocolCheckinCreate) async throws -> CheckIn {

        guard let url = resolveURL(path: "/protocols/\(payload.protocolId)/checkins") else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let jsonData = try encoder.encode(payload)
        var body = Data()

        guard let boundaryData = "--\(boundary)\r\n".data(using: .utf8),
              let dispositionData = "Content-Disposition: form-data; name=\"checkin_data\"\r\n\r\n".data(using: .utf8),
              let crlfData = "\r\n".data(using: .utf8),
              let closingData = "--\(boundary)--\r\n".data(using: .utf8) else {
            throw APIError.server(status: -1, message: "Failed to encode multipart body.")
        }

        body.append(boundaryData)
        body.append(dispositionData)
        body.append(jsonData)
        body.append(crlfData)
        body.append(closingData)
        request.httpBody = body

        return try await perform(request: request)
    }

    func deleteCheckin(token: String, protocolId: String, checkinId: String) async throws {
        try await delete(path: "/protocols/\(protocolId)/checkins/\(checkinId)", token: token)
    }

    // MARK: - Journal

    func fetchJournalEntries(token: String, protocolId: String, dateFrom: String? = nil, dateTo: String? = nil) async throws -> [JournalEntry] {
        var path = "/protocols/\(protocolId)/journal"
        var params: [String] = []
        if let dateFrom { params.append("date_from=\(dateFrom)") }
        if let dateTo { params.append("date_to=\(dateTo)") }
        if !params.isEmpty { path += "?" + params.joined(separator: "&") }
        return try await get(path: path, token: token)
    }

    func fetchJournalEntry(token: String, protocolId: String, date: String) async throws -> JournalEntryDetail {
        let path = "/protocols/\(protocolId)/journal/\(date)"
        return try await get(path: path, token: token)
    }

    func saveJournalEntry(token: String, protocolId: String, date: String, metrics: [String: Int], notes: String? = nil) async throws -> JournalEntry {
        let path = "/protocols/\(protocolId)/journal/\(date)"
        let body = JournalEntryBody(metrics: metrics, notes: notes)
        return try await post(path: path, body: body, token: token)
    }

    private struct JournalEntryBody: Encodable {
        let metrics: [String: Int]
        let notes: String?
    }

    func uploadJournalPhoto(token: String, protocolId: String, date: String, imageData: Data) async throws -> JournalEntry {
        try await uploadImage(
            path: "/protocols/\(protocolId)/journal/\(date)/photo",
            imageData: imageData,
            token: token
        )
    }

    func fetchMetricsTrend(token: String, protocolId: String, days: Int? = nil) async throws -> MetricTrendResponse {
        var path = "/protocols/\(protocolId)/metrics-trend"
        if let days { path += "?days=\(days)" }
        return try await get(path: path, token: token)
    }

    // MARK: - Image Upload

    func uploadProtocolImage(token: String, protocolId: String, imageData: Data) async throws -> ImageAttachmentCreate {
        try await uploadImage(
            path: "/images/protocols/\(protocolId)",
            imageData: imageData,
            token: token
        )
    }

    func fetchProtocolImage(token: String, protocolId: String) async throws -> ImageAttachment {
        try await get(path: "/images/protocols/\(protocolId)", token: token)
    }

    func deleteImage(token: String, imageId: String) async throws {
        try await delete(path: "/images/\(imageId)", token: token)
    }

    // MARK: - Notification Schedules

    func fetchNotificationSchedules(token: String, protocolActionId: String? = nil) async throws -> [NotificationScheduleResponse] {
        var path = "/notifications/schedule"
        if let protocolActionId = protocolActionId {
            path += "?protocol_action_id=\(protocolActionId)"
        }
        return try await get(path: path, token: token)
    }

    func fetchProtocolNotificationSchedules(token: String, protocolId: String) async throws -> [String: NotificationScheduleResponse] {
        let request = try makeRequest(path: "/protocols/\(protocolId)/notification-schedules", method: "GET", token: token)
        let data = try await performData(request: request)
        let decoded = try decoder.decode(BatchSchedulesResponse.self, from: data)
        return decoded.schedules
    }

    func fetchNotificationSchedule(token: String, scheduleId: String) async throws -> NotificationScheduleResponse {
        try await get(path: "/notifications/schedule/\(scheduleId)", token: token)
    }

    func createNotificationSchedule(token: String, payload: NotificationScheduleCreate) async throws -> NotificationScheduleResponse {
        try await post(path: "/notifications/schedule", body: payload, token: token)
    }

    func updateNotificationSchedule(token: String, scheduleId: String, payload: NotificationScheduleUpdate) async throws -> NotificationScheduleResponse {
        guard let url = resolveURL(path: "/notifications/schedule/\(scheduleId)") else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(payload)
        return try await perform(request: request)
    }

    func upsertNotificationSchedule(token: String, actionId: String, payload: NotificationScheduleCreate) async throws -> NotificationScheduleResponse {
        guard let url = resolveURL(path: "/notifications/schedule/action/\(actionId)") else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(payload)
        return try await perform(request: request)
    }

    func deleteNotificationSchedule(token: String, scheduleId: String) async throws {
        try await delete(path: "/notifications/schedule/\(scheduleId)", token: token)
    }



    // MARK: - User Profile

    func fetchCurrentUser(token: String) async throws -> UserMeResponse {
        try await get(path: "/profile", token: token)
    }

    func updateProfile(token: String, payload: ProfileUpdateRequest) async throws -> UserMeResponse {
        guard let url = resolveURL(path: "/profile") else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(payload)
        return try await perform(request: request)
    }

    func uploadProfileImage(token: String, imageData: Data) async throws -> UserMeResponse {
        try await uploadImage(
            path: "/profile/avatar",
            imageData: imageData,
            token: token
        )
    }

    func deleteAccount(token: String) async throws {
        try await delete(path: "/profile", token: token)
    }

    // MARK: - Generic Image Upload

    private func uploadImage<T: Decodable>(path: String, imageData: Data, token: String) async throws -> T {
        guard let url = resolveURL(path: path) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        guard let boundaryData = "--\(boundary)\r\n".data(using: .utf8),
              let dispositionData = "Content-Disposition: form-data; name=\"file\"; filename=\"image.jpg\"\r\n".data(using: .utf8),
              let contentTypeData = "Content-Type: image/jpeg\r\n\r\n".data(using: .utf8),
              let crlfData = "\r\n".data(using: .utf8),
              let closingData = "--\(boundary)--\r\n".data(using: .utf8) else {
            throw APIError.server(status: -1, message: "Failed to encode multipart body.")
        }

        body.append(boundaryData)
        body.append(dispositionData)
        body.append(contentTypeData)
        body.append(imageData)
        body.append(crlfData)
        body.append(closingData)

        request.httpBody = body

        return try await perform(request: request)
    }

    // MARK: - Generic Request Methods

    private func get<T: Decodable>(path: String, token: String) async throws -> T {
        let request = try makeRequest(path: path, method: "GET", token: token)
        return try await perform(request: request)
    }

    private func post<T: Decodable>(path: String, body: Encodable, token: String? = nil) async throws -> T {
        let request = try makeRequest(path: path, method: "POST", body: body, token: token)
        return try await perform(request: request)
    }

    private func post(path: String, body: Encodable, token: String? = nil) async throws {
        let request = try makeRequest(path: path, method: "POST", body: body, token: token)
        _ = try await performData(request: request)
    }

    private func delete(path: String, token: String) async throws {
        let request = try makeRequest(path: path, method: "DELETE", token: token)
        _ = try await performData(request: request)
    }

    // MARK: - Request Building

    private func makeRequest(
        path: String,
        method: String,
        body: Encodable? = nil,
        token: String? = nil
    ) throws -> URLRequest {
        guard let url = resolveURL(path: path) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method

        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try encoder.encode(body)
        }

        return request
    }

    // MARK: - Request Execution

    private func perform<T: Decodable>(request: URLRequest) async throws -> T {
        let data = try await performData(request: request)

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            let body = String(data: data, encoding: .utf8)
            throw APIError.decoding(error, context: body)
        }
    }

    // MARK: - Retry Logic

    /// Determines whether an error is transient and worth retrying.
    private func isTransientError(_ error: Error) -> Bool {
        // 5xx server errors
        if let apiError = error as? APIError,
           case .server(let status, _) = apiError,
           (500...599).contains(status) {
            return true
        }

        // Network / timeout errors
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            switch nsError.code {
            case NSURLErrorTimedOut,
                 NSURLErrorCannotConnectToHost,
                 NSURLErrorNetworkConnectionLost,
                 NSURLErrorNotConnectedToInternet,
                 NSURLErrorDNSLookupFailed,
                 NSURLErrorResourceUnavailable:
                return true
            default:
                break
            }
        }

        // Transport-wrapped network errors
        if let apiError = error as? APIError,
           case .transport(let underlying) = apiError {
            return isTransientError(underlying)
        }

        return false
    }

    private func performData(request: URLRequest, retryCount: Int = 0) async throws -> Data {
        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.server(status: -1, message: "Invalid server response.")
            }

            let isAuthRequest = request.url?.path.hasSuffix("/auth/refresh") == true
                || request.url?.path.hasSuffix("/auth/login") == true
                || request.url?.path.hasSuffix("/auth/register") == true
                || request.url?.path.hasSuffix("/auth/logout") == true

            if httpResponse.statusCode == 401, retryCount == 0, !isAuthRequest, let manager = tokenRefreshManager {
                let refreshed = await manager.refreshTokens()
                if refreshed, let newToken = await authStore?.accessToken {
                    var newRequest = request
                    newRequest.setValue("Bearer \(newToken)", forHTTPHeaderField: "Authorization")
                    return try await performData(request: newRequest, retryCount: 1)
                } else {
                    await authStore?.logout()
                }
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                let message = String(data: data, encoding: .utf8)
                throw APIError.server(status: httpResponse.statusCode, message: message)
            }

            return data
        } catch let error as APIError {
            // Retry transient 5xx errors with exponential backoff
            if isTransientError(error) && retryCount < Self.maxRetryCount {
                let delay = Self.baseRetryDelay * pow(2.0, Double(retryCount))
                try await Task.sleep(for: .seconds(delay))
                return try await performData(request: request, retryCount: retryCount + 1)
            }
            throw error
        } catch {
            // Retry transport errors with exponential backoff
            if isTransientError(error) && retryCount < Self.maxRetryCount {
                let delay = Self.baseRetryDelay * pow(2.0, Double(retryCount))
                try await Task.sleep(for: .seconds(delay))
                return try await performData(request: request, retryCount: retryCount + 1)
            }
            throw APIError.transport(error)
        }
    }
}

private struct EmptyBody: Encodable {}

private struct BatchSchedulesResponse: Codable {
    let schedules: [String: NotificationScheduleResponse]
}
