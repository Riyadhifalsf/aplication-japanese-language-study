# Japanese Language Study 1.7.1

## Release status

Pre-release candidate.

## Build

- Application version: `1.7.1+9`
- Flutter: `3.47.2`
- Dart: `3.13.2`
- Target: Android APK

## Highlights

- Refreshed project documentation
- Expanded and deeper N5/N4 Learning Path
- Cleaner Library navigation
- Donation ranking based on contribution amount
- Continued chapter-level `Lanjut` navigation
- Updated application release metadata

## Validation

Before publishing this build as a GitHub Pre-release, run:

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

The generated APK should be attached to the GitHub Pre-release using the matching version tag.
