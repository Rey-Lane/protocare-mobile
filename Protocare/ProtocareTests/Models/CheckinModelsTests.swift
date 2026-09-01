import XCTest
@testable import Protocare

/// Step 24 (unified action model): CheckIn wire models + adaptive check-in form logic.
final class CheckinModelsTests: XCTestCase {

    // MARK: - Wire decoding

    func test_checkIn_decodesBackendShape() throws {
        // Backend serializes Decimal quantity as a JSON string ("2.5").
        let json = """
        {
          "protocol_action_id": "pa-1",
          "ts": "2026-09-01T10:00:00Z",
          "quantity": "2.5",
          "unit": "ml",
          "duration_seconds": 320,
          "completed": true,
          "id": "c-1",
          "user_id": "u-1"
        }
        """.data(using: .utf8)!

        let checkin = try JSONDecoder().decode(CheckIn.self, from: json)
        XCTAssertEqual(checkin.protocolActionId, "pa-1")
        XCTAssertEqual(checkin.quantity, 2.5)
        XCTAssertEqual(checkin.unit, .ml)
        XCTAssertEqual(checkin.durationSeconds, 320)
        XCTAssertTrue(checkin.completed)
        XCTAssertEqual(checkin.id, "c-1")
    }

    func test_checkIn_decodesNumericQuantityAndOmitsDefaults() throws {
        let json = """
        {
          "protocol_action_id": "pa-1",
          "ts": "2026-09-01T10:00:00Z",
          "quantity": 5,
          "id": "c-2"
        }
        """.data(using: .utf8)!

        let checkin = try JSONDecoder().decode(CheckIn.self, from: json)
        XCTAssertEqual(checkin.quantity, 5)
        XCTAssertNil(checkin.unit)
        XCTAssertNil(checkin.durationSeconds)
        // `completed` defaults to true when absent.
        XCTAssertTrue(checkin.completed)
    }

    func test_protocolCheckinCreate_encodesBackendPayloadShape() throws {
        let payload = ProtocolCheckinCreate(
            protocolId: "p-1",
            protocolActionId: "pa-1",
            ts: "2026-09-01T10:00:00Z",
            quantity: 7,
            unit: .spray,
            durationSeconds: nil,
            completed: true
        )

        let data = try JSONEncoder().encode(payload)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertEqual(json["protocol_action_id"] as? String, "pa-1")
        XCTAssertEqual(json["ts"] as? String, "2026-09-01T10:00:00Z")
        XCTAssertEqual(json["quantity"] as? Double, 7)
        XCTAssertEqual(json["unit"] as? String, "spray")
        XCTAssertNil(json["duration_seconds"])
        XCTAssertEqual(json["completed"] as? Bool, true)
        // protocol_id must NOT be encoded — it rides the URL path, backend has no such field.
        XCTAssertNil(json["protocol_id"])
    }

    func test_dailyActionStatus_decodesUnifiedShape() throws {
        let json = """
        {
          "protocol_action_id": "pa-1",
          "action_id": "a-1",
          "action_name": "Minoxidil",
          "description": "5% topical solution",
          "scheduled_time": "21:30",
          "is_completed": false,
          "completed_at": null,
          "checkin_id": null,
          "quantity": null,
          "unit": null,
          "duration_seconds": null,
          "completed": true,
          "default_parameters": {"volume_amount": 7.0, "volume_unit": "SPRAY"},
          "user_parameters": {"volume_amount": 5.0}
        }
        """.data(using: .utf8)!

        let status = try JSONDecoder().decode(DailyActionStatus.self, from: json)
        XCTAssertEqual(status.actionId, "a-1")
        XCTAssertNil(status.userParameters?["volume_amount"] == nil ? nil : nil)
        XCTAssertEqual(status.checkInFormKind, .substance)
        // user override wins over default
        XCTAssertEqual(status.defaultQuantity?.amount, 5.0)
        // UPPERCASE seed unit is matched case-insensitively
        XCTAssertEqual(status.defaultQuantity?.unit, .spray)
    }

