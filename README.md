# Japanese Language Study 🇯🇵

A modern Flutter application for learning Japanese from **JLPT N5 to N1**, with a structured, linear learning path and a large chapter-based curriculum.

> **Status:** Active development  
> **Current curriculum:** N5 — 30 chapters · N4 — 25 chapters  
> **Repository:** `Riyadhifalsf/aplication-japanese-language-study`

## ✨ Overview

**Japanese Language Study** is built as a complete self-study companion. The primary course journey lives in **Learning Path**; **Library** is reserved for supporting references and practice tools.

## 🧭 Navigation

| Section | Purpose |
|---|---|
| 🏠 **Beranda** | Daily overview, progress, streak, and quick actions |
| 🗺️ **Learning** | Main structured JLPT learning path |
| 🏋️ **Practice** | Standalone practice, quizzes, and drills |
| 📚 **Library** | Supplementary vocabulary, grammar, kanji, reading, and tools |
| 💝 **Donasi** | Donation totals, contributor count, and amount-based ranking |

**Learning Path is the single primary course.** Library intentionally does not duplicate the active-learning journey.

## 🎯 Features

- 🗺️ Linear Learning Path
- 📚 Deep multi-lesson chapters
- 🈁 Hiragana & Katakana
- 🧩 Vocabulary
- 🧠 Grammar / Bunpou
- 漢 Kanji
- 🗣️ Conversation & shadowing
- 🎧 Listening with TTS-assisted activities
- 📖 Reading and comprehension
- ✍️ Writing / production
- 🎯 Quiz, unit tests, mock tests, and final tests
- 🔁 Review and weak-area practice
- 📊 Learning statistics
- 💝 Donation totals and ranking by contribution amount

## 📖 Chapter & lesson design

A chapter is deliberately substantial. Depending on the topic, a learner may work through:

1. 📌 Learning objective
2. 📘 Concept explanation
3. 🧩 Vocabulary
4. 🧠 Grammar / sentence patterns
5. 🗣️ Examples and dialogue
6. 🎧 Listening
7. 📖 Reading
8. ✍️ Writing / production
9. 🧪 Quiz
10. 🔁 Review
11. ✅ Checkpoint / unit test
12. 🏆 Boss or final test

Every chapter has a clear **Lanjut** flow so the learner knows what to do next.

## 🎓 Curriculum

| Level | Chapters | Focus |
|---|---:|---|
| 🇯🇵 **N5** | **30** | Foundations, kana, vocabulary, kanji, grammar, everyday communication |
| 🇯🇵 **N4** | **25** | Practical intermediate grammar, reading, listening, conversation |
| 🇯🇵 **N3** | In progress | Independent intermediate Japanese |
| 🇯🇵 **N2** | In progress | Formal language, news, argumentation |
| 🇯🇵 **N1** | In progress | Advanced nuance, long reading, professional Japanese |

### N5

N5 is divided into **30 chapters** so concepts can be taught in smaller, deeper units while keeping one continuous path.

Example themes: greetings, introductions, family, people, rooms, ownership, places, directions, time, schedules, transport, food, shopping, routines, adjectives, preferences, requests, invitations, health, weather, reading, listening, and integrated review.

### N4

N4 contains **25 chapters** with progressively stronger control of grammar, vocabulary, reading, listening, and practical conversation.

Example themes: plain forms, reasons, potential, plans, preparation, completion, conditionals, permission, obligation, giving/receiving, passive, transitivity, relative clauses, nominalization, connectors, contrast, change, practical situations, workplace communication, and integrated review.

## 💝 Donations

Donations are a dedicated product area and are **not mixed into Library or Learning Path**.

The donation experience includes:

- 💰 **Total donation amount**
- 👥 **Contributor count**
- 🏆 **Top contributor ranking**
- 📈 **Ranking by amount**, highest contribution first
- 🇮🇩 **Rupiah formatting (`Rp`)**

The current structure leaves room for a production payment provider without redesigning the learning navigation.

## 🏗️ Architecture

```text
Flutter UI
   ↓
Presentation / State
   ↓
Application Layer
   ↓
Learning / Assessment / Mastery / Remediation Engine
   ↓
Curriculum Repository
   ↓
Knowledge Graph
   ↓
Local Storage
   ↓
Sync
   ↓
Cloud / Backend
```

