import XCTest
@testable import KaoriApp

final class UnitConverterTests: XCTestCase {

    // MARK: - Weight conversion

    func testDisplayWeightKg() {
        XCTAssertEqual(UnitConverter.displayWeight(80.0, unit: .kg), 80.0)
    }

    func testDisplayWeightLb() {
        let result = UnitConverter.displayWeight(80.0, unit: .lb)
        XCTAssertEqual(result, 80.0 / 0.45359237, accuracy: 0.01)
    }

    func testToMetricWeightKg() {
        XCTAssertEqual(UnitConverter.toMetricWeight(80.0, unit: .kg), 80.0)
    }

    func testToMetricWeightLb() {
        let result = UnitConverter.toMetricWeight(176.37, unit: .lb)
        XCTAssertEqual(result, 176.37 * 0.45359237, accuracy: 0.01)
    }

    func testWeightRoundTrip() {
        let original = 80.0
        let inLb = UnitConverter.displayWeight(original, unit: .lb)
        let backToKg = UnitConverter.toMetricWeight(inLb, unit: .lb)
        XCTAssertEqual(backToKg, original, accuracy: 0.001)
    }

    // MARK: - Height conversion

    func testDisplayHeightCm() {
        XCTAssertEqual(UnitConverter.displayHeight(180.0, unit: .cm), 180.0)
    }

    func testDisplayHeightIn() {
        let result = UnitConverter.displayHeight(180.0, unit: .in)
        XCTAssertEqual(result, 180.0 / 2.54, accuracy: 0.01)
    }

    func testCmToFeetInches() {
        // 177.8 cm ≈ 70 inches = 5 feet 10 inches
        let (feet, inches) = UnitConverter.cmToFeetInches(177.8)
        XCTAssertEqual(feet, 5)
        XCTAssertEqual(inches, 10)
    }

    func testFeetInchesToCm() {
        let cm = UnitConverter.feetInchesToCm(feet: 5, inches: 10)
        XCTAssertEqual(cm, Double(5 * 12 + 10) * 2.54, accuracy: 0.01)
    }

    func testHeightRoundTrip() {
        let original = 177.8
        let (ft, inc) = UnitConverter.cmToFeetInches(original)
        let backToCm = UnitConverter.feetInchesToCm(feet: ft, inches: inc)
        XCTAssertEqual(backToCm, original, accuracy: 2.54) // within 1 inch
    }

    // MARK: - Formatting

    func testFormatBodyWeightKg() {
        let result = UnitConverter.formatBodyWeight(80.0, unit: .kg)
        XCTAssertEqual(result, "80.0 kg")
    }

    func testFormatBodyWeightLb() {
        let result = UnitConverter.formatBodyWeight(80.0, unit: .lb)
        XCTAssertTrue(result.hasSuffix(" lb"))
        XCTAssertTrue(result.contains("176"))
    }

    func testFormatHeightCm() {
        XCTAssertEqual(UnitConverter.formatHeight(180.0, unit: .cm), "180 cm")
    }

    func testFormatHeightIn() {
        let result = UnitConverter.formatHeight(177.8, unit: .in)
        XCTAssertEqual(result, "5'10\"")
    }

    func testFormatWeightDelta() {
        let result = UnitConverter.formatWeightDelta(2.0, unit: .kg)
        XCTAssertEqual(result, "+2.0 kg")
    }

    func testFormatWeightDeltaNegative() {
        let result = UnitConverter.formatWeightDelta(-1.5, unit: .kg)
        XCTAssertEqual(result, "-1.5 kg")
    }

    func testDisplayWeightString() {
        XCTAssertEqual(UnitConverter.displayWeightString(80.0, unit: .kg), "80.0")
    }

    // MARK: - Edge cases

    func testZeroWeight() {
        XCTAssertEqual(UnitConverter.displayWeight(0.0, unit: .kg), 0.0)
        XCTAssertEqual(UnitConverter.displayWeight(0.0, unit: .lb), 0.0)
    }

    func testVeryLargeWeight() {
        let result = UnitConverter.displayWeight(500.0, unit: .lb)
        XCTAssertTrue(result.isFinite)
    }
}
