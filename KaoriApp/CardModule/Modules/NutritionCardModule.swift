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

    func feedItems(for group: FeedAPIDateGroup, context: CardFeedDateGroupContext) -> [FeedItem] {
        if let totals = group.nutritionTotals, totals.totalCal > 0 {
            return [.nutrition(totals, context.cachedProfile, date: group.date)]
        }

        if group.date == context.todayString {
            let zeroTotals = NutritionTotals(totalCal: 0, totalProtein: 0, totalCarbs: 0, totalFat: 0)
            return [.nutrition(zeroTotals, context.cachedProfile, date: group.date)]
        }

        return []
    }
}
