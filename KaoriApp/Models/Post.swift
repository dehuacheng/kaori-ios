import Foundation

struct Post: Codable, Identifiable {
    let id: Int
    let date: String
    let title: String?
    let content: String
    let isPinned: Int
    let createdAt: String?
    let updatedAt: String?
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
