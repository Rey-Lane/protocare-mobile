import XCTest
@testable import Protocare

@MainActor
final class ProtocolBuilderViewModelNotificationTests: XCTestCase {

    var sut: ProtocolBuilderViewModel!
    var mockAPI: MockAuthAPI!
    var mockAuthStore: MockAuthStore!

    override func setUp() {
        super.setUp()
        mockAPI = MockAuthAPI()
        mockAuthStore = MockAuthStore()
        mockAuthStore.mockAccessToken = "test-token"
        mockAuthStore.mockUserId = "test-user-id"
        sut = ProtocolBuilderViewModel(api: mockAPI, authStore: mockAuthStore)
    }

    override func tearDown() {
        sut = nil
        mockAPI = nil
        mockAuthStore = nil
        super.tearDown()
    }

    func testAddAction_DoesNotDuplicate() {
        let action = TestFixtures.morningCleanse
        sut.addAction(action)
        sut.addAction(action)

        XCTAssertEqual(sut.draft.actions.count, 1)
    }

    func testRemoveAction_RemovesAction() {
        let action = TestFixtures.morningCleanse
        sut.addAction(action)

        sut.removeAction(action)
        XCTAssertTrue(sut.draft.actions.isEmpty)
    }

    func testCanSave_RequiresNameAndActions() {
        XCTAssertFalse(sut.canSave)

        sut.draft.name = "Test Protocol"
        XCTAssertFalse(sut.canSave)

        sut.addAction(TestFixtures.morningCleanse)
        XCTAssertTrue(sut.canSave)
    }

    func testCanSave_FalseWhileSaving() {
        sut.draft.name = "Test Protocol"
        sut.addAction(TestFixtures.morningCleanse)
        XCTAssertTrue(sut.canSave)

        sut.isSaving = true
        XCTAssertFalse(sut.canSave)
    }

    func testSave_FailsWithoutAuth() async {
        mockAuthStore.mockAccessToken = nil
        sut.draft.name = "Test"
        sut.addAction(TestFixtures.morningCleanse)

        let result = await sut.save()
        XCTAssertFalse(result)
        XCTAssertNotNil(sut.errorMessage)
    }

    func testSave_FailsWithoutUserId() async {
        mockAuthStore.mockUserId = nil
        sut.draft.name = "Test"
        sut.addAction(TestFixtures.morningCleanse)

        let result = await sut.save()
        XCTAssertFalse(result)
        XCTAssertNotNil(sut.errorMessage)
    }

    func testSave_ProtocolCreationFails() async {
        sut.draft.name = "Test Protocol"
        sut.addAction(TestFixtures.morningCleanse)

        mockAPI.createProtocolWithImageResult = .failure(
            APIError.server(status: 500, message: "Internal Server Error")
        )
        mockAPI.createProtocolResult = .failure(
            APIError.server(status: 500, message: "Internal Server Error")
        )

        let result = await sut.save()
        XCTAssertFalse(result)
        XCTAssertNotNil(sut.errorMessage)
    }

    func testLoadActions_FailsWithoutAuth() async {
        mockAuthStore.mockAccessToken = nil
        await sut.loadActions()
        XCTAssertEqual(sut.availableActions.count, 0)
        XCTAssertNotNil(sut.errorMessage)
    }

    func testLoadActions_LoadsSuccessfully() async {
        mockAPI.fetchActionsResult = .success([
            Action(id: "action-1", name: "Minoxidil Spray", category: .hair, modality: .topical)
        ])

        await sut.loadActions()
        XCTAssertEqual(sut.availableActions.count, 1)
        XCTAssertNil(sut.errorMessage)
    }

    // MARK: - Unified Add (single ID space)

    func testAddAction_UsesActionItemIDirectly() {
        let action = ActionItem(id: "a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d", name: "Meditation", category: .mindfulness)
        sut.addAction(action)

        XCTAssertEqual(sut.draft.actions.count, 1)
        XCTAssertEqual(sut.draft.actions.first?.id, action.id)
    }

    // MARK: - Alert Binding Pattern (SW-03)

    func testErrorMessage_CanBeSetToNil_AfterBeingSet() {
        // Simulate error state
        sut.errorMessage = "Something went wrong"
        XCTAssertNotNil(sut.errorMessage, "errorMessage should be set")

        // Simulate alert dismiss
        sut.errorMessage = nil
        XCTAssertNil(sut.errorMessage, "errorMessage should be nil after dismiss — alert binding must support re-assignment")
    }
}

// MARK: - ProtocolActionCreate Encoding

final class ProtocolActionCreateEncodingTests: XCTestCase {

    func testEncode_WithActionId_IncludesActionIdInJSON() throws {
        let payload = ProtocolActionCreate(
            actionId: "action-123",
            rrule: "FREQ=DAILY",
            position: 0
        )

        let data = try JSONEncoder().encode(payload)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(json["action_id"] as? String, "action-123")
        XCTAssertNil(json["user_action_id"])
    }

