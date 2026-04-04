import Foundation

struct Post: Codable, Identifiable {
    let id: Int
    let date: String
    let title: String?
    let content: String
    let photoPath: String?
    let photoPaths: String?
    let isPinned: Int
    let createdAt: String?
    let updatedAt: String?

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

struct PostCreateBody: Codable {
    let date: String?
    let title: String?
    let content: String
}

struct PostUpdateBody: Codable {
    let title: String?
    let content: String?
    let isPinned: Bool?
}

struct PostCreateResponse: Codable {
    let id: Int
    let date: String?
}

struct PostUpdateResponse: Codable {
    let id: Int
}

struct PostDeleteResponse: Codable {
    let id: Int
    let deleted: Bool
}
