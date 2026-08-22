import XCTest
@testable import Protocare

@MainActor
final class ProtocolsViewModelTests: XCTestCase {

    var sut: ProtocolsViewModel!
    var mockAPI: MockAuthAPI!
    var mockAuthStore: MockAuthStore!

    override func setUp() {
        super.setUp()
        mockAPI = MockAuthAPI()
        mockAuthStore = MockAuthStore()
        mockAuthStore.mockAccessToken = "test_access_token"
        sut = ProtocolsViewModel(api: mockAPI, authStore: mockAuthStore)
    }

    override func tearDown() {
        sut = nil
        mockAPI = nil
        mockAuthStore = nil
        super.tearDown()
    }

    // MARK: - Delete Protocol Success

    func testDeleteProtocol_Success_RemovesFromList() async {
        mockAPI.fetchProtocolsResult = .success([TestFixtures.morningRoutine, TestFixtures.eveningRoutine])
        mockAPI.deleteProtocolResult = .success(())

        await sut.load()
        XCTAssertEqual(sut.protocols.count, 2)

        await sut.deleteProtocol(TestFixtures.morningRoutine)
        XCTAssertEqual(sut.protocols.count, 1)
        XCTAssertFalse(sut.protocols.contains(where: { $0.id == TestFixtures.morningRoutine.id }))
        XCTAssertNil(sut.deletionErrorMessage)
    }

    func testDeleteProtocol_Success_RemovesImageURL() async {
        let item = TestFixtures.morningRoutine
        mockAPI.fetchProtocolsResult = .success([item])
        mockAPI.fetchProtocolImageResult = .success(
            ImageAttachment(
                id: "img-id",
                ownerId: "owner-id",
                attachableType: "protocol",
                attachableId: item.id,
                filename: "test.jpg",
                contentType: "image/jpeg",
                fileSize: 1024,
                url: "https://example.com/img.jpg",
                createdAt: "2024-01-01T12:00:00Z"
            )
        )
        mockAPI.deleteProtocolResult = .success(())

        await sut.load()
        XCTAssertEqual(sut.protocolImageURLs[item.id], "https://example.com/img.jpg")

        await sut.deleteProtocol(item)
        XCTAssertNil(sut.protocolImageURLs[item.id])
    }

    // MARK: - Delete Protocol Error Handling

    func testDeleteProtocol_Conflict409_ShowsScheduledNotificationsMessage() async {
        mockAPI.fetchProtocolsResult = .success([TestFixtures.morningRoutine])
        mockAPI.deleteProtocolResult = .failure(APIError.server(status: 409, message: "Conflict"))

        await sut.load()
        await sut.deleteProtocol(TestFixtures.morningRoutine)

        XCTAssertEqual(sut.protocols.count, 1)
        XCTAssertEqual(sut.deletionErrorMessage, "This protocol has scheduled notifications and cannot be deleted right now.")
    }

    func testDeleteProtocol_NotFound404_ShowsAlreadyDeletedMessage() async {
        mockAPI.fetchProtocolsResult = .success([TestFixtures.morningRoutine])
        mockAPI.deleteProtocolResult = .failure(APIError.server(status: 404, message: "Not found"))

        await sut.load()
        await sut.deleteProtocol(TestFixtures.morningRoutine)

        XCTAssertEqual(sut.deletionErrorMessage, "This protocol no longer exists. It may have already been deleted.")
    }

    func testDeleteProtocol_Unauthorized401_ShowsPermissionMessage() async {
        mockAPI.fetchProtocolsResult = .success([TestFixtures.morningRoutine])
        mockAPI.deleteProtocolResult = .failure(APIError.server(status: 401, message: "Unauthorized"))

        await sut.load()
        await sut.deleteProtocol(TestFixtures.morningRoutine)

        XCTAssertEqual(sut.deletionErrorMessage, "You don't have permission to delete this protocol.")
    }