    func testEncode_WithUserParameters_IncludesUserParametersInJSON() throws {
        let payload = ProtocolActionCreate(
            actionId: "action-123",
            userParameters: ["volume_amount": AnyCodable(7.0), "volume_unit": AnyCodable("spray")],
            rrule: "FREQ=DAILY",
            position: 0
        )

        let data = try JSONEncoder().encode(payload)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(json["action_id"] as? String, "action-123")
        let params = try XCTUnwrap(json["user_parameters"] as? [String: Any])
        XCTAssertEqual(params["volume_amount"] as? Double, 7.0)
        XCTAssertEqual(params["volume_unit"] as? String, "spray")
    }

    func testEncode_WithNotificationFields_IncludesWhenPresent() throws {
        let payload = ProtocolActionCreate(
            actionId: "action-123",
            rrule: "FREQ=DAILY",
            position: 2,
            notificationTime: "08:00",
            notificationTimezone: "Europe/Amsterdam"
        )

        let data = try JSONEncoder().encode(payload)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(json["action_id"] as? String, "action-123")
        XCTAssertEqual(json["rrule"] as? String, "FREQ=DAILY")
        XCTAssertEqual(json["position"] as? Int, 2)
        XCTAssertEqual(json["notification_time"] as? String, "08:00")
        XCTAssertEqual(json["notification_timezone"] as? String, "Europe/Amsterdam")
    }

    func testEncode_WithoutOptionalFields_OmitsThemFromJSON() throws {
        // Step 23: action_id is required by the unified backend contract,
        // so only user_parameters/position/notification fields stay omittable.
        let payload = ProtocolActionCreate(
            actionId: "action-123",
            rrule: "FREQ=DAILY"
        )

        let data = try JSONEncoder().encode(payload)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(json["action_id"] as? String, "action-123")
        XCTAssertFalse(json.keys.contains("user_parameters"))
        XCTAssertFalse(json.keys.contains("position"))
        XCTAssertFalse(json.keys.contains("notification_time"))
        XCTAssertFalse(json.keys.contains("notification_timezone"))
        XCTAssertEqual(json["rrule"] as? String, "FREQ=DAILY")
    }

    func testDecode_WithActionId() throws {
        let jsonString = """
        {"action_id": "action-123", "rrule": "FREQ=DAILY", "position": 0}
        """
        let data = Data(jsonString.utf8)
        let decoded = try JSONDecoder().decode(ProtocolActionCreate.self, from: data)

        XCTAssertEqual(decoded.actionId, "action-123")
        XCTAssertEqual(decoded.rrule, "FREQ=DAILY")
    }

    func testDecode_WithUserParameters() throws {
        let jsonString = """
        {"action_id": "action-123", "user_parameters": {"volume_amount": 7.5, "volume_unit": "spray"}, "rrule": "FREQ=DAILY", "position": 1}
        """
        let data = Data(jsonString.utf8)
        let decoded = try JSONDecoder().decode(ProtocolActionCreate.self, from: data)

        XCTAssertEqual(decoded.actionId, "action-123")
        let amount = try XCTUnwrap(decoded.userParameters?["volume_amount"]?.value as? Double)
        XCTAssertEqual(amount, 7.5)
        XCTAssertEqual(decoded.userParameters?["volume_unit"]?.value as? String, "spray")
    }
}

// MARK: - ProtocolAction Response Model

final class ProtocolActionModelTests: XCTestCase {

    func testProtocolAction_WithActionId() {
        let action = ProtocolAction(
            id: "pa-1",
            actionId: "action-123",
            rrule: "FREQ=DAILY",
            position: 0
        )
        XCTAssertEqual(action.actionId, "action-123")
    }

    func testProtocolAction_DecodeWithActionId() throws {
        let jsonString = """
        {"id": "pa-1", "action_id": "action-123", "rrule": "FREQ=DAILY", "position": 0}
        """
        let data = Data(jsonString.utf8)
        let decoded = try JSONDecoder().decode(ProtocolAction.self, from: data)

        XCTAssertEqual(decoded.actionId, "action-123")
    }

    func testProtocolAction_DecodeWithUserParameters() throws {
        let jsonString = """
        {"id": "pa-1", "action_id": "action-123", "user_parameters": {"serving": 2, "serving_unit": "capsule"}, "rrule": "FREQ=DAILY", "position": 0}
        """
        let data = Data(jsonString.utf8)
        let decoded = try JSONDecoder().decode(ProtocolAction.self, from: data)

        XCTAssertEqual(decoded.actionId, "action-123")
        let serving = try XCTUnwrap(decoded.userParameters?["serving"]?.value as? Int)
        XCTAssertEqual(serving, 2)
        XCTAssertEqual(decoded.userParameters?["serving_unit"]?.value as? String, "capsule")
    }
}
