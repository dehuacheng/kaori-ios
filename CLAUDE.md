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

## Backend Repo
GitHub: https://github.com/dehuacheng/kaori
