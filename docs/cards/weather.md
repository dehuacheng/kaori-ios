# Card: Weather (iOS)

## Module
| Property | Value |
|----------|-------|
| File | `CardModule/Modules/WeatherCardModule.swift` |
| cardType | `"weather"` |
| icon | `cloud.sun.fill` |
| accentColor | .cyan |
| supportsManualCreation | No |
| hasFeedDetailView | Yes |
| hasDataListView | Yes |
| hasSettingsView | No |
| feedSwipeActions | [] |
| sortPriority | 0 (current), 0 (forecast) |

## FeedItem Factory
- `FeedItem.weatherCurrent(_ response:)` — payload type: `WeatherPayload` with `.current` kind
- `FeedItem.weatherForecast(_ response:forDate:)` — payload type: `WeatherPayload` with `.forecast` kind

Two `FeedItem`s can be created per day from the single `WeatherResponse` in the feed API response:
- `weatherCurrent` for current conditions when current data is available
- `weatherForecast` for the daily forecast when forecast data is available

The module owns this date-group contribution through `WeatherCardModule.feedItems(for:context:)`, so `FeedStore` does not need special weather branching.

## Views
- Feed card: `Views/Weather/WeatherFeedCard.swift` — renders both current and forecast styles based on `WeatherCardKind`
- Detail: `Views/Weather/WeatherDetailView.swift`
- Data list: `Views/Weather/WeatherDataListView.swift`

## Payload Types
```swift
enum WeatherCardKind { case current, forecast }
struct WeatherPayload {
    let data: WeatherData
    let location: WeatherLocation?
    let isLive: Bool
    let kind: WeatherCardKind
}
```

## Location
`Utils/LocationManager.swift` — CLLocationManager wrapper.
- Requests "when in use" authorization on app launch
- Gets current location, reverse geocodes to city name
- Saves to backend via `PUT /api/weather/location`

## Feed Behavior
- Weather cards are derived from the top-level feed date group, not from per-item rows.
- Only the live/today weather group contributes a forecast card. Past weather groups never generate an additional "Tomorrow" card.
- The current card stays in the source date section, while the forecast card is filed under the next day's section.
- When feed grouping and weather payload dates differ, the module prefers the payload's own date to place the forecast card correctly.
- Weather cards sort with pinned priority and therefore appear near the top of the date group.
- The module provides a feed detail view and a data list/history surface.

## Temperature Display
Backend stores Celsius. iOS converts to Fahrenheit for display.
