# Release Audit — 1.7.0+8

## Scope

This release is a repository-wide quality pass over the Flutter client, curriculum layer, authentication backend, PostgreSQL schema, Firebase rules, reverse proxy, CI workflow, and documentation.

## Curriculum surface

- N5: 24 chapters in the combined catalog.
- N4: 20 chapters in the combined catalog.
- N3: 20 chapters in the combined catalog.
- N2: 20 chapters in the combined catalog.
- N1: 22 chapters in the combined catalog.
- Extended topic chapters now use six sub-lessons instead of four.
- Kana foundation remains before the N5 chapter list.
- Lessons inside an unlocked level remain directly accessible; sequence is guidance.

## Client quality

- Learning is the single canonical curriculum surface.
- Legacy `LearningPathScreen` is now a compatibility wrapper instead of a second curriculum implementation.
- Home no longer places a native ad slot at the bottom of the page.
- Profile retains activity history and analytics.
- Writing/editing icons are no longer used as decorative Learning-path UI.
- Production builds reject invalid TLS certificates by default.

## Backend quality

- Google/Firebase ID tokens are verified with provider JWKS, issuer, audience, expiry, `iat`, algorithm and `kid` checks.
- Google-only users can establish a local password through the verified reset-email flow.
- Password reset updates use a single PostgreSQL client transaction.
- JSON and progress payloads are bounded.
- Rate limits and security headers are enabled.
- Firestore rules are narrowed to the authenticated owner's progress document.
- API container runs on Node.js 24 LTS as a non-root user.
- Nginx adds body/timeouts, rate limiting, TLS hardening, and security headers.

## Verification performed in this environment

- Node syntax checks: PASS.
- Dart delimiter/static structure audit across `lib/`: PASS.
- ZIP integrity: validated when the final bundle is produced.

Flutter compiler/analyzer execution is intentionally not claimed here because the build environment used for this repository audit does not contain the Flutter/Dart SDK. Run the project's CI or local `flutter analyze` / `flutter test` before release.
