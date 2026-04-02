import Foundation

@Observable
class NotificationRouter {
    static let shared = NotificationRouter()

    var pendingDestination: Destination?

    enum Destination {
        case dailySummary
        case weeklySummary
    }

    private init() {}
}
