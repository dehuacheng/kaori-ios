# Card: Reminder/TODO (iOS)

## Module
| Property | Value |
|----------|-------|
| File | `CardModule/Modules/ReminderCardModule.swift` |
| cardType | `"reminder"` |
| icon | `checklist` |
| accentColor | Green |
| supportsManualCreation | Yes |
| hasFeedDetailView | Yes |
| hasDataListView | Yes |
| hasSettingsView | No |
| presentationStyle | .sheet |
| feedSwipeActions | Custom (see below) |
| sortPriority | 3 (pinned above chronological items) |

## Purpose

Date-targeted items with two subtypes:
- **todo**: Checkable, can be marked done or pushed to a later date
- **reminder**: Informational, stays visible until deleted

Overdue items and items due tomorrow automatically surface on today's feed.

## Swipe Actions
- **Swipe left (trailing)**: "Tomorrow" (push to tomorrow, orange) + "Delete" (red)
- **Swipe right (leading)**: "Done"/"Undo" (green) — only for todo type

Custom swipe views provided via `feedTrailingSwipeContent` / `feedLeadingSwipeContent` on CardModule protocol.

## FeedItem Factory
`FeedItem.reminder(...)` — payload type: `Reminder`

## Views
- Feed card: `Views/Feed/ReminderFeedCard.swift` — shows checkbox (todo) or bell (reminder), title, overdue badge, priority indicator
- Detail: `Views/Reminder/ReminderDetailView.swift` — full detail with push-to-date sheet
- Create: `Views/Reminder/ReminderCreateView.swift` — title, description, date, type, priority
- Data list: `Views/Reminder/ReminderListView.swift` — split into Active / Completed sections

## Store
`Stores/ReminderStore.swift` — CRUD + mark done + push via `/api/reminders`

## Backend
- `POST /api/reminders` — create {title, description, due_date, item_type, priority}
- `GET /api/reminders?date=...` — list for date (today includes overdue + tomorrow)
- `POST /api/reminders/{id}/done` — mark done/undone
- `POST /api/reminders/{id}/push` — push to new date
- `DELETE /api/reminders/{id}` — delete
