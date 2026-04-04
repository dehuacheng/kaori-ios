import Foundation

struct MealListResponse: Codable {
    let date: String
    let meals: [Meal]
    let totals: NutritionTotals
}

struct NutritionTotals: Codable {
    let totalCal: Int
    let totalProtein: Double
    let totalCarbs: Double
    let totalFat: Double
}

struct Meal: Codable, Identifiable {
    let id: Int
    let date: String
    let mealType: String?
    let photoPath: String?
    let photoPaths: String?  // JSON array of paths, e.g. "[\"a.jpg\",\"b.jpg\"]"
    let notes: String?
    let createdAt: String?
    let updatedAt: String?
    let description: String?
    let calories: Int?
    let proteinG: Double?
    let carbsG: Double?
    let fatG: Double?
    let isEstimated: Int?
    let analysisStatus: String?
    let confidence: String?

    /// All photo paths for this meal. Falls back to single photoPath if photoPaths is absent.
    var allPhotoPaths: [String] {
        if let photoPaths,
           let data = photoPaths.data(using: .utf8),
           let paths = try? JSONDecoder().decode([String].self, from: data),
           !paths.isEmpty {
            return paths
        }
        if let photoPath { return [photoPath] }
        return []
    }
}

struct CreateMealResponse: Codable {
    let id: Int
    let date: String
    let analysisStatus: String
}

struct UpdateMealResponse: Codable {
    let id: Int
    let date: String
}

struct DeleteMealResponse: Codable {
    let id: Int
    let date: String?
}

struct MealUpdate: Codable {
    var mealDate: String?
    var mealType: String?
    var description: String?
    var calories: Int?
    var proteinG: Double?
    var carbsG: Double?
    var fatG: Double?
    var notes: String?
}

struct AnalysesResponse: Codable {
    let mealId: Int
    let analyses: [Analysis]
}

struct Analysis: Codable, Identifiable {
    let id: Int
    let mealId: Int
    let status: String
    let isActive: Int
    let llmBackend: String?
    let model: String?
    let description: String?
    let calories: Int?
    let proteinG: Double?
    let carbsG: Double?
    let fatG: Double?
    let confidence: String?
    let createdAt: String?
    let completedAt: String?
}

struct ReprocessResponse: Codable {
    let mealId: Int
    let analysisId: Int
    let analysisStatus: String
}
