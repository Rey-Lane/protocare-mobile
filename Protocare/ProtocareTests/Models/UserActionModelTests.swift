import XCTest
@testable import Protocare

/// Tests for the models that survived the UserAction stack removal (Step 20):
/// ActionCategory, ActionFieldType/ActionField/ActionParameters (kept in
/// UserActionLegacy.swift until Steps 25d/31), and AnyCodable.
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

    // MARK: - ActionFieldType

    func testActionFieldTypeAllCases() {
        XCTAssertEqual(ActionFieldType.allCases.count, 6)
        XCTAssertEqual(ActionFieldType.text.rawValue, "text")
        XCTAssertEqual(ActionFieldType.number.rawValue, "number")
        XCTAssertEqual(ActionFieldType.boolean.rawValue, "boolean")
        XCTAssertEqual(ActionFieldType.select.rawValue, "select")
        XCTAssertEqual(ActionFieldType.time.rawValue, "time")
        XCTAssertEqual(ActionFieldType.duration.rawValue, "duration")
    }

    // MARK: - ActionField

    func testActionFieldID() {
        let field = ActionField(key: "dosage", label: "Dosage", type: .number)
        XCTAssertEqual(field.id, "dosage")
    }

    func testActionFieldWithAllProperties() {
        let field = ActionField(
            key: "temperature",
            label: "Temperature",
            type: .number,
            isRequired: true,
            defaultValue: AnyCodable(20),
            options: nil,
            unit: "°C",
            minValue: AnyCodable(0),
            maxValue: AnyCodable(50)
        )
        XCTAssertEqual(field.key, "temperature")
        XCTAssertTrue(field.isRequired)
        XCTAssertEqual(field.unit, "°C")
    }

    // MARK: - ActionParameters

    func testActionParametersCreation() {
        let params = ActionParameters(fields: [
            ActionField(key: "amount", label: "Amount", type: .number),
            ActionField(key: "unit", label: "Unit", type: .select, options: ["ml", "mg"])
        ])
        XCTAssertEqual(params.fields.count, 2)
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

    // MARK: - Coding Keys

    func testActionFieldCodingKeys() {
        let field = ActionField(
            key: "test",
            label: "Test",
            type: .number,
            isRequired: true,
            defaultValue: AnyCodable(5),
            unit: "mg",
            minValue: AnyCodable(0),
            maxValue: AnyCodable(100)
        )

        let encoder = JSONEncoder()
        let data = try! encoder.encode(field)
        let json = try! JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(json["required"] as? Bool, true)
        XCTAssertEqual(json["unit"] as? String, "mg")
        XCTAssertEqual(json["default_value"] as? Int, 5)
        XCTAssertEqual(json["min_value"] as? Int, 0)
        XCTAssertEqual(json["max_value"] as? Int, 100)
    }
}
