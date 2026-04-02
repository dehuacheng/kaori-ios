import Foundation

struct WeightResponse: Codable {
    let weightsAsc: [WeightEntry]
    let latest: Double?
    let avg7d: Double?
    let deltaWeek: Double?
}

struct WeightEntry: Codable, Identifiable {
    let id: Int
    let date: String
    let weightKg: Double
    let notes: String?
    let createdAt: String?
}

struct WeightCreate: Codable {
    let weightDate: String?
    let weightKg: Double
    let notes: String?
}

struct WeightUpdateBody: Codable {
    let weightKg: Double
    let notes: String?
}

struct WeightCreateResponse: Codable {
    let id: Int
    let date: String?
    let weightKg: Double
}

struct WeightUpdateResponse: Codable {
    let id: Int
    let weightKg: Double
}

struct WeightDeleteResponse: Codable {
    let id: Int
    let deleted: Bool
}

struct BulkImportEntry: Codable {
    let date: String
    let weightKg: Double
    let notes: String?
}

struct BulkImportRequest: Codable {
    let entries: [BulkImportEntry]
}

struct BulkImportResponse: Codable {
    let imported: Int
    let skipped: Int
}
