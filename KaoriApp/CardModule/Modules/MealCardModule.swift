import SwiftUI

struct MealCardModule: CardModule {
    let cardType = "meal"
    let displayNameKey = "card.meal"
    let iconName = "fork.knife"
    let accentColor = Color.orange
    let supportsManualCreation = true
    let hasFeedDetailView = true
    let hasDataListView = true
    let presentationStyle = CardPresentationStyle.sheet

    @MainActor
    func feedCardView(item: FeedItem, displayTime: String?) -> AnyView {
        guard let meal = item.payload as? Meal else { return AnyView(EmptyView()) }
        return AnyView(MealFeedCard(meal: meal, displayTime: displayTime))
    }

    @MainActor
    func feedDetailView(item: FeedItem) -> AnyView? {
        guard let meal = item.payload as? Meal else { return nil }
        return AnyView(MealDetailView(mealId: meal.id))
    }

    @MainActor
    func createView(onDismiss: @escaping () -> Void) -> AnyView? {
        AnyView(MealCreateView())
    }

    @MainActor
    func dataListView() -> AnyView? {
        AnyView(MealListView())
    }

    func decodeFeedItem(_ item: FeedAPIItem, context: CardFeedDecodingContext) -> FeedItem? {
        guard item.type == cardType, let rawData = item.rawData,
              let meal = try? context.decoder.decode(Meal.self, from: rawData) else {
            return nil
        }
        return .meal(meal)
    }

    @MainActor
    func deleteFeedItem(_ item: FeedItem, context: CardDeleteContext) async {
        guard let meal = item.payload as? Meal else { return }
        _ = try? await context.mealStore.deleteMeal(meal.id)
    }
}
