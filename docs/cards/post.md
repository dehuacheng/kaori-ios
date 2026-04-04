# Card: Post (iOS)

## Module
| Property | Value |
|----------|-------|
| File | `CardModule/Modules/PostCardModule.swift` |
| cardType | `"post"` |
| icon | `note.text` |
| accentColor | Purple |
| supportsManualCreation | Yes |
| hasFeedDetailView | Yes |
| hasDataListView | Yes |
| hasSettingsView | No |
| presentationStyle | .sheet |
| feedSwipeActions | [.delete] (default) |
| sortPriority | 10 (chronological) |

## Purpose

Personal microblog for quick thoughts. No title required — just content and date.

## FeedItem Factory
`FeedItem.post(...)` — payload type: `Post`

## Views
- Feed card: `Views/Feed/PostFeedCard.swift`
- Detail: `Views/Post/PostDetailView.swift`
- Create: `Views/Post/PostCreateView.swift`
- Data list: `Views/Post/PostListView.swift`

## Store
`Stores/PostStore.swift` — CRUD via `/api/post`

## Backend
- `POST /api/post` — create {date, content}
- `GET /api/post?date=...` — list by date
- `GET /api/post/{id}` — detail
- `PUT /api/post/{id}` — update
- `DELETE /api/post/{id}` — delete
