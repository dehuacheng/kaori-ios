import SwiftUI

struct NutritionCardModule: CardModule {
    let cardType = "nutrition"
    let displayNameKey = "card.nutrition"
    let iconName = "chart.bar.fill"
    let accentColor = Color.red
    let supportsManualCreation = false
    let feedSwipeActions: [CardSwipeAction] = []

    @MainActor
    func feedCardView(item: FeedItem, displayTime: String?) -> AnyView {
        guard let p = item.payload as? NutritionPayload else { return AnyView(EmptyView()) }
        return AnyView(DailyNutritionCard(totals: p.totals, profile: p.profile))
    }
}
