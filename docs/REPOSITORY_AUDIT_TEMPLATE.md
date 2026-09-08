# Repository Audit Template

## 1. Build
- [ ] `flutter analyze`
- [ ] `flutter test`
- [ ] Android build
- [ ] Web build

## 2. Secrets
- [ ] no `.env` with credentials
- [ ] no private keys
- [ ] no keystore
- [ ] no API tokens
- [ ] no hard-coded PSP secrets

## 3. Dependencies
- [ ] versions are intentional
- [ ] unused packages removed
- [ ] lockfiles consistent

## 4. Data
- [ ] JSON valid
- [ ] IDs unique
- [ ] references resolve
- [ ] schema version present
- [ ] migration tested

## 5. Learning
- [ ] mastery != completion
- [ ] review queue works offline
- [ ] remedial path works
- [ ] streak cannot bypass mastery
- [ ] curriculum unlock deterministic

## 6. Sync
- [ ] local-first
- [ ] retry/backoff
- [ ] conflict resolution
- [ ] no destructive overwrite
- [ ] timestamp/version fields

## 7. AI
- [ ] key is server-side
- [ ] quota enforced
- [ ] timeout configured
- [ ] provider errors normalized
- [ ] offline fallback honest

## 8. Payment
- [ ] entitlement verified server-side
- [ ] provider configuration explicit
- [ ] no fake success
- [ ] Play Store policy reviewed
- [ ] refunds/revocation handled

## 9. UX
- [ ] loading states
- [ ] empty states
- [ ] errors
- [ ] offline state
- [ ] accessibility
- [ ] responsive web

## 10. Security
- [ ] auth enforcement
- [ ] role checks
- [ ] input validation
- [ ] rate limits
- [ ] Firestore rules
- [ ] CORS restricted
