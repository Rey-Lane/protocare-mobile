//
//  ActionItemEnrichmentTests.swift
//  ProtocareTests
//
//  Tests for ActionItem enrichment logic
//

import XCTest
@testable import Protocare

final class ActionItemEnrichmentTests: XCTestCase {

    // MARK: - Test Data

    let vitaminC = Substance(
        id: "vitamin-c-id",
        name: "Vitamin C",
        type: .oral,
        unit: .capsule,
        notes: "Antioxidant"
    )

    let retinol = Substance(
        id: "retinol-id",
        name: "Retinol",
        type: .topical,
        unit: .mg,
        notes: "Vitamin A"
    )

    // MARK: - resolvingSubstance Tests

    func testResolvingSubstance_ReturnsActionSubstanceIfPresent() {
        let action = ActionItem(
            id: "test-action-id",
            name: "Test Action",
            substanceId: retinol.id,
            substance: vitaminC  // Already has substance
        )

        let resolved = action.resolvingSubstance(from: [retinol, vitaminC])
        XCTAssertEqual(resolved?.id, vitaminC.id)
    }

    func testResolvingSubstance_LooksUpByIdWhenNoSubstance() {
        let action = ActionItem(
            id: "test-action-id",
            name: "Test Action",
            substanceId: vitaminC.id,
            substance: nil  // No substance attached
        )

        let resolved = action.resolvingSubstance(from: [vitaminC, retinol])
        XCTAssertEqual(resolved?.id, vitaminC.id)
    }

    func testResolvingSubstance_ReturnsNilWhenNotFound() {
        let unknownId = "unknown-id"
        let action = ActionItem(
            id: "test-action-id",
            name: "Test Action",
            substanceId: unknownId,
            substance: nil
        )

        let resolved = action.resolvingSubstance(from: [vitaminC, retinol])
        XCTAssertNil(resolved)
    }

    // MARK: - enriched Tests

    func testEnriched_CreatesNewInstanceWithResolvedSubstance() {
        let action = ActionItem(
            id: "test-action-id",
            name: "Test Action",
            substanceId: vitaminC.id,
            substance: nil,
            volume: Quantity(amount: 2.5, unit: .ml),
            durationSeconds: 60
        )

        let enriched = action.enriched(with: [vitaminC, retinol])

        XCTAssertEqual(enriched.id, action.id)
        XCTAssertEqual(enriched.name, action.name)
        XCTAssertEqual(enriched.substance?.id, vitaminC.id)
        XCTAssertEqual(enriched.volume?.amount, 2.5)
    }

    func testEnriched_KeepsOriginalSubstanceIfPresent() {
        let action = ActionItem(
            id: "test-action-id",
            name: "Test Action",
            substanceId: retinol.id,  // Different ID
            substance: vitaminC  // But has this substance
        )

        let enriched = action.enriched(with: [retinol])

        XCTAssertEqual(enriched.substance?.id, vitaminC.id)
    }

    // MARK: - Array Extension Tests

    func testArrayEnriched_EnrichesAllActions() {
        let action1 = ActionItem(
            id: "action-1-id",
            name: "Action 1",
            substanceId: vitaminC.id,
            substance: nil
        )
        let action2 = ActionItem(
            id: "action-2-id",
            name: "Action 2",
            substanceId: retinol.id,
            substance: nil
        )

        let actions = [action1, action2]
        let enriched = actions.enriched(with: [vitaminC, retinol])

        XCTAssertEqual(enriched.count, 2)
        XCTAssertEqual(enriched[0].substance?.id, vitaminC.id)
        XCTAssertEqual(enriched[1].substance?.id, retinol.id)
    }
}
