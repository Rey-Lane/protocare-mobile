import XCTest
@testable import Protocare

/// Tests for the models that survived the UserAction stack removal (Step 20)
/// and the ActionField/ActionParameters deletion (Step 25d):
/// ActionCategory and AnyCodable.
final class UserActionModelTests: XCTestCase {

    // MARK: - ActionCategory

    func testActionCategoryAllCases() {
        XCTAssertEqual(ActionCategory.allCases.count, 10)
        XCTAssertEqual(ActionCategory.supplement.displayName, "Supplement")
        XCTAssertEqual(ActionCategory.hair.displayName, "Hair")
        XCTAssertEqual(ActionCategory.measurement.displayName, "Measurement")
        XCTAssertEqual(ActionCategory.custom.displayName, "Custom")
        XCTAssertEqual(ActionCategory.medical.displayName, "Medical")
    }

    func testActionCategoryIcons() {
        XCTAssertEqual(ActionCategory.supplement.tagIcon, "pill.fill")
        XCTAssertEqual(ActionCategory.skincare.tagIcon, "drop.fill")
        XCTAssertEqual(ActionCategory.hair.tagIcon, "scissors")
        XCTAssertEqual(ActionCategory.exercise.tagIcon, "figure.run")
        XCTAssertEqual(ActionCategory.mindfulness.tagIcon, "brain.head.profile.fill")
        XCTAssertEqual(ActionCategory.measurement.tagIcon, "chart.bar.fill")
        XCTAssertEqual(ActionCategory.medical.tagIcon, "stethoscope")
        XCTAssertEqual(ActionCategory.sleep.tagIcon, "bedtime.fill")
        XCTAssertEqual(ActionCategory.custom.tagIcon, "star.fill")
    }

    // MARK: - AnyCodable

    func testAnyCodableBool() {
        let codable = AnyCodable(true)
        XCTAssertEqual(codable, AnyCodable(true))
        XCTAssertNotEqual(codable, AnyCodable(false))
    }

    func testAnyCodableInt() {
        let codable = AnyCodable(42)
        XCTAssertEqual(codable, AnyCodable(42))
        XCTAssertNotEqual(codable, AnyCodable(43))
    }

    func testAnyCodableDouble() {
        let codable = AnyCodable(3.14)
        XCTAssertEqual(codable, AnyCodable(3.14))
    }

    func testAnyCodableString() {
        let codable = AnyCodable("hello")
        XCTAssertEqual(codable, AnyCodable("hello"))
        XCTAssertNotEqual(codable, AnyCodable("world"))
    }
}
