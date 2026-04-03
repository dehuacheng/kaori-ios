import SwiftUI

struct FeedView: View {
    @Environment(Localizer.self) private var L
    @Environment(MealStore.self) private var mealStore
    @Environment(WeightStore.self) private var weightStore
    @Environment(WorkoutStore.self) private var workoutStore
    @Environment(ProfileStore.self) private var profileStore
    @Environment(APIClient.self) private var api
    @Environment(FinanceStore.self) private var financeStore

    @Environment(NotificationSettings.self) private var notificationSettings

    @State private var feedItems: [FeedItem] = []
    @State private var loadedDates: Set<String> = []
    @State private var dailyTotals: [String: NutritionTotals] = [:]
    @State private var portfolioSummaries: [String: PortfolioSummaryResponse] = [:]
    @State private var portfolioLoading = false
    @State private var hasPortfolioAccounts: Bool?
    @State private var portfolioRefreshTask: Task<Void, Never>?
    @State private var isLoading = false
    @State private var showAnalytics = false
    @State private var selectedMealId: Int?
    @State private var selectedWorkoutId: Int?
    @State private var showSummaryDetail = false
    @State private var selectedPortfolioDate: String?

    // AI Summary state
    @State private var dailySummaryText: String?
    @State private var weeklySummaryText: String?
    @State private var isGeneratingDaily = false
    @State private var isGeneratingWeekly = false
    @State private var summarySectionsCollapsed = false
    @Binding var showMealCreate: Bool
    @Binding var showWeightCreate: Bool
    var refreshToken: UUID

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    var body: some View {
        NavigationStack {
            List {
                if feedItems.isEmpty && !isLoading {
                    ContentUnavailableView(
                        L.t("feed.empty"),
                        systemImage: "tray",
                        description: Text(L.t("feed.emptyHint"))
                    )
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }

                ForEach(groupedByDate(), id: \.date) { group in
                    Section {
                        // AI Summary — only for today
                        if group.date == todayString {
                            summaryCard
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                .listRowBackground(Color.clear)
                                .swipeActions(edge: .trailing) {
                                    Button {
                                        Task {
                                            if isWeeklySummaryDay { await generateWeeklySummary() }
                                            else { await generateDailySummary() }
                                        }
                                    } label: {
                                        Label(L.t("summary.regenerate"), systemImage: "arrow.clockwise")
                                    }
                                    .tint(.blue)
                                }
                        }

                        // Portfolio card (after summary, before nutrition) — today only
                        if group.date == todayString, hasPortfolioAccounts == true {
                            if let portfolioSummary = portfolioSummaries[group.date],
                               portfolioSummary.combined != nil {
                                Button {
                                    selectedPortfolioDate = group.date
                                } label: {
                                    PortfolioFeedCard(summary: portfolioSummary)
                                }
                                .buttonStyle(.plain)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                .listRowBackground(Color.clear)
                            } else {
                                PortfolioFeedCardPlaceholder()
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                    .listRowBackground(Color.clear)
                            }
                        }

                        // Daily nutrition summary pinned at top
                        if let totals = dailyTotals[group.date] {
                            DailyNutritionCard(totals: totals, profile: profileStore.profile)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                .listRowBackground(Color.clear)
                        }

                        ForEach(group.items) { item in
                            feedCard(for: item)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                .listRowBackground(Color.clear)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        Task { await deleteItem(item) }
                                    } label: {
                                        Label(L.t("common.delete"), systemImage: "trash")
                                    }
                                }
                        }
                    } header: {
                        Text(dayLabel(group.date))
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            .textCase(nil)
                    }

                    // Load more trigger at the last group
                    if group.date == groupedByDate().last?.date {
                        Color.clear
                            .frame(height: 1)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .onAppear {
                                Task { await loadMoreDays() }
                            }
                    }
                }

                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
            }
            .listStyle(.plain)
            .refreshable {
                await refreshFeed()
            }
            .navigationTitle(L.t("tab.home"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAnalytics = true
                    } label: {
                        Image(systemName: "chart.xyaxis.line")
                    }
                }
            }
            .sheet(isPresented: $showAnalytics) {
                AnalyticsView()
            }
            .navigationDestination(isPresented: $showSummaryDetail) {
                SummaryDetailView(summaryType: summaryType)
                    .toolbar(.hidden, for: .tabBar)
            }
            .navigationDestination(item: $selectedPortfolioDate) { date in
                PortfolioDetailView(date: date)
                    .toolbar(.hidden, for: .tabBar)
            }
            .navigationDestination(item: $selectedMealId) { mealId in
                MealDetailView(mealId: mealId)
                    .toolbar(.hidden, for: .tabBar)
            }
            .navigationDestination(item: $selectedWorkoutId) { workoutId in
                Group {
                    if let meta = WorkoutStore.importedMeta(forWorkoutId: workoutId) {
                        ImportedWorkoutDetailView(workoutId: workoutId, meta: meta)
                    } else {
                        WorkoutDetailView(workoutId: workoutId)
                    }
                }
                .toolbar(.hidden, for: .tabBar)
            }
            .onChange(of: refreshToken) {
                Task { await refreshToday() }
            }
            .sheet(isPresented: $showMealCreate, onDismiss: {
                Task { await refreshToday() }
            }) {
                MealCreateView()
            }
            .sheet(isPresented: $showWeightCreate, onDismiss: {
                Task { await refreshToday() }
            }) {
                WeightCreateView()
            }
            .task {
                await profileStore.load()
                await weightStore.load()
                await loadInitialFeed()
                await loadSummary()
                // Portfolio: check if accounts exist, then load in background
                startPortfolioBackground()
            }
            .onDisappear {
                portfolioRefreshTask?.cancel()
            }
        }
    }

    // MARK: - Summary

    private var todayString: String {
        dateFormatter.string(from: Date())
    }

    private var isWeeklySummaryDay: Bool {
        Calendar.current.component(.weekday, from: Date()) == notificationSettings.weeklySummaryWeekday
    }

    private var shouldShowSummary: Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        return hour >= notificationSettings.dailySummaryHour
    }

    private var summaryType: SummaryDetailView.SummaryType {
        isWeeklySummaryDay ? .weekly : .daily(date: todayString)
    }

    @ViewBuilder
    private var summaryCard: some View {
        if shouldShowSummary {
            let isWeekly = isWeeklySummaryDay
            let text = isWeekly ? weeklySummaryText : dailySummaryText
            let isGenerating = isWeekly ? isGeneratingWeekly : isGeneratingDaily

            Button {
                showSummaryDetail = true
            } label: {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: isWeekly ? "calendar.badge.clock" : "sparkles")
                            .foregroundStyle(isWeekly ? .blue : .yellow)
                        Text(L.t(isWeekly ? "summary.weeklyTitle" : "summary.dailyTitle"))
                            .font(.subheadline.bold())
                            .foregroundStyle(isWeekly ? .blue : .yellow)
                        Spacer()
                        if isGenerating {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if isGenerating && text == nil {
                        Text(L.t("summary.generating"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else if let text {
                        // Preview — first 3 lines
                        Text(text.components(separatedBy: "\n").prefix(3).joined(separator: "\n"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                    } else {
                        Text(L.t("summary.noSummary"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .feedCard()
            }
            .buttonStyle(.plain)
        }
    }

    private func loadSummary() async {
        if isWeeklySummaryDay {
            do {
                let result: SummaryDetail = try await api.get(
                    "/api/summary/weekly-detail",
                    query: ["date": todayString]
                )
                weeklySummaryText = result.summaryText
            } catch {}
        } else {
            do {
                let result: SummaryDetail = try await api.get(
                    "/api/summary/daily-detail",
                    query: ["date": todayString]
                )
                dailySummaryText = result.summaryText
            } catch {}
        }
    }

    private func generateDailySummary() async {
        isGeneratingDaily = true
        defer { isGeneratingDaily = false }
        let langRaw = UserDefaults.standard.string(forKey: "appLanguage") ?? "en"
        let lang = langRaw.hasPrefix("zh") ? "zh" : "en"
        do {
            let result: SummaryDetail = try await api.post(
                "/api/summary/daily-detail",
                query: ["language": lang, "date": todayString]
            )
            dailySummaryText = result.summaryText
        } catch {
            dailySummaryText = "Error: \(error.localizedDescription)"
        }
    }

    private func generateWeeklySummary() async {
        isGeneratingWeekly = true
        defer { isGeneratingWeekly = false }
        let langRaw = UserDefaults.standard.string(forKey: "appLanguage") ?? "en"
        let lang = langRaw.hasPrefix("zh") ? "zh" : "en"
        do {
            let result: SummaryDetail = try await api.post(
                "/api/summary/weekly-detail",
                query: ["language": lang]
            )
            weeklySummaryText = result.summaryText
        } catch {
            weeklySummaryText = "Error: \(error.localizedDescription)"
        }
    }

    // MARK: - Card Rendering

    @ViewBuilder
    private func feedCard(for item: FeedItem) -> some View {
        let time = item.displayTime
        switch item {
        case .meal(let meal):
            Button {
                selectedMealId = meal.id
            } label: {
                MealFeedCard(meal: meal, displayTime: time)
            }
            .buttonStyle(.plain)
        case .weight(let entry):
            WeightFeedCard(entry: entry, displayTime: time)
        case .workout(let workout, _):
            Button {
                selectedWorkoutId = workout.id
            } label: {
                WorkoutFeedCard(workout: workout, displayTime: time)
            }
            .buttonStyle(.plain)
        case .summary(let text, let date):
            SummaryFeedCard(text: text, date: date)
        case .portfolio:
            EmptyView()  // Portfolio card is rendered as a pinned card, not a feed item
        }
    }

    // MARK: - Data Loading

    private func loadInitialFeed() async {
        guard feedItems.isEmpty else { return }
        isLoading = true
        let today = dateFormatter.string(from: Date())
        await loadDate(today)
        // Also load yesterday for some content
        if let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) {
            await loadDate(dateFormatter.string(from: yesterday))
        }
        isLoading = false
    }

    private func refreshFeed() async {
        // Reload all previously loaded dates, replacing items in place
        let datesToReload = loadedDates
        loadedDates.removeAll()
        var newTotals: [String: NutritionTotals] = [:]
        var newItems: [FeedItem] = []
        for dateStr in datesToReload.sorted(by: >) {
            loadedDates.insert(dateStr)
            var items: [FeedItem] = []
            if let response: MealListResponse = try? await api.get("/api/meals", query: ["date": dateStr]) {
                for meal in response.meals { items.append(.meal(meal)) }
                newTotals[dateStr] = response.totals
            }
            if let response: WeightResponse = try? await api.get("/api/weight") {
                for entry in response.weightsAsc where entry.date == dateStr { items.append(.weight(entry)) }
            }
            if let workouts: [Workout] = try? await api.get("/api/workouts", query: ["date": dateStr]) {
                for workout in workouts { items.append(.workout(workout, meta: WorkoutStore.importedMeta(forWorkoutId: workout.id))) }
            }
            newItems.append(contentsOf: items)
        }
        // Also ensure today is loaded
        let today = dateFormatter.string(from: Date())
        if !loadedDates.contains(today) {
            loadedDates.insert(today)
            if let response: MealListResponse = try? await api.get("/api/meals", query: ["date": today]) {
                for meal in response.meals { newItems.append(.meal(meal)) }
                newTotals[today] = response.totals
            }
            if let response: WeightResponse = try? await api.get("/api/weight") {
                for entry in response.weightsAsc where entry.date == today { newItems.append(.weight(entry)) }
            }
            if let workouts: [Workout] = try? await api.get("/api/workouts", query: ["date": today]) {
                for workout in workouts { newItems.append(.workout(workout, meta: WorkoutStore.importedMeta(forWorkoutId: workout.id))) }
            }
        }
        dailyTotals = newTotals
        feedItems = newItems.sorted { $0.sortDate > $1.sortDate }
    }

    private func refreshToday() async {
        let today = dateFormatter.string(from: Date())
        // Load new data first, then replace — avoids flicker
        var newItems: [FeedItem] = []
        if let response: MealListResponse = try? await api.get("/api/meals", query: ["date": today]) {
            for meal in response.meals { newItems.append(.meal(meal)) }
            dailyTotals[today] = response.totals
        }
        if let response: WeightResponse = try? await api.get("/api/weight") {
            for entry in response.weightsAsc where entry.date == today { newItems.append(.weight(entry)) }
        }
        if let workouts: [Workout] = try? await api.get("/api/workouts", query: ["date": today]) {
            for workout in workouts { newItems.append(.workout(workout, meta: WorkoutStore.importedMeta(forWorkoutId: workout.id))) }
        }
        // Swap today's items atomically
        var updated = feedItems.filter { $0.dateString != today }
        updated.append(contentsOf: newItems)
        feedItems = updated.sorted { $0.sortDate > $1.sortDate }
        loadedDates.insert(today)
    }

    private func loadMoreDays() async {
        guard !isLoading else { return }
        isLoading = true
        // Find the earliest loaded date and load the day before
        let earliest = loadedDates.sorted().first ?? dateFormatter.string(from: Date())
        if let earliestDate = dateFormatter.date(from: earliest),
           let previousDay = Calendar.current.date(byAdding: .day, value: -1, to: earliestDate) {
            await loadDate(dateFormatter.string(from: previousDay))
        }
        isLoading = false
    }

    private func loadDate(_ dateStr: String) async {
        guard !loadedDates.contains(dateStr) else { return }
        loadedDates.insert(dateStr)

        var items: [FeedItem] = []

        // Fetch meals for this date
        if let response: MealListResponse = try? await api.get("/api/meals", query: ["date": dateStr]) {
            for meal in response.meals {
                items.append(.meal(meal))
            }
            dailyTotals[dateStr] = response.totals
        }

        // Fetch weight entries (API returns all; filter client-side)
        if let response: WeightResponse = try? await api.get("/api/weight") {
            for entry in response.weightsAsc where entry.date == dateStr {
                items.append(.weight(entry))
            }
        }

        // Fetch workouts for this date
        if let workouts: [Workout] = try? await api.get("/api/workouts", query: ["date": dateStr]) {
            for workout in workouts {
                items.append(.workout(workout, meta: WorkoutStore.importedMeta(forWorkoutId: workout.id)))
            }
        }

        feedItems.append(contentsOf: items)
        feedItems.sort { $0.sortDate > $1.sortDate }
    }

    // MARK: - Portfolio (background loading + periodic refresh)

    private func startPortfolioBackground() {
        portfolioRefreshTask?.cancel()
        portfolioRefreshTask = Task {
            // Quick check: do any accounts exist?
            let accounts = (try? await financeStore.loadAccountsQuick()) ?? []
            await MainActor.run { hasPortfolioAccounts = !accounts.isEmpty }
            guard !accounts.isEmpty else { return }

            // Initial fetch
            await refreshPortfolio()

            // Periodic refresh: every 60 seconds
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(60))
                guard !Task.isCancelled else { break }
                await refreshPortfolio()
            }
        }
    }

    private func refreshPortfolio() async {
        let today = dateFormatter.string(from: Date())
        if let summary = try? await financeStore.getPortfolioSummary(date: today),
           summary.combined != nil {
            await MainActor.run {
                portfolioSummaries[today] = summary
            }
        }
    }

    // MARK: - Deletion

    private func deleteItem(_ item: FeedItem) async {
        switch item {
        case .meal(let meal):
            _ = try? await mealStore.deleteMeal(meal.id)
        case .weight(let entry):
            try? await weightStore.delete(id: entry.id)
        case .workout(let workout, _):
            try? await workoutStore.deleteWorkout(workout.id)
        case .summary:
            break
        case .portfolio:
            break
        }
        feedItems.removeAll { $0.id == item.id }
    }

    // MARK: - Grouping

    private struct DayGroup: Identifiable {
        let date: String
        let items: [FeedItem]
        var id: String { date }
    }

    private func groupedByDate() -> [DayGroup] {
        let grouped = Dictionary(grouping: feedItems) { $0.dateString }
        return grouped.map { DayGroup(date: $0.key, items: $0.value) }
            .sorted { $0.date > $1.date }
    }

    private func dayLabel(_ dateStr: String) -> String {
        let today = dateFormatter.string(from: Date())
        if dateStr == today { return L.t("common.today") }
        if let _ = dateFormatter.date(from: dateStr),
           let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()),
           dateFormatter.string(from: yesterday) == dateStr {
            return L.t("feed.yesterday")
        }
        // Format as "Apr 1"
        if let date = dateFormatter.date(from: dateStr) {
            let display = DateFormatter()
            display.dateFormat = "MMM d"
            return display.string(from: date)
        }
        return dateStr
    }
}
