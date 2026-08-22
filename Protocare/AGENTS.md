# Repository Guidelines

## Project Structure & Module Organization
- `Protocare.xcodeproj` at root; all app sources are in `Protocare/`.
- SwiftUI MVVM: `RootView` routes between auth and protocol flows; view models (`RegistrationViewModel`, `LoginViewModel`, `ProtocolsViewModel`, `ProtocolBuilderViewModel`) are `@MainActor` `ObservableObject`s.
- Networking lives in `APIClient.swift` with auth models in `AuthModels.swift`; auth state and keychain persistence are in `AuthStore.swift`/`KeychainStore.swift`.
- UI layers: auth screens (`LoginView.swift`, `RegistrationView.swift`), protocol list (`ProtocolsView.swift`), builder (`ProtocolBuilderView.swift`, `ProtocolDraft.swift`, `LibraryCardView.swift`), and shared components such as `ActionRow.swift`. Assets sit in `Assets.xcassets`. Tests are not yet present—plan to add `ProtocareTests/`.

## Build, Test, and Development Commands
- Open in Xcode: `open Protocare.xcodeproj`, select the `Protocare` scheme, run on a simulator or device.
- CLI build (tweak destination to your simulator):  
  ```sh
  xcodebuild -scheme Protocare -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 15' clean build
  ```
- Tests (after adding a test target):  
  ```sh
  xcodebuild -scheme Protocare -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 15' test
  ```
- API base URL is set in `Protocare/ProtocareApp.swift`; prefer scheme/build settings over hardcoded strings for new environments.

## Coding Style & Naming Conventions
- Swift 5/SwiftUI with 4-space indent; keep view logic in `struct` `View`s and state in `final class` view models marked `@MainActor`.
- Use property wrappers (`@StateObject`, `@ObservedObject`, `@Published`) consistently; validate form inputs before hitting the network as in `RegistrationViewModel`.
- Suffixes: `View`, `ViewModel`, `Store`, `Client`, `Draft`, `Request/Response`. Keep API request construction and JSON decoding centralized in `APIClient`.
- Favor small, testable helpers (e.g., `String.isValidEmail`); keep copy concise and user-facing strings ready for localization.

## Testing Guidelines
- Introduce an `XCTest` target covering validation rules, error mapping, date formatting, and persistence. Stub network calls with `URLProtocol` and inject `URLSession`.
- Name tests after the behavior under test (`testLoginRejectsInvalidEmail`, etc.) and keep them deterministic. Run `xcodebuild ... test` before merging.

## Commit & Pull Request Guidelines
- Commit messages: short, imperative (e.g., “Add protocol builder actions”), scoped to a single concern.
- PRs should include a summary of changes, test commands executed, and screenshots/recordings for UI updates. Link issues/tasks and note impacts to API contracts, base URLs, or stored data so reviewers can retest auth and protocol flows.

## Security & Configuration Tips
- Never commit secrets or tokens; rely on `KeychainStore` for sensitive values and avoid logging auth data.
- Configure env-specific base URLs via schemes/build settings; clear keychain data (`AuthStore.logout()`) when changing auth contexts.
- Keep derived data and personal Xcode settings out of source control.
