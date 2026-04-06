# Card: Weather (iOS)

## Module
| Property | Value |
|----------|-------|
| File | `CardModule/Modules/WeatherCardModule.swift` |
| cardType | `"weather"` |
| icon | `cloud.sun.fill` |
| accentColor | .cyan |
| supportsManualCreation | No |
| hasFeedDetailView | No |
| hasDataListView | No |
| hasSettingsView | No |
| feedSwipeActions | [] |
| sortPriority | 4 (current), 5 (forecast) |

## FeedItem Factory
- `FeedItem.weatherCurrent(_ response:)` — payload type: `WeatherPayload` with `.current` kind
- `FeedItem.weatherForecast(_ response:forDate:)` — payload type: `WeatherPayload` with `.forecast` kind

Two FeedItems created per day from the single `WeatherResponse` in the feed API response.

## Views
- Feed card: `Views/Weather/WeatherFeedCard.swift` — renders both current and forecast styles based on `WeatherCardKind`

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

## Temperature Display
Backend stores Celsius. iOS converts to Fahrenheit for display.
