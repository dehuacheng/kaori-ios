# KaoriApp — iOS Client

## Overview
SwiftUI iOS client for the Kaori personal life management app. Connects to the Kaori Python backend via JSON API over Tailscale.

## Architecture
- **Pure thin client** — no local database, all data fetched from the backend
- **iOS 17.0+**, SwiftUI with `@Observable` state management
- **Zero external dependencies** — only Apple frameworks

## Structure
```
KaoriApp/
  Config/         — AppConfig (server URL + token in UserDefaults)
  Network/        — APIClient (URLSession wrapper), APIError
  Models/         — Codable structs matching backend JSON responses
    FeedItem.swift    — Unified feed item enum (meal, weight, workout, summary)
    Meal.swift        — Meal, MealListResponse, NutritionTotals
    Weight.swift      — WeightEntry, WeightResponse, WeightCreate
    Workout.swift     — Workout, WorkoutDetail, ExerciseSet, etc.
    Profile.swift     — Profile, ProfileUpdate, WeightUnit/HeightUnit enums
    Summary.swift     — SummaryDetail
    ImportedWorkoutMeta.swift — Apple Health workout metadata
  Stores/         — @Observable stores (MealStore, WeightStore, ProfileStore, WorkoutStore, FinanceStore)
  Utils/          — UnitConverter (kg/lb, cm/in conversion + formatting)
  Views/
    Feed/           — Feed timeline and card components (see App Layout below)
    Meals/          — MealListView, MealCreateView, MealDetailView, MealEditView
    Weight/         — WeightView, WeightCreateView, WeightChartView
    Workout/        — WorkoutListView, WorkoutDetailView, SetRowView, TimerView
    Profile/        — ProfileView
    Settings/       — SettingsView, NotificationSettingsView
    Summary/        — SummaryDetailView, SummarySectionsView
    AnalyticsView.swift — Calorie + weight charts (shown as sheet)
    Finance/        — Account list, account detail, holdings import (screenshot/PDF)
    Portfolio/      — Portfolio feed card, portfolio detail view
    ManageView.swift    — "More" tab: data, tools, profile, settings menu
  Health/         — HealthKitManager (weight + workout sync)
  Notifications/  — NotificationManager, NotificationSettings, BackgroundTaskManager
  Localization/   — en.json, zh-Hans.json (flat key-value)
```

## App Layout (3 Tabs)

### Tab 1: Home (Feed)
- **FeedView** — multi-day infinite scroll timeline
- Day headers ("Today", "Yesterday", "Apr 1")
- Per-day pinned cards (top to bottom):
  1. **AI Summary card** (daily or weekly, only for today, after configured hour)
  2. **DailyNutritionCard** (4 progress bars: calories, protein, carbs, fat vs targets)
  3. **Feed item cards** (meals, weight, workouts) sorted by time, newest first
- Pull-to-refresh reloads data
- Tap cards → detail views (tab bar hidden)
- Swipe left → delete (all items) or regenerate (summaries)

### Tab 2: "+" (Add Menu)
- Center tab, intercepted — never actually navigated to
- Opens iOS 18 Control Center–style overlay:
  - Dark dimmed backdrop, frosted glass panel with 3 square buttons
  - **Meal** → MealCreateView sheet
  - **Weight** → WeightCreateView sheet
  - **Workout** → creates workout, opens WorkoutDetailView as full-screen cover
- Workout auto-deleted on dismiss if no exercises were added
- Tap outside to dismiss

### Tab 3: More
- **MoreView** — list menu with NavigationLinks:
  - Data: Meals, Weight, Gym (existing list/detail views)
  - Tools: Timer
  - Profile, Settings

### Other Overlays
- **AnalyticsView** — opened via chart icon in feed nav bar (sheet)
  - Daily calorie bar chart (30 days, with target line)
  - Weight trend chart (with range presets)
- **SummaryDetailView** — full markdown summary with collapsible sections, regenerate in toolbar

## Data Flow

### Feed (Client-Side Merge)
- FeedView fetches meals, weight, workouts per date using existing API endpoints
- Merges into `[FeedItem]` sorted by `sortDate` (newest first)
- `FeedItem` enum: `.meal(Meal)`, `.weight(WeightEntry)`, `.workout(Workout, meta:)`, `.summary(text, date)`
- Imported workouts use `ImportedWorkoutMeta.startDate` for time sorting/display
- `NutritionTotals` captured per-date from meal API responses
- Pagination: loads today + yesterday initially, loads more days on scroll

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
- **Detail view actions** (delete, reanalyze, etc.) go in a `...` toolbar menu with confirmation alerts for destructive actions.
- **Nutrition progress bars** use colored bars: red (calories), blue (protein), orange (carbs), yellow (fat)

## Backend Repo
GitHub: https://github.com/dehuacheng/kaori
