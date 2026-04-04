import SwiftUI

struct PortfolioCardModule: CardModule {
    let cardType = "portfolio"
    let displayNameKey = "card.portfolio"
    let iconName = "chart.line.uptrend.xyaxis"
    let accentColor = Color.green
    let supportsManualCreation = false
    let hasFeedDetailView = true
    let hasDataListView = true
    let feedSwipeActions: [CardSwipeAction] = []

    @MainActor
    func feedCardView(item: FeedItem, displayTime: String?) -> AnyView {
        guard let summary = item.payload as? PortfolioSummaryResponse else { return AnyView(EmptyView()) }
        return AnyView(PortfolioFeedCard(summary: summary))
    }

    @MainActor
    func feedDetailView(item: FeedItem) -> AnyView? {
        guard let summary = item.payload as? PortfolioSummaryResponse else { return nil }
        return AnyView(PortfolioDetailView(date: summary.date))
    }

    @MainActor
    func dataListView() -> AnyView? {
        AnyView(PortfolioDetailView(date: {
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd"
            return f.string(from: Date())
        }()))
    }
}
