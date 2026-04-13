بسم الله الرحمن الرحيم

<div align="center">
  <img src="Azkar/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png" height="80" style="border-radius: 18px"/>
  
  # Azkar App
  
  Azkar is an iOS app that helps you learn and recite daily adhkar consistently. Track your progress, set reminders, deepen your understanding and memozie adhkar using Azkar App.
  
  [![Download on the App Store](https://toolbox.marketingtools.apple.com/api/v2/badges/download-on-the-app-store/black/en-us?releaseDate=1704067200)](https://apple.co/2X7LNo7)
  
  ![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)
  ![Platform](https://img.shields.io/badge/Platform-iOS%2015.0%2B-blue.svg)
  ![Platform](https://img.shields.io/badge/Platform-macOS%2012.0+-blue.svg)
  
  <a href="https://telegram.me/jawziyya">
    <img src="https://img.shields.io/badge/Telegram-@jawziyya-blue.svg?style=flat" alt="Telegram: @jawziyya" />
  </a>
</div>

---

## Features

- 📖 **Comprehensive Dhikr Collection** - Browse and recite morning and evening adhkar
- 🌐 **Multiple Languages** - Available in Arabic, English, Russian, Turkish, Georgian, Chechen, Ingush, Uzbek, Kyrgyz, Kazakh and Tatar
- ⏰ **Daily Reminders** - Never miss your morning and evening adhkar
- 🔊 **Audio Recitations** - Listen to authentic audio for each dhikr
- 📝 **Progress Tracking** - Track your daily recitation progress
- 🔤 **Multiple Fonts** - Read in Arabic with beautiful custom fonts
- 📚 **Source References** - Find sources (Hadith/Quran) for each dhikr
- 📱 **Home Screen Widgets** - Track your progress directly from the home screen

---

## Tech Stack

| Library | Purpose |
|---------|---------|
| SwiftUI | UI framework |
| [Stinsen](https://github.com/rundfunk47/stinsen) | Coordinator-based navigation |
| [Tuist](https://tuist.io) | Xcode project generation |
| [GRDB](https://github.com/groue/GRDB.swift) | SQLite database access |
| [Supabase](https://supabase.com) | Backend API |
| [RevenueCat](https://www.revenuecat.com) | In-app subscriptions |
| [SuperwallKit](https://superwall.com) | Paywall presentation |
| Firebase Analytics + Messaging | Analytics and push notifications |
| Mixpanel | Event analytics |
| Lottie | Animations |
| Alamofire | HTTP networking |
| NukeUI | Image loading |

---

## Architecture

**SwiftUI + MVVM with Coordinator navigation**

- Navigation is handled by `RootCoordinator` using the Stinsen coordinator library
- Each scene has a `ViewModel` (ObservableObject) and a SwiftUI `View`
- Dependency injection is constructor-based, passed through coordinators
- Combine is used for reactive state alongside SwiftUI property wrappers
- Reusable modules live in local SPM packages under `Packages/`

---

## Project Structure

```
azkar-ios/
├── Azkar/                        # Main app target
│   └── Sources/
│       ├── Scenes/               # Feature modules (MVVM)
│       ├── Services/             # App-level services
│       ├── Library/              # Shared utilities, subscription logic
│       └── Extensions/           # Swift/UIKit extensions
├── AzkarWidgets/                 # Home screen widget extension
├── AzkarTests/                   # Unit tests
├── AzkarUITests/                 # UI tests
├── Packages/                     # Local SPM packages
│   ├── Core/                     # Entities, AzkarServices, AzkarResources
│   ├── Interactors/              # Database access layer (GRDB)
│   └── Modules/                  # Library, Components, AudioPlayer, ArticleReader, …
├── Tuist/
│   └── Package.swift             # All external SPM dependencies
└── scripts/                      # Build helpers (SwiftLint, secrets, localizations)
```

---

## Getting Started

The project uses **Tuist** for Xcode project generation. Edit `Project.swift` to change targets, settings, or build phases — `.xcodeproj` is regenerated from it.

### Prerequisites

- [Mise](https://mise.jdx.dev) — manages Tuist version (`brew install mise`)
- Xcode 16+

### Setup

```bash
# Install Tuist (version pinned in .mise.toml)
mise install

# Fetch SPM dependencies and generate the Xcode project
mise x -- tuist install
mise x -- tuist generate

# Open in Xcode
open Azkar.xcworkspace
```

### Secrets

Local builds require `Azkar/Resources/Secrets.plist`. Generate it from environment variables:

```bash
export AZKAR_SUPABASE_API_KEY=...
export AZKAR_SUPABASE_API_URL=...
export REVENUE_CAT_API_KEY=...
export SUPERWALL_API_KEY=...
export MIXPANEL_TOKEN=...
scripts/configure_secrets.sh
```

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
