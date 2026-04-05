import XCTest
@testable import KaoriApp

final class CodableRoundTripTests: XCTestCase {

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.keyEncodingStrategy = .convertToSnakeCase
        return e
    }()

    // MARK: - Meal

    func testMealDecode() throws {
        let json = """
        {
            "id": 1, "date": "2025-01-15", "meal_type": "lunch",
            "photo_path": "2025/01/15/abc.jpg", "photo_paths": null,
            "notes": null, "created_at": "2025-01-15 12:00:00",
            "updated_at": null, "description": "Chicken rice",
            "calories": 600, "protein_g": 40.0, "carbs_g": 70.0, "fat_g": 15.0,
            "is_estimated": 1, "analysis_status": "done", "confidence": "high"
        }
        """.data(using: .utf8)!
        let meal = try decoder.decode(Meal.self, from: json)
        XCTAssertEqual(meal.id, 1)
        XCTAssertEqual(meal.calories, 600)
        XCTAssertEqual(meal.mealType, "lunch")
    }

    func testMealMinimalFields() throws {
        let json = """
        {"id": 1, "date": "2025-01-15"}
        """.data(using: .utf8)!
        let meal = try decoder.decode(Meal.self, from: json)
        XCTAssertEqual(meal.id, 1)
        XCTAssertNil(meal.calories)
        XCTAssertNil(meal.mealType)
    }

    func testMealAllPhotoPathsMulti() throws {
        let json = """
        {
            "id": 1, "date": "2025-01-15",
            "photo_path": "a.jpg",
            "photo_paths": "[\\"a.jpg\\",\\"b.jpg\\"]"
        }
        """.data(using: .utf8)!
        let meal = try decoder.decode(Meal.self, from: json)
        XCTAssertEqual(meal.allPhotoPaths, ["a.jpg", "b.jpg"])
    }

    func testMealAllPhotoPathsSingle() throws {
        let json = """
        {"id": 1, "date": "2025-01-15", "photo_path": "a.jpg"}
        """.data(using: .utf8)!
        let meal = try decoder.decode(Meal.self, from: json)
        XCTAssertEqual(meal.allPhotoPaths, ["a.jpg"])
    }

    func testMealAllPhotoPathsEmpty() throws {
        let json = """
        {"id": 1, "date": "2025-01-15"}
        """.data(using: .utf8)!
        let meal = try decoder.decode(Meal.self, from: json)
        XCTAssertEqual(meal.allPhotoPaths, [])
    }

    // MARK: - WeightEntry

    func testWeightEntryDecode() throws {
        let json = """
        {"id": 1, "date": "2025-01-15", "weight_kg": 80.5, "notes": null, "created_at": "2025-01-15 08:00:00"}
        """.data(using: .utf8)!
        let entry = try decoder.decode(WeightEntry.self, from: json)
        XCTAssertEqual(entry.weightKg, 80.5)
    }

    func testWeightEntryRoundTrip() throws {
        let entry = WeightEntry(id: 1, date: "2025-01-15", weightKg: 80.5, notes: "Morning", createdAt: nil)
        let data = try encoder.encode(entry)
        let decoded = try decoder.decode(WeightEntry.self, from: data)
        XCTAssertEqual(decoded.id, entry.id)
        XCTAssertEqual(decoded.weightKg, entry.weightKg)
    }

    // MARK: - NutritionTotals

    func testNutritionTotalsRoundTrip() throws {
        let json = """
        {"total_cal": 2100, "total_protein": 128.0, "total_carbs": 240.0, "total_fat": 70.0}
        """.data(using: .utf8)!
        let totals = try decoder.decode(NutritionTotals.self, from: json)
        XCTAssertEqual(totals.totalCal, 2100)
        XCTAssertEqual(totals.totalProtein, 128.0)
    }

    // MARK: - Profile

    func testProfileDecode() throws {
        let json = """
        {
            "id": 1, "display_name": "User", "height_cm": 180.0, "gender": "male",
            "birth_date": "1994-01-15", "protein_per_kg": 1.6, "carbs_per_kg": 3.0,
            "calorie_adjustment_pct": 0, "llm_mode": "claude_cli", "notes": null,
            "unit_body_weight": "kg", "unit_height": "cm", "unit_exercise_weight": "lb",
            "age": 31, "latest_weight_kg": 80.0, "bmr": 1749,
            "estimated_tdee": 2098, "target_calories": 2098,
            "target_protein_g": 128, "target_carbs_g": 240
        }
        """.data(using: .utf8)!
        let profile = try decoder.decode(Profile.self, from: json)
        XCTAssertEqual(profile.displayName, "User")
        XCTAssertEqual(profile.heightCm, 180.0)
        XCTAssertEqual(profile.exerciseWeightUnit, .lb)
        XCTAssertEqual(profile.bodyWeightUnit, .kg)
    }

    // MARK: - Snake case decoding

    func testSnakeCaseDecoding() throws {
        // Verify that convertFromSnakeCase handles all model fields correctly
        let json = """
        {"id": 1, "date": "2025-01-15", "weight_kg": 80.5, "created_at": "2025-01-15 08:00:00"}
        """.data(using: .utf8)!
        let entry = try decoder.decode(WeightEntry.self, from: json)
        XCTAssertEqual(entry.weightKg, 80.5)
        XCTAssertEqual(entry.createdAt, "2025-01-15 08:00:00")
    }
}
