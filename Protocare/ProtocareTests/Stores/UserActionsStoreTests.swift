import XCTest
@testable import Protocare

@MainActor
final class UserActionsStoreTests: XCTestCase {
    private var api: MockAuthAPI!
    private var authStore: AuthStore!

    override func setUp() {
        super.setUp()
        api = MockAuthAPI()
        authStore = AuthStore()
        authStore.setAuth(tokens: AuthTokens(
            userId: "550e8400-e29b-41d4-a716-446655440000",
            accessToken: "test_token",
            refreshToken: "test_refresh_token",
            tokenType: "Bearer"
        ))
    }

    override func tearDown() {
        api = nil
        authStore = nil
        super.tearDown()
    }

    // MARK: - Load Actions

    func testLoadUserActionsSuccess() async {
        api.fetchUserActionsResult = .success(PaginatedUserActions(
            items: [TestFixtures.testUserAction],
            total: 1,
            page: 1,
            pageSize: 20
        ))
        api.fetchUserActionTemplatesResult = .success([TestFixtures.testUserActionTemplate])

        let store = UserActionsStore(api: api, authStore: authStore)
        await store.loadUserActions()

        XCTAssertEqual(store.userActions.count, 1)
        XCTAssertEqual(store.userActions.first?.name, "Cold Plunge")
        XCTAssertEqual(store.templates.count, 1)
        XCTAssertNil(store.errorMessage)
    }

    func testLoadUserActionsFailure() async {
        api.fetchUserActionsResult = .failure(APIError.server(status: 500, message: "Server error"))

        let store = UserActionsStore(api: api, authStore: authStore)
        await store.loadUserActions()

        XCTAssertTrue(store.userActions.isEmpty)
        XCTAssertNotNil(store.errorMessage)
    }

    func testLoadUserActionsNotAuthenticated() async {
        authStore.logout()

        let store = UserActionsStore(api: api, authStore: authStore)
        await store.loadUserActions()

        XCTAssertTrue(store.userActions.isEmpty)
        XCTAssertNotNil(store.errorMessage)
    }

    // MARK: - Active Actions

    func testActiveActionsFiltersInactive() async {
        let activeAction = UserAction(
            id: UUID(),
            userId: UUID(),
            name: "Active",
            category: .custom,
            isActive: true
        )
        let inactiveAction = UserAction(
            id: UUID(),
            userId: UUID(),
            name: "Inactive",
            category: .custom,
            isActive: false
        )

        api.fetchUserActionsResult = .success(PaginatedUserActions(
            items: [activeAction, inactiveAction],
            total: 2,
            page: 1,
            pageSize: 20
        ))
        api.fetchUserActionTemplatesResult = .success([])

        let store = UserActionsStore(api: api, authStore: authStore)
        await store.loadUserActions()

        XCTAssertEqual(store.userActions.count, 2)
        XCTAssertEqual(store.activeActions.count, 1)
        XCTAssertEqual(store.activeActions.first?.name, "Active")
    }

    // MARK: - Create Action

    func testCreateUserActionSuccess() async {
        let created = TestFixtures.testUserAction
        api.createUserActionResult = .success(created)

        let store = UserActionsStore(api: api, authStore: authStore)
        let result = await store.createUserAction(TestFixtures.testUserActionCreate)

        XCTAssertEqual(result?.name, "Cold Plunge")
        XCTAssertEqual(store.userActions.count, 1)
    }

    func testCreateUserActionFailure() async {
        api.createUserActionResult = .failure(APIError.server(status: 400, message: "Bad request"))

        let store = UserActionsStore(api: api, authStore: authStore)
        let result = await store.createUserAction(TestFixtures.testUserActionCreate)

        XCTAssertNil(result)
        XCTAssertNotNil(store.errorMessage)
    }

    // MARK: - Update Action

    func testUpdateUserActionSuccess() async {
        let original = TestFixtures.testUserAction
        api.fetchUserActionsResult = .success(PaginatedUserActions(items: [original], total: 1, page: 1, pageSize: 20))
        api.fetchUserActionTemplatesResult = .success([])

        let updated = UserAction(
            id: original.id,
            userId: original.userId,
            name: "Updated Cold Plunge",
            description: "Updated",
            category: .mindfulness,
            isActive: true,
            createdAt: original.createdAt,
            updatedAt: Date()
        )
        api.updateUserActionResult = .success(updated)

        let store = UserActionsStore(api: api, authStore: authStore)
        await store.loadUserActions()
        let result = await store.updateUserAction(id: original.id, payload: TestFixtures.testUserActionUpdate)

        XCTAssertEqual(result?.name, "Updated Cold Plunge")
        XCTAssertEqual(store.userActions.first?.name, "Updated Cold Plunge")
    }

    // MARK: - Delete Action

    func testDeleteUserActionSuccess() async {
        let action = TestFixtures.testUserAction
        api.fetchUserActionsResult = .success(PaginatedUserActions(items: [action], total: 1, page: 1, pageSize: 20))
        api.fetchUserActionTemplatesResult = .success([])
        api.deleteUserActionResult = .success(())

        let store = UserActionsStore(api: api, authStore: authStore)
        await store.loadUserActions()
        XCTAssertEqual(store.userActions.count, 1)

        let deleted = await store.deleteUserAction(id: action.id)
        XCTAssertTrue(deleted)
        XCTAssertTrue(store.userActions.isEmpty)
    }

    // MARK: - Duplicate Action

    func testDuplicateUserActionSuccess() async {
        let original = TestFixtures.testUserAction
        api.fetchUserActionsResult = .success(PaginatedUserActions(items: [original], total: 1, page: 1, pageSize: 20))
        api.fetchUserActionTemplatesResult = .success([])

        let duplicated = UserAction(
            id: UUID(),
            userId: original.userId,
            name: "Cold Plunge (Copy)",
            category: .mindfulness,
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        )
        api.duplicateUserActionResult = .success(duplicated)

        let store = UserActionsStore(api: api, authStore: authStore)
        await store.loadUserActions()

        let result = await store.duplicateAction(id: original.id)
        XCTAssertEqual(result?.name, "Cold Plunge (Copy)")
        XCTAssertEqual(store.userActions.count, 2)
    }

    // MARK: - Action Lookup

    func testActionWithId() async {
        let action = TestFixtures.testUserAction
        api.fetchUserActionsResult = .success(PaginatedUserActions(items: [action], total: 1, page: 1, pageSize: 20))
        api.fetchUserActionTemplatesResult = .success([])

        let store = UserActionsStore(api: api, authStore: authStore)
        await store.loadUserActions()

        let found = store.action(withId: action.id)
        XCTAssertEqual(found?.name, "Cold Plunge")

        let notFound = store.action(withId: UUID())
        XCTAssertNil(notFound)
    }
}
