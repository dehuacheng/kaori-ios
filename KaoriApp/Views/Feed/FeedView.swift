import SwiftUI
import UIKit

/// Navigation target for feed card detail views. Carries stable identity
/// plus a snapshot of the tapped feed item so the destination can be built
/// at navigation time instead of storing a prebuilt AnyView in the path.
struct FeedNavigationTarget: Identifiable, Hashable {
    let id: String
    let item: FeedItem

    static func == (lhs: FeedNavigationTarget, rhs: FeedNavigationTarget) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

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
    @State private var selectedTarget: FeedNavigationTarget?
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
            feedList
            .listStyle(.plain)
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
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAnalytics = true } label: {
                        Image(systemName: "chart.xyaxis.line")
                    }
                }
            }
            .sheet(isPresented: $showAnalytics) {
                AnalyticsView()
            }
            .navigationDestination(item: $selectedTarget) { target in
                detailDestination(for: target)
                    .toolbar(.hidden, for: .tabBar)
                    .background { DetailSafeAreaForcer() }
                    .onAppear {
                    }
                    .onDisappear {
                        if selectedTarget?.id == target.id {
                            selectedTarget = nil
                        }
                    }
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

    private var feedList: some View {
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

            if module.canNavigateToFeedDetail(item: item),
               module.feedDetailView(item: item) != nil {
                let detailID = module.feedDetailNavigationID(item: item)
                Button {
                    selectedTarget = FeedNavigationTarget(
                        id: detailID,
                        item: item
                    )
                } label: {
                    cardView
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            } else {
                cardView
            }
        }
    }

    @ViewBuilder
    private func detailDestination(for target: FeedNavigationTarget) -> some View {
        if let module = cardRegistry.module(for: target.item.cardType),
           let detail = module.feedDetailView(item: target.item) {
            LoggedFeedDetailContainer {
                detail
            }
        } else {
            ContentUnavailableView(
                L.t("common.loading"),
                systemImage: "exclamationmark.triangle"
            )
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

private struct LoggedFeedDetailContainer<Content: View>: View {
    let content: Content
    @State private var fallbackTopInset: CGFloat = 0
    @State private var fallbackBottomInset: CGFloat = 0

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        GeometryReader { proxy in
            let safeTop = proxy.safeAreaInsets.top
            let safeBottom = proxy.safeAreaInsets.bottom
            let appliedTopInset = safeTop == 0 ? fallbackTopInset : 0
            let appliedBottomInset = safeBottom == 0 ? fallbackBottomInset : 0

            content
                .safeAreaInset(edge: .top, spacing: 0) {
                    Color.clear
                        .frame(height: appliedTopInset)
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    Color.clear
                        .frame(height: appliedBottomInset)
                }
                .background {
                    DetailChromeProbe(
                        fallbackTopInset: $fallbackTopInset,
                        fallbackBottomInset: $fallbackBottomInset
                    )
                }
        }
    }
}

// MARK: - Safe Area Fix

/// Forces the hosting view controller to recalculate safe area insets
/// when a detail view is pushed onto the NavigationStack.
///
/// Works around a SwiftUI bug where the NavigationStack's hosting
/// controller fails to propagate safe area to pushed content after
/// certain view-hierarchy mutations (e.g., overlay animations).
/// The fix: temporarily bump `additionalSafeAreaInsets` by a tiny
/// amount and reset, which triggers UIKit's full safe-area
/// propagation pass including `safeAreaInsetsDidChange` on all
/// descendant views.
private struct DetailSafeAreaForcer: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let v = SafeAreaForcerView()
        v.isHidden = true
        v.isUserInteractionEnabled = false
        return v
    }
    func updateUIView(_ uiView: UIView, context: Context) {}
}

private final class SafeAreaForcerView: UIView {
    private var didForce = false

    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard window != nil, !didForce else { return }
        didForce = true
        DispatchQueue.main.async { [weak self] in
            self?.forceSafeAreaRecalc()
        }
    }

    private func forceSafeAreaRecalc() {
        guard let vc = nearestViewController() else { return }
        let original = vc.additionalSafeAreaInsets
        // Bump top inset by a negligible amount to trigger recalculation
        vc.additionalSafeAreaInsets = UIEdgeInsets(
            top: original.top + 0.01,
            left: original.left,
            bottom: original.bottom,
            right: original.right
        )
        vc.view.setNeedsLayout()
        vc.view.layoutIfNeeded()
        // Restore original insets — the layout pass already recalculated
        vc.additionalSafeAreaInsets = original
        vc.view.setNeedsLayout()
        vc.view.layoutIfNeeded()
    }

    private func nearestViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while let current = responder {
            if let vc = current as? UIViewController { return vc }
            responder = current.next
        }
        return nil
    }
}

private struct DetailChromeProbe: UIViewRepresentable {
    @Binding var fallbackTopInset: CGFloat
    @Binding var fallbackBottomInset: CGFloat

    func makeUIView(context: Context) -> DetailChromeProbeView {
        let view = DetailChromeProbeView()
        view.onMetrics = { top, bottom in
            fallbackTopInset = top
            fallbackBottomInset = bottom
        }
        return view
    }

    func updateUIView(_ uiView: DetailChromeProbeView, context: Context) {
        uiView.onMetrics = { top, bottom in
            fallbackTopInset = top
            fallbackBottomInset = bottom
        }
        uiView.report()
    }
}

private final class DetailChromeProbeView: UIView {
    var onMetrics: ((CGFloat, CGFloat) -> Void)?
    private var lastTopInset: CGFloat = -1
    private var lastBottomInset: CGFloat = -1

    override func didMoveToWindow() {
        super.didMoveToWindow()
        report()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        report()
    }

    override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        report()
    }

    func report() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            guard let vc = self.nearestViewController() else { return }
            let navBarMaxY = vc.navigationController?.navigationBar.frame.maxY ?? 0
            let tabBarHeight = vc.tabBarController?.tabBar.frame.height ?? 0
            let windowBottom = self.window?.safeAreaInsets.bottom ?? 0
            let bottomInset = max(tabBarHeight - windowBottom, 0)

            if abs(navBarMaxY - lastTopInset) > 0.5 || abs(bottomInset - lastBottomInset) > 0.5 {
                lastTopInset = navBarMaxY
                lastBottomInset = bottomInset
                onMetrics?(navBarMaxY, bottomInset)
            }
        }
    }

    private func nearestViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while let current = responder {
            if let vc = current as? UIViewController { return vc }
            responder = current.next
        }
        return nil
    }
}
