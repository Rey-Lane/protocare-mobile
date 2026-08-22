import XCTest
@testable import Protocare

final class UserActionModelTests: XCTestCase {

    // MARK: - ActionCategory

    func testActionCategoryAllCases() {
        XCTAssertEqual(ActionCategory.allCases.count, 9)
        XCTAssertEqual(ActionCategory.supplement.displayName, "Supplement")
        XCTAssertEqual(ActionCategory.hair.displayName, "Hair")
        XCTAssertEqual(ActionCategory.measurement.displayName, "Measurement")
        XCTAssertEqual(ActionCategory.custom.displayName, "Custom")
    }

    func testActionCategoryIcons() {
        XCTAssertEqual(ActionCategory.supplement.icon, "pill.fill")
        XCTAssertEqual(ActionCategory.skincare.icon, "drop.fill")
        XCTAssertEqual(ActionCategory.hair.icon, "scissors")
        XCTAssertEqual(ActionCategory.exercise.icon, "figure.run")
        XCTAssertEqual(ActionCategory.mindfulness.icon, "brain.head.profile.fill")
        XCTAssertEqual(ActionCategory.measurement.icon, "ruler")
        XCTAssertEqual(ActionCategory.custom.icon, "sparkles")
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

    // MARK: - UserAction

    func testUserActionCreation() {
        let action = TestFixtures.testUserAction
        XCTAssertEqual(action.name, "Cold Plunge")
        XCTAssertEqual(action.category, .mindfulness)
        XCTAssertFalse(action.isTemplate)
        XCTAssertTrue(action.isActive)
        XCTAssertEqual(action.protocolCount, 3)
    }

    func testUserActionDisplayIcon() {
        let action = TestFixtures.testUserAction
        XCTAssertEqual(action.displayIcon, "snowflake")

        let actionWithoutIcon = UserAction(
            id: UUID(),
            userId: UUID(),
            name: "Test",
            category: .supplement
        )
        XCTAssertEqual(actionWithoutIcon.displayIcon, "pill.fill")
    }

    func testUserActionDisplayColor() {
        let action = TestFixtures.testUserAction
        XCTAssertEqual(action.displayColor, "#007AFF")

        let actionWithoutColor = UserAction(
            id: UUID(),
            userId: UUID(),
            name: "Test",
            category: .custom
        )
        XCTAssertEqual(actionWithoutColor.displayColor, "#34C759")
    }

    func testUserActionFieldCountLabel() {
        let action = TestFixtures.testUserAction
        XCTAssertEqual(action.fieldCountLabel, "2 parameters")

        let actionNoParams = UserAction(
            id: UUID(),
            userId: UUID(),
            name: "Test",
            category: .custom,
            parameters: nil
        )
        XCTAssertEqual(actionNoParams.fieldCountLabel, "No parameters")

        let actionEmptyParams = UserAction(
            id: UUID(),
            userId: UUID(),
            name: "Test",
            category: .custom,
            parameters: ActionParameters(fields: [])
        )
        XCTAssertEqual(actionEmptyParams.fieldCountLabel, "No parameters")

        let actionSingleParam = UserAction(
            id: UUID(),
            userId: UUID(),
            name: "Test",
            category: .custom,
            parameters: ActionParameters(fields: [
                ActionField(key: "x", label: "X", type: .text)
            ])
        )
        XCTAssertEqual(actionSingleParam.fieldCountLabel, "1 parameter")
    }

    func testUserActionTemplateFlag() {
        let template = TestFixtures.testUserActionTemplate
        XCTAssertTrue(template.isTemplate)

        let regular = TestFixtures.testUserAction
        XCTAssertFalse(regular.isTemplate)
    }

    // MARK: - UserActionCreate

    func testUserActionCreate() {
        let payload = TestFixtures.testUserActionCreate
        XCTAssertEqual(payload.name, "Red Light Therapy")
        XCTAssertEqual(payload.category, .mindfulness)
        XCTAssertEqual(payload.iconKey, "sunrise.fill")
        XCTAssertEqual(payload.color, "#FF9500")
    }

    // MARK: - UserActionUpdate

    func testUserActionUpdate() {
        let payload = TestFixtures.testUserActionUpdate
        XCTAssertEqual(payload.name, "Updated Cold Plunge")
        XCTAssertEqual(payload.description, "Updated description")
        XCTAssertNil(payload.category)
        XCTAssertNil(payload.isActive)
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

    // MARK: - PaginatedUserActions

    func testPaginatedUserActions() {
        let page = TestFixtures.testPaginatedUserActions
        XCTAssertEqual(page.items.count, 1)
        XCTAssertEqual(page.total, 1)
        XCTAssertEqual(page.page, 1)
        XCTAssertEqual(page.pageSize, 20)
    }

    // MARK: - UserActionUsage

    func testUserActionUsageEntry() {
        let entry = UserActionUsageEntry(
            protocolId: UUID(),
            protocolName: "Test Protocol",
            protocolActionId: UUID()
        )
        XCTAssertEqual(entry.protocolName, "Test Protocol")
    }

    func testUserActionUsage() {
        let usage = TestFixtures.testUserActionUsage
        XCTAssertEqual(usage.count, 2)
        XCTAssertEqual(usage.first?.protocolName, "Morning Routine")
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

    func testUserActionCodingKeys() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try! encoder.encode(TestFixtures.testUserAction)
        let json = try! JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertNotNil(json["id"])
        XCTAssertNotNil(json["user_id"])
        XCTAssertEqual(json["is_template"] as? Bool, false)
        XCTAssertEqual(json["is_active"] as? Bool, true)
        XCTAssertEqual(json["protocol_count"] as? Int, 3)
    }
}
