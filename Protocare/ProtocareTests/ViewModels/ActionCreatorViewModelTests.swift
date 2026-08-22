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

    // MARK: - Add/Remove Fields

    func testAddField_appendsField() {
        let vm = ActionCreatorViewModel(api: api, authStore: authStore)
        let field = ActionField(key: "dosage", label: "Dosage", type: .number)
        vm.addField(field)
        XCTAssertEqual(vm.fields.count, 1)
        XCTAssertEqual(vm.fields.first?.key, "dosage")
    }

    func testAddField_max20Fields() {
        let vm = ActionCreatorViewModel(api: api, authStore: authStore)
        for i in 0..<21 {
            let field = ActionField(key: "field_\(i)", label: "Field \(i)", type: .text)
            vm.addField(field)
        }
        XCTAssertEqual(vm.fields.count, 20)
    }

    func testRemoveField_removesMatchingKey() {
        let vm = ActionCreatorViewModel(api: api, authStore: authStore)
        vm.addField(ActionField(key: "dosage", label: "Dosage", type: .number))
        vm.addField(ActionField(key: "duration", label: "Duration", type: .duration))
        vm.removeField(ActionField(key: "dosage", label: "Dosage", type: .number))
        XCTAssertEqual(vm.fields.count, 1)
        XCTAssertEqual(vm.fields.first?.key, "duration")
    }

    // MARK: - Save (Create)

    func testSave_create_success() async {
        let createdAction = TestFixtures.testUserAction
        api.createUserActionResult = .success(createdAction)

        let vm = ActionCreatorViewModel(api: api, authStore: authStore)
        vm.name = "Cold Plunge"
        vm.category = .custom

        let result = await vm.save()
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.name, createdAction.name)
        XCTAssertFalse(vm.isSaving)
    }

    func testSave_create_failure_setsErrorMessage() async {
        api.createUserActionResult = .failure(NSError(domain: "test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"]))

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
        let editingAction = TestFixtures.testUserAction
        let updatedAction = UserAction(
            id: editingAction.id,
            userId: editingAction.userId,
            name: "Updated Name",
            category: .exercise
        )
        api.updateUserActionResult = .success(updatedAction)

        let vm = ActionCreatorViewModel(api: api, authStore: authStore, editingAction: editingAction)
        vm.name = "Updated Name"

        let result = await vm.save()
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.name, "Updated Name")
        XCTAssertTrue(vm.isEditing)
    }

    func testSave_edit_failure_setsErrorMessage() async {
        let editingAction = TestFixtures.testUserAction
        api.updateUserActionResult = .failure(NSError(domain: "test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Update failed"]))

        let vm = ActionCreatorViewModel(api: api, authStore: authStore, editingAction: editingAction)
        vm.name = "Updated Name"

        let result = await vm.save()
        XCTAssertNil(result)
        XCTAssertNotNil(vm.errorMessage)
    }

    // MARK: - Editing Mode

    func testInit_withEditingAction_populatesFields() {
        let action = TestFixtures.testUserAction
        let vm = ActionCreatorViewModel(api: api, authStore: authStore, editingAction: action)

        XCTAssertTrue(vm.isEditing)
        XCTAssertEqual(vm.name, action.name)
        XCTAssertEqual(vm.category, action.category)
    }

    func testInit_withoutEditingAction_isCreateMode() {
        let vm = ActionCreatorViewModel(api: api, authStore: authStore)
        XCTAssertFalse(vm.isEditing)
        XCTAssertTrue(vm.name.isEmpty)
    }
}
