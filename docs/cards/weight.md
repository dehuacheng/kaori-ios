# Card: Weight (iOS)

## Module

| Property | Value |
|----------|-------|
| File | `CardModule/Modules/WeightCardModule.swift` |
| cardType | `"weight"` |
| icon | `scalemass.fill` |
| accentColor | Cyan |
| supportsManualCreation | Yes |
| presentationStyle | `.sheet` |
| hasFeedDetailView | No |
| hasDataListView | Yes |
| hasSettingsView | No |
| feedSwipeActions | `[.delete]` |
| sortPriority | 10 |

## FeedItem

Factory: `FeedItem.weight(...)`
Payload type: `WeightEntry`

## Views

| View | File | Purpose |
|------|------|---------|
| WeightFeedCard | `Views/Weight/WeightFeedCard.swift` | Compact card shown in the daily feed |
| WeightCreateView | `Views/Weight/WeightCreateView.swift` | Sheet for logging a new weight entry |
| WeightView | `Views/Weight/WeightView.swift` | Data list view with weight history and trend chart |

## Store

`Stores/WeightStore.swift` — Manages weight entries, syncs with backend API, provides trend data for charting.
