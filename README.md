# Japanese Language Study

> A modern Flutter application for learning Japanese through a structured, chapter-based learning path from JLPT N5 to N1.

[![Flutter](https://img.shields.io/badge/Flutter-3.47.2-02569B?logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.13.2-0175C2?logo=dart&logoColor=white)](https://dart.dev/)
[![App Version](https://img.shields.io/badge/App%20Version-1.7.1%2B9-4C8BF5)](https://github.com/Riyadhifalsf/aplication-japanese-language-study/releases)
[![Android](https://img.shields.io/badge/Android-APK-3DDC84?logo=android&logoColor=white)](https://github.com/Riyadhifalsf/aplication-japanese-language-study/releases)
[![License](https://img.shields.io/badge/License-Repository-lightgrey)](LICENSE)

## Project Information

| Item | Version / Information |
| --- | --- |
| Flutter | **3.47.2** |
| Dart | **3.13.2** |
| Application | **1.7.1+9** |
| Platform | Android / Flutter |
| Main branch | `main` |
| Curriculum | JLPT N5–N1 |

## Support the Project

If this application is useful, support development through Saweria:

**[Support via Saweria](https://saweria.co/Riyadhifalsf)**

## Download

### Android APK

Release APK builds are published on GitHub Releases.

**[Download the latest APK / View Releases](https://github.com/Riyadhifalsf/aplication-japanese-language-study/releases)**

Pre-release builds are intended for testing before a stable release. Stable releases should only be published after the corresponding APK has been tested.

## Overview

Japanese Language Study is designed as a self-study application with one clear primary course journey. Learners progress through chapters, lessons, exercises, review, and tests without duplicate learning paths.

The current release focuses on a deeper N5 and N4 curriculum, a continuous Learning Path, richer chapter content, and a cleaner supporting Library.

## Features

- Structured Learning Path from N5 to N1
- 30 N5 chapters and 25 N4 chapters
- Deep chapter and lesson structure
- Hiragana and Katakana foundations
- Vocabulary and grammar study
- Kanji learning and review
- Reading and listening activities
- Conversation and practical Japanese
- Guided exercises and quizzes
- Chapter tests and review flows
- Learning progress, streaks, and statistics
- Donation page with amount-based ranking
- Modern responsive Flutter interface

## Learning Path

Learning Path is the primary course experience.

```text
Learning
│
├── N5
│   ├── Chapter 01
│   ├── Chapter 02
│   ├── Chapter 03
│   ├── ...
│   └── Chapter 30
│
├── N4
│   ├── Chapter 01
│   ├── Chapter 02
│   ├── Chapter 03
│   ├── ...
│   └── Chapter 25
│
├── N3
├── N2
└── N1
```

Each chapter is intended to contain multiple learning activities instead of a short single-screen lesson.

A typical chapter can contain:

1. Learning objectives
2. Explanation and notes
3. Vocabulary
4. Grammar and sentence patterns
5. Examples and dialogue
6. Listening
7. Reading
8. Writing or production practice
9. Guided exercises
10. Quiz
11. Review
12. Chapter checkpoint or test

The learner always has a clear `Lanjut` action to continue through the course.

## Curriculum

| Level | Chapters | Status |
| --- | ---: | --- |
| N5 | 30 | Active |
| N4 | 25 | Active |
| N3 | In progress | Expansion planned |
| N2 | In progress | Expansion planned |
| N1 | In progress | Expansion planned |

### N5

The N5 course is divided into 30 chapters covering foundational Japanese and everyday communication. Topics include kana, greetings, introductions, people, family, places, directions, time, schedules, transport, food, shopping, routines, descriptions, preferences, requests, invitations, health, weather, reading, listening, and integrated review.

### N4

The N4 course contains 25 chapters focused on practical intermediate Japanese. Topics include plain forms, reasons, potential forms, plans, preparation, completion, conditions, permission, obligation, giving and receiving, passive forms, transitivity, relative clauses, nominalization, connectors, contrast, change, practical situations, workplace communication, and integrated review.

## Application Navigation

| Section | Purpose |
| --- | --- |
| Home | Daily overview, progress, streak, and shortcuts |
| Learning | Primary JLPT learning path |
| Practice | Standalone quizzes, drills, and practice activities |
| Library | Supporting vocabulary, grammar, kanji, reading, and reference tools |
| Donation | Donation totals and contribution ranking |

Library is intentionally separate from the primary Learning Path. It does not contain a duplicate active-learning journey.

## Donation

The Donation section is a separate product area.

It currently provides:

- Total donation amount
- Number of contributors
- Contributor ranking
- Ranking ordered by donation amount
- Indonesian Rupiah formatting

Donation support is available through [Saweria](https://saweria.co/Riyadhifalsf).

## Architecture

```text
Flutter UI
    |
    v
Presentation / State
    |
    v
Application Layer
    |
    v
Learning / Assessment / Mastery / Remediation
    |
    v
Curriculum Repository
    |
    v
Knowledge Graph
    |
    v
Local Storage
    |
    v
Sync
    |
    v
Cloud / Backend
```

The curriculum is data-driven. Curriculum models and catalogs define the learning structure while screens and widgets render that data.

## Tech Stack

- Flutter 3.47.2
- Dart 3.13.2
- Firebase Core
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
- Node.js backend
- PostgreSQL

## Repository Structure

```text
.
├── android/                    Android application configuration
├── assets/                     Application assets and data
├── backend/                    API and proxy services
├── docs/                       Product and technical documentation
├── lib/
│   ├── core/                   Core configuration and theme
│   ├── features/
│   │   ├── curriculum/         Curriculum models and catalogs
│   │   ├── learning/           Learning and progress logic
│   │   └── ...
│   ├── screens/                Application screens
│   └── widgets/                Reusable UI components
├── test/                       Automated tests
├── pubspec.yaml                Flutter dependencies and metadata
├── analysis_options.yaml       Dart analysis configuration
└── README.md                   Project documentation
```

## Important Files

### Curriculum

```text
lib/features/curriculum/
├── curriculum_models.dart
├── curriculum_catalog.dart
└── curriculum_depth_catalog.dart
```

### Learning Path

```text
lib/screens/curriculum/
├── curriculum_path_screen.dart
├── curriculum_unit_screen.dart
└── curriculum_lesson_detail_screen.dart
```

These screens handle the level selector, continuous chapter path, chapter contents, lessons, and next-step navigation.

## Development

### Requirements

- Flutter SDK 3.47.2 or compatible
- Dart SDK included with Flutter
- Android Studio or Android SDK for Android builds
- A configured Firebase project for Firebase features

### Install

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

### Build Android APK

```bash
flutter build apk --release
```

## Release Process

1. Update the application version in `pubspec.yaml`.
2. Run `flutter pub get`.
3. Run `flutter analyze`.
4. Run `flutter test`.
5. Build the release APK.
6. Create a GitHub Release with the matching version tag.
7. Mark testing builds as **Pre-release**.
8. Attach the generated APK to the release.

## Git Workflow

The main development branch is `main`.

```bash
git status
git diff --stat
git diff
```

Keep commits focused and avoid destructive operations that can remove unrelated work.

## Security

Do not commit credentials, API keys, signing keys, or private configuration files.

Common protected files include:

```text
.env
*.jks
*.keystore
android/key.properties
**/google-services.json
**/GoogleService-Info.plist
```

If a credential is exposed, rotate it and update the local configuration rather than committing the secret.

## UI Principles

- Clear hierarchy
- One primary action per learning step
- Continuous vertical learning path
- Visible chapter numbers
- Prominent `Lanjut` navigation
- Comfortable touch targets
- Responsive mobile layout
- Modern surfaces without unnecessary visual noise

## Project Status

Current focus:

- Deepening the N5 and N4 curriculum
- Expanding lesson content and exercises
- Improving Learning Path navigation
- Improving mastery and review flows
- Expanding N3, N2, and N1 content
- Increasing automated regression coverage

## Roadmap

### Current

- N5: 30 chapters
- N4: 25 chapters
- Continuous Learning Path
- Chapter-level `Lanjut` navigation
- Deep chapter presentation
- Library separated from the main course
- Donation ranking by amount
- Ad placeholders removed from the learning navigation

### Planned

- Expand N3, N2, and N1
- Add larger authored content pools
- Expand reading and listening datasets
- Increase exercise variety
- Improve mastery and remediation
- Add production-ready donation/payment processing
- Expand automated tests

## Project Name

User-facing name:

`Japanese Language Study`

Repository name:

`aplication-japanese-language-study`

The repository slug remains unchanged so existing Git remotes, links, and integrations continue to work.

## License

See the repository license for the current licensing terms.

## Contributing

Contributions are welcome. Before changing curriculum or learning logic, review the existing implementation and related tests. Keep changes focused and update documentation when product behavior changes.
