# Japanese Study

Japanese Study is an offline-first Flutter learning platform designed to take a learner from Kana fundamentals through JLPT N5-N1, with optional JFT-Basic and Work-in-Japan / SSW study tracks.

## Product principles

- **Kana first:** Hiragana and Katakana appear before the main JLPT curriculum.
- **Open learning:** Lessons inside the active level are available from the start. The recommended order is guidance, not a lesson lock.
- **Clear levels:** N5, N4, N3, N2 and N1 have separate visual level selectors and their own progress.
- **Library is reference-first:** Library contains study material; assessments live in Quiz Center.
- **Adaptive review:** Progress, mistakes and mastery signals feed review recommendations.
- **Offline first:** Bundled content stays usable without an internet connection, then syncs when connectivity returns.
- **Natural UX:** Copy and navigation are written as normal product language rather than exposing internal AI terminology.

## Curriculum

The content model is:

`Level -> Chapter -> Sub-chapter -> Activity -> Review`

Each JLPT level is intentionally deeper than a short list of grammar points. The current catalog targets roughly 20+ chapters per level and uses six-part sub-lesson sequences for the extended topic units: concept, guided practice, nuance comparison, real context, active recall, and checkpoint review.

The curriculum is original project-authored material. Standards and public educational references inform the scope and progression, while proprietary textbook pages and question banks are not reproduced.

## Main learning areas

- Kana foundation
- Vocabulary and Kanji
- Grammar and example sentences
- Reading and listening
- Speaking, shadowing and conversation practice
- Adaptive review and mistake recovery
- JLPT Quiz Center and mock tests
- JFT-Basic practice
- SSW / Work-in-Japan practice
- Profile analytics, achievements and weekly learning activity

## Architecture

```text
Flutter UI
  ├─ Home
  ├─ Learning
  ├─ Quiz Center
  ├─ Library
  ├─ Profile / Settings
  └─ Offline-first services
       ├─ AppController
       ├─ Curriculum Engine
       ├─ Study Intelligence
       ├─ Content Repository
       └─ Progress Sync

Backend
  ├─ Express API
  ├─ PostgreSQL
  ├─ Authentication / reset flows
  ├─ Audit logging
  └─ Nginx TLS proxy

Firebase
  ├─ Authentication
  └─ Firestore progress sync
```

## Repository layout

- `lib/features/curriculum/` — curriculum models, catalog and depth blueprint
- `lib/screens/curriculum/` — Learning level and lesson UI
- `lib/services/` — sync, adaptive learning, auth, content and other domain services
- `lib/widgets/` — reusable UI components and profile analytics
- `assets/data/` — bundled Japanese learning datasets
- `backend/api/` — Express API
- `backend/db/` — PostgreSQL schema and migrations
- `backend/proxy/` — Nginx TLS reverse proxy
- `docs/` — architecture, migration, curriculum and security specifications

## Local Flutter setup

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

For local development against a self-signed HTTPS proxy only, you may explicitly opt in with `--dart-define=ALLOW_INSECURE_LOCAL_TLS=true`. Do not use that flag for release builds.

## Backend setup

Create the required environment variables from the environment documentation. At minimum, production authentication requires a strong `JWT_SECRET` and a working `DATABASE_URL`. Configure explicit `CORS_ORIGIN` values for browser clients rather than using a wildcard in production.

```bash
cd backend/api
npm install
node src/server.js
```

For container deployment:

```bash
docker compose -f backend/docker-compose.yml up -d --build
```

## Security baseline

The API uses Helmet, explicit CORS configuration, request IDs, body limits, rate limiting, bcrypt password hashing, short-lived JWTs, password-change token invalidation, signed Google/Firebase token verification, parameterized SQL, reset-code hashing, and audit logging.

The Firestore client is restricted to the authenticated user's own progress document. Other user documents are not directly writable by the client.

No application can honestly promise that it is impossible to hack. The goal of this repository is defense in depth: narrow permissions, small attack surfaces, safe defaults, observability, testing, and regular dependency/security review.

## Verification

The CI workflow runs Flutter analysis/tests and backend syntax checks. Production teams should additionally run Firebase Emulator Suite rules tests, backend integration tests, dependency vulnerability scans, and deployment smoke tests.

## License

See `LICENSE`.
