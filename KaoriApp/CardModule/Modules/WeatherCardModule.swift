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

    func feedItems(for group: FeedAPIDateGroup, context: CardFeedDateGroupContext) -> [FeedItem] {
        guard let weather = group.weather else { return [] }

        var items: [FeedItem] = []
        if weather.current != nil {
            items.append(.weatherCurrent(weather))
        }
        if weather.forecast != nil, shouldShowForecast(for: weather, groupDate: group.date, todayString: context.todayString) {
            items.append(.weatherForecast(weather, forDate: forecastSectionDate(for: weather, groupDate: group.date)))
        }
        return items
    }

    private func shouldShowForecast(for weather: WeatherResponse, groupDate: String, todayString: String) -> Bool {
        if groupDate == todayString {
            return true
        }
        if weather.current?.date == todayString {
            return true
        }
        return false
    }

    private func forecastSectionDate(for weather: WeatherResponse, groupDate: String) -> String {
        if let forecastDate = parseDateString(weather.forecast?.date),
           let currentDate = parseDateString(weather.current?.date),
           forecastDate > currentDate {
            return formatDateString(forecastDate)
        }

        if let forecastDate = parseDateString(weather.forecast?.date),
           let groupedDate = parseDateString(groupDate),
           forecastDate > groupedDate {
            return formatDateString(forecastDate)
        }

        if let currentDate = parseDateString(weather.current?.date),
           let nextDay = Calendar(identifier: .gregorian).date(byAdding: .day, value: 1, to: currentDate) {
            return formatDateString(nextDay)
        }

        if let nextDay = nextDateString(after: groupDate) {
            return nextDay
        }

        return weather.forecast?.date ?? groupDate
    }

    private func nextDateString(after dateString: String) -> String? {
        guard let date = parseDateString(dateString),
              let nextDay = Calendar(identifier: .gregorian).date(byAdding: .day, value: 1, to: date) else {
            return nil
        }
        return formatDateString(nextDay)
    }

    private func parseDateString(_ dateString: String?) -> Date? {
        guard let dateString else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.date(from: dateString)
    }

    private func formatDateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.string(from: date)
    }
}
