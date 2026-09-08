# Security Hardening Plan

This project treats security as a layered engineering problem rather than a claim of being impossible to hack. The current baseline uses authenticated ownership checks, narrow database rules, short-lived JWTs, password-change invalidation, rate limiting, input-size limits, signed Google/Firebase token verification, structured error responses, audit logging, HTTPS proxy hardening, and a non-root API container.

## Authentication

- Passwords are hashed with bcrypt.
- JWT lifetime defaults to seven days and may be configured through the environment.
- `password_changed_at` invalidates tokens issued before a password change.
- Password reset codes are stored only as SHA-256 digests and expire quickly.
- Reset attempts are capped and reset endpoints are rate limited.
- Google/Firebase ID tokens are verified locally against provider JWKS with issuer, audience, expiry, `iat`, algorithm, and key-id checks.
- Google-only accounts can establish a local password through the verified email reset flow.

## API abuse resistance

- JSON request bodies are capped at 1.5 MB.
- Per-API and authentication rate limits are applied.
- Sensitive password routes have stricter rate limiting.
- Profile fields are allowlisted and size-bounded.
- Progress payloads are object-only and size-bounded.
- CORS defaults to deny unless explicit origins are configured.
- Authentication responses are intended to remain cache-resistant.

## Database safety

- SQL access uses parameterized queries.
- Password reset updates use a single checked-out PostgreSQL client for transaction atomicity.
- Account-owned records are deleted with database foreign-key cascades where appropriate.
- Security audit records keep a lightweight trail of sensitive account actions.

## Firebase / Firestore

The client is only allowed to access its own `users/{uid}/progress/main` document. The document envelope is restricted to the expected fields and bounded in size. Arbitrary `/users/{uid}` writes are denied.

## Network / container

- Nginx exposes TLS 1.2/1.3, HSTS, MIME sniffing protection, referrer policy, and restrictive browser permissions.
- Request body and timeout limits are configured at the proxy.
- API traffic is rate limited again at the proxy layer.
- The API container uses Node.js 24 LTS and runs as a non-root user.
- The image includes a health check and removes the npm cache after installation.

## Operational requirements

Secrets must live in a secret manager or environment injection mechanism, never in the repository. Production deployments should enable Firebase App Check where supported, use least-privilege IAM, rotate secrets, run database backups, and monitor authentication/audit events.
