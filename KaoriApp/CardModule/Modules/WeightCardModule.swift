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

    func decodeFeedItem(_ item: FeedAPIItem, context: CardFeedDecodingContext) -> FeedItem? {
        guard item.type == cardType, let rawData = item.rawData,
              let entry = try? context.decoder.decode(WeightEntry.self, from: rawData) else {
            return nil
        }
        return .weight(entry)
    }

    @MainActor
    func deleteFeedItem(_ item: FeedItem, context: CardDeleteContext) async {
        guard let entry = item.payload as? WeightEntry else { return }
        try? await context.weightStore.delete(id: entry.id)
    }
}
