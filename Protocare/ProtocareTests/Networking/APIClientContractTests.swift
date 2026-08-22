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

    // MARK: - Templates

    func test_fetchTemplates_sendsGETToTemplatesEndpoint() async throws {
        MockURLProtocol.handler = { request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.url?.path, "/v1/templates")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-token")
            return (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, Data("[]".utf8))
        }

        _ = try await client.fetchTemplates(token: "test-token")
    }

    func test_fetchTemplate_sendsGETToTemplateByIdEndpoint() async throws {
        MockURLProtocol.handler = { request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.url?.path, "/v1/templates/tpl-123")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-token")
            return (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!,
                    Data("""
                    {"id":"tpl-123","name":"Test","description":null,"category":"morning_routine","action_drafts":[]}
                    """.utf8))
        }

        _ = try await client.fetchTemplate(token: "test-token", templateId: "tpl-123")
    }

    func test_createProtocolFromTemplate_sendsPOSTToFromTemplateEndpoint() async throws {
        MockURLProtocol.handler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertTrue(request.url?.path.contains("/v1/protocols/from-template/tpl-123") ?? false)
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-token")
            return (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!,
                    Data("""
                    {"id":"proto-1","user_id":"u-1","name":"Test","actions":[],"is_active":true}
                    """.utf8))
        }

        _ = try await client.createProtocolFromTemplate(token: "test-token", templateId: "tpl-123")
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

    // MARK: - User Actions

    func test_fetchUserActions_sendsGETToUserActionsEndpoint() async throws {
        MockURLProtocol.handler = { request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.url?.path, "/v1/user-actions")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-token")
            return (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!,
                    Data("""
                    {"items":[],"total":0,"page":1,"page_size":50}
                    """.utf8))
        }

        _ = try await client.fetchUserActions(token: "test-token", category: nil, isActive: nil, page: nil, pageSize: nil)
    }

    func test_fetchUserActions_withFilters_sendsGETWithQueryParams() async throws {
        MockURLProtocol.handler = { request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.url?.path, "/v1/user-actions")
            XCTAssertTrue(request.url?.query?.contains("category=supplement") ?? false)
            XCTAssertTrue(request.url?.query?.contains("is_active=true") ?? false)
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-token")
            return (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!,
                    Data("""
                    {"items":[],"total":0,"page":1,"page_size":50}
                    """.utf8))
        }

        _ = try await client.fetchUserActions(token: "test-token", category: .supplement, isActive: true, page: nil, pageSize: nil)
    }

    func test_createUserAction_sendsPOSTToUserActionsEndpoint() async throws {
        MockURLProtocol.handler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.url?.path, "/v1/user-actions")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-token")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
            return (HTTPURLResponse(url: request.url!, statusCode: 201, httpVersion: nil, headerFields: nil)!,
                    Data("""
                    {"id":"00000000-0000-0000-0000-000000000001","user_id":"00000000-0000-0000-0000-000000000099","name":"Cold Plunge","description":null,"category":"custom","parameters":null,"icon_key":null,"color":null,"is_template":false,"template_source_id":null,"protocol_count":0,"sort_order":0,"is_active":true,"created_at":"2024-01-01T12:00:00Z","updated_at":"2024-01-01T12:00:00Z"}
                    """.utf8))
        }

        let payload = UserActionCreate(name: "Cold Plunge", category: .custom)
        _ = try await client.createUserAction(token: "test-token", payload: payload)
    }

    func test_fetchUserAction_sendsGETToUserActionByIdEndpoint() async throws {
        let actionId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        MockURLProtocol.handler = { request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.url?.path, "/v1/user-actions/\(actionId.uuidString)")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-token")
            return (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!,
                    Data("""
                    {"id":"00000000-0000-0000-0000-000000000001","user_id":"00000000-0000-0000-0000-000000000099","name":"Cold Plunge","description":null,"category":"custom","parameters":null,"icon_key":null,"color":null,"is_template":false,"template_source_id":null,"protocol_count":0,"sort_order":0,"is_active":true,"created_at":"2024-01-01T12:00:00Z","updated_at":"2024-01-01T12:00:00Z"}
                    """.utf8))
        }

        _ = try await client.fetchUserAction(token: "test-token", actionId: actionId)
    }

    func test_updateUserAction_sendsPATCHToUserActionByIdEndpoint() async throws {
        let actionId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        MockURLProtocol.handler = { request in
            XCTAssertEqual(request.httpMethod, "PATCH")
            XCTAssertEqual(request.url?.path, "/v1/user-actions/\(actionId.uuidString)")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-token")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
            return (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!,
                    Data("""
                    {"id":"00000000-0000-0000-0000-000000000001","user_id":"00000000-0000-0000-0000-000000000099","name":"Updated Action","description":null,"category":"custom","parameters":null,"icon_key":null,"color":null,"is_template":false,"template_source_id":null,"protocol_count":0,"sort_order":0,"is_active":true,"created_at":"2024-01-01T12:00:00Z","updated_at":"2024-01-01T12:00:00Z"}
                    """.utf8))
        }

        let payload = UserActionUpdate(name: "Updated Action")
        _ = try await client.updateUserAction(token: "test-token", actionId: actionId, payload: payload)
    }

    func test_deleteUserAction_sendsDELETEToUserActionByIdEndpoint() async throws {
        let actionId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        MockURLProtocol.handler = { request in
            XCTAssertEqual(request.httpMethod, "DELETE")
            XCTAssertEqual(request.url?.path, "/v1/user-actions/\(actionId.uuidString)")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-token")
            return (HTTPURLResponse(url: request.url!, statusCode: 204, httpVersion: nil, headerFields: nil)!, Data())
        }

        try await client.deleteUserAction(token: "test-token", actionId: actionId)
    }

    func test_fetchUserActionTemplates_sendsGETToTemplatesEndpoint() async throws {
        MockURLProtocol.handler = { request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.url?.path, "/v1/user-actions/templates")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-token")
            return (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, Data("[]".utf8))
        }

        _ = try await client.fetchUserActionTemplates(token: "test-token")
    }

    func test_duplicateUserAction_sendsPOSTToDuplicateEndpoint() async throws {
        let actionId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        MockURLProtocol.handler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.url?.path, "/v1/user-actions/\(actionId.uuidString)/duplicate")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-token")
            return (HTTPURLResponse(url: request.url!, statusCode: 201, httpVersion: nil, headerFields: nil)!,
                    Data("""
                    {"id":"00000000-0000-0000-0000-000000000002","user_id":"00000000-0000-0000-0000-000000000099","name":"Cold Plunge (1)","description":null,"category":"custom","parameters":null,"icon_key":null,"color":null,"is_template":false,"template_source_id":"00000000-0000-0000-0000-000000000001","protocol_count":0,"sort_order":0,"is_active":true,"created_at":"2024-01-01T12:00:00Z","updated_at":"2024-01-01T12:00:00Z"}
                    """.utf8))
        }

        _ = try await client.duplicateUserAction(token: "test-token", actionId: actionId)
    }

    func test_fetchUserActionUsage_sendsGETToUsageEndpoint() async throws {
        let actionId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        MockURLProtocol.handler = { request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.url?.path, "/v1/user-actions/\(actionId.uuidString)/usage")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-token")
            return (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!,
                    Data("""
                    [{"protocol_id":"00000000-0000-0000-0000-000000000100","protocol_name":"Morning Routine","protocol_action_id":"00000000-0000-0000-0000-000000000200"}]
                    """.utf8))
        }

        _ = try await client.fetchUserActionUsage(token: "test-token", actionId: actionId)
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
