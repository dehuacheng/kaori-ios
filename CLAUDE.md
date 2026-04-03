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
  Stores/         — @Observable stores (MealStore, WeightStore, ProfileStore)
  Views/          — SwiftUI views organized by feature
```

## Backend API
- Base URL: configured at runtime (Tailscale IP/hostname + port)
- Auth: `Authorization: Bearer <token>` on all `/api/*` routes
- Health check: `GET /api/health` (unauthenticated)
- Meals: `GET/POST/PUT/DELETE /api/meals/*` (POST is multipart for photo upload)
- Weight: `GET/POST/PUT/DELETE /api/weight/*` (JSON bodies)
- Profile: `GET/PUT /api/profile` (JSON body)

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
- Key naming convention: `{feature}.{element}` (e.g., `dashboard.today`, `meal.logMeal`, `common.save`).
- Units (kg, kcal, g, cm) are NOT localized — they are international.
- The widget extension (`KaoriTimerWidget`) is not localized (separate target, minimal text).

## Design Language

The app follows an **Apple Health–inspired** aesthetic:
- **Feed cards** use `FeedCardModifier` (`.feedCard()`) — `secondarySystemGroupedBackground`, 16pt padding, 14pt continuous corner radius
- **Card headers** use colored SF Symbols + colored bold text per type: orange (meals), cyan (weight), orange/flame (workouts), yellow/sparkles (daily summary), blue/calendar (weekly summary), purple (AI)
- **"+" add menu** uses iOS 18 Control Center style: dark dimmed backdrop, frosted glass panel (`.ultraThinMaterial` dark), translucent rounded square buttons with white icons
- **Tab bar** hides when navigating into detail views (`.toolbar(.hidden, for: .tabBar)`)
- **Swipe left** on feed items reveals contextual actions (delete for all items, regenerate for summaries)
- **Tap** on feed cards navigates to the full detail view (meals → MealDetailView, workouts → WorkoutDetailView, summaries → SummaryDetailView). Cards should NOT expand/collapse inline.
- All new feed cards must use `.feedCard()` for consistent styling

## Backend Repo
GitHub: https://github.com/dehuacheng/kaori
