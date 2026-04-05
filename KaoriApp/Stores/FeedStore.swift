import Foundation

/// Manages feed state by fetching from the unified `/api/feed` endpoint.
///
/// ALL card types (meals, weight, workouts, summary, portfolio, nutrition)
/// are stored as FeedItem entries in `feedItems`. No card gets special treatment.
/// Ranking within a day group is controlled by FeedItem.sortPriority.
@Observable
class FeedStore {
    var feedItems: [FeedItem] = []
    var isLoading = false
    var hasPortfolioAccounts: Bool?
    var regeneratingSummaryDates: Set<String> = []

    /// Cached profile for nutrition card rendering
    var cachedProfile: Profile?

    let api: APIClient
    private var loadedDates: Set<String> = []
    private var portfolioRefreshTask: Task<Void, Never>?
    private var useUnifiedEndpoint = true

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    init(api: APIClient) {
        self.api = api
    }

    var todayString: String {
        dateFormatter.string(from: Date())
    }

    /// Whether today is a US stock market trading day (Mon–Fri).
    private var isMarketDay: Bool {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return weekday >= 2 && weekday <= 6
    }

    // MARK: - Public API

    /// Load initial feed (today + yesterday).
    func loadInitial(
        mealStore: MealStore,
        weightStore: WeightStore,
        workoutStore: WorkoutStore,
        financeStore: FinanceStore
    ) async {
        guard feedItems.isEmpty else { return }
        isLoading = true
        let today = todayString
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())
            .map { dateFormatter.string(from: $0) }

        if useUnifiedEndpoint {
            let startDate = yesterday ?? today
            do {
                let response: FeedAPIResponse = try await api.get(
                    "/api/feed",
                    query: ["start_date": startDate, "end_date": today]
                )
                applyFeedResponse(response)
                loadedDates.insert(today)
                if let y = yesterday { loadedDates.insert(y) }
                ensureTodayNutrition()
                isLoading = false
                return
            } catch {
                useUnifiedEndpoint = false
            }
        }

