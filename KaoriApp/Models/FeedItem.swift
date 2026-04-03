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

/// Formats a Date as local time "HH:mm"
private let localTimeFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "HH:mm"
    f.timeZone = .current
    return f
}()

/// Parse a backend UTC timestamp string to a Date
func parseUTCTimestamp(_ ts: String?) -> Date? {
    guard let ts else { return nil }
    return utcTimestampFormatter.date(from: ts)
}

/// Format a backend UTC timestamp as local time string (e.g., "14:30")
func formatLocalTime(_ ts: String?) -> String? {
    guard let date = parseUTCTimestamp(ts) else { return nil }
    return localTimeFormatter.string(from: date)
}

enum FeedItem: Identifiable {
    case meal(Meal)
    case weight(WeightEntry)
    case workout(Workout, meta: ImportedWorkoutMeta?)
    case summary(text: String, date: String)
    case portfolio(PortfolioSummaryResponse)

    var id: String {
        switch self {
        case .meal(let m): "meal-\(m.id)"
        case .weight(let w): "weight-\(w.id)"
        case .workout(let w, _): "workout-\(w.id)"
        case .summary(_, let d): "summary-\(d)"
        case .portfolio(let p): "portfolio-\(p.date)"
        }
    }

    /// Date string (YYYY-MM-DD) for grouping
    var dateString: String {
        switch self {
        case .meal(let m): m.date
        case .weight(let w): w.date
        case .workout(let w, _): w.date
        case .summary(_, let d): d
        case .portfolio(let p): p.date
        }
    }

    /// For sorting within a day (newest first)
    var sortDate: Date {
        switch self {
        case .meal(let m):
            if let d = parseUTCTimestamp(m.createdAt) { return d }
        case .weight(let w):
            if let d = parseUTCTimestamp(w.createdAt) { return d }
        case .workout(_, let meta):
            if let meta { return meta.startDate }
            // Fall through handled below
        case .summary(_, let dateStr):
            if let d = dateOnlyFormatter.date(from: dateStr) { return d }
        case .portfolio(let p):
            if let d = dateOnlyFormatter.date(from: p.date) { return d }
        }
        // Fallback for workouts without meta: use created_at
        if case .workout(let w, _) = self, let d = parseUTCTimestamp(w.createdAt) { return d }
        // Final fallback: parse date string as midnight UTC
        return dateOnlyFormatter.date(from: dateString) ?? Date.distantPast
    }

    /// Local time string for display
    var displayTime: String? {
        switch self {
        case .meal(let m):
            return formatLocalTime(m.createdAt)
        case .weight(let w):
            return formatLocalTime(w.createdAt)
        case .workout(let w, let meta):
            if let meta {
                return localTimeFormatter.string(from: meta.startDate)
            }
            return formatLocalTime(w.createdAt)
        case .summary:
            return nil
        case .portfolio:
            return nil
        }
    }
}

// Note: MealListResponse is defined in Meal.swift
// Workouts API returns [Workout] directly (no wrapper)
