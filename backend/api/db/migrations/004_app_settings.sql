-- 004_app_settings: konfigurasi runtime di Postgres (pengganti sebagian .env).
--
-- Prinsip:
-- - Bootstrap secret (POSTGRES_PASSWORD/DATABASE_URL, JWT_SECRET, ADMIN_TOKEN)
--   TETAP di env/secret-manager. Tanpa itu server tidak bisa konek DB sama
--   sekali (chicken-and-egg), jadi tidak dipindah ke tabel ini.
-- - Yang boleh dioverride di sini hanya allowlist di src/app_config.js:
--   secret: GEMINI_API_KEY (disimpan TERENKRIPSI AES-256-GCM via CONFIG_KEK)
--   plain : GEMINI_MODEL, AI_RATE_MAX, GEMINI_TIMEOUT_MS
-- - Nilai env selalu jadi FALLBACK bila tidak ada override di DB.
-- - Endpoint admin TIDAK PERNAH mengembalikan plaintext secret
--   (hanya configured/preview mask + source db|env|none).
-- Idempoten (aman dijalankan berulang via migrate.js).

CREATE TABLE IF NOT EXISTS app_settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL DEFAULT '',
  is_secret BOOLEAN NOT NULL DEFAULT false,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_by TEXT NOT NULL DEFAULT ''
);

-- Seed baris allowlist agar GET selalu mengembalikan daftar lengkap
-- (tanpa menimpa override yang sudah ada).
INSERT INTO app_settings(key, value, is_secret) VALUES
  ('GEMINI_API_KEY', '', true),
  ('GEMINI_MODEL', '', false),
  ('AI_RATE_MAX', '', false),
  ('GEMINI_TIMEOUT_MS', '', false)
ON CONFLICT (key) DO NOTHING;