The curriculum is data-driven: chapter and lesson data belong in the curriculum/domain layer, while UI widgets render that data.

## 🛠️ Tech stack

- **Flutter** 3.47.x
- **Dart** 3.13.x
- **Firebase** — Core, Authentication, Firestore
- **Google Sign-In**
- **Local storage** — SharedPreferences, Flutter Secure Storage
- **Networking** — HTTP
- **Charts** — fl_chart
- **Notifications** — flutter_local_notifications + timezone
- **Utilities** — image_picker, path_drawing, url_launcher
- **Backend** — Node.js API + PostgreSQL
- **UI** — Material-based Flutter UI with modern/glass surfaces where appropriate

## 📂 Repository structure

```text
.
├── android/                       # Android configuration
├── assets/                        # Images and packaged assets
├── backend/                       # API / proxy services
├── docs/                          # Product, architecture, UI, and project docs
├── lib/
│   ├── core/                      # Core configuration and theme
│   ├── features/
│   │   ├── curriculum/            # N5–N1 curriculum models and catalogs
│   │   ├── learning/              # Learning engine and progress
│   │   └── ...
│   ├── screens/                   # Main application screens
│   └── widgets/                   # Reusable UI components
├── test/                          # Automated tests
├── .gitignore
├── pubspec.yaml
└── README.md
```

## 🧩 Important curriculum files

- `lib/features/curriculum/curriculum_models.dart` — core curriculum domain models.
- `lib/features/curriculum/curriculum_catalog.dart` — main level/unit composition.
- `lib/features/curriculum/curriculum_depth_catalog.dart` — deep chapter blueprints.
- `lib/screens/curriculum/` — Learning Path, chapter, lesson, and continue-navigation UI.

## 🧪 Development

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Android APK:

```bash
flutter build apk
```

Before a large change or release:

```bash
git status
git diff --stat
git diff
```

## 🔐 Security

Keep secrets and signing material out of Git:

```text
.env
*.jks
*.keystore
android/key.properties
**/google-services.json
**/GoogleService-Info.plist
```

Never place API keys, passwords, private tokens, or signing credentials in source code or documentation.

## 🔄 Development principles

1. Read the current implementation before editing.
2. Treat source code as implementation truth.
3. Treat the current product requirement as requirement truth.
4. Keep Learning Path as the primary course journey.
5. Keep Library as supplementary content/tools.
6. Add curriculum through data/models rather than duplicate UI logic.
7. Preserve unrelated work and learner progress data.
8. Run analysis/tests before declaring a change healthy.
9. Update documentation when product or architecture behavior changes.

## 🎨 UI / UX principles

- ✨ Modern card-based surfaces
- 🪟 Glass-style surfaces where useful
- 🧭 Clear linear progression
- 🔢 Chapter numbers always visible
- ▶️ Prominent **Lanjut** action
- 📱 Mobile-first layout
- 🎯 One obvious primary action per learning step
- ♿ Readable hierarchy and comfortable touch targets
- 📊 Progress shown clearly without excessive noise

Visual references are used as inspiration only; the implementation remains original.

## 📝 Naming

### User-facing product name

**Japanese Language Study 🇯🇵**

### Repository name

**`aplication-japanese-language-study`**

The repository slug stays unchanged so existing Git remotes, links, history, and integrations continue to work. The user-facing product name is **Japanese Language Study**.

## 🗺️ Roadmap

### ✅ Current

- 30 N5 chapters
- 25 N4 chapters
- Deep multi-lesson chapter structure
- Linear Learning Path
- Chapter-level **Lanjut** navigation
- Library separated from the primary learning journey
- Donation ranking by amount
- Ad placeholders removed from product navigation

### 🔜 Next

- Expand N3, N2, and N1 to the same depth
- Add larger authored content pools per lesson
- Expand reading and listening datasets
- Increase question variety per lesson
- Strengthen mastery and remediation
- Connect production-ready donation/payment processing
- Add broader automated regression coverage

## 🤝 Contribution notes

Keep commits focused. Avoid destructive Git operations when another change may be in progress. Add or update tests when changing learning logic.

## 📄 License

Refer to the repository license configuration for the current licensing terms.

---

**Japanese Language Study 🇯🇵**  
*Belajar bahasa Jepang langkah demi langkah, bab demi bab.*