import Foundation

struct Document: Codable, Identifiable {
    let id: Int
    let filename: String
    let originalType: String
    let pageCount: Int?
    let extractedText: String?
    let summary: String?
    let status: String?
    let errorMessage: String?
    let createdAt: String?
}

struct DocumentUploadResponse: Codable {
    let id: Int
    let filename: String
    let status: String
    let pageCount: Int?
}

struct DocumentDeleteResponse: Codable {
    let id: Int
    let deleted: Bool
}