        // Fallback
        await loadDateLegacy(today, mealStore: mealStore, weightStore: weightStore, workoutStore: workoutStore)
        if let y = yesterday {
            await loadDateLegacy(y, mealStore: mealStore, weightStore: weightStore, workoutStore: workoutStore)
        }
        ensureTodayNutrition()
        isLoading = false
    }

    /// Refresh all loaded dates.
    func refresh(
        mealStore: MealStore,
        weightStore: WeightStore,
        workoutStore: WorkoutStore,
        financeStore: FinanceStore
    ) async {
        if useUnifiedEndpoint, let earliest = loadedDates.sorted().first {
            do {
                let response: FeedAPIResponse = try await api.get(
                    "/api/feed",
                    query: ["start_date": earliest, "end_date": todayString]
                )
                loadedDates.insert(todayString)
                // Clear and re-apply
                feedItems.removeAll()
                applyFeedResponse(response)
                ensureTodayNutrition()
                return
            } catch {
                useUnifiedEndpoint = false
            }
        }

        // Fallback
        let datesToReload = loadedDates
        loadedDates.removeAll()
        feedItems.removeAll()
        for dateStr in datesToReload.sorted(by: >) {
            await loadDateLegacy(dateStr, mealStore: mealStore, weightStore: weightStore, workoutStore: workoutStore)
        }
        let today = todayString
        if !loadedDates.contains(today) {
            await loadDateLegacy(today, mealStore: mealStore, weightStore: weightStore, workoutStore: workoutStore)
        }
        ensureTodayNutrition()
    }

    /// Quick refresh of today via unified endpoint only (no store deps).
    func refreshTodayQuick() async {
        let today = todayString
        guard useUnifiedEndpoint else { return }
        do {
            let response: FeedAPIResponse = try await api.get(
                "/api/feed",
                query: ["start_date": today, "end_date": today]
            )
            feedItems.removeAll { $0.dateString == today }
            applyFeedResponse(response)
            loadedDates.insert(today)
            ensureTodayNutrition()
        } catch {}
    }

    /// Refresh only today's data.
    func refreshToday(
        mealStore: MealStore,
        weightStore: WeightStore,
        workoutStore: WorkoutStore
    ) async {
        let today = todayString

        if useUnifiedEndpoint {
            do {
                let response: FeedAPIResponse = try await api.get(
                    "/api/feed",
                    query: ["start_date": today, "end_date": today]
                )
                feedItems.removeAll { $0.dateString == today }
                applyFeedResponse(response)
                loadedDates.insert(today)
                ensureTodayNutrition()
                return
            } catch {
                useUnifiedEndpoint = false
            }
        }

        // Fallback
        feedItems.removeAll { $0.dateString == today }
        loadedDates.remove(today)
        await loadDateLegacy(today, mealStore: mealStore, weightStore: weightStore, workoutStore: workoutStore)
        ensureTodayNutrition()
    }

    /// Number of loaded day-groups remaining below the current scroll position.
    func daysRemainingBelow(_ currentDate: String) -> Int {
        let sorted = loadedDates.sorted()
        guard let idx = sorted.firstIndex(of: currentDate) else { return 0 }
        return idx
    }

    /// Prefetch 7 days of past cards at once.
    func loadMoreDays(
        mealStore: MealStore,
        weightStore: WeightStore,
        workoutStore: WorkoutStore
    ) async {
        guard !isLoading else { return }
        isLoading = true
        let earliest = loadedDates.sorted().first ?? todayString
        guard let earliestDate = dateFormatter.date(from: earliest) else {
            isLoading = false
            return
        }

        let endDate = Calendar.current.date(byAdding: .day, value: -1, to: earliestDate)!
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: earliestDate)!
        let endStr = dateFormatter.string(from: endDate)
        let startStr = dateFormatter.string(from: startDate)

        if useUnifiedEndpoint {
            do {
                let response: FeedAPIResponse = try await api.get(
                    "/api/feed",
                    query: ["start_date": startStr, "end_date": endStr]
                )
                applyFeedResponse(response)
                var d = startDate
                while d <= endDate {
                    loadedDates.insert(dateFormatter.string(from: d))
                    d = Calendar.current.date(byAdding: .day, value: 1, to: d)!
                }
                isLoading = false
                return
            } catch {
                useUnifiedEndpoint = false
            }
        }

        // Fallback
        var d = endDate
        while d >= startDate {
            await loadDateLegacy(
                dateFormatter.string(from: d),
                mealStore: mealStore,
                weightStore: weightStore,
                workoutStore: workoutStore
            )
            d = Calendar.current.date(byAdding: .day, value: -1, to: d)!
        }
        isLoading = false
    }

    /// Delete a feed item.
    func deleteItem(
        _ item: FeedItem,
        mealStore: MealStore,
        weightStore: WeightStore,
        workoutStore: WorkoutStore
    ) async {
        // Dispatch by cardType string — no switch on FeedItem cases needed
        if let meal = item.payload as? Meal {
            _ = try? await mealStore.deleteMeal(meal.id)
        } else if let entry = item.payload as? WeightEntry {
            try? await weightStore.delete(id: entry.id)
        } else if let workout = item.payload as? Workout {
            try? await workoutStore.deleteWorkout(workout.id)
        } else if let p = item.payload as? HealthKitWorkoutPayload {
            try? await workoutStore.deleteWorkout(p.workout.id)
        } else if let post = item.payload as? Post {
            let _: PostDeleteResponse? = try? await api.delete("/api/post/\(post.id)")
        } else if let reminder = item.payload as? Reminder {
            let _: ReminderDeleteResponse? = try? await api.delete("/api/reminders/\(reminder.id)")
        } else if let p = item.payload as? SummaryPayload, let summaryId = p.summaryId {
            let _: SummaryDeleteResponse? = try? await api.delete("/api/summary/\(summaryId)")
        }
        feedItems.removeAll { $0.id == item.id }
    }

    // MARK: - Portfolio Background Refresh

    func startPortfolioRefresh(financeStore: FinanceStore) {
        portfolioRefreshTask?.cancel()
        portfolioRefreshTask = Task {
            let accounts = (try? await financeStore.loadAccountsQuick()) ?? []
            await MainActor.run { hasPortfolioAccounts = !accounts.isEmpty }
            guard !accounts.isEmpty else { return }

            await refreshPortfolio(financeStore: financeStore)

            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(60))
                guard !Task.isCancelled else { break }
                await refreshPortfolio(financeStore: financeStore)
            }
        }
    }

    func stopPortfolioRefresh() {
        portfolioRefreshTask?.cancel()
    }

    // MARK: - Summary Generation (triggered via "+" menu or swipe-to-regenerate)

    func regenerateSummary(for date: String? = nil) async {
        let targetDate = date ?? todayString
        let weekday = Calendar.current.component(.weekday, from: Date())
        let weeklySummaryWeekday = UserDefaults.standard.integer(forKey: "weeklySummaryWeekday")
        if targetDate == todayString && weekday == weeklySummaryWeekday {
            _ = await generateWeeklySummary()
        } else {
            _ = await generateDailySummary(for: targetDate)
        }
    }

    func generateDailySummary(for date: String? = nil) async -> String? {
        let targetDate = date ?? todayString
        let langRaw = UserDefaults.standard.string(forKey: "appLanguage") ?? "en"
        let lang = langRaw.hasPrefix("zh") ? "zh" : "en"
        regeneratingSummaryDates.insert(targetDate)
        defer { regeneratingSummaryDates.remove(targetDate) }
        do {
            let result: SummaryDetail = try await api.post(
                "/api/summary/daily-detail",
                query: ["language": lang, "date": targetDate]
            )
            // Replace in-place or add the summary feed item for the target date
            let newItem = FeedItem.summary(id: result.id, text: result.summaryText, date: targetDate)
            if let idx = feedItems.firstIndex(where: { $0.id == "summary-\(targetDate)" }) {
                feedItems[idx] = newItem
            } else {
                feedItems.append(newItem)
                sortFeedItems()
            }
            return result.summaryText
        } catch {
            return "Error: \(error.localizedDescription)"
        }
    }

    func generateWeeklySummary() async -> String? {
        let langRaw = UserDefaults.standard.string(forKey: "appLanguage") ?? "en"
        let lang = langRaw.hasPrefix("zh") ? "zh" : "en"
        regeneratingSummaryDates.insert(todayString)
        defer { regeneratingSummaryDates.remove(todayString) }
        do {
            let result: SummaryDetail = try await api.post(
                "/api/summary/weekly-detail",
                query: ["language": lang]
            )
            let newItem = FeedItem.summary(id: result.id, text: result.summaryText, date: todayString)
            if let idx = feedItems.firstIndex(where: { $0.id == "summary-\(todayString)" }) {
                feedItems[idx] = newItem
            } else {
                feedItems.append(newItem)
                sortFeedItems()
            }
            return result.summaryText
        } catch {
            return "Error: \(error.localizedDescription)"
        }
    }

    // MARK: - Private

    private func refreshPortfolio(financeStore: FinanceStore) async {
        guard isMarketDay else { return }
        let today = todayString
        if let summary = try? await financeStore.getPortfolioSummary(date: today),
           summary.combined != nil {
            await MainActor.run {
                // Replace or add the portfolio feed item for today
                feedItems.removeAll { $0.id == "portfolio-\(today)" }
                feedItems.append(.portfolio(summary))
                sortFeedItems()
            }
        }
    }

    /// Ensure today always has a nutrition card (even with zero values).
    private func ensureTodayNutrition() {
        let today = todayString
        let hasNutrition = feedItems.contains { $0.id == "nutrition-\(today)" }
        if !hasNutrition {
            let zeroTotals = NutritionTotals(totalCal: 0, totalProtein: 0, totalCarbs: 0, totalFat: 0)
            feedItems.append(.nutrition(zeroTotals, cachedProfile, date: today))
        }
        sortFeedItems()
    }

    private func sortFeedItems() {
        feedItems.sort { a, b in
            if a.dateString != b.dateString {
                return a.dateString > b.dateString
            }
            if a.sortPriority != b.sortPriority {
                return a.sortPriority < b.sortPriority
            }
            return a.sortDate > b.sortDate
        }
    }

    /// Apply a unified feed API response to local state.
    private func applyFeedResponse(_ response: FeedAPIResponse) {
        for group in response.dates {
            // Regular items (meals, weight, workouts)
            for item in group.items {
                if let feedItem = convertToFeedItem(item),
                   !feedItems.contains(where: { $0.id == feedItem.id }) {
                    feedItems.append(feedItem)
                }
            }

            // Nutrition totals → nutrition card
            if let totals = group.nutritionTotals, totals.totalCal > 0 {
                feedItems.removeAll { $0.id == "nutrition-\(group.date)" }
                feedItems.append(.nutrition(totals, cachedProfile, date: group.date))
            }

            // Summary → summary card
            if let summary = group.summary,
               let text = summary.summaryText, !text.isEmpty {
                feedItems.removeAll { $0.id == "summary-\(group.date)" }
                feedItems.append(.summary(id: summary.id, text: text, date: group.date))
            }

            // Portfolio → portfolio card (only on market days for today)
            if let portfolio = group.portfolio, portfolio.combined != nil {
                let isToday = group.date == todayString
                if !isToday || isMarketDay {
                    feedItems.removeAll { $0.id == "portfolio-\(group.date)" }
                    feedItems.append(.portfolio(portfolio))
                }
            }
        }

        sortFeedItems()
    }

    /// Decode a single feed item from the raw JSON data within the feed response.
    /// We re-decode from the original JSON bytes instead of going through AnyCodableValue,
    /// because AnyCodableValue can't represent nested objects/arrays.
    private func convertToFeedItem(_ item: FeedAPIItem) -> FeedItem? {
        guard let rawData = item.rawData else { return nil }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        switch item.type {
        case "meal":
            if let meal = try? decoder.decode(Meal.self, from: rawData) {
                return .meal(meal)
            }
        case "weight":
            if let weight = try? decoder.decode(WeightEntry.self, from: rawData) {
                return .weight(weight)
            }
        case "workout":
            if let workout = try? decoder.decode(Workout.self, from: rawData) {
                if workout.isImported {
                    return .healthKitWorkout(workout, meta: WorkoutStore.importedMeta(forWorkoutId: workout.id))
                }
                return .workout(workout)
            }
        case "healthkit_workout":
            if let workout = try? decoder.decode(Workout.self, from: rawData) {
                return .healthKitWorkout(workout, meta: WorkoutStore.importedMeta(forWorkoutId: workout.id))
            }
        case "post":
            if let post = try? decoder.decode(Post.self, from: rawData) {
                return .post(post)
            }
        case "reminder":
            if let reminder = try? decoder.decode(Reminder.self, from: rawData) {
                return .reminder(reminder)
            }
        default:
            break
        }
        return nil
    }

    /// Legacy per-endpoint loading (fallback).
    private func loadDateLegacy(
        _ dateStr: String,
        mealStore: MealStore,
        weightStore: WeightStore,
        workoutStore: WorkoutStore
    ) async {
        guard !loadedDates.contains(dateStr) else { return }
        loadedDates.insert(dateStr)

        // Meals
        if let response: MealListResponse = try? await api.get("/api/meals", query: ["date": dateStr]) {
            for meal in response.meals {
                feedItems.append(.meal(meal))
            }
            if response.totals.totalCal > 0 {
                feedItems.append(.nutrition(response.totals, cachedProfile, date: dateStr))
            }
        }

        // Weight
        if let response: WeightResponse = try? await api.get("/api/weight") {
            for entry in response.weightsAsc where entry.date == dateStr {
                feedItems.append(.weight(entry))
            }
        }

        // Workouts
        if let workouts: [Workout] = try? await api.get("/api/workouts", query: ["date": dateStr]) {
            for workout in workouts {
                if workout.isImported {
                    feedItems.append(.healthKitWorkout(workout, meta: WorkoutStore.importedMeta(forWorkoutId: workout.id)))
                } else {
                    feedItems.append(.workout(workout))
                }
            }
        }

        // Summary
        if let result: SummaryDetail = try? await api.get(
            "/api/summary/daily-detail", query: ["date": dateStr]
        ), !result.summaryText.isEmpty {
            feedItems.append(.summary(id: result.id, text: result.summaryText, date: dateStr))
        }

        sortFeedItems()
    }
}

