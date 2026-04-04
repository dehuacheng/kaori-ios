import SwiftUI

struct WeightCardModule: CardModule {
    let cardType = "weight"
    let displayNameKey = "card.weight"
    let iconName = "scalemass.fill"
    let accentColor = Color.cyan
    let supportsManualCreation = true
    let hasDataListView = true
    let presentationStyle = CardPresentationStyle.sheet

    @MainActor
    func feedCardView(item: FeedItem, displayTime: String?) -> AnyView {
        guard let entry = item.payload as? WeightEntry else { return AnyView(EmptyView()) }
        return AnyView(WeightFeedCard(entry: entry, displayTime: displayTime))
    }

    @MainActor
    func createView(onDismiss: @escaping () -> Void) -> AnyView? {
        AnyView(WeightCreateView())
    }

    @MainActor
    func dataListView() -> AnyView? {
        AnyView(WeightView())
    }
}
