# Card Design Docs (iOS)

Every feature in Kaori is a **card type** implemented as a `CardModule`. Each card has a design doc here covering its iOS module, views, feed behavior, and interaction patterns.

**When adding or modifying a card, update its doc here.** See `CLAUDE.md` for the full checklist.

## Cards

| Card Type | Doc | Module | Feed Card | Detail View |
|-----------|-----|--------|-----------|-------------|
| `meal` | [meal.md](meal.md) | `MealCardModule` | `MealFeedCard` | `MealDetailView` |
| `weight` | [weight.md](weight.md) | `WeightCardModule` | `WeightFeedCard` | — |
| `workout` | [workout.md](workout.md) | `WorkoutCardModule` | `WorkoutFeedCard` | `WorkoutDetailView` |
| `healthkit_workout` | [healthkit-workout.md](healthkit-workout.md) | `HealthKitWorkoutCardModule` | `WorkoutFeedCard` | `ImportedWorkoutDetailView` |
| `portfolio` | [portfolio.md](portfolio.md) | `PortfolioCardModule` | `PortfolioFeedCard` | `PortfolioDetailView` |
| `nutrition` | [nutrition.md](nutrition.md) | `NutritionCardModule` | `DailyNutritionCard` | — |
| `summary` | [summary.md](summary.md) | `SummaryCardModule` | `SummaryFeedCard` | `SummaryDetailView` |
| `post` | [post.md](post.md) | `PostCardModule` | `PostFeedCard` | `PostDetailView` |
| `reminder` | [reminder.md](reminder.md) | `ReminderCardModule` | `ReminderFeedCard` | `ReminderDetailView` |

## Template for New Cards

```markdown
# Card: <Name> (iOS)

## Module
| Property | Value |
|----------|-------|
| File | `CardModule/Modules/XxxCardModule.swift` |
| cardType | `"xxx"` |
| icon | `<sf.symbol.name>` |
| accentColor | <Color> |
| supportsManualCreation | Yes/No |
| hasFeedDetailView | Yes/No |
| hasDataListView | Yes/No |
| hasSettingsView | Yes/No |
| presentationStyle | .sheet / .fullScreenCover |
| feedSwipeActions | [.delete] / [.regenerate] / [] |
| sortPriority | 10 (chronological) / 0-2 (pinned) |

## FeedItem Factory
`FeedItem.xxx(...)` — payload type: `Xxx` or `XxxPayload`

## Views
- Feed card: `Views/Xxx/XxxFeedCard.swift`
- Detail: `Views/Xxx/XxxDetailView.swift`
- Create: `Views/Xxx/XxxCreateView.swift`
- Data list: `Views/Xxx/XxxListView.swift`

## Store
`Stores/XxxStore.swift` — API calls, state management
```