// MARK: - Feed API Response Models

struct FeedAPIResponse: Codable {
    let dates: [FeedAPIDateGroup]
    let cardPreferences: [CardPreferenceItem]?
}

struct FeedAPIDateGroup: Codable {
    let date: String
    let items: [FeedAPIItem]
    let nutritionTotals: NutritionTotals?
    let summary: FeedAPISummary?
    let portfolio: PortfolioSummaryResponse?
}

struct FeedAPISummary: Codable {
    let id: Int?
    let type: String?
    let date: String?
    let summaryText: String?
}

struct FeedAPIItem: Codable {
    let type: String
    let id: Int
    let date: String
    let createdAt: String?

    /// Raw JSON bytes of the `data` field, preserved for proper decoding
    /// of nested objects that AnyCodableValue can't handle.
    let rawData: Data?

    enum CodingKeys: String, CodingKey {
        case type, id, date, createdAt, data
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        type = try c.decode(String.self, forKey: .type)
        id = try c.decode(Int.self, forKey: .id)
        date = try c.decode(String.self, forKey: .date)
        createdAt = try c.decodeIfPresent(String.self, forKey: .createdAt)
        // Capture the raw JSON of `data` as bytes for later re-decoding
        if let dataValue = try? c.decodeIfPresent(AnyCodableJSON.self, forKey: .data) {
            rawData = dataValue.rawBytes
        } else {
            rawData = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(type, forKey: .type)
        try c.encode(id, forKey: .id)
        try c.encode(date, forKey: .date)
        try c.encodeIfPresent(createdAt, forKey: .createdAt)
    }
}

/// Captures arbitrary JSON as raw bytes for later re-decoding into concrete types.
struct AnyCodableJSON: Codable {
    let rawBytes: Data

