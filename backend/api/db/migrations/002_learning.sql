-- 002_learning: domain pembelajaran server-authoritative.
-- Idempoten (aman dijalankan berulang via migrate.js).
-- Prinsip: client mengirim EVENT/attempt; server menghitung XP, mastery,
-- SRS, mistake, streak. Tidak ada state learner dari client yang dipercaya
-- mentah-mentah selain fakta jawaban terobservasi (fase 1; evaluasi penuh
-- butuh bank jawaban server — lihat docs).

-- Katalog item belajar (ID stabil, didaftarkan saat attempt pertama bila
-- belum ada; kurikulum Flutter memakai ID yang sama).
CREATE TABLE IF NOT EXISTS learning_items (
  id TEXT PRIMARY KEY,
  kind TEXT NOT NULL DEFAULT 'exercise'
    CHECK (kind IN ('kanji','vocabulary','grammar','listening','reading','speaking','exercise','lesson')),
  level TEXT NOT NULL DEFAULT 'N5',
  title TEXT NOT NULL DEFAULT '',
  tags TEXT[] NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_learning_items_kind ON learning_items(kind);
CREATE INDEX IF NOT EXISTS idx_learning_items_level ON learning_items(level);

-- Mastery per user per item (satu baris pasti via PK komposit).
CREATE TABLE IF NOT EXISTS user_item_mastery (
  user_id UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  item_id TEXT NOT NULL,
  skill TEXT NOT NULL DEFAULT 'vocabulary',
  mastery_score INTEGER NOT NULL DEFAULT 0 CHECK (mastery_score BETWEEN 0 AND 100),
  confidence INTEGER NOT NULL DEFAULT 0 CHECK (confidence BETWEEN 0 AND 100),
  attempt_count INTEGER NOT NULL DEFAULT 0 CHECK (attempt_count >= 0),
  correct_count INTEGER NOT NULL DEFAULT 0 CHECK (correct_count >= 0),
  incorrect_count INTEGER NOT NULL DEFAULT 0 CHECK (incorrect_count >= 0),
  consecutive_correct INTEGER NOT NULL DEFAULT 0,
  consecutive_wrong INTEGER NOT NULL DEFAULT 0,
  last_seen_at TIMESTAMPTZ,
  last_correct_at TIMESTAMPTZ,
  PRIMARY KEY (user_id, item_id)
);
CREATE INDEX IF NOT EXISTS idx_mastery_user_skill ON user_item_mastery(user_id, skill);
CREATE INDEX IF NOT EXISTS idx_mastery_score ON user_item_mastery(user_id, mastery_score);

-- SRS review state (abstraksi; algoritma dapat diganti tanpa ubah skema).
CREATE TABLE IF NOT EXISTS review_states (
  user_id UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  item_id TEXT NOT NULL,
  stability_days DOUBLE PRECISION NOT NULL DEFAULT 1.0,
  difficulty DOUBLE PRECISION NOT NULL DEFAULT 5.0,
  interval_days DOUBLE PRECISION NOT NULL DEFAULT 1.0,
  next_review_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  repetitions INTEGER NOT NULL DEFAULT 0,
  lapses INTEGER NOT NULL DEFAULT 0,
  last_reviewed_at TIMESTAMPTZ,
  PRIMARY KEY (user_id, item_id)
);
CREATE INDEX IF NOT EXISTS idx_review_due ON review_states(user_id, next_review_at);

-- Error notebook.
CREATE TABLE IF NOT EXISTS user_mistakes (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  item_id TEXT NOT NULL DEFAULT '',
  skill TEXT NOT NULL DEFAULT 'vocabulary',
  prompt TEXT NOT NULL DEFAULT '',
  user_answer TEXT NOT NULL DEFAULT '',
  correct_answer TEXT NOT NULL DEFAULT '',
  mistake_count INTEGER NOT NULL DEFAULT 1,
  last_occurred_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, item_id, skill)
);
CREATE INDEX IF NOT EXISTS idx_mistakes_user ON user_mistakes(user_id, mistake_count DESC);

-- Attempt idempoten (retry aman: UNIQUE(user_id, client_attempt_id)).
CREATE TABLE IF NOT EXISTS attempts (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  exercise_id TEXT NOT NULL DEFAULT '',
  question_id TEXT NOT NULL DEFAULT '',
  client_attempt_id TEXT NOT NULL DEFAULT '',
  item_id TEXT NOT NULL DEFAULT '',
  skill TEXT NOT NULL DEFAULT 'vocabulary',
  answer TEXT NOT NULL DEFAULT '',
  is_correct BOOLEAN NOT NULL DEFAULT false,
  score INTEGER NOT NULL DEFAULT 0,
  duration_ms INTEGER NOT NULL DEFAULT 0,
  result JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, client_attempt_id)
);
CREATE INDEX IF NOT EXISTS idx_attempts_user_created ON attempts(user_id, created_at DESC);

-- Ledger XP (sumber audit; total = SUM, bukan kolom yang bisa ditimpa).
CREATE TABLE IF NOT EXISTS xp_transactions (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  amount INTEGER NOT NULL,
  reason TEXT NOT NULL DEFAULT 'exercise',
  ref_type TEXT NOT NULL DEFAULT '',
  ref_id TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_xp_user ON xp_transactions(user_id, created_at DESC);

-- Sesi belajar harian (streak server-side; idempoten per tanggal).
CREATE TABLE IF NOT EXISTS study_sessions (
  user_id UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  session_date DATE NOT NULL,
  seconds INTEGER NOT NULL DEFAULT 0 CHECK (seconds >= 0),
  PRIMARY KEY (user_id, session_date)
);

-- Ledger operasi sync (dedupe retry offline).
CREATE TABLE IF NOT EXISTS sync_operations (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  operation_id TEXT NOT NULL,
  entity TEXT NOT NULL DEFAULT '',
  entity_id TEXT NOT NULL DEFAULT '',
  operation TEXT NOT NULL DEFAULT '',
  client_ts TIMESTAMPTZ,
  server_ts TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, operation_id)
);

-- Langganan/entitlement (sumber kebenaran premium).
CREATE TABLE IF NOT EXISTS subscriptions (
  user_id UUID PRIMARY KEY REFERENCES app_users(id) ON DELETE CASCADE,
  plan TEXT NOT NULL DEFAULT 'free',
  status TEXT NOT NULL DEFAULT 'active',
  expires_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