    func testDeleteProtocol_Forbidden403_ShowsPermissionMessage() async {
        mockAPI.fetchProtocolsResult = .success([TestFixtures.morningRoutine])
        mockAPI.deleteProtocolResult = .failure(APIError.server(status: 403, message: "Forbidden"))

        await sut.load()
        await sut.deleteProtocol(TestFixtures.morningRoutine)

        XCTAssertEqual(sut.deletionErrorMessage, "You don't have permission to delete this protocol.")
    }

    func testDeleteProtocol_ServerError500_ShowsServerErrorRetryMessage() async {
        mockAPI.fetchProtocolsResult = .success([TestFixtures.morningRoutine])
        mockAPI.deleteProtocolResult = .failure(APIError.server(status: 500, message: "Internal Server Error"))

        await sut.load()
        await sut.deleteProtocol(TestFixtures.morningRoutine)

        XCTAssertEqual(sut.deletionErrorMessage, "A server error occurred. Please try again later.")
    }

    func testDeleteProtocol_TransportError_ShowsNetworkMessage() async {
        mockAPI.fetchProtocolsResult = .success([TestFixtures.morningRoutine])
        mockAPI.deleteProtocolResult = .failure(APIError.transport(NSError(domain: "NSURLErrorDomain", code: -1009)))

        await sut.load()
        await sut.deleteProtocol(TestFixtures.morningRoutine)

        XCTAssertEqual(sut.deletionErrorMessage, "Unable to reach the server. Check your internet connection and try again.")
    }

    func testDeleteProtocol_Unauthenticated_ShowsAuthMessage() async {
        mockAuthStore.mockAccessToken = nil
        mockAPI.fetchProtocolsResult = .success([TestFixtures.morningRoutine])

        await sut.deleteProtocol(TestFixtures.morningRoutine)

        XCTAssertEqual(sut.deletionErrorMessage, "User not authenticated.")
    }

    // MARK: - Deletion State Tracking

    func testDeleteProtocol_AddsToRemoveSetDuringDeletion() async {
        mockAPI.fetchProtocolsResult = .success([TestFixtures.morningRoutine])
        mockAPI.deleteProtocolResult = .success(())

        await sut.load()
        let id = TestFixtures.morningRoutine.id

        let task = Task { await sut.deleteProtocol(TestFixtures.morningRoutine) }
        try? await Task.sleep(nanoseconds: 10_000_000)

        _ = await task.value
        XCTAssertFalse(sut.deletingProtocolIDs.contains(id))
    }

    // MARK: - Confirmation Flow

    func testRequestDeletion_SetsPendingProtocol() {
        sut.requestDeletion(of: TestFixtures.morningRoutine)
        XCTAssertEqual(sut.protocolPendingDeletion?.id, TestFixtures.morningRoutine.id)
    }

    func testCancelDeletion_ClearsPendingProtocol() {
        sut.requestDeletion(of: TestFixtures.morningRoutine)
        sut.cancelDeletion()
        XCTAssertNil(sut.protocolPendingDeletion)
    }

    func testConfirmDeletion_DeletesPendingProtocol() async {
        mockAPI.fetchProtocolsResult = .success([TestFixtures.morningRoutine, TestFixtures.eveningRoutine])
        mockAPI.deleteProtocolResult = .success(())

        await sut.load()
        sut.requestDeletion(of: TestFixtures.morningRoutine)
        await sut.confirmDeletion()

        XCTAssertNil(sut.protocolPendingDeletion)
        XCTAssertEqual(sut.protocols.count, 1)
        XCTAssertFalse(sut.protocols.contains(where: { $0.id == TestFixtures.morningRoutine.id }))
    }

    func testConfirmDeletion_WithNoPendingProtocol_DoesNothing() async {
        mockAPI.fetchProtocolsResult = .success([TestFixtures.morningRoutine])
        await sut.load()

        await sut.confirmDeletion()

        XCTAssertEqual(sut.protocols.count, 1)
        XCTAssertNil(sut.protocolPendingDeletion)
    }
}
