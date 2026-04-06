import SwiftUI

struct WeatherCardModule: CardModule {
    let cardType = "weather"
    let displayNameKey = "card.weather"
    let iconName = "cloud.sun.fill"
    let accentColor = Color.cyan
    let supportsManualCreation = false
    let hasFeedDetailView = true
    let hasDataListView = true
    let feedSwipeActions: [CardSwipeAction] = []

    @MainActor
    func feedCardView(item: FeedItem, displayTime: String?) -> AnyView {
        guard let payload = item.payload as? WeatherPayload else { return AnyView(EmptyView()) }
        return AnyView(WeatherFeedCard(payload: payload))
    }

    @MainActor
    func feedDetailView(item: FeedItem) -> AnyView? {
        guard let payload = item.payload as? WeatherPayload else { return nil }
        return AnyView(WeatherDetailView(payload: payload))
    }

    @MainActor
    func dataListView() -> AnyView? {
        AnyView(WeatherDataListView())
    }
}
