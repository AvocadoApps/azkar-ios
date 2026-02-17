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

- **UI Framework**: SwiftUI
- **Architecture**: MVVM with Coordinators
- **Project Generation**: [Tuist](https://tuist.io)
- **Dependency Management**: Swift Package Manager
- **Database**: GRDB
- **Analytics**: Firebase Analytics, Mixpanel
- **Payments**: RevenueCat
- **Ads**: Superwall
- **Backend**: Supabase

---

## Project Structure

```
Azkar/
├── Azkar/                    # Main app target
│   ├── Sources/              # Swift source files
│   └── Resources/            # Assets, localizations, database
├── AzkarWidgets/             # Home screen widgets extension
├── AzkarTests/               # Unit tests
├── AzkarUITests/             # UI tests
├── Tuist/                    # Tuist package definitions
└── scripts/                  # Build scripts
```

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
