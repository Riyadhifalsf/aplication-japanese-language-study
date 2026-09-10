# Environment

Sumber: `.env` (tidak di-commit) dari contoh `backend/.env.example`.
WAJIB: `POSTGRES_PASSWORD JWT_SECRET ADMIN_TOKEN ADMIN_EMAIL
ADMIN_PASSWORD`. OPSIONAL: `TLS_IP CORS_ORIGIN FIREBASE_PROJECT_ID
GEMINI_API_KEY GEMINI_MODEL AI_RATE_MAX GEMINI_TIMEOUT_MS JWT_EXPIRES_IN WEB_PORT
CONFIG_KEK`.
`DATABASE_URL` dirakit compose (jangan tulis manual).
`JWT_SECRET` kosong = api exit(1). Rotasi: ganti nilai → `up -d`
(recreate api) → semua JWT lama otomatis invalid.

## Pengaturan runtime di Postgres (tabel `app_settings`)

Sebagian `.env` yang aman dipindah ke DB (migrasi `004_app_settings.sql`):
boleh dioverride — `GEMINI_API_KEY` (secret, terenkripsi AES-256-GCM),
`GEMINI_MODEL`, `AI_RATE_MAX`, `GEMINI_TIMEOUT_MS`.
Nilai DB menang atas env; value kosong = fallback env.

Tetap di env dan JANGAN dipindah (bootstrap): `POSTGRES_PASSWORD` /
`DATABASE_URL`, `JWT_SECRET`, `ADMIN_TOKEN`, kredensial admin, `TLS_IP`.
Tanpa itu server tidak bisa konek DB sama sekali.

Syarat simpan secret ke DB: `CONFIG_KEK` = 32 byte hex
(`openssl rand -hex 32`). Tanpa itu, PUT secret ditolak
`503 CONFIG_KEK_MISSING` dan secret hanya bisa via env.
Kelola via admin: `GET /admin/settings` (mask, tanpa plaintext),
`PUT /api/admin/settings/:key {value}`, `DELETE` = kembali ke env.
Setiap perubahan tercatat di `api_audit_logs`.

## Password & email reset (Gmail SMTP)

Wajib ganti password: konfirmasi password lama. Lupa password: kode 6 digit
ke Gmail (hash SHA-256 di DB, 15 menit, max 5x salah, sekali pakai).
Env: `SMTP_HOST SMTP_PORT SMTP_USER SMTP_PASS SMTP_FROM APP_NAME
RESET_CODE_TTL_MIN`. Gmail butuh **App Password** (Security > 2-Step
Verification > App passwords), bukan password akun. Kosong = mode log-only
(server tetap jalan; `forgot` tetap 200 generik anti-enumeration).
