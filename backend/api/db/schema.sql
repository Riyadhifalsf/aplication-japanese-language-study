-- Japanese Study — schema produksi (idempotent; aman dijalankan berulang)
-- Dijalankan otomatis oleh entrypoint container api sebelum seeding.
-- (Salinan dari backend/db/schema.sql agar sesuai COPY api/db di Dockerfile.)

CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- ================= AUTH / AKUN =================
CREATE TABLE IF NOT EXISTS app_users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL UNIQUE,
  password_hash TEXT,
  display_name TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'user' CHECK (role IN ('user','moderator','admin')),
  google_subject TEXT UNIQUE,
  is_active BOOLEAN NOT NULL DEFAULT true,
  profile JSONB NOT NULL DEFAULT '{}'::jsonb,
  progress JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_login_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_app_users_role ON app_users(role);
CREATE INDEX IF NOT EXISTS idx_app_users_created ON app_users(created_at);
CREATE INDEX IF NOT EXISTS idx_app_users_email_trgm ON app_users USING GIN (email gin_trgm_ops);

CREATE TABLE IF NOT EXISTS api_audit_logs (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID REFERENCES app_users(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  ip TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_audit_created ON api_audit_logs(created_at);
CREATE INDEX IF NOT EXISTS idx_audit_action ON api_audit_logs(action);
CREATE INDEX IF NOT EXISTS idx_audit_user ON api_audit_logs(user_id);

CREATE OR REPLACE FUNCTION set_updated_at() RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_app_users_updated_at ON app_users;
CREATE TRIGGER trg_app_users_updated_at
BEFORE UPDATE ON app_users FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ================= KOTABA (vocabulary) =================
CREATE TABLE IF NOT EXISTS vocabularies (
  id BIGSERIAL PRIMARY KEY,
  word TEXT NOT NULL,
  reading TEXT NOT NULL,
  meaning TEXT NOT NULL,
  level TEXT NOT NULL CHECK (level IN ('N5','N4','N3','N2','N1','Tambahan')),
  kanji_ids JSONB NOT NULL DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_vocab_level ON vocabularies(level);
CREATE INDEX IF NOT EXISTS idx_vocab_word_trgm ON vocabularies USING GIN (word gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_vocab_meaning_trgm ON vocabularies USING GIN (meaning gin_trgm_ops);

-- ================= KONTEN BELAJAR =================
CREATE TABLE IF NOT EXISTS content_kanji (
  id INTEGER PRIMARY KEY,
  level TEXT NOT NULL,
  search_text TEXT NOT NULL,
  raw JSONB NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_content_kanji_level ON content_kanji(level);
CREATE INDEX IF NOT EXISTS idx_content_kanji_search_trgm ON content_kanji USING GIN (search_text gin_trgm_ops);

CREATE TABLE IF NOT EXISTS content_vocabulary (
  id INTEGER PRIMARY KEY,
  level TEXT NOT NULL,
  word TEXT NOT NULL,
  reading TEXT NOT NULL,
  meaning TEXT NOT NULL,
  search_text TEXT NOT NULL,
  raw JSONB NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_content_vocab_level ON content_vocabulary(level);
CREATE INDEX IF NOT EXISTS idx_content_vocab_search_trgm ON content_vocabulary USING GIN (search_text gin_trgm_ops);

CREATE TABLE IF NOT EXISTS content_grammar (
  id TEXT PRIMARY KEY,
  level TEXT NOT NULL,
  pattern TEXT NOT NULL,
  search_text TEXT NOT NULL,
  raw JSONB NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_content_grammar_level ON content_grammar(level);
CREATE INDEX IF NOT EXISTS idx_content_grammar_search_trgm ON content_grammar USING GIN (search_text gin_trgm_ops);

CREATE TABLE IF NOT EXISTS content_phrases (
  id TEXT PRIMARY KEY,
  category TEXT NOT NULL,
  search_text TEXT NOT NULL,
  raw JSONB NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_content_phrases_category ON content_phrases(category);
CREATE INDEX IF NOT EXISTS idx_content_phrases_search_trgm ON content_phrases USING GIN (search_text gin_trgm_ops);

CREATE TABLE IF NOT EXISTS content_sentences (
  id TEXT PRIMARY KEY,
  level TEXT NOT NULL,
  category TEXT NOT NULL,
  search_text TEXT NOT NULL,
  raw JSONB NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_content_sentences_level ON content_sentences(level);
CREATE INDEX IF NOT EXISTS idx_content_sentences_category ON content_sentences(category);
CREATE INDEX IF NOT EXISTS idx_content_sentences_search_trgm ON content_sentences USING GIN (search_text gin_trgm_ops);

CREATE TABLE IF NOT EXISTS content_culture (
  id TEXT PRIMARY KEY,
  category TEXT NOT NULL,
  search_text TEXT NOT NULL,
  raw JSONB NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_content_culture_category ON content_culture(category);
CREATE INDEX IF NOT EXISTS idx_content_culture_search_trgm ON content_culture USING GIN (search_text gin_trgm_ops);

CREATE TABLE IF NOT EXISTS content_readings (
  id TEXT PRIMARY KEY,
  level TEXT NOT NULL,
  category TEXT NOT NULL,
  search_text TEXT NOT NULL,
  raw JSONB NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_content_readings_level ON content_readings(level);
CREATE INDEX IF NOT EXISTS idx_content_readings_category ON content_readings(category);
CREATE INDEX IF NOT EXISTS idx_content_readings_search_trgm ON content_readings USING GIN (search_text gin_trgm_ops);

-- ================= ADMIN / KOMUNITAS =================
CREATE TABLE IF NOT EXISTS admin_users (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  role TEXT NOT NULL DEFAULT 'user' CHECK (role IN ('user','moderator','admin')),
  level TEXT NOT NULL DEFAULT 'N5' CHECK (level IN ('N5','N4','N3','N2','N1')),
  online BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_admin_users_role ON admin_users(role);

CREATE TABLE IF NOT EXISTS community_posts (
  id TEXT PRIMARY KEY,
  author TEXT NOT NULL,
  text TEXT NOT NULL,
  likes INTEGER NOT NULL DEFAULT 0 CHECK (likes >= 0),
  comments_count INTEGER NOT NULL DEFAULT 0 CHECK (comments_count >= 0),
  status TEXT NOT NULL DEFAULT 'published' CHECK (status IN ('published','hidden')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_posts_created ON community_posts(created_at);
CREATE INDEX IF NOT EXISTS idx_posts_status ON community_posts(status);

CREATE TABLE IF NOT EXISTS admin_comments (
  id TEXT PRIMARY KEY,
  post_id TEXT NOT NULL REFERENCES community_posts(id) ON DELETE CASCADE,
  author TEXT NOT NULL,
  text TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'published' CHECK (status IN ('published','hidden')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_comments_post ON admin_comments(post_id);
CREATE INDEX IF NOT EXISTS idx_comments_created ON admin_comments(created_at);

CREATE TABLE IF NOT EXISTS complaint_reports (
  id TEXT PRIMARY KEY,
  reporter TEXT NOT NULL,
  category TEXT NOT NULL,
  message TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open','resolved')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_reports_status ON complaint_reports(status);
CREATE INDEX IF NOT EXISTS idx_reports_created ON complaint_reports(created_at);

CREATE TABLE IF NOT EXISTS admin_activities (
  id TEXT PRIMARY KEY,
  label TEXT NOT NULL,
  type TEXT NOT NULL DEFAULT 'system',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_activities_created ON admin_activities(created_at);

CREATE TABLE IF NOT EXISTS admin_announcements (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  type TEXT NOT NULL DEFAULT 'announcement' CHECK (type IN ('announcement','banner','ad')),
  active BOOLEAN NOT NULL DEFAULT true,
  free_only BOOLEAN NOT NULL DEFAULT false,
  cta_label TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_announcements_active ON admin_announcements(active);
