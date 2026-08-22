import XCTest
@testable import Protocare

@MainActor
final class TemplatesViewModelTests: XCTestCase {

    var sut: TemplatesViewModel!
    var mockAPI: MockAuthAPI!
    var mockAuthStore: MockAuthStore!

    override func setUp() {
        super.setUp()
        mockAPI = MockAuthAPI()
        mockAuthStore = MockAuthStore()
        mockAuthStore.mockAccessToken = "test_access_token"
        sut = TemplatesViewModel(api: mockAPI, authStore: mockAuthStore)
    }

    override func tearDown() {
        sut = nil
        mockAPI = nil
        mockAuthStore = nil
        super.tearDown()
    }

    // MARK: - loadTemplates

    func test_loadTemplates_success() async {
        mockAPI.fetchTemplatesResult = .success(TestFixtures.testTemplates)

        await sut.loadTemplates()

        XCTAssertEqual(sut.templates.count, 2)
        XCTAssertEqual(sut.templates[0].id, TestFixtures.morningRoutineTemplate.id)
        XCTAssertEqual(sut.templates[1].id, TestFixtures.supplementTemplate.id)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
    }

    func test_loadTemplates_empty() async {
        mockAPI.fetchTemplatesResult = .success([])

        await sut.loadTemplates()

        XCTAssertTrue(sut.templates.isEmpty)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
    }

    func test_loadTemplates_error() async {
        mockAPI.fetchTemplatesResult = .failure(
            APIError.server(status: 500, message: "Internal Server Error")
        )

        await sut.loadTemplates()

        XCTAssertTrue(sut.templates.isEmpty)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNotNil(sut.errorMessage)
    }

    func test_loadTemplates_unauthenticated() async {
        mockAuthStore.mockAccessToken = nil

        await sut.loadTemplates()

        XCTAssertTrue(sut.templates.isEmpty)
        XCTAssertNotNil(sut.errorMessage)
    }

    // MARK: - createProtocol

    func test_createProtocolFromTemplate_success() async {
        mockAPI.createProtocolFromTemplateResult = .success(
            ProtocolItem(
                id: "new-protocol-id",
                userId: "test-user-id",
                name: "Morning Routine",
                actions: [],
                isActive: true
            )
        )

        let result = await sut.createProtocol(from: TestFixtures.morningRoutineTemplate)

        XCTAssertTrue(result)
        XCTAssertFalse(sut.isCreating)
        XCTAssertNil(sut.creationErrorMessage)
    }

    func test_createProtocolFromTemplate_error() async {
        mockAPI.createProtocolFromTemplateResult = .failure(
            APIError.server(status: 500, message: "Internal Server Error")
        )

        let result = await sut.createProtocol(from: TestFixtures.morningRoutineTemplate)

        XCTAssertFalse(result)
        XCTAssertFalse(sut.isCreating)
        XCTAssertNotNil(sut.creationErrorMessage)
    }

    func test_createProtocolFromTemplate_unauthenticated() async {
        mockAuthStore.mockAccessToken = nil

        let result = await sut.createProtocol(from: TestFixtures.morningRoutineTemplate)

        XCTAssertFalse(result)
        XCTAssertNotNil(sut.creationErrorMessage)
    }

    // MARK: - groupedByCategory

    func test_groupedByCategory_groupsCorrectly() async {
        mockAPI.fetchTemplatesResult = .success(TestFixtures.testTemplates)

        await sut.loadTemplates()

        let grouped = sut.groupedByCategory
        XCTAssertFalse(grouped.isEmpty)
        XCTAssertEqual(grouped[0].category, .morningRoutine)
        XCTAssertEqual(grouped[0].templates.count, 1)
        XCTAssertEqual(grouped[1].category, .supplement)
        XCTAssertEqual(grouped[1].templates.count, 1)
    }
}
