import Foundation

/// Parses backend timestamps ("yyyy-MM-dd HH:mm:ss" in UTC) to Date
private let utcTimestampFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd HH:mm:ss"
    f.timeZone = TimeZone(identifier: "UTC")
    f.locale = Locale(identifier: "en_US_POSIX")
    return f
}()

private let dateOnlyFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd"
    f.timeZone = TimeZone(identifier: "UTC")
    f.locale = Locale(identifier: "en_US_POSIX")
    return f
}()

private let localTimeFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "HH:mm"
    f.timeZone = .current
    return f
}()

func parseUTCTimestamp(_ ts: String?) -> Date? {
    guard let ts else { return nil }
    return utcTimestampFormatter.date(from: ts)
}

func formatLocalTime(_ ts: String?) -> String? {
    guard let date = parseUTCTimestamp(ts) else { return nil }
    return localTimeFormatter.string(from: date)
}

/// A single item in the feed. Struct-based (not enum) so new card types
/// can be added without modifying this file — no switches to update.
///
/// Each CardModule knows how to cast `payload` to its concrete type.
struct FeedItem: Identifiable {
    let id: String
    let cardType: String
    let dateString: String
    let sortPriority: Int
    let sortDate: Date
    let displayTime: String?

    /// The domain object (Meal, WeightEntry, Workout, etc.).
    /// Each CardModule casts this to the type it expects.
    let payload: Any

    // MARK: - Factory methods for each card type

    static func meal(_ meal: Meal) -> FeedItem {
        FeedItem(
            id: "meal-\(meal.id)",
            cardType: "meal",
            dateString: meal.date,
            sortPriority: 10,
            sortDate: parseUTCTimestamp(meal.createdAt) ?? .distantPast,
            displayTime: formatLocalTime(meal.createdAt),
            payload: meal
        )
    }

    static func weight(_ entry: WeightEntry) -> FeedItem {
        FeedItem(
            id: "weight-\(entry.id)",
            cardType: "weight",
            dateString: entry.date,
            sortPriority: 10,
            sortDate: parseUTCTimestamp(entry.createdAt) ?? .distantPast,
            displayTime: formatLocalTime(entry.createdAt),
            payload: entry
        )
    }

    static func workout(_ workout: Workout) -> FeedItem {
        FeedItem(
            id: "workout-\(workout.id)",
            cardType: "workout",
            dateString: workout.date,
            sortPriority: 10,
            sortDate: parseUTCTimestamp(workout.createdAt) ?? .distantPast,
            displayTime: formatLocalTime(workout.createdAt),
            payload: workout
        )
    }

    static func healthKitWorkout(_ workout: Workout, meta: ImportedWorkoutMeta? = nil) -> FeedItem {
        let sort: Date = meta?.startDate ?? parseUTCTimestamp(workout.createdAt) ?? .distantPast
        let time: String? = meta.map { localTimeFormatter.string(from: $0.startDate) }
            ?? formatLocalTime(workout.createdAt)

        return FeedItem(
            id: "healthkit-workout-\(workout.id)",
            cardType: "healthkit_workout",
            dateString: workout.date,
            sortPriority: 10,
            sortDate: sort,
            displayTime: time,
            payload: HealthKitWorkoutPayload(workout: workout, meta: meta)
        )
    }

    static func summary(text: String, date: String) -> FeedItem {
        FeedItem(
            id: "summary-\(date)",
            cardType: "summary",
            dateString: date,
            sortPriority: 0,
            sortDate: dateOnlyFormatter.date(from: date) ?? .distantPast,
            displayTime: nil,
            payload: SummaryPayload(text: text, date: date)
        )
    }

    static func portfolio(_ summary: PortfolioSummaryResponse) -> FeedItem {
        FeedItem(
            id: "portfolio-\(summary.date)",
            cardType: "portfolio",
            dateString: summary.date,
            sortPriority: 1,
            sortDate: dateOnlyFormatter.date(from: summary.date) ?? .distantPast,
            displayTime: nil,
            payload: summary
        )
    }

    static func nutrition(_ totals: NutritionTotals, _ profile: Profile?, date: String) -> FeedItem {
        FeedItem(
            id: "nutrition-\(date)",
            cardType: "nutrition",
            dateString: date,
            sortPriority: 2,
            sortDate: .distantFuture,
            displayTime: nil,
            payload: NutritionPayload(totals: totals, profile: profile)
        )
    }

    static func post(_ post: Post) -> FeedItem {
        FeedItem(
            id: "post-\(post.id)",
            cardType: "post",
            dateString: post.date,
            sortPriority: 10,
            sortDate: parseUTCTimestamp(post.createdAt) ?? .distantPast,
            displayTime: formatLocalTime(post.createdAt),
            payload: post
        )
    }

    static func reminder(_ reminder: Reminder) -> FeedItem {
        FeedItem(
            id: "reminder-\(reminder.id)",
            cardType: "reminder",
            dateString: reminder.dueDate,
            sortPriority: 3,
            sortDate: parseUTCTimestamp(reminder.createdAt) ?? .distantPast,
            displayTime: nil,
            payload: reminder
        )
    }
}

// MARK: - Payload types for compound data

struct HealthKitWorkoutPayload {
    let workout: Workout
    let meta: ImportedWorkoutMeta?
}

struct SummaryPayload {
    let text: String
    let date: String
}

struct NutritionPayload {
    let totals: NutritionTotals
    let profile: Profile?
}
