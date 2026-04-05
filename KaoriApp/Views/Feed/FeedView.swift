import SwiftUI

struct FeedView: View {
    @Environment(Localizer.self) private var L
    @Environment(MealStore.self) private var mealStore
    @Environment(WeightStore.self) private var weightStore
    @Environment(WorkoutStore.self) private var workoutStore
    @Environment(ProfileStore.self) private var profileStore
    @Environment(FinanceStore.self) private var financeStore
    @Environment(FeedStore.self) private var feedStore
    @Environment(CardRegistry.self) private var cardRegistry
    @Environment(CardPreferenceStore.self) private var prefStore
    @Environment(NotificationSettings.self) private var notificationSettings

    @State private var showAnalytics = false
    @State private var selectedItemId: String?
    @State private var showDebugLog = false

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
                if feedStore.feedItems.isEmpty && !feedStore.isLoading {
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
                        ForEach(group.items) { item in
                            if prefStore.isEnabled(item.cardType) {
                                feedCard(for: item)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                    .listRowBackground(Color.clear)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        swipeActions(for: item)
                                    }
                                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                        leadingSwipeActions(for: item)
                                    }
                                    .onAppear {
                                        if item.id == group.items.last?.id,
                                           feedStore.daysRemainingBelow(group.date) <= 3 {
                                            Task {
                                                await feedStore.loadMoreDays(
                                                    mealStore: mealStore,
                                                    weightStore: weightStore,
                                                    workoutStore: workoutStore
                                                )
                                            }
                                        }
                                    }
                            }
                        }
                    } header: {
                        Text(dayLabel(group.date))
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            .textCase(nil)
                    }
                }

                if feedStore.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
            }
            .listStyle(.plain)
            .toolbar(.visible, for: .tabBar)
            .refreshable {
                await feedStore.refresh(
                    mealStore: mealStore,
                    weightStore: weightStore,
                    workoutStore: workoutStore,
                    financeStore: financeStore
                )
            }
            .navigationTitle(L.t("tab.home"))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showDebugLog = true } label: {
                        Image(systemName: "ladybug")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAnalytics = true } label: {
                        Image(systemName: "chart.xyaxis.line")
                    }
                }
            }
            .sheet(isPresented: $showAnalytics) {
                AnalyticsView()
            }
            .sheet(isPresented: $showDebugLog) {
                NavigationStack {
                    List {
                        ForEach(Array(FeedDebugLog.shared.lines.enumerated()), id: \.offset) { _, line in
                            Text(line).font(.caption2).monospaced()
                        }
                    }
                    .navigationTitle("Feed Debug")
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { showDebugLog = false }
                        }
                    }
                }
            }
            .navigationDestination(item: $selectedItemId) { itemId in
                Group {
                    if let item = feedStore.feedItems.first(where: { $0.id == itemId }),
                       let module = cardRegistry.module(for: item.cardType),
                       let detail = module.feedDetailView(item: item) {
                        detail
                    } else {
                        ContentUnavailableView(
                            L.t("common.loading"),
                            systemImage: "exclamationmark.triangle"
                        )
                    }
                }
                .toolbar(.hidden, for: .tabBar)
            }
            .onChange(of: refreshToken) {
                Task {
                    await feedStore.refreshToday(
                        mealStore: mealStore,
                        weightStore: weightStore,
                        workoutStore: workoutStore
                    )
                }
            }
            .sheet(isPresented: $showMealCreate, onDismiss: {
                Task {
                    await feedStore.refreshToday(
                        mealStore: mealStore,
                        weightStore: weightStore,
                        workoutStore: workoutStore
                    )
                }
            }) {
                MealCreateView()
            }
            .sheet(isPresented: $showWeightCreate, onDismiss: {
                Task {
                    await feedStore.refreshToday(
                        mealStore: mealStore,
                        weightStore: weightStore,
                        workoutStore: workoutStore
                    )
                }
            }) {
                WeightCreateView()
            }
            .task {
                await profileStore.load()
                await weightStore.load()
                await prefStore.load()
                feedStore.cachedProfile = profileStore.profile
                await feedStore.loadInitial(
                    mealStore: mealStore,
                    weightStore: weightStore,
                    workoutStore: workoutStore,
                    financeStore: financeStore
                )
                feedStore.startPortfolioRefresh(financeStore: financeStore)
            }
            .onDisappear {
                feedStore.stopPortfolioRefresh()
            }
        }
    }

    // MARK: - Unified Card Rendering (no card-type switches)
    //
    // Pattern for every card:
    //   1. Tap → detail view (if module.hasFeedDetailView)
    //   2. Swipe left → actions from module.feedSwipeActions

    @ViewBuilder
    private func feedCard(for item: FeedItem) -> some View {
        if let module = cardRegistry.module(for: item.cardType) {
            let cardView = module.feedCardView(item: item, displayTime: item.displayTime)

            if module.hasFeedDetailView {
                Button { selectedItemId = item.id } label: { cardView }
                    .buttonStyle(.plain)
            } else {
                cardView
            }
        }
    }

    @ViewBuilder
    private func swipeActions(for item: FeedItem) -> some View {
        if let module = cardRegistry.module(for: item.cardType) {
            if let custom = module.feedTrailingSwipeContent(item: item) {
                custom
            } else {
                ForEach(module.feedSwipeActions, id: \.self) { action in
                    switch action {
                    case .delete:
                        Button(role: .destructive) {
                            Task {
                                await feedStore.deleteItem(
                                    item,
                                    mealStore: mealStore,
                                    weightStore: weightStore,
                                    workoutStore: workoutStore
                                )
                            }
                        } label: {
                            Label(L.t("common.delete"), systemImage: "trash")
                        }
                    case .regenerate:
                        Button {
                            Task { await feedStore.regenerateSummary(for: item.dateString) }
                        } label: {
                            Label(L.t("summary.regenerate"), systemImage: "arrow.clockwise")
                        }
                        .tint(.blue)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func leadingSwipeActions(for item: FeedItem) -> some View {
        if let module = cardRegistry.module(for: item.cardType),
           let content = module.feedLeadingSwipeContent(item: item) {
            content
        }
    }

    // MARK: - Grouping

    private struct DayGroup: Identifiable {
        let date: String
        let items: [FeedItem]
        var id: String { date }
    }

    private func groupedByDate() -> [DayGroup] {
        var grouped = Dictionary(grouping: feedStore.feedItems) { $0.dateString }
        let today = dateFormatter.string(from: Date())
        if grouped[today] == nil {
            grouped[today] = []
        }
        return grouped
            .map { DayGroup(date: $0.key, items: $0.value) }
            .filter { !$0.items.isEmpty || $0.date == today }
            .sorted { $0.date > $1.date }
    }

    private func dayLabel(_ dateStr: String) -> String {
        let today = dateFormatter.string(from: Date())
        if dateStr == today { return L.t("common.today") }
        if let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()),
           dateFormatter.string(from: tomorrow) == dateStr {
            return L.t("feed.tomorrow")
        }
        if let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()),
           dateFormatter.string(from: yesterday) == dateStr {
            return L.t("feed.yesterday")
        }
        if let date = dateFormatter.date(from: dateStr) {
            let display = DateFormatter()
            display.dateFormat = "MMM d"
            return display.string(from: date)
        }
        return dateStr
    }
}
