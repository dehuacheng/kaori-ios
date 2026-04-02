import Foundation

@Observable
class MealStore {
    var meals: [Meal] = []
    var totals: NutritionTotals?
    var currentDate: String = MealStore.todayString()
    var isLoading = false
    var error: String?

    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    static func todayString() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    var currentDateDisplay: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        guard let d = f.date(from: currentDate) else { return currentDate }
        f.dateStyle = .medium
        return f.string(from: d)
    }

    var isToday: Bool {
        currentDate == Self.todayString()
    }

    var hasPendingAnalysis: Bool {
        meals.contains { $0.analysisStatus == "pending" || $0.analysisStatus == "analyzing" }
    }

    func navigateDay(offset: Int) {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        guard let d = f.date(from: currentDate),
              let next = Calendar.current.date(byAdding: .day, value: offset, to: d) else { return }
        currentDate = f.string(from: next)
    }

    @MainActor
    func loadMeals() async {
        isLoading = true
        error = nil
        do {
            let response: MealListResponse = try await api.get("/api/meals", query: ["date": currentDate])
            meals = response.meals
            totals = response.totals
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func createMeal(
        description: String?,
        photo: Data?,
        mealType: String,
        notes: String?
    ) async throws -> CreateMealResponse {
        var fields: [String: String] = ["meal_type": mealType]
        if let description, !description.isEmpty { fields["description"] = description }
        if let notes, !notes.isEmpty { fields["notes"] = notes }
        fields["meal_date"] = currentDate

        let response: CreateMealResponse = try await api.postMultipart(
            "/api/meals", fields: fields, imageData: photo
        )
        return response
    }

    @MainActor
    func getMeal(_ id: Int) async throws -> Meal {
        try await api.get("/api/meals/\(id)")
    }

    func updateMeal(_ id: Int, body: MealUpdate) async throws -> UpdateMealResponse {
        try await api.put("/api/meals/\(id)", body: body)
    }

    func deleteMeal(_ id: Int) async throws -> DeleteMealResponse {
        try await api.delete("/api/meals/\(id)")
    }

    func getAnalyses(_ mealId: Int) async throws -> AnalysesResponse {
        try await api.get("/api/meals/\(mealId)/analyses")
    }

    func reprocess(_ mealId: Int) async throws -> ReprocessResponse {
        try await api.post("/api/meals/\(mealId)/reprocess")
    }

    func activateAnalysis(mealId: Int, analysisId: Int) async throws {
        let _: [String: AnyCodable] = try await api.post(
            "/api/meals/\(mealId)/analyses/\(analysisId)/activate"
        )
    }
}

// Helper for decoding arbitrary JSON responses
struct AnyCodable: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let s = try? container.decode(String.self) { _ = s }
        else if let i = try? container.decode(Int.self) { _ = i }
        else if let d = try? container.decode(Double.self) { _ = d }
        else if let b = try? container.decode(Bool.self) { _ = b }
    }
    func encode(to encoder: Encoder) throws {}
}
