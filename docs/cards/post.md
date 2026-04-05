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

Personal microblog for quick thoughts with optional photo attachments (up to 5). No title required — just content, date, and optional photos.

## FeedItem Factory
`FeedItem.post(...)` — payload type: `Post`

## Views
- Feed card: `Views/Feed/PostFeedCard.swift`
- Detail: `Views/Post/PostDetailView.swift`
- Create: `Views/Post/PostCreateView.swift`
- Data list: `Views/Post/PostListView.swift`

## Store
`Stores/PostStore.swift` — CRUD via `/api/post`

## Share Extension
Posts can also be created via the iOS Share Extension (`KaoriShareExtension/`). When sharing from other apps (Xiaohongshu, Douyin, Safari, etc.):
- The extension appears in the iOS share sheet as "Kaori"
- Accepts URLs, text, and images
- For URLs: fetches Open Graph metadata (title, description, og:image) to enrich the post content
- Shows a compose view where the user can edit before saving
- Communicates with the backend via `SharedConfig` (App Group shared UserDefaults for server URL + token)

## Linked URLs
URLs in post content are rendered as tappable links via `LinkedText` (`Views/Shared/LinkedText.swift`), using `NSDataDetector` for URL detection. Works in both feed cards and detail views.

## Backend
- `POST /api/post` — create (multipart: photos + fields {post_date, title, content})
- `GET /api/post?date=...` — list by date
- `GET /api/post/{id}` — detail
- `PUT /api/post/{id}` — update
- `DELETE /api/post/{id}` — delete
