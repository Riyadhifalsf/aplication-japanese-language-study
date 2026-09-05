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
CREATE INDEX IF NOT EXISTS idx_vocab_word ON vocabularies USING GIN (to_tsvector('simple', word));
CREATE TABLE IF NOT EXISTS ai_code_jobs (
  id UUID PRIMARY KEY,
  error_message TEXT NOT NULL,
  file_path TEXT,
  line_number INTEGER,
  status TEXT NOT NULL DEFAULT 'queued',
  explanation TEXT,
  patch JSONB,
  analyze_output TEXT,
  test_output TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
