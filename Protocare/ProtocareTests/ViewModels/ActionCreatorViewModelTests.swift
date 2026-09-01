import XCTest
@testable import Protocare

@MainActor
final class ActionCreatorViewModelTests: XCTestCase {

    var api: MockAuthAPI!
    var authStore: MockAuthStore!

    override func setUp() {
        super.setUp()
        api = MockAuthAPI()
        authStore = MockAuthStore()
        authStore.mockAccessToken = "test-token"
    }

    override func tearDown() {
        api = nil
        authStore = nil
        super.tearDown()
    }

    // MARK: - Can Save

    func testCanSave_withValidName_returnsTrue() {
        let vm = ActionCreatorViewModel(api: api, authStore: authStore)
        vm.name = "Cold Plunge"
        XCTAssertTrue(vm.canSave)
    }

    func testCanSave_withEmptyName_returnsFalse() {
        let vm = ActionCreatorViewModel(api: api, authStore: authStore)
        vm.name = ""
        XCTAssertFalse(vm.canSave)
    }

    func testCanSave_withSingleCharName_returnsFalse() {
        let vm = ActionCreatorViewModel(api: api, authStore: authStore)
        vm.name = "A"
        XCTAssertFalse(vm.canSave)
    }

    func testCanSave_withWhitespaceOnlyName_returnsFalse() {
        let vm = ActionCreatorViewModel(api: api, authStore: authStore)
        vm.name = "   "
        XCTAssertFalse(vm.canSave)
    }

    func testCanSave_withNameOver100Chars_returnsFalse() {
        let vm = ActionCreatorViewModel(api: api, authStore: authStore)
        vm.name = String(repeating: "A", count: 101)
        XCTAssertFalse(vm.canSave)
    }

    func testCanSave_whileSaving_returnsFalse() {
        let vm = ActionCreatorViewModel(api: api, authStore: authStore)
        vm.name = "Valid Name"
        vm.isSaving = true
        XCTAssertFalse(vm.canSave)
    }

    // MARK: - Save (Create)

    func testSave_create_success() async {
        let createdAction = TestFixtures.testAction
        api.createActionResult = .success(createdAction)

        let vm = ActionCreatorViewModel(api: api, authStore: authStore)
        vm.name = "Cold Plunge"
        vm.category = .mindfulness
        vm.modality = .activity

        let result = await vm.save()
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.name, createdAction.name)
        XCTAssertFalse(vm.isSaving)
        XCTAssertNil(vm.errorMessage)
    }

    func testSave_create_sendsUnifiedPayload() async {
        api.createActionResult = .success(TestFixtures.testAction)

        let vm = ActionCreatorViewModel(api: api, authStore: authStore)
        vm.name = "Vitamin D3"
        vm.category = .supplement
        vm.modality = .oral
        vm.parameterMode = .amount
        vm.amount = 2
        vm.unit = .capsule

        _ = await vm.save()

        let payload = api.lastCreateActionPayload
        XCTAssertNotNil(payload)
        XCTAssertEqual(payload?.name, "Vitamin D3")
        XCTAssertEqual(payload?.category, .supplement)
        XCTAssertEqual(payload?.modality, .oral)
        XCTAssertEqual(payload?.defaultParameters?["volume_amount"], AnyCodable(2.0))
        XCTAssertEqual(payload?.defaultParameters?["volume_unit"], AnyCodable("capsule"))
    }

    func testSave_create_withDuration_sendsDurationSeconds() async {
        api.createActionResult = .success(TestFixtures.testAction)

        let vm = ActionCreatorViewModel(api: api, authStore: authStore)
        vm.name = "Meditation"
        vm.parameterMode = .duration
        vm.durationMinutes = 10

        _ = await vm.save()

        let payload = api.lastCreateActionPayload
        XCTAssertEqual(payload?.defaultParameters?["duration_seconds"], AnyCodable(600))
    }

    func testSave_create_withNoneMode_sendsNilParameters() async {
        api.createActionResult = .success(TestFixtures.testAction)

        let vm = ActionCreatorViewModel(api: api, authStore: authStore)
        vm.name = "Floss"
        vm.parameterMode = .none

        _ = await vm.save()

        let payload = api.lastCreateActionPayload
        XCTAssertNil(payload?.defaultParameters)
    }

    func testSave_create_failure_setsErrorMessage() async {
        api.createActionResult = .failure(NSError(domain: "test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"]))

        let vm = ActionCreatorViewModel(api: api, authStore: authStore)
        vm.name = "Cold Plunge"

        let result = await vm.save()
        XCTAssertNil(result)
        XCTAssertNotNil(vm.errorMessage)
    }

    func testSave_create_notAuthenticated_returnsNil() async {
        authStore.mockAccessToken = nil

        let vm = ActionCreatorViewModel(api: api, authStore: authStore)
        vm.name = "Cold Plunge"

        let result = await vm.save()
        XCTAssertNil(result)
        XCTAssertEqual(vm.errorMessage, "User not authenticated.")
    }

    // MARK: - Save (Edit)

    func testSave_edit_success() async {
        let editingAction = TestFixtures.testAction
        let updatedAction = Action(
            id: editingAction.id,
            name: "Updated Name",
            category: .exercise
        )
        api.updateActionResult = .success(updatedAction)

        let vm = ActionCreatorViewModel(api: api, authStore: authStore, editingAction: editingAction)
        vm.name = "Updated Name"

        let result = await vm.save()
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.name, "Updated Name")
        XCTAssertTrue(vm.isEditing)
        XCTAssertEqual(api.lastUpdateActionPayload?.name, "Updated Name")
    }

    func testSave_edit_failure_setsErrorMessage() async {
        let editingAction = TestFixtures.testAction
        api.updateActionResult = .failure(NSError(domain: "test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Update failed"]))

        let vm = ActionCreatorViewModel(api: api, authStore: authStore, editingAction: editingAction)
        vm.name = "Updated Name"

        let result = await vm.save()
        XCTAssertNil(result)
        XCTAssertNotNil(vm.errorMessage)
    }

    // MARK: - Editing Mode

    func testInit_withEditingAction_populatesFields() async {
        let action = TestFixtures.testAction
        let vm = ActionCreatorViewModel(api: api, authStore: authStore, editingAction: action)

        XCTAssertTrue(vm.isEditing)
        XCTAssertEqual(vm.name, action.name)
        XCTAssertEqual(vm.category, action.category)
        XCTAssertEqual(vm.modality, action.modality)
        // duration_seconds in default_parameters → duration mode, 180s = 3 min
        XCTAssertEqual(vm.parameterMode, .duration)
        XCTAssertEqual(vm.durationMinutes, 3)
    }

    func testInit_withoutEditingAction_isCreateMode() {
        let vm = ActionCreatorViewModel(api: api, authStore: authStore)
        XCTAssertFalse(vm.isEditing)
        XCTAssertTrue(vm.name.isEmpty)
    }
}
