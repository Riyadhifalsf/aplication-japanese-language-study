-- 005_password_reset: ganti password + lupa password via kode email.
--
-- - app_users.password_changed_at: penanda kapan password terakhir diganti.
--   NULL = belum pernah diganti. authRequired menolak JWT yang diterbitkan
--   SEBELUM waktu ini (token lama mati otomatis saat password diganti).
-- - password_resets: kode 6 digit HANYA disimpan sebagai hash SHA-256
--   (plaintext tidak pernah tersimpan), kedaluwarsa singkat, max percobaan,
--   sekali pakai.
-- Idempoten (aman dijalankan berulang via migrate.js).

ALTER TABLE app_users
  ADD COLUMN IF NOT EXISTS password_changed_at TIMESTAMPTZ NULL;

CREATE TABLE IF NOT EXISTS password_resets (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  code_hash TEXT NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  attempts INTEGER NOT NULL DEFAULT 0 CHECK (attempts >= 0),
  used_at TIMESTAMPTZ NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_password_resets_user ON password_resets(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_password_resets_expiry ON password_resets(expires_at);
