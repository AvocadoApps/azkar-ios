# AGENTS.md

Guidelines for AI agents working on the **Azkar** iOS project.

## Project Overview

Azkar is an Islamic adhkar (daily remembrance) app for iOS 15.0+ and macOS 12.0+ (Mac Catalyst). It lets users browse, recite, and track morning/evening adhkar with audio playback, multilingual support (11 languages), home screen widgets, and Spotlight search.

- Bundle ID: `io.jawziyya.azkar-app`
- Team: Al Jawziyya (`486STKKP6Y`)
- Current version: 2.9.9

## Architecture

**SwiftUI + MVVM with Coordinator navigation**

- Navigation is handled by `RootCoordinator` using the [Stinsen](https://github.com/rundfunk47/stinsen) coordinator library
- Each scene has a `ViewModel` (ObservableObject) and a SwiftUI `View`
- Dependency injection is constructor-based, passed through coordinators
- Combine is used for reactive state alongside SwiftUI property wrappers

## Project Structure

```
azkar-ios/
├── Azkar/                        # Main app target
│   └── Sources/
│       ├── Scenes/               # 11 scene modules (MVVM)
│       ├── Services/             # App-level services
│       ├── Library/              # Shared utilities, subscriptions
│       ├── Extensions/           # Swift/UIKit extensions
│       └── Generated/            # SwiftGen output (do not edit)
├── AzkarWidgets/                 # Home screen widget extension
├── AzkarTests/                   # Unit tests
├── AzkarUITests/                 # UI tests
├── Packages/                     # Local SPM packages
│   ├── Core/
│   │   ├── AzkarResources/       # Resource bundle
│   │   ├── AzkarServices/        # Backend/network services
│   │   ├── Entities/             # Domain models (Zikr, Category, etc.)
│   │   └── Extensions/           # Framework extensions
│   ├── Interactors/
│   │   └── DatabaseInteractors/  # GRDB SQLite operations
│   └── Modules/
│       ├── Library/              # Themes, preferences, shared UI utilities
│       ├── Components/           # Reusable SwiftUI components
│       ├── AudioPlayer/          # Audio playback module
│       ├── ArticleReader/        # Article viewer
│       ├── AboutApp/             # About screen
│       └── ZikrCollectionsOnboarding/
├── Tuist/                        # Tuist project generation config
│   └── Package.swift             # All external SPM dependencies
├── scripts/                      # Build helpers
│   ├── swiftlint.sh
│   ├── configure_secrets.sh      # Injects API keys into Secrets.plist
│   └── download-localizations.py
├── fastlane/                     # Release automation
└── .github/workflows/cd.yml      # CI/CD pipeline
```

## Key Files

| File | Purpose |
|------|---------|
| `Azkar/Sources/AzkarApp.swift` | App entry point; scene setup, deep linking, Spotlight |
| `Azkar/Sources/AppDelegate.swift` | UIKit lifecycle; Firebase, RevenueCat, push notifications |
| `Azkar/Sources/Scenes/Root/RootCoordinator.swift` | Central navigation hub; all routes live here |
| `Packages/Core/Sources/Entities/` | Domain models — start here to understand data structures |
| `Packages/Interactors/Sources/DatabaseInteractors/` | All database queries (GRDB) |
| `Tuist/Package.swift` | External dependencies with version pins |
| `Project.swift` | Tuist project definition (targets, settings, build phases) |

## Setup

The project uses **Tuist** for Xcode project generation. Edit `Project.swift` to change targets, settings, or build phases — `.xcodeproj` is regenerated from it.

```bash
# 1. Install mise (if not installed)
brew install mise

# 2. Install Tuist (version pinned in .mise.toml to 4.43.0)
mise install

# 3. Fetch SPM dependencies and generate the Xcode project
mise x -- tuist install
mise x -- tuist generate

# 4. Open in Xcode
open Azkar.xcworkspace
```

## When to Run `tuist generate`

Run `mise x -- tuist generate` after any of these:

- Adding, removing, or moving `.swift` source files
- Adding, removing, or moving resources (assets, `.strings`, `.plist`, etc.)
- Editing `Project.swift` (targets, build phases, settings)
- Editing `Tuist/Package.swift` (adding/removing/updating external dependencies)

**Not required** when only editing the content of existing files.

## Secrets

Local development requires `Azkar/Resources/Secrets.plist`. Generate it from environment variables:

```bash
export AZKAR_SUPABASE_API_KEY=...
export AZKAR_SUPABASE_API_URL=...
export REVENUE_CAT_API_KEY=...
export SUPERWALL_API_KEY=...
export MIXPANEL_TOKEN=...
scripts/configure_secrets.sh
```

## Building & Testing

```bash
# Regenerate project after changing Project.swift or adding packages
mise x -- tuist generate

# Run SwiftLint manually
scripts/swiftlint.sh

# Run tests via xcodebuild
xcodebuild test -workspace Azkar.xcworkspace -scheme Azkar -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Generated Code

`Azkar/Sources/Generated/` contains SwiftGen output — **do not edit these files manually**:

- `Strings+Generated.swift` — typed accessors for all localized strings
- `XCAssets+Generated.swift` — typed accessors for asset catalog entries

Re-run SwiftGen when adding new string keys or asset catalog entries:

```bash
scripts/run-swiftgen.sh
```

Always use the generated typed accessors (e.g. `L10n.someKey`, `Asset.someImage`) rather than raw string literals.

## Code Style

SwiftLint is enforced via a build phase. Configuration: `.swiftlint.yml`

- **Applies to:** `Azkar/` directory only (excludes `Packages/`, `Tuist/`, `fastlane/`)
- Max file length: 500 lines (warning) / 800 (error)
- Max function body: 150 lines (warning) / 200 (error)
- Max type body: 300 lines (warning) / 500 (error)
- Cyclomatic complexity warnings enabled

## Deep Linking

All deep links flow through three files:

1. **`AppDeepLink.swift`** — URL parsing (`azkar://` scheme) and Spotlight token parsing. Add a new enum case, implement `init?(url:)` parsing, `var url`, and `var searchableToken`.
2. **`Deeplinker.swift`** — Internal `Route` enum used across the app. Add the matching case here.
3. **`RootCoordinator.swift`** — Handles `Deeplinker.Route` values and triggers navigation. Add the route handling here.

URL format: `azkar://<route>/<param>` (e.g. `azkar://zikr/42`, `azkar://category/morning`).

## UserDefaults Keys

All `UserDefaults` keys are centralized in `Azkar/Sources/Library/Keys.swift`. Add new keys there — never use raw string literals inline.

## App Intents

Siri and Shortcuts intents live in `Azkar/Sources/AppIntents/AzkarAppIntents.swift`. Add new `AppIntent` conformances there.

## Adding New Scenes

1. Create a folder under `Azkar/Sources/Scenes/<SceneName>/`
2. Add `<SceneName>ViewModel.swift` (ObservableObject) and `<SceneName>View.swift`
3. Add a route case to `RootCoordinator` and implement the navigation in `RootCoordinator.swift`
4. Register any new dependencies through the coordinator constructor chain

## Adding New Packages

Edit `Tuist/Package.swift` to add external dependencies, then run `mise x -- tuist install && mise x -- tuist generate`.

For new local packages, add them under `Packages/` following the existing structure, then reference them in `Project.swift`.

## Deployment

CI/CD runs via GitHub Actions (`.github/workflows/cd.yml`):

| Trigger | Fastlane Lane | Destination |
|---------|--------------|-------------|
| Push to `release/**` | `closed_beta` | TestFlight |
| Tag `iOS_v*` | `release` | App Store |
| Tag `macOS_v*` | `app_store_release` | Mac App Store |

Code signing uses Fastlane Match (manual signing). Required secrets are stored in GitHub repository secrets.

## External Dependencies (key ones)

| Library | Purpose |
|---------|---------|
| GRDB | SQLite database access |
| Stinsen | Coordinator-based navigation |
| Supabase | Backend API |
| RevenueCat | In-app subscriptions |
| SuperwallKit | Paywall presentation |
| Firebase (Analytics + Messaging) | Analytics and push notifications |
| Mixpanel | Event analytics |
| Lottie | Animations |
| Alamofire | HTTP networking |
| NukeUI | Image loading |
