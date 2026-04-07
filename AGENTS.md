# KaoriApp — iOS Client

## Overview
SwiftUI iOS client for the Kaori personal life management app. Connects to the Kaori Python backend via JSON API over Tailscale.

## Architecture
- **Pure thin client** — no local database, all data fetched from the backend
- **iOS 17.0+**, SwiftUI with `@Observable` state management
- **One external dependency** — [MarkdownUI](https://github.com/gonzalezreal/swift-markdown-ui) for AI chat markdown rendering

## Structure
```
KaoriApp/
  Config/         — AppConfig (server URL + token in UserDefaults), SharedConfig (App Group shared defaults for extensions)
  Network/        — APIClient (URLSession wrapper), APIError, SSEClient (agent chat streaming)
  Models/         — Codable structs matching backend JSON responses
    FeedItem.swift    — Unified feed item struct with `payload: Any`
    Meal.swift        — Meal, MealListResponse, NutritionTotals
    Weight.swift      — WeightEntry, WeightResponse, WeightCreate
    Workout.swift     — Workout, WorkoutDetail, ExerciseSet, etc.
    Profile.swift     — Profile, ProfileUpdate, WeightUnit/HeightUnit enums
    Summary.swift     — SummaryDetail
    Finance.swift     — PortfolioSummaryResponse, FinancialAccount, etc.
    Agent.swift       — AgentSession, AgentMessage, AgentMemoryEntry, AgentPrompt, SSE event types
    ImportedWorkoutMeta.swift — Apple Health workout metadata
  CardModule/     — Card-first architecture (see below)
    CardModule.swift      — Protocol definition
    CardRegistry.swift    — Module registry (@Observable, injected via Environment)
    Modules/              — One file per card type
      MealCardModule.swift, WeightCardModule.swift, WorkoutCardModule.swift,
      HealthKitWorkoutCardModule.swift, PortfolioCardModule.swift,
      NutritionCardModule.swift, SummaryCardModule.swift, WeatherCardModule.swift,
      PostCardModule.swift, ReminderCardModule.swift
  Stores/         — @Observable stores
    MealStore, WeightStore, ProfileStore, WorkoutStore, FinanceStore
    FeedStore         — Unified feed state (calls /api/feed or per-endpoint fallback)
    CardPreferenceStore — Card enable/disable preferences
    AgentStore        — Agent chat sessions, SSE streaming, memory, prompts
  Utils/          — UnitConverter (kg/lb, cm/in conversion + formatting)
  Views/
    Feed/           — Feed timeline and card components (see App Layout below)
    Meals/          — MealListView, MealCreateView, MealDetailView, MealEditView
    Weight/         — WeightView, WeightCreateView, WeightChartView
    Workout/        — WorkoutListView, WorkoutDetailView, SetRowView, TimerView
    Profile/        — ProfileView
    Settings/       — SettingsView, NotificationSettingsView, CardModuleSettingsView
    Summary/        — SummaryDetailView, SummarySectionsView
    AnalyticsView.swift — Calorie + weight charts (shown as sheet)
    Finance/        — Account list, account detail, holdings import (screenshot/PDF)
    Portfolio/      — Portfolio feed card, portfolio detail view
    Weather/        — Weather feed, detail, and history/location views
    Reminder/       — Reminder feed, detail, create/edit, and list views
    Post/           — Post feed, detail, create/edit, and list views
    Chat/           — ChatSessionListView, ChatView, ChatBubbleView, AgentMemoryView
    ManageView.swift    — "More" tab: data, tools, profile, finances, settings menu
  Health/         — HealthKitManager (weight + workout sync)
  Notifications/  — NotificationManager, NotificationSettings, BackgroundTaskManager
  Localization/   — en.json, zh-Hans.json (flat key-value)
  Shared/         — LinkedText (URL-detecting tappable text view)
KaoriShareExtension/  — iOS Share Extension (share from other apps → Post card)
```

## Card-First Architecture

Kaori is a **feed-first, card-first** app. Every user-facing feature is a **card type** — the atomic unit of the app. Before adding a new feature or modifying an existing one, think: "which card does this belong to?"

### Design Principles
1. **No card is special in the feed.** All cards flow through one unified `ForEach` in FeedView. Ranking (priority) differs per card, but rendering and interaction are uniform.
2. **Every card follows the same interaction pattern:** tap → detail view (if any), swipe left → contextual actions (if any). No inline expand/collapse, no special buttons.
3. **Parallel development.** Adding a new card type should NOT require editing FeedView, MoreView, CardModuleSettingsView, shared feed decode/delete logic, or add-menu routing. The expected shared touchpoint is manual registration in app bootstrap. If your change adds a `switch` or `if cardType ==` to shared rendering/routing code, you're doing it wrong.
4. **Data section is for data.** More > Data shows raw data for browsing/editing/deleting. Analytics and charts are separate (accessed via the chart icon in the feed nav bar).

### FeedItem (struct, not enum)
`FeedItem` is a **struct** with `payload: Any` — NOT a Swift enum. This is intentional: new card types create `FeedItem` instances via static factory methods (e.g., `FeedItem.post(...)`) without modifying `FeedItem.swift`. Each `CardModule` casts `item.payload as? MyType` to extract its data. Key stored properties: `id`, `cardType`, `dateString`, `sortPriority`, `sortDate`, `displayTime`.

### CardModule Protocol
Defined in `KaoriApp/CardModule/CardModule.swift`. Each card module provides:
- **Identity**: `cardType`, `displayNameKey`, `iconName`, `accentColor`
- **Behavior**: `supportsManualCreation`, `presentationStyle`, `feedSwipeActions`, `hasFeedDetailView`
- **Feed ownership**: `decodeFeedItem`, `feedItems(for:)`, `deleteFeedItem`, `performAddAction`
- **Views**: `feedCardView(item:)`, `feedDetailView(item:)`, `createView()`, `dataListView()`, `settingsView()`

### CardRegistry
`KaoriApp/CardModule/CardRegistry.swift` — keyed registry of all registered modules, injected via `@Environment`. It drives feed rendering, feed decoding, derived date-group cards, deletion routing, "+" menu actions, Data tab, and card settings. FeedView has **zero** card-type switches — it delegates everything to the registry.

### Adding a New Card Type (iOS)
1. **Write a card design doc** at `docs/cards/<type>.md` (see `docs/cards/README.md` for template)
2. Create `KaoriApp/CardModule/Modules/XxxCardModule.swift` conforming to `CardModule`
3. Add a static factory `FeedItem.xxx(...)` if needed, and implement the module's feed hooks (`decodeFeedItem`, `feedItems(for:)`, `deleteFeedItem`, `performAddAction`) as appropriate
4. Create feed card view, create view, data list view as needed under `Views/Xxx/`
5. Register in `KaoriApp.init()`: `registry.register(XxxCardModule())`
6. Add localization keys to both `en.json` and `zh-Hans.json`
7. **No other shared files should need modification** — FeedView, MoreView, CardModuleSettingsView, shared feed decode/delete logic, and add-menu routing are registry/module-driven

### Modifying an Existing Card Type
- All changes to a card's views stay within that card's module file and its associated view files
- The CardModule protocol ensures consistent behavior across all card types, including feed decode/delete/add behavior
- Do NOT add card-specific logic to FeedView, MoreView, or shared feed routing code — those are generic and registry-driven
- **Update the card's design doc** in `docs/cards/<type>.md` to reflect the change

### Card Design Docs
Every card type has a design doc at `docs/cards/<type>.md` covering module properties, views, store, FeedItem factory, and interaction patterns. See `docs/cards/README.md` for the index and template. **These docs must be kept in sync with the code.**

### Key Invariants (enforced by pre-commit check)
- All feed cards MUST use `.feedCard()` modifier
- All card types MUST be registered in CardRegistry
- FeedView.swift, MoreView.swift, and app bootstrap/add-menu routing MUST NOT contain `switch` or `if`/`case` on card types or `FeedItem` payloads — all card-specific logic lives in CardModule implementations
- FeedStore.swift MUST NOT contain central card-type decode switches or payload-casting delete chains for app cards
- "+" menu options come from `CardRegistry.addableModules` — never hardcode
- Data tab entries come from `CardRegistry.dataModules` — never hardcode
- Swipe actions come from `module.feedSwipeActions` — never hardcode per-type
- Detail navigation comes from `module.feedDetailView(item:)` — never hardcode per-type
- Card enable/disable is managed via `CardPreferenceStore`

### Pre-Commit Design Check
Before pushing to GitHub, verify these constraints:
```bash
# Must return 0 results — no card-type switches in shared files
grep -n 'switch item.type\|case "meal"\|case "weight"\|case "workout"\|case "summary"' \
  KaoriApp/Stores/FeedStore.swift \
  KaoriApp/KaoriApp.swift
grep -n 'case \.meal\|case \.weight\|case \.workout\|case \.summary\|case \.portfolio\|case \.nutrition' \
  KaoriApp/Views/Feed/FeedView.swift \
  KaoriApp/Views/ManageView.swift \
  KaoriApp/KaoriApp.swift
# Must return 0 — no payload type checks in shared files
grep -n 'as? Meal\|as? WeightEntry\|as? Workout\|as? SummaryPayload\|as? PortfolioSummary\|as? NutritionPayload' \
  KaoriApp/Stores/FeedStore.swift \
  KaoriApp/Views/Feed/FeedView.swift \
  KaoriApp/Views/ManageView.swift
```
If either returns results, the change violates the card-first architecture. Move the logic into the appropriate `CardModule`.

## App Layout (4 Tabs)

### Tab 1: Home (Feed)
- **FeedView** — multi-day infinite scroll timeline, powered by `FeedStore`
- Day headers ("Today", "Yesterday", "Apr 1")
- **All cards rendered uniformly** via one `ForEach` — no hardcoded sections for any card type
- Cards sorted by `(date desc, sortPriority asc, sortDate desc)` — pinned cards (summary=0, portfolio=1, nutrition=2) appear first, then chronological items (priority=10)
- Portfolio card hidden on weekends/market-closed days
- Nutrition card always shown for today (even with zero values)
- Prefetches 7 days when ≤3 days remain while scrolling
- Pull-to-refresh reloads all data via `FeedStore`
- Tap → detail view (via `module.feedDetailView`), Swipe left → actions (via `module.feedSwipeActions`)

### Tab 2: Chat
- **ChatSessionListView** — session list with create/delete
- Tap → **ChatView** with SSE streaming, MarkdownUI rendering, tool call indicators, and session memory
- Tab bar hidden in ChatView (`.toolbar(.hidden, for: .tabBar)`)

### Tab 3: "+" (Add Menu)
- Center tab, intercepted — never actually navigated to
- Opens iOS 18 Control Center–style overlay:
  - Dark dimmed backdrop, frosted glass panel with buttons driven by `CardRegistry.addableModules`
  - **Meal** → MealCreateView sheet
  - **Weight** → WeightCreateView sheet
  - **Workout** → creates workout, opens WorkoutDetailView as full-screen cover
  - **Summary** → triggers AI summary generation
- Workout auto-deleted on dismiss if no exercises were added
- Tap outside to dismiss

### Tab 4: More
- **MoreView** — list menu with NavigationLinks:
  - Data: driven by `CardRegistry.dataModules` (Meals, Weight, Gym, Portfolio, etc.)
  - Tools: Timer
  - Profile (personal data), Finances (account setup, parallel to Profile), Settings (app behavior)

### Other Overlays
- **AnalyticsView** — opened via chart icon in feed nav bar (sheet)
  - Daily calorie bar chart (30 days, with target line)
  - Weight trend chart (with range presets)
- **SummaryDetailView** — full markdown summary with collapsible sections, regenerate in toolbar

## Data Flow

### Feed (FeedStore)
- `FeedStore` calls unified `GET /api/feed?start_date=...&end_date=...` (falls back to per-endpoint fetching if unavailable)
- **All card types** (meals, weight, workouts, summary, portfolio, nutrition) stored as `FeedItem` structs in `feedItems: [FeedItem]` — no side dictionaries
- `FeedItem` is a struct with `payload: Any`. Factory methods: `.meal()`, `.weight()`, `.workout()`, `.summary()`, `.portfolio()`, `.nutrition()`
- Sorted by `(date desc, sortPriority asc, sortDate desc)`
- Pagination: loads today + yesterday initially, prefetches 7 days when ≤3 remain
- Portfolio auto-refreshes every 60s (market days only) via `FeedStore.startPortfolioRefresh()`
- Card preferences (`CardPreferenceStore`) control which card types are visible

### Timestamps
- Backend stores `created_at` in UTC (`datetime('now')` → `"yyyy-MM-dd HH:mm:ss"`)
- `parseUTCTimestamp()` and `formatLocalTime()` in FeedItem.swift handle UTC→local conversion
- All displayed times are local timezone

### Unit Preferences
- Stored on backend profile: `unit_body_weight` (kg/lb), `unit_height` (cm/in), `unit_exercise_weight` (kg/lb)
- DB always stores metric; conversion at iOS display/input layer via `UnitConverter`
- Three preferences are independent (e.g., body weight in kg, exercise weight in lb)
- Imperial height displayed as `5'10"` (ft/in), input via two fields

### Photo Handling
- iOS resizes to max 1600px before JPEG compression (quality 0.8)
- Backend also resizes on save (max 1600px, JPEG quality 85) as safety net
- Photos served as static files via `/photos/{path}`

## Backend API
- Base URL: configured at runtime (Tailscale IP/hostname + port)
- Auth: `Authorization: Bearer <token>` on all `/api/*` routes
- Health check: `GET /api/health` (unauthenticated)
- Meals: `GET/POST/PUT/DELETE /api/meals/*` (POST is multipart for photo upload)
- Weight: `GET/POST/PUT/DELETE /api/weight/*` (JSON bodies)
- Workouts: `GET/POST/PUT/DELETE /api/workouts/*` (JSON bodies)
- Profile: `GET/PUT /api/profile` (JSON body, includes unit preferences)
- Summaries: `GET/POST /api/summary/daily-detail`, `GET/POST /api/summary/weekly-detail`

## Building
1. Install Xcode from the App Store
2. `xcodegen generate` (requires `brew install xcodegen`)
3. Open `KaoriApp.xcodeproj` in Xcode
4. Sign with personal Apple ID (Signing & Capabilities)
5. Connect iPhone via USB, select as destination, hit Run (Cmd+R)

## Free Provisioning
- No paid Apple Developer Account required
- Certificate expires every 7 days — re-sign by hitting Run in Xcode
- App data persists across re-signings

## README — Bilingual (EN/CN)
- `README.md` contains both English and Chinese versions using `<details>` toggles.
- **When updating the README, always update both language sections to keep them in sync.**
- English is open by default; Chinese is collapsed.

## Localization (In-App EN/CN)
- The app supports English and Simplified Chinese via an in-app language toggle in Settings.
- Translation files: `KaoriApp/Localization/en.json` and `KaoriApp/Localization/zh-Hans.json` (flat key-value JSON).
- **When adding new user-facing strings, add keys to BOTH `en.json` and `zh-Hans.json`. Never hardcode strings in views.**
- Use `@Environment(Localizer.self) private var L` in views, then `L.t("key")` or `L.t("key", arg1, arg2)` for interpolation.
- Key naming convention: `{feature}.{element}` (e.g., `meal.logMeal`, `common.save`, `feed.empty`).
- Units (kg, kcal, g, cm) are NOT localized — they are international.
- The widget extension (`KaoriTimerWidget`) is not localized (separate target, minimal text).

## Design Language

The app follows an **Apple Health–inspired** aesthetic:
- **Feed cards** use `FeedCardModifier` (`.feedCard()`) — `secondarySystemGroupedBackground`, 16pt padding, 14pt continuous corner radius. All feed cards MUST use this modifier.
- **Card headers** use colored SF Symbols (`.fill` variants) + colored bold text per type:
  - Meals: orange (sunrise/sun.max/moon/leaf icons per meal type)
  - Weight: cyan (scalemass.fill)
  - Workouts: orange (flame.fill)
  - Daily summary: yellow (sparkles)
  - Weekly summary: blue (calendar.badge.clock)
- **"+" add menu** uses iOS 18 Control Center style: dark dimmed backdrop (`Color.black.opacity(0.4)`), frosted glass panel (`.ultraThinMaterial` dark mode), translucent rounded square buttons (`white.opacity(0.15)`) with white icons and subdued labels
- **Tab bar** hides when navigating into detail views (`.toolbar(.hidden, for: .tabBar)`)
- **Swipe left** on feed items reveals contextual actions (delete for all items, regenerate for summaries). This is the standard pattern for revealing actions — do NOT use inline buttons or `...` menus on feed cards.
- **Tap** on feed cards navigates to the full detail view. Cards should NOT expand/collapse inline.
- **Feed cards are passive** — no nested tappable/editable controls inside the card body. Passive horizontal media scrolling is allowed for photo carousels (for example meal/post cards), but buttons, menus, toggles, text fields, and custom tap gestures belong in the detail view instead.
- **Detail view actions** (delete, reanalyze, etc.) go in a `...` toolbar menu with confirmation alerts for destructive actions.
- **Nutrition progress bars** use colored bars: red (calories), blue (protein), orange (carbs), yellow (fat)

## Backend Repo
GitHub: https://github.com/dehuacheng/kaori