    // MARK: - merge_params parity with backend

    func test_mergeParams_overrideWinsAndNullDeletes() {
        let defaults: [String: AnyCodable] = [
            "volume_amount": AnyCodable(7.0),
            "volume_unit": AnyCodable("spray")
        ]
        let override: [String: AnyCodable] = [
            "volume_amount": AnyCodable(5.0),
            "volume_unit": AnyCodable(NSNull())
        ]

        let merged = mergeParams(defaults, overriding: override)

        XCTAssertEqual(merged["volume_amount"], AnyCodable(5.0))
        // null override removes the key entirely (backend merge_params semantics)
        XCTAssertNil(merged["volume_unit"])
    }

    func test_mergeParams_nilInputsYieldEmpty() {
        let merged = mergeParams(nil, overriding: nil)
        XCTAssertTrue(merged.isEmpty)
    }

    // MARK: - Adaptive form resolution

    func test_formKind_substanceForVolumeAmount() {
        let params: [String: AnyCodable] = ["volume_amount": AnyCodable(7.0), "volume_unit": AnyCodable("spray")]
        XCTAssertEqual(CheckInFormResolver.formKind(for: params), .substance)
    }

    func test_formKind_substanceForServing() {
        let params: [String: AnyCodable] = ["serving": AnyCodable(2), "serving_unit": AnyCodable("capsule")]
        XCTAssertEqual(CheckInFormResolver.formKind(for: params), .substance)
    }

    func test_formKind_substanceForDosageMg() {
        let params: [String: AnyCodable] = ["dosage_mg": AnyCodable(50)]
        XCTAssertEqual(CheckInFormResolver.formKind(for: params), .substance)
    }

    func test_formKind_timedActivityForDurationSeconds() {
        let params: [String: AnyCodable] = ["duration_seconds": AnyCodable(600)]
        XCTAssertEqual(CheckInFormResolver.formKind(for: params), .timedActivity)
    }

    func test_formKind_binaryForEmptyParameters() {
        XCTAssertEqual(CheckInFormResolver.formKind(for: nil), .binary)
        XCTAssertEqual(CheckInFormResolver.formKind(for: [:]), .binary)
    }

    func test_formKind_binaryForUnrecognizedKeys() {
        let params: [String: AnyCodable] = ["notes": AnyCodable("hello")]
        XCTAssertEqual(CheckInFormResolver.formKind(for: params), .binary)
    }

    func test_defaultQuantity_prefersVolumeAmountOverServing() {
        let params: [String: AnyCodable] = [
            "volume_amount": AnyCodable(0.5),
            "volume_unit": AnyCodable("ml"),
            "serving": AnyCodable(9),
            "serving_unit": AnyCodable("tablet")
        ]
        let quantity = CheckInFormResolver.defaultQuantity(in: params)
        XCTAssertEqual(quantity?.amount, 0.5)
        XCTAssertEqual(quantity?.unit, .ml)
    }

    func test_defaultQuantity_requiresUnit() {
        let params: [String: AnyCodable] = ["volume_amount": AnyCodable(2.0)]
        XCTAssertNil(CheckInFormResolver.defaultQuantity(in: params))
    }

    func test_defaultDurationSeconds_readsMergedValue() {
        let actionDefault: [String: AnyCodable] = ["duration_seconds": AnyCodable(300)]
        let userOverride: [String: AnyCodable] = ["duration_seconds": AnyCodable(900)]

        let effective = CheckInFormResolver.effectiveParameters(
            actionDefault: actionDefault,
            userOverride: userOverride
        )
        XCTAssertEqual(CheckInFormResolver.defaultDurationSeconds(in: effective), 900)
    }

    func test_unitValue_caseInsensitiveUppercaseSeedUnits() {
        let params: [String: AnyCodable] = ["volume_unit": AnyCodable("TABLET")]
        XCTAssertEqual(params.unitValue(forKey: "volume_unit"), .tablet)
    }
}
