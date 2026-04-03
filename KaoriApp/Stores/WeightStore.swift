import Foundation

@Observable
class WeightStore {
    var weights: [WeightEntry] = []
    var latest: Double?
    var avg7d: Double?
    var deltaWeek: Double?
    var isLoading = false
    var error: String?

    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    @MainActor
    func load(force: Bool = false) async {
        guard force || weights.isEmpty else { return }
        isLoading = true
        error = nil
        do {
            let response: WeightResponse = try await api.get("/api/weight")
            weights = response.weightsAsc
            latest = response.latest
            avg7d = response.avg7d
            deltaWeek = response.deltaWeek
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func log(date: String?, weightKg: Double, notes: String?) async throws {
        let body = WeightCreate(weightDate: date, weightKg: weightKg, notes: notes)
        let _: WeightCreateResponse = try await api.post("/api/weight", body: body)
        await load(force: true)
    }

    func update(id: Int, weightKg: Double, notes: String?) async throws {
        let body = WeightUpdateBody(weightKg: weightKg, notes: notes)
        let _: WeightUpdateResponse = try await api.put("/api/weight/\(id)", body: body)
        await load(force: true)
    }

    func delete(id: Int) async throws {
        let _: WeightDeleteResponse = try await api.delete("/api/weight/\(id)")
        await load(force: true)
    }

    func bulkImport(entries: [BulkImportEntry]) async throws -> BulkImportResponse {
        let body = BulkImportRequest(entries: entries)
        return try await api.post("/api/weight/bulk-import", body: body)
    }
}
