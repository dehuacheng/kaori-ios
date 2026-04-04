import Foundation

@Observable
class ReminderStore {
    var reminders: [Reminder] = []
    var isLoading = false
    var error: String?

    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    @MainActor
    func load(force: Bool = false) async {
        guard force || reminders.isEmpty else { return }
        isLoading = true
        error = nil
        do {
            let result: [Reminder] = try await api.get("/api/reminders")
            reminders = result
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func create(title: String, description: String?, dueDate: String?, itemType: String, priority: Int) async throws {
        let body = ReminderCreateBody(title: title, description: description, dueDate: dueDate, itemType: itemType, priority: priority)
        let _: ReminderCreateResponse = try await api.post("/api/reminders", body: body)
        await load(force: true)
    }

    func update(id: Int, title: String?, description: String?, dueDate: String?, itemType: String?, priority: Int?) async throws {
        let body = ReminderUpdateBody(title: title, description: description, dueDate: dueDate, itemType: itemType, priority: priority)
        let _: ReminderUpdateResponse = try await api.put("/api/reminders/\(id)", body: body)
        await load(force: true)
    }

    func markDone(id: Int, isDone: Bool) async throws {
        let body = ReminderDoneBody(isDone: isDone)
        let _: ReminderDoneResponse = try await api.post("/api/reminders/\(id)/done", body: body)
        await load(force: true)
    }

    func push(id: Int, newDate: String) async throws {
        let body = ReminderPushBody(newDate: newDate)
        let _: ReminderPushResponse = try await api.post("/api/reminders/\(id)/push", body: body)
        await load(force: true)
    }

    func delete(id: Int) async throws {
        let _: ReminderDeleteResponse = try await api.delete("/api/reminders/\(id)")
        await load(force: true)
    }
}
