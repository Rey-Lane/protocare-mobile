//
//  ActionItemEnrichmentTests.swift
//  ProtocareTests
//
//  Unified action model (Step 25a): substance enrichment is gone —
//  Action → ActionItem conversion is direct. These tests cover the
//  unified conversion.
//

import XCTest
@testable import Protocare

final class ActionItemEnrichmentTests: XCTestCase {

    // MARK: - Action → ActionItem (unified)

    func testToActionItem_carriesUnifiedFields() {
        let action = Action(
            id: "action-1",
            name: "Vitamin D3",
            description: "Morning supplement",
            category: .supplement,
            modality: .oral,
            defaultParameters: [
                "serving": AnyCodable(1),
                "serving_unit": AnyCodable("capsule")
            ],
            substanceId: "sub-1",
            isLibrary: false
        )

        let item = action.toActionItem()

        XCTAssertEqual(item.id, "action-1")
        XCTAssertEqual(item.displayName, "Vitamin D3")
        XCTAssertEqual(item.category, .supplement)
        XCTAssertEqual(item.modality, .oral)
        XCTAssertEqual(item.isLibrary, false)
        XCTAssertEqual(item.substanceId, "sub-1")
        XCTAssertNil(item.substance)
        XCTAssertEqual(item.defaultParameters?["serving"], AnyCodable(1))
    }

    func testToActionItem_volumeFromDefaultParameters() {
        let action = Action(
            id: "action-2",
            name: "Minoxidil",
            category: .hair,
            modality: .topical,
            defaultParameters: [
                "volume_amount": AnyCodable(5.0),
                "volume_unit": AnyCodable("spray")
            ]
        )

        let item = action.toActionItem()

        XCTAssertEqual(item.volume?.amount, 5.0)
        XCTAssertEqual(item.volume?.unit, .spray)
        XCTAssertNil(item.durationSeconds)
    }

    func testToActionItem_durationFromDefaultParameters() {
        let action = Action(
            id: "action-3",
            name: "Meditation",
            category: .mindfulness,
            modality: .activity,
            defaultParameters: ["duration_seconds": AnyCodable(600)]
        )

        let item = action.toActionItem()

        XCTAssertEqual(item.durationSeconds, 600)
        XCTAssertNil(item.volume)
    }

    func testToActionItem_binaryActionHasNoVolumeOrDuration() {
        let action = Action(
            id: "action-4",
            name: "Floss",
            category: .custom,
            modality: .hygiene
        )

        let item = action.toActionItem()

        XCTAssertNil(item.volume)
        XCTAssertNil(item.durationSeconds)
        XCTAssertNil(item.defaultParameters)
        XCTAssertEqual(item.tagLabel, "—")
    }

    // MARK: - Array conversion

    func testArrayToActionItems_mapsAll() {
        let actions = [
            Action(id: "a-1", name: "One", category: .skincare),
            Action(id: "a-2", name: "Two", category: .supplement)
        ]

        let items = actions.toActionItems()

        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(items[0].id, "a-1")
        XCTAssertEqual(items[1].id, "a-2")
        XCTAssertEqual(Set(items.map(\.category)), Set([.skincare, .supplement]))
    }
}
