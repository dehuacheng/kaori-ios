import SwiftUI

struct SummaryCardModule: CardModule {
    let cardType = "summary"
    let displayNameKey = "card.summary"
    let iconName = "sparkles"
    let accentColor = Color.yellow
    let supportsManualCreation = true
    let hasFeedDetailView = true
    let hasDataListView = true
    let presentationStyle = CardPresentationStyle.sheet
    let feedSwipeActions: [CardSwipeAction] = [.delete, .regenerate]

    @MainActor
    func feedCardView(item: FeedItem, displayTime: String?) -> AnyView {
        guard let p = item.payload as? SummaryPayload else { return AnyView(EmptyView()) }
        return AnyView(SummaryFeedCard(text: p.text, date: p.date))
    }

    @MainActor
    func feedDetailView(item: FeedItem) -> AnyView? {
        guard let p = item.payload as? SummaryPayload else { return nil }
        let isWeekly = Calendar.current.component(.weekday, from: Date()) ==
            UserDefaults.standard.integer(forKey: "weeklySummaryWeekday")
        let type: SummaryDetailView.SummaryType = isWeekly ? .weekly : .daily(date: p.date)
        return AnyView(SummaryDetailView(summaryType: type))
    }

    @MainActor
    func createView(onDismiss: @escaping () -> Void) -> AnyView? {
        AnyView(SummaryGenerateView(onDismiss: onDismiss))
    }

    @MainActor
    func dataListView() -> AnyView? {
        AnyView(SummaryListView())
    }
}

/// Simple view that triggers summary generation and shows progress.
struct SummaryGenerateView: View {
    @Environment(FeedStore.self) private var feedStore
    @Environment(Localizer.self) private var L
    @Environment(NotificationSettings.self) private var notificationSettings
    let onDismiss: () -> Void

    @State private var isGenerating = false
    @State private var resultText: String?

    private var isWeeklySummaryDay: Bool {
        Calendar.current.component(.weekday, from: Date()) == notificationSettings.weeklySummaryWeekday
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if isGenerating {
                    ProgressView()
                        .controlSize(.large)
                    Text(L.t("summary.generating"))
                        .foregroundStyle(.secondary)
                } else if let text = resultText {
                    ScrollView {
                        Text(text)
                            .padding()
                    }
                } else {
                    Image(systemName: isWeeklySummaryDay ? "calendar.badge.clock" : "sparkles")
                        .font(.largeTitle)
                        .foregroundStyle(isWeeklySummaryDay ? .blue : .yellow)
                    Text(L.t(isWeeklySummaryDay ? "summary.weeklyTitle" : "summary.dailyTitle"))
                        .font(.title2.bold())
                    Text(L.t("summary.generating"))
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .navigationTitle(L.t("summary.aiSummary"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L.t("common.done")) { onDismiss() }
                }
            }
            .task {
                isGenerating = true
                if isWeeklySummaryDay {
                    resultText = await feedStore.generateWeeklySummary()
                } else {
                    resultText = await feedStore.generateDailySummary()
                }
                isGenerating = false
            }
        }
    }
}
