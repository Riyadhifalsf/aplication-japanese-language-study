# Production Operations & Security Checklist

## Before deployment

- Set a long random `JWT_SECRET` and keep it outside source control.
- Configure explicit `CORS_ORIGIN` values for trusted web origins.
- Configure `FIREBASE_PROJECT_ID` for Firebase ID-token verification and `GOOGLE_CLIENT_ID` for direct Google ID-token verification when that path is needed.
- Configure SMTP with an application password or transactional mail provider.
- Use PostgreSQL TLS in production and keep `PGSSL_REJECT_UNAUTHORIZED=true`.
- Supply a trusted `PGSSL_CA` when the database requires a private CA.
- Replace the development self-signed proxy certificate with a trusted certificate for a public deployment.
- Never ship `ALLOW_INSECURE_LOCAL_TLS=true` in a production/release build.
- Enable Firebase App Check where appropriate.
- Run Firestore Emulator Suite tests before changing production rules.

## Database

- Keep automated backups and test restore procedures.
- Use a dedicated database role with only the privileges the application requires.
- Restrict network access so PostgreSQL is not exposed directly to the public internet.
- Rotate credentials and encryption keys on a schedule.

## Authentication

- Prefer the Firebase ID-token path for Firebase-authenticated clients.
- Do not log access tokens, reset codes, passwords, SMTP credentials, or database URLs.
- Monitor authentication failures and reset-code abuse.
- Keep password reset codes short-lived and one-time.

## CI/CD

- Run Flutter analysis/tests on every pull request.
- Run backend syntax checks and migration checks on every pull request.
- Add emulator-backed Firestore rules tests before production rollout.
- Add dependency vulnerability scanning and secret scanning in the hosting provider.
- Require review for changes to authentication, Firestore rules, SQL schema, and deployment files.

## Incident response

Preserve request IDs, audit events, deployment versions, and relevant timestamps. Revoke or rotate compromised credentials first, then invalidate sessions/tokens and investigate the affected user/data scope.
