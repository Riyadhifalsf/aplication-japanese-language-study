# File-by-File Implementation Plan

## Existing files to preserve/extend

### `lib/features/curriculum/*`
Tambahkan:
- mastery gates;
- SRS event emission;
- speaking/shadowing activities;
- work scenario activities.

### `lib/features/learning/domain/learning_engine.dart`
Tambahkan/adaptasikan:
- skill mastery;
- adaptive recommendation;
- review scheduling;
- remedial selection.

### `lib/services/study_intelligence_service.dart`
Naikkan menjadi facade:
- local heuristics;
- optional backend AI;
- recommendation normalization.

### `lib/services/offline_packs.dart`
Tambahkan:
- manifest schema;
- checksums;
- atomic install;
- rollback.

### `lib/screens/home/home_screen.dart`
Pertahankan:
- XP;
- streak;
- current learning;
- mission;
- Kanji hari ini;
- due review.

### `lib/screens/study/study_modes_screen.dart`
Tambahkan:
- SSW Manufacturing;
- Speaking;
- Shadowing;
- Adaptive session.

### `lib/screens/speaking/`
Buat:
- speaking hub;
- exercise screen;
- recorder;
- playback;
- shadowing screen;
- self rating.

### `lib/services/`
Buat:
- `speaking_service.dart`
- `shadowing_service.dart`
- `ai_sensei_service.dart`
- `ssw_service.dart`
- `entitlement_service.dart`

### `lib/models/`
Buat:
- `speaking_exercise.dart`
- `shadowing_session.dart`
- `work_scenario.dart`
- `entitlement.dart`
- `content_pack.dart`

### `lib/screens/profile/premium_screen.dart`
Hubungkan hanya ke provider yang configured.
Jangan ubah `ready=false` menjadi `true` tanpa integrasi nyata.

### `backend/api/src/server.js`
Tambahkan route groups:
- `/api/v1/ai/*`
- `/api/v1/speaking/*`
- `/api/v1/work/*`
- `/api/v1/entitlements/*`

### `backend/api/src/`
Buat adapter:
- `ai_provider.js`
- `billing_provider.js`
- `entitlement_service.js`
- `work_content_service.js`

### `backend/api/db/`
Migration:
- user entitlements;
- AI usage quota;
- work progress;
- speaking progress;
- audit events.

### `assets/data/`
Konten:
- `ssw_manufacturing.json`
- `speaking.json`
- `shadowing.json`
- optional level packs.

## Execution order
1. models/contracts
2. repositories/services
3. local persistence
4. backend migrations/API
5. curriculum integration
6. screens
7. tests
8. validation
9. release build
