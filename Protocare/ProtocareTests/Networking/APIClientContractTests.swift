import XCTest
@testable import Protocare

final class APIClientContractTests: XCTestCase {

    var client: APIClient!

    override func setUp() {
        super.setUp()
        MockURLProtocol.handler = nil
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)
        client = APIClient(baseURL: URL(string: "https://api.example.com/v1")!, session: session)
    }

    override func tearDown() {
        MockURLProtocol.handler = nil
        client = nil
        super.tearDown()
    }

    // MARK: - Notification Schedules

    func test_fetchNotificationSchedules_sendsGETToScheduleEndpoint() async throws {
        MockURLProtocol.handler = { request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.url?.path, "/v1/notifications/schedule")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-token")
            return (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, Data("[]".utf8))
        }

        _ = try await client.fetchNotificationSchedules(token: "test-token", protocolActionId: nil)
    }

    func test_fetchNotificationSchedule_sendsGETToScheduleByIdEndpoint() async throws {
        MockURLProtocol.handler = { request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.url?.path, "/v1/notifications/schedule/sched-123")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-token")
            return (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!,
                    Data("""
                    {"id":"sched-123","protocol_action_id":"a-1","user_id":"u-1","preferred_time":"08:00","timezone":"Europe/Amsterdam","is_enabled":true,"created_at":"2024-01-01T12:00:00Z"}
                    """.utf8))
        }

        _ = try await client.fetchNotificationSchedule(token: "test-token", scheduleId: "sched-123")
    }

    func test_createNotificationSchedule_sendsPOSTToScheduleEndpoint() async throws {
        MockURLProtocol.handler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.url?.path, "/v1/notifications/schedule")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-token")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
            return (HTTPURLResponse(url: request.url!, statusCode: 201, httpVersion: nil, headerFields: nil)!,
                    Data("""
                    {"id":"sched-new","protocol_action_id":"a-1","user_id":"u-1","preferred_time":"08:00","timezone":"Europe/Amsterdam","is_enabled":true,"created_at":"2024-01-01T12:00:00Z"}
                    """.utf8))
        }

        let payload = NotificationScheduleCreate(
            protocolActionId: "a-1",
            preferredTime: "08:00",
            timezone: "Europe/Amsterdam"
        )
        _ = try await client.createNotificationSchedule(token: "test-token", payload: payload)
    }

    func test_updateNotificationSchedule_sendsPATCHToScheduleByIdEndpoint() async throws {
        MockURLProtocol.handler = { request in
            XCTAssertEqual(request.httpMethod, "PATCH")
            XCTAssertEqual(request.url?.path, "/v1/notifications/schedule/sched-123")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-token")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
            return (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!,
                    Data("""
                    {"id":"sched-123","protocol_action_id":"a-1","user_id":"u-1","preferred_time":"09:00","timezone":"Europe/Amsterdam","is_enabled":false,"created_at":"2024-01-01T12:00:00Z"}
                    """.utf8))
        }

        let payload = NotificationScheduleUpdate(isEnabled: false)
        _ = try await client.updateNotificationSchedule(token: "test-token", scheduleId: "sched-123", payload: payload)
    }

    func test_deleteNotificationSchedule_sendsDELETETOScheduleByIdEndpoint() async throws {
        MockURLProtocol.handler = { request in
            XCTAssertEqual(request.httpMethod, "DELETE")
            XCTAssertEqual(request.url?.path, "/v1/notifications/schedule/sched-123")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-token")
            return (HTTPURLResponse(url: request.url!, statusCode: 204, httpVersion: nil, headerFields: nil)!, Data())
        }

        try await client.deleteNotificationSchedule(token: "test-token", scheduleId: "sched-123")
    }

    func test_upsertNotificationSchedule_sendsPUTToScheduleActionEndpoint() async throws {
        MockURLProtocol.handler = { request in
            XCTAssertEqual(request.httpMethod, "PUT")
            XCTAssertEqual(request.url?.path, "/v1/notifications/schedule/action/action-123")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-token")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
            return (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!,
                    Data("""
                    {"id":"sched-upserted","protocol_action_id":"action-123","user_id":"u-1","preferred_time":"08:00","timezone":"Europe/Amsterdam","is_enabled":true,"created_at":"2024-01-01T12:00:00Z"}
                    """.utf8))
        }

        let payload = NotificationScheduleCreate(
            protocolActionId: "action-123",
            preferredTime: "08:00",
            timezone: "Europe/Amsterdam"
        )
        _ = try await client.upsertNotificationSchedule(token: "test-token", actionId: "action-123", payload: payload)
    }

    // MARK: - Unified Actions

    func test_fetchActions_sendsGETToActionsEndpoint() async throws {
        MockURLProtocol.handler = { request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.url?.path, "/v1/actions")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-token")
            return (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, Data("[]".utf8))
        }

        _ = try await client.fetchActions(token: "test-token", category: nil, modality: nil, query: nil)
    }

    func test_fetchActions_withFilters_sendsGETWithQueryParams() async throws {
        MockURLProtocol.handler = { request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.url?.path, "/v1/actions")
            XCTAssertTrue(request.url?.query?.contains("category=skincare") ?? false)
            XCTAssertTrue(request.url?.query?.contains("modality=topical") ?? false)
            XCTAssertTrue(request.url?.query?.contains("q=retinol") ?? false)
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-token")
            return (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, Data("[]".utf8))
        }

        _ = try await client.fetchActions(token: "test-token", category: .skincare, modality: .topical, query: "retinol")
    }

    // MARK: - Existing Endpoint Contracts

    func test_fetchProtocols_sendsGETToProtocolsEndpoint() async throws {
        MockURLProtocol.handler = { request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.url?.path, "/v1/protocols")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-token")
            return (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, Data("[]".utf8))
        }

        _ = try await client.fetchProtocols(token: "test-token")
    }
}

final class MockURLProtocol: URLProtocol {
    nonisolated(unsafe) static var handler: ((URLRequest) -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.handler else {
            fatalError("MockURLProtocol.handler not set")
        }
        let (response, data) = handler(request)
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
