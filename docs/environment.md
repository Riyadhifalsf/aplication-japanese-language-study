# Environment

Sumber: `.env` (tidak di-commit) dari contoh `backend/.env.example`.
WAJIB: `POSTGRES_PASSWORD JWT_SECRET ADMIN_TOKEN ADMIN_EMAIL
ADMIN_PASSWORD`. OPSIONAL: `TLS_IP CORS_ORIGIN FIREBASE_PROJECT_ID
OPENAI_API_KEY OPENAI_MODEL JWT_EXPIRES_IN WEB_PORT`.
`DATABASE_URL` dirakit compose (jangan tulis manual).
`JWT_SECRET` kosong = api exit(1). Rotasi: ganti nilai → `up -d`
(recreate api) → semua JWT lama otomatis invalid.
