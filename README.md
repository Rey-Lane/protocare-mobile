# Protocare iOS

SwiftUI iOS client for the Protocare health protocol tracker.

## What it does

Create health protocols (supplements, medications, routines), track daily check-ins, and monitor progress. The app provides a structured way to stay consistent with health routines.

## Tech Stack

- **Swift** + **SwiftUI**
- **MVVM** architecture (Views → ViewModels → API layer)
- **Keychain** for secure token storage
- **Xcode** 16+

## Screens

| Tab | Screen | Description |
|-----|--------|-------------|
| Daily | `DailyDashboardView` | Today's check-ins, streaks, progress cards, week calendar |
| Journal | `JournalListView` / `OutcomeJournalView` | Check-in history, metric tracking with sliders |
| Protocols | `ProtocolsView` | Protocol list, creation, templates |
| Me | `ProfileView` | Profile settings |

## Project Structure

```
Protocare/
  App/
    ProtocareApp.swift       # App entry point
    RootView.swift           # Auth gate + MainTabView
  Models/                    # Data models
    APIModels.swift          # API response types
    DailyStatusModels.swift
    JournalModels.swift
    ActionSchedule.swift
    Profile/ProfileModels.swift
  Networking/
    APIClient.swift          # HTTP client with token refresh
    TokenRefreshManager.swift
  Stores/
    AuthStore.swift          # Auth state management
    KeychainStore.swift      # Secure token storage
    UserActionsStore.swift
  ViewModels/                # Business logic (MVVM)
    Auth/                    # Login, Registration
    Dashboard/               # Daily dashboard
    Journal/                 # Journal list, outcome
    Protocols/               # Protocol CRUD, builder, detail, settings, templates
    Profile/                 # Profile
  Views/                     # SwiftUI views
    Auth/                    # Login, Registration, tab switcher
    Dashboard/               # Daily view + components
    Journal/                 # Journal list + outcome entry
    Protocols/               # Protocol list, detail, builder, settings, templates
    Profile/                 # Profile screen
    Components/              # Shared UI components
    Splash/                  # Splash screen
  Utilities/
    AppEnvironment.swift      # Environment config (base URL, etc.)
    AppTheme.swift
    DependencyInjection.swift
    NotificationManager.swift
  Config/                     # Xcode configs (Debug, Staging, Release)
ProtocareTests/              # Unit tests
```

## Getting Started

1. Open `Protocare.xcodeproj` in Xcode
2. Select the **Protocare** scheme and an iOS simulator (iPhone 17)
3. Build & run (Cmd+R)

### Backend

The app requires the Protocare backend running. See the [backend repo](https://github.com/Rey-Lane/protocare) for setup instructions.

By default, the app connects to `http://localhost:8000`. Change the base URL in `AppEnvironment.swift` if needed.

## Architecture

The app follows **MVVM**:

- **Views** — SwiftUI, bind to ViewModels via `@ObservedObject` / `@StateObject`
- **ViewModels** — `ObservableObject`, call `APIClient`, publish state changes
- **APIClient** — thin HTTP layer, handles auth tokens and refresh
- **Models** — plain structs conforming to `Codable`

## Testing

```bash
# Run tests via Xcode
Cmd+U

# Or via command line
xcodebuild test -scheme Protocare -destination 'platform=iOS Simulator,name=iPhone 17'
```

## License

Private repository. All rights reserved.