    init(from decoder: Decoder) throws {
        // Decode as a generic JSON container, then re-encode to get raw bytes
        let value = try JSONValue(from: decoder)
        rawBytes = try JSONEncoder().encode(value)
    }

    func encode(to encoder: Encoder) throws {
        // Not needed for our use case
    }
}

/// Helper to capture arbitrary JSON structure.
private enum JSONValue: Codable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: JSONValue])
    case array([JSONValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let v = try? container.decode([String: JSONValue].self) { self = .object(v) }
        else if let v = try? container.decode([JSONValue].self) { self = .array(v) }
        else if let v = try? container.decode(String.self) { self = .string(v) }
        else if let v = try? container.decode(Double.self) { self = .number(v) }
        else if let v = try? container.decode(Bool.self) { self = .bool(v) }
        else if container.decodeNil() { self = .null }
        else { self = .null }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let v): try container.encode(v)
        case .number(let v): try container.encode(v)
        case .bool(let v): try container.encode(v)
        case .object(let v): try container.encode(v)
        case .array(let v): try container.encode(v)
        case .null: try container.encodeNil()
        }
    }
}

// MARK: - Debug log (temporary — remove after debugging)

@Observable
class FeedDebugLog {
    static let shared = FeedDebugLog()
    var lines: [String] = []

    static func append(_ msg: String) {
        Task { @MainActor in
            shared.lines.append("[\(Date().formatted(date: .omitted, time: .standard))] \(msg)")
            if shared.lines.count > 50 { shared.lines.removeFirst() }
        }
    }
}

