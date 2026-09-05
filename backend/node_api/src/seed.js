import 'dotenv/config';
import pg from 'pg';
import fs from 'node:fs/promises';
import path from 'node:path';
const { Pool } = pg;
const pool = new Pool({ connectionString: process.env.DATABASE_URL });
const root = path.resolve(process.env.PROJECT_ROOT || '../../..');
const source = path.join(root, 'assets', 'data', 'vocabulary.json');
const raw = JSON.parse(await fs.readFile(source, 'utf8'));
const rows = Array.isArray(raw) ? raw : (raw.vocabulary || raw.data || []);
let count = 0;
for (const v of rows) {
  if (!v?.word || !v?.reading || !v?.meaning) continue;
  await pool.query(`INSERT INTO vocabularies(id,word,reading,meaning,level) VALUES($1,$2,$3,$4,$5) ON CONFLICT (id) DO UPDATE SET word=EXCLUDED.word,reading=EXCLUDED.reading,meaning=EXCLUDED.meaning,level=EXCLUDED.level,updated_at=NOW()`, [Number(v.id), String(v.word), String(v.reading), String(v.meaning), String(v.level || 'N5')]);
  count++;
}
await pool.query(`SELECT setval(pg_get_serial_sequence('vocabularies','id'), COALESCE((SELECT MAX(id) FROM vocabularies),1), true)`);
console.log(`Seed selesai: ${count} kotoba`);
await pool.end();
