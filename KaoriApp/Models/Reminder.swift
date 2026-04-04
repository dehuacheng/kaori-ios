import Foundation

struct Reminder: Codable, Identifiable {
    let id: Int
    let title: String
    let description: String?
    let dueDate: String
    let originalDate: String
    let itemType: String
    let isDone: Int
    let doneAt: String?
    let priority: Int
    let createdAt: String?
    let updatedAt: String?

    var isTodo: Bool { itemType == "todo" }
    var isCompleted: Bool { isDone != 0 }
    var isOverdue: Bool {
        let today = {
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd"
            return f.string(from: Date())
        }()
        return dueDate < today && !isCompleted
    }
}

struct ReminderCreateBody: Codable {
    let title: String
    let description: String?
    let dueDate: String?
    let itemType: String
    let priority: Int
}

struct ReminderUpdateBody: Codable {
    let title: String?
    let description: String?
    let dueDate: String?
    let itemType: String?
    let priority: Int?
}

struct ReminderPushBody: Codable {
    let newDate: String
}

struct ReminderDoneBody: Codable {
    let isDone: Bool
}

struct ReminderCreateResponse: Codable {
    let id: Int
}

struct ReminderUpdateResponse: Codable {
    let id: Int
}

struct ReminderDeleteResponse: Codable {
    let id: Int
    let deleted: Bool
}

struct ReminderPushResponse: Codable {
    let id: Int
    let newDate: String
}

struct ReminderDoneResponse: Codable {
    let id: Int
    let isDone: Bool
}
