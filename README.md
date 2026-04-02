# Kaori iOS

SwiftUI iOS client for [Kaori](https://github.com/dehuacheng/kaori) — a personal AI-powered life management app.

## Features

- **Dashboard** — Daily calorie/macro progress, recent meals and workouts
- **Meal tracking** — Log meals via photo or text, view AI-generated nutrition analysis
- **Weight tracking** — Log weight, view trends with interactive charts
- **Workout tracking** — Structured gym logging with exercises, sets, reps, weights
- **Workout timer** — Rest/work interval timer with Dynamic Island and Live Activity support
- **Apple Health** — Sync weight and workouts with HealthKit
- **LLM backend picker** — Choose between Claude CLI, Anthropic API, or Codex CLI

## Requirements

- iOS 17.0+
- Xcode 16+
- [xcodegen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)
- A running [Kaori backend](https://github.com/dehuacheng/kaori) accessible over the network

## Setup

```bash
git clone https://github.com/dehuacheng/kaori-ios.git
cd kaori-ios
xcodegen generate
open KaoriApp.xcodeproj
```

1. In Xcode, go to **Signing & Capabilities** and sign with your Apple ID
2. Connect your iPhone via USB, select it as the build destination
3. Press **Cmd+R** to build and run
4. In the app's **Settings**, enter your backend server URL and auth token

## Architecture

Pure thin client — no local database. All data lives on the Kaori Python backend and is accessed via JSON API.

- `Config/` — Server URL + bearer token (stored in UserDefaults)
- `Network/` — APIClient with URLSession
- `Models/` — Codable structs matching backend responses
- `Stores/` — `@Observable` state managers
- `Views/` — SwiftUI views organized by feature

## Free Provisioning

No paid Apple Developer Account required. The certificate expires every 7 days — re-sign by running from Xcode. App data persists across re-signings.

## Backend

The Python backend is at [kaori](https://github.com/dehuacheng/kaori).

## License

Private project.
