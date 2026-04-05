import XCTest
import HealthKit
@testable import KaoriApp

/// Regression test for Bug 8: HealthKit activity type mapping was incomplete.
/// Seven types (stairClimbing, elliptical, rowing, flexibility, mixedCardio, dance, jumpRope)
/// were missing and defaulted to "activity.other" when imported from Apple Health.
final class HealthKitMappingTests: XCTestCase {

    // All known activity type strings and their expected HKWorkoutActivityType
    private let knownMappings: [(String, HKWorkoutActivityType)] = [
        ("traditionalStrengthTraining", .traditionalStrengthTraining),
        ("functionalStrengthTraining", .functionalStrengthTraining),
        ("running", .running),
        ("cycling", .cycling),
        ("swimming", .swimming),
        ("yoga", .yoga),
        ("pilates", .pilates),
        ("hiking", .hiking),
        ("crossTraining", .crossTraining),
        ("highIntensityIntervalTraining", .highIntensityIntervalTraining),
        ("coreTraining", .coreTraining),
        ("walking", .walking),
        // Bug 8: these 7 were previously missing
        ("stairClimbing", .stairClimbing),
        ("elliptical", .elliptical),
        ("rowing", .rowing),
        ("flexibility", .flexibility),
        ("mixedCardio", .mixedCardio),
        ("dance", .dance),
        ("jumpRope", .jumpRope),
    ]

    // MARK: - String → HKWorkoutActivityType

    func testAllKnownTypesMapCorrectly() {
        for (string, expected) in knownMappings {
            let result = HealthKitManager.workoutActivityType(from: string)
            XCTAssertEqual(result, expected, "'\(string)' should map to \(expected)")
        }
    }

    func testPreviouslyMissingStairClimbing() {
        XCTAssertEqual(
            HealthKitManager.workoutActivityType(from: "stairClimbing"),
            .stairClimbing
        )
    }

    func testPreviouslyMissingElliptical() {
        XCTAssertEqual(
            HealthKitManager.workoutActivityType(from: "elliptical"),
            .elliptical
        )
    }

    func testPreviouslyMissingRowing() {
        XCTAssertEqual(
            HealthKitManager.workoutActivityType(from: "rowing"),
            .rowing
        )
    }

    func testPreviouslyMissingFlexibility() {
        XCTAssertEqual(
            HealthKitManager.workoutActivityType(from: "flexibility"),
            .flexibility
        )
    }

    func testPreviouslyMissingMixedCardio() {
        XCTAssertEqual(
            HealthKitManager.workoutActivityType(from: "mixedCardio"),
            .mixedCardio
        )
    }

    func testPreviouslyMissingDance() {
        XCTAssertEqual(
            HealthKitManager.workoutActivityType(from: "dance"),
            .dance
        )
    }

    func testPreviouslyMissingJumpRope() {
        XCTAssertEqual(
            HealthKitManager.workoutActivityType(from: "jumpRope"),
            .jumpRope
        )
    }

    func testUnknownTypeDefaultsToStrengthTraining() {
        XCTAssertEqual(
            HealthKitManager.workoutActivityType(from: "unknownActivity"),
            .traditionalStrengthTraining
        )
    }

    func testNilDefaultsToStrengthTraining() {
        XCTAssertEqual(
            HealthKitManager.workoutActivityType(from: nil),
            .traditionalStrengthTraining
        )
    }

    // MARK: - HKWorkoutActivityType → String

    func testActivityTypeStringRoundTrip() {
        for (string, hkType) in knownMappings {
            let result = HealthKitManager.activityTypeString(from: hkType)
            XCTAssertEqual(result, string, "Round-trip failed for \(string)")
        }
    }

    // MARK: - Display names

    func testAllMappedTypesHaveDisplayName() {
        for (_, hkType) in knownMappings {
            let name = HealthKitManager.activityDisplayName(from: hkType)
            XCTAssertFalse(name.isEmpty, "\(hkType) should have a display name")
            XCTAssertNotEqual(name, "Workout", "\(hkType) should have a specific name, not generic 'Workout'")
        }
    }
}
