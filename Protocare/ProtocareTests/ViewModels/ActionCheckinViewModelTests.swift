import XCTest
@testable import Protocare

@MainActor
final class ActionCheckinViewModelTests: XCTestCase {

    var sut: ActionCheckinViewModel!
    var mockAPI: MockAuthAPI!
    var mockAuthStore: MockAuthStore!

    override func setUp() {
        super.setUp()
        mockAPI = MockAuthAPI()
        mockAuthStore = MockAuthStore()
        mockAuthStore.mockAccessToken = "test_access_token"
        sut = ActionCheckinViewModel(
            api: mockAPI,
            authStore: mockAuthStore,
            protocolId: "test-protocol-id",
            protocolActionId: "test-action-id"
        )
    }

    override func tearDown() {
        sut = nil
        mockAPI = nil
        mockAuthStore = nil
        super.tearDown()
    }

    // MARK: - submit

    func test_createCheckin_success() async {
        mockAPI.createCheckinResult = .success(
            CheckIn(
                protocolActionId: "test-action-id",
                ts: "2024-01-01T12:00:00Z",
                id: "checkin-001"
            )
        )

        let payload = TestFixtures.makeCheckinCreate()
        let result = await sut.submit(payload: payload)

        XCTAssertTrue(result)
        XCTAssertFalse(sut.isSaving)
        XCTAssertNil(sut.errorMessage)
    }

    func test_createCheckin_withQuantity() async {
        mockAPI.createCheckinResult = .success(
            CheckIn(
                protocolActionId: "test-action-id",
                ts: "2024-01-01T12:00:00Z",
                quantity: 5.0,
                unit: .ml,
                id: "checkin-002"
            )
        )

        let payload = TestFixtures.makeCheckinCreate(
            quantity: 5.0,
            unit: .ml
        )
        let result = await sut.submit(payload: payload)

        XCTAssertTrue(result)
        XCTAssertNil(sut.errorMessage)
    }

    func test_createCheckin_binaryCompletedFalse() async {
        mockAPI.createCheckinResult = .success(
            CheckIn(
                protocolActionId: "test-action-id",
                ts: "2024-01-01T12:00:00Z",
                completed: false,
                id: "checkin-003"
            )
        )

        let payload = TestFixtures.makeCheckinCreate(completed: false)
        let result = await sut.submit(payload: payload)

        XCTAssertTrue(result)
        XCTAssertNil(sut.errorMessage)
    }

    func test_createCheckin_error() async {
        mockAPI.createCheckinResult = .failure(
            APIError.server(status: 500, message: "Internal Server Error")
        )

        let payload = TestFixtures.makeCheckinCreate()
        let result = await sut.submit(payload: payload)

        XCTAssertFalse(result)
        XCTAssertFalse(sut.isSaving)
        XCTAssertNotNil(sut.errorMessage)
    }

    func test_createCheckin_unauthorized() async {
        mockAuthStore.mockAccessToken = nil

        let payload = TestFixtures.makeCheckinCreate()
        let result = await sut.submit(payload: payload)

        XCTAssertFalse(result)
        XCTAssertNotNil(sut.errorMessage)
    }
}
