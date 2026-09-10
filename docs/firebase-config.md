# Firebase configuration

## Android API key

The Android Firebase API key is intentionally not committed to this repository.
Provide it at build time with Dart's `--dart-define`:

```bash
flutter run --dart-define=FIREBASE_ANDROID_API_KEY=YOUR_RESTRICTED_FIREBASE_KEY
```

For a release build:

```bash
flutter build apk --release --dart-define=FIREBASE_ANDROID_API_KEY=YOUR_RESTRICTED_FIREBASE_KEY
```

For local development, keep the key outside the repo (for example
`~/.config/japanese-study/firebase-android-key.txt`) and never paste the real
value into source files, docs, or chat logs that get stored.

Use a Firebase-provisioned Android API key restricted to Firebase-related APIs.
Do not put a Gemini Developer API key or another billable Google Cloud API key
in this value.

## google-services.json (lokal saja)

The `google-services` Gradle plugin needs `android/app/google-services.json`
at build time. Download it from Firebase Console → Project settings → Your
apps, place it at `android/app/google-services.json`, and leave it there:
it is gitignored and must never be committed.

## CI / GitHub Actions secrets

The manual release workflow (`.github/workflows/release.yml`) restores
everything it needs from repository secrets — nothing secret is hardcoded:

| Secret | Used for |
| --- | --- |
| `FIREBASE_ANDROID_API_KEY` | `--dart-define` for release builds |
| `FIREBASE_GOOGLE_SERVICES_JSON` | base64 of `google-services.json`, decoded to `android/app/` at build time |
| `ANDROID_KEYSTORE_B64` | base64 keystore, decoded at build time |
| `ANDROID_KEYSTORE_PASSWORD` | `key.properties` (generated, never committed) |
| `ANDROID_KEY_ALIAS` | `key.properties` (generated, never committed) |
| `ANDROID_KEY_PASSWORD` | `key.properties` (generated, never committed) |

Set them in GitHub → repository Settings → Secrets and variables → Actions.
To create the base64 value locally without exposing it:

```bash
base64 -w0 android/app/google-services.json
```

## Client config vs server secret

Safe to commit (public client identifiers): `appId`, `messagingSenderId`,
`projectId`, `databaseURL`, `storageBucket`, API base URL, AdMob ad unit IDs.

Must stay secret (env / GitHub Secrets / server `.env` only): Firebase API
key value, `google-services.json`, keystore + passwords, `JWT_SECRET`,
`ADMIN_TOKEN`, `DATABASE_URL` / DB passwords, SMTP credentials, Gemini keys.
The backend refuses to start without `JWT_SECRET` (fail-closed).

## Google Cloud restrictions

In Google Cloud Console, open **APIs & Services → Credentials**, select the
Firebase Android API key, and verify its API restrictions and Android
application restriction (package name + SHA-1/SHA-256 certificate as
appropriate for the build).

## Secret-scanning alert

Firebase client API keys are public-by-design identifiers for Firebase apps, not
server credentials. GitHub may still report them as public leaks. The important
security controls are API restrictions, Firebase Security Rules, and App Check.

A previously committed key remains present in Git history even after the file is
updated. Revoke/delete an old key only after the application has been moved to a
replacement key, and purge the old value from repository history when it is
necessary to satisfy repository security policy.
