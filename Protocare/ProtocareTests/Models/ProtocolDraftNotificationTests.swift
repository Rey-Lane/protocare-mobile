import XCTest
@testable import Protocare

final class ProtocolDraftNotificationTests: XCTestCase {

    func testDefaultNotificationPreferencesIsEmpty() {
        let draft = ProtocolDraft()
        XCTAssertTrue(draft.actions.isEmpty)
    }
}
