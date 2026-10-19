# Protocare iOS — Agent Guide

> Branch: `feature/unified-action-model`. This file was rewritten 2026-10-09 to match the actual branch state.

## Workflow Rules

- Read files before assuming — this guide is a map, not the territory
- Make minimal changes to achieve the goal; no drive-by refactors
- Run tests after any code change (Cmd+U or `xcodebuild test`, see below)
- When backend API schemas change, update iOS models manually — code generation is abandoned
- **Design reference**: Stitch project `3277867970988009263` for target UI screens

## Stack

| Layer | Technology |
|-------|------------|
| Language | Swift 5.9, SwiftUI, MVVM |
| Min target | iOS 17 (Package.swift: `.iOS(.v17)`) |
| Concurrency | async/await, `@MainActor` view models |
| Networking | Custom `APIClient` (~760 lines) + `TokenRefreshManager` (refresh rotation) |
| Persistence | `KeychainStore` (tokens); in-memory caches |
| Testing | XCTest, 22 test files under `ProtocareTests/` |

**SPM dependencies: none in app code.** (`swift-openapi-runtime` resolves but is unused — no `import OpenAPIRuntime` in `Protocare/`.)

## Commands

```bash
cd protocare_mobile/Protocare
open Protocare.xcodeproj                # scheme: Protocare

# CLI build/test (iPhone 17 simulator available locally):
xcodebuild -scheme Protocare -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 17' build

xcodebuild -scheme Protocare -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 17' test
```

API base URL is selected at compile time in `Utilities/AppEnvironment.swift` (the `Config/*.xcconfig` files are NOT wired into the project — no `baseConfigurationReference`, and `GENERATE_INFOPLIST_FILE` emits no `API_BASE_URL` key):
- Debug & Release: `https://api.protocare.dev/v1` (deployed backend)
- Local backend on the Mac: flip `AppEnvironment.current` to `.local(ip: "192.168.1.71")`

## Project Structure

```
Protocare/
├── Protocare/
│   ├── App/                     # ProtocareApp.swift, RootView.swift (auth/protocol routing)
│   ├── Views/
│   │   ├── Auth/                # LoginView, RegistrationView, AuthContainerView, PillTabSwitcher
│   │   ├── Protocols/           # list, detail, builder, settings, checkin, ScheduleActionSheet + Components/
│   │   ├── Dashboard/           # DashboardView + Components/ (ActionRowView, WeekCalendarView, ProgressCardView, CheckinDosageSheet, StreakCardView)
│   │   ├── Journal/             # OutcomeJournalView, JournalListView, MetricSliderView, ActionCheckinCard
│   │   ├── Profile/            # ProfileView, EditProfileView, NotificationSettingsView
│   │   ├── UserActions/        # ActionPickerView, ActionCreatorView
│   │   ├── Splash/             # SplashView
│   │   └── Components/         # TimeDrumPicker, ComparisonSliderView, ImagePicker, SearchBar, ImageViewer, ResilientAsyncImage, CategoryChips
│   ├── ViewModels/             # @MainActor ObservableObject (one per screen)
│   ├── Models/                 # APIModels.swift + ActionSchedule, DailyStatus, Journal, MetricTrend models; Profile/
│   ├── Networking/             # APIClient.swift (all endpoints), TokenRefreshManager.swift
│   ├── Stores/                 # AuthStore, KeychainStore
│   ├── Utilities/              # AppEnvironment, AppTheme, DependencyInjection, NotificationManager
│   └── Extensions/             # Action+Enrichment, Double+Formatting, String+Validation
├── ProtocareTests/             # 22 files: Mocks/ (MockAuthAPI, MockAuthStore), Models/, Networking/, Stores/, ViewModels/, Extensions/, Utils/
└── Config/                     # xcconfigs + openapi.json (stale snapshot)
```

**Empty legacy dirs (do not use):** `Views/Subscription/`, `Models/Subscription/`, `ViewModels/Subscription/`, `Services/Subscription/`, `ProtocareTests/Services/Subscription/`, `ProtocareTests/ViewModels/Subscription/` — subscription code was removed from this branch; the directories remain empty. Same for `Views/Dashboard/` comparison-era leftovers if referenced elsewhere.

## Code Style

- 4-space indent, `@MainActor final class` view models
- Property wrappers: `@StateObject`, `@ObservedObject`, `@Published` (ObservableObject — no `@Observable` macro yet)
- Suffixes: View, ViewModel, Store, Client, Draft, Request/Response
- All networking centralized in `APIClient.swift` — no fetch calls in views
- Views must not access `vm.api`/`vm.authStore` internals (MVVM layering)

## Cross-Platform Notes

| Backend (API) | iOS | Notes |
|---------------|-----|-------|
| snake_case fields | camelCase | manual mapping in models |
| `datetime` ISO8601 + `Z` | `Date` (.iso8601) | UTC everywhere |
| UUID strings | `UUID`/`String` | |
| All routes under `/v1` | `AppEnvironment.baseURL` ends with `/v1` | keep in sync |

- Images: presigned URLs from backend; `ResilientAsyncImage` retries against `AppEnvironment.current.baseURL` host when localhost
- Local dev: MinIO `127.0.0.1:9000`

## Security

- `KeychainStore` for tokens; atomic `SecItemUpdate`, errors surfaced on write/delete; cleared on logout
- `AuthStore.accessToken` private; `isAuthenticated` published proxy
- `#if !DEBUG` guard: HTTP URLs fatal-error in production builds
- Never commit secrets; `.env` and tfstate are gitignored in the backend repo

## Testing

- XCTest target `ProtocareTests`, mocks in `ProtocareTests/Mocks/`
- `TestFixtures.swift` for shared fixtures
- Run full suite via `xcodebuild test` (destination above) — keep it green before merges
