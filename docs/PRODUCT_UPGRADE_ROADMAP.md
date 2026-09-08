# Product Upgrade Roadmap

## Completed in this release

- Kana-first Learning experience.
- Unlocked lesson navigation within the active level.
- Modern N5-N1 selector with visible progress.
- Expanded chapter depth and six-part sub-lesson pattern.
- Quiz content separated from Library.
- Profile analytics, achievements and weekly learning pulse.
- Donation summary and donor ranking model.
- Google-account local-password reset flow.
- Firestore ownership rules narrowed to the real sync document.
- Backend token verification and reset transaction hardening.
- Node.js 24 LTS runtime and non-root API container.
- Nginx timeout, body-size, security-header and API throttling baseline.

## Next high-value work

1. Add emulator-backed Firestore rule tests to CI.
2. Add integration tests for password reset, Google sign-in and progress sync.
3. Add contract tests for payment and donation webhooks before accepting live transactions.
4. Add Sentry/OpenTelemetry or equivalent observability with privacy filtering.
5. Add content QA gates for Japanese examples and reading/listening scripts.
6. Add migration versioning for bundled curriculum IDs so progress remains stable as content grows.
