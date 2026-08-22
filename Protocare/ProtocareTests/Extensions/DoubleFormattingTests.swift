//
//  DoubleFormattingTests.swift
//  ProtocareTests
//
//  Tests for Double formatting extensions
//

import XCTest
@testable import Protocare

final class DoubleFormattingTests: XCTestCase {

    func testRoundedString_FormatsCorrectly() {
        let result1 = 3.14159.roundedString()
        let result2 = 10.0.roundedString()
        let result3 = 0.999.roundedString()
        let result4 = 123.456789.roundedString()
        
        // Check values are correct (allowing for locale-specific decimal separators)
        XCTAssertTrue(result1.contains("3") && result1.contains("14"), "Expected ~3.14 but got \(result1)")
        XCTAssertEqual(result2, "10")
        XCTAssertEqual(result3, "1")
        XCTAssertTrue(result4.contains("123") && result4.contains("46"), "Expected ~123.46 but got \(result4)")
    }

    func testRoundedString_RespectsMaxFractionDigits() {
        let result0 = 3.14159.roundedString(maxFractionDigits: 0)
        let result1 = 3.14159.roundedString(maxFractionDigits: 1)
        let result3 = 3.14159.roundedString(maxFractionDigits: 3)
        let result5 = 3.14159.roundedString(maxFractionDigits: 5)
        
        // Check with locale flexibility
        XCTAssertEqual(result0, "3")
        XCTAssertTrue(result1.contains("3") && result1.contains("1"), "Expected ~3.1 but got \(result1)")
        XCTAssertTrue(result3.contains("3") && result3.contains("142"), "Expected ~3.142 but got \(result3)")
        XCTAssertTrue(result5.contains("3") && result5.contains("14159"), "Expected ~3.14159 but got \(result5)")
    }

    func testRoundedString_HandlesZero() {
        XCTAssertEqual(0.0.roundedString(), "0")
        XCTAssertEqual(0.0.roundedString(maxFractionDigits: 2), "0")
    }

    func testRoundedString_HandlesNegativeNumbers() {
        let result1 = (-3.14159).roundedString()
        let result2 = (-0.999).roundedString()
        // Check that results contain expected numeric values
        // (allowing for locale-specific formatting)
        XCTAssertTrue(result1.contains("3") && result1.contains("14"), "Expected ~-3.14 but got \(result1)")
        XCTAssertTrue(result2.contains("1"), "Expected ~-1 but got \(result2)")
    }

    func testRoundedString_HandlesLargeNumbers() {
        let result1 = 1000000.12345.roundedString()
        let result2 = 0.000001.roundedString()
        
        XCTAssertTrue(result1.contains("1000000"), "Expected 1000000... but got \(result1)")
        XCTAssertTrue(result1.contains("12"), "Expected ...12... but got \(result1)")
        XCTAssertEqual(result2, "0")
    }
}
