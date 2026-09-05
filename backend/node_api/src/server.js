import 'dotenv/config';
import Fastify from 'fastify';
import cors from '@fastify/cors';
import pg from 'pg';

const { Pool } = pg;
const app = Fastify({ logger: true });
await app.register(cors, { origin: process.env.CORS_ORIGIN || true });
const pool = new Pool({ connectionString: process.env.DATABASE_URL });
const port = Number(process.env.PORT || 3000);

function auth(req, reply) {
  const configured = (process.env.ADMIN_TOKEN || '').trim();
  if (!configured) return;
  const supplied = (req.headers.authorization || '').replace(/^Bearer\s+/i, '').trim();
  if (supplied !== configured) return reply.code(401).send({ message: 'Token admin tidak valid.' });
}
app.get('/api/health', async () => ({ ok: true, database: (await pool.query('SELECT 1')).rowCount === 1 }));

app.get('/api/vocabulary', { preHandler: auth }, async (req) => {
  const { level, search, limit = '200', offset = '0' } = req.query;
  const params = [];
  const where = [];
  if (level && level !== 'Semua') { params.push(level); where.push(`level = $${params.length}`); }
  if (search?.trim()) {
    params.push(`%${search.trim()}%`);
    const i = params.length;
    where.push(`(word ILIKE $${i} OR reading ILIKE $${i} OR meaning ILIKE $${i})`);
  }
  params.push(Math.min(Number(limit) || 200, 500));
  params.push(Math.max(Number(offset) || 0, 0));
  const result = await pool.query(`SELECT * FROM vocabularies ${where.length ? 'WHERE ' + where.join(' AND ') : ''} ORDER BY id LIMIT $${params.length - 1} OFFSET $${params.length}`, params);
  return { data: result.rows };
});

app.post('/api/vocabulary', { preHandler: auth }, async (req, reply) => {
  const { word, reading, meaning, level = 'N5', kanji_ids = [] } = req.body || {};
  if (!word || !reading || !meaning) return reply.code(400).send({ message: 'word, reading, dan meaning wajib diisi.' });
  const r = await pool.query('INSERT INTO vocabularies(word,reading,meaning,level,kanji_ids) VALUES($1,$2,$3,$4,$5) RETURNING *', [word.trim(), reading.trim(), meaning.trim(), level, JSON.stringify(kanji_ids)]);
  return reply.code(201).send({ data: r.rows[0] });
});

app.put('/api/vocabulary/:id', { preHandler: auth }, async (req, reply) => {
  const { word, reading, meaning, level, kanji_ids = [] } = req.body || {};
  const r = await pool.query('UPDATE vocabularies SET word=$1,reading=$2,meaning=$3,level=$4,kanji_ids=$5,updated_at=NOW() WHERE id=$6 RETURNING *', [word?.trim(), reading?.trim(), meaning?.trim(), level || 'N5', JSON.stringify(kanji_ids), req.params.id]);
  if (!r.rowCount) return reply.code(404).send({ message: 'Kotoba tidak ditemukan.' });
  return { data: r.rows[0] };
});

app.delete('/api/vocabulary/:id', { preHandler: auth }, async (req, reply) => {
  const r = await pool.query('DELETE FROM vocabularies WHERE id=$1 RETURNING id', [req.params.id]);
  if (!r.rowCount) return reply.code(404).send({ message: 'Kotoba tidak ditemukan.' });
  return { ok: true };
});

await pool.query(`
CREATE TABLE IF NOT EXISTS vocabularies (id BIGSERIAL PRIMARY KEY, word TEXT NOT NULL, reading TEXT NOT NULL, meaning TEXT NOT NULL, level TEXT NOT NULL, kanji_ids JSONB NOT NULL DEFAULT '[]'::jsonb, created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW());
`);
app.listen({ port, host: '0.0.0.0' }).catch((e) => { app.log.error(e); process.exit(1); });
