# Japanese Language Study

[![Flutter](https://img.shields.io/badge/Flutter-3.47.2-02569B?logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.13.2-0175C2?logo=dart&logoColor=white)](https://dart.dev/)
[![App Version](https://img.shields.io/badge/App-1.7.1%2B9-4C8BF5)](https://github.com/Riyadhifalsf/aplication-japanese-language-study/releases)
[![Android](https://img.shields.io/badge/Android-APK-3DDC84?logo=android&logoColor=white)](https://github.com/Riyadhifalsf/aplication-japanese-language-study/releases)

A Flutter app for studying Japanese with a structured learning path, practice tools, progress tracking, and JLPT-focused content.

## Versions

| Component | Version |
| --- | --- |
| Flutter | 3.47.2 |
| Dart | 3.13.2 |
| Application | 1.7.1+9 |

## Features

- Learning Path for JLPT N5–N1
- 30 N5 chapters and 25 N4 chapters
- Hiragana and Katakana
- Vocabulary, grammar, kanji, reading, and listening
- Quizzes, drills, review, and chapter tests
- Progress, streaks, and study statistics
- Library for supporting study materials
- Donation page with Saweria and donor leaderboard

## Learning Path

The main course is organized as a continuous path by level and chapter.

```text
Learning
├── N5
│   ├── Chapter 01
│   ├── Chapter 02
│   └── ...
├── N4
│   ├── Chapter 01
│   ├── Chapter 02
│   └── ...
├── N3
├── N2
└── N1
```

Each chapter contains lessons, explanations, vocabulary, grammar, exercises, review, and a chapter checkpoint where available.

## Donation

Donations are handled through the project's Saweria page:

**https://saweria.co/Riyadhifalsf**

The app provides a direct Saweria button and a donor leaderboard. Leaderboard totals are displayed from the donation data supplied to the application; payment credentials are not stored in the app.

## Tech Stack

- Flutter 3.47.2
- Dart 3.13.2
- Firebase Authentication
- Cloud Firestore
- Google Sign-In
- SharedPreferences
- Flutter Secure Storage
- HTTP
- fl_chart
- flutter_local_notifications
- timezone
- image_picker
- path_drawing
- url_launcher
- google_mobile_ads
- Node.js
- PostgreSQL

## Project Structure

```text
.
├── android/                  Android application
├── assets/                   App assets and data
├── backend/                  API and proxy services
├── docs/                     Documentation
├── lib/
│   ├── core/                 Core configuration and theme
│   ├── features/             Curriculum and learning logic
│   ├── screens/              Application screens
│   └── widgets/              Reusable UI components
├── test/                     Automated tests
├── pubspec.yaml              Flutter dependencies and version
└── README.md                 Project documentation
```

## Development

### Requirements

- Flutter SDK 3.47.2
- Android SDK for Android builds
- Firebase project configuration for Firebase features

### Install dependencies

```bash
flutter pub get
```

### Run

```bash
flutter run
```

### Analyze

```bash
flutter analyze
```

### Test

```bash
flutter test
```

### Build release APK

```bash
flutter build apk --release
```

The generated APK is located at:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## Release

Release builds are published through GitHub Releases.

[View releases](https://github.com/Riyadhifalsf/aplication-japanese-language-study/releases)

For a test build, use a pre-release tag such as `v1.7.1-beta.1` and attach the generated APK to the release.

## Security

Do not commit API keys, signing keys, Firebase configuration files containing secrets, or private environment files.

```text
.env
*.jks
*.keystore
android/key.properties
**/google-services.json
**/GoogleService-Info.plist
```

## Repository

GitHub: https://github.com/Riyadhifalsf/aplication-japanese-language-study

The package identifier remains `japanese_study`; the application name is `Japanese Language Study`.

## Support

Support the project through Saweria:

https://saweria.co/Riyadhifalsf
