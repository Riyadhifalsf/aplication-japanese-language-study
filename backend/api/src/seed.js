require('dotenv').config();
const fs = require('fs');
const path = require('path');
const pool = require('./db');

const DATA_DIR = process.env.DATA_DIR || '/app/data';

const joinText = (...parts) => parts.filter(Boolean).join(' ').toLowerCase();

const defs = [
  {
    file: 'kanji.json', table: 'content_kanji', idKey: 'id', levelKey: 'level',
    search: (e) => joinText(e.char, e.meaning, e.on, e.kun, (e.themes || []).join(' ')),
    insertCols: ['id', 'level', 'search_text', 'raw'],
  },
  {
    file: 'vocabulary.json', table: 'content_vocabulary', idKey: 'id', levelKey: 'level',
    search: (e) => joinText(e.word, e.reading, e.meaning),
    insertCols: ['id', 'level', 'word', 'reading', 'meaning', 'search_text', 'raw'],
  },
  {
    file: 'grammar.json', table: 'content_grammar', idKey: 'id', levelKey: 'level',
    search: (e) => joinText(e.pattern, e.title, e.explanation),
    insertCols: ['id', 'level', 'pattern', 'search_text', 'raw'],
  },
  {
    file: 'phrases.json', table: 'content_phrases', idKey: 'id', levelKey: 'category',
    search: (e) => joinText(e.category, e.japanese, e.reading, e.meaning, e.politeness, e.note, (e.tags || []).join(' ')),
    insertCols: ['id', 'category', 'search_text', 'raw'],
  },
  {
    file: 'sentences.json', table: 'content_sentences', idKey: 'id', levelKey: 'level',
    search: (e) => joinText(e.level, e.category, e.japanese, e.reading, e.meaning, e.pattern, e.note),
    insertCols: ['id', 'level', 'category', 'search_text', 'raw'],
  },
  {
    file: 'culture.json', table: 'content_culture', idKey: 'id', levelKey: 'category',
    search: (e) => joinText(e.category, e.title, e.summary, e.detail, e.example, (e.tips || []).join(' ')),
    insertCols: ['id', 'category', 'search_text', 'raw'],
  },
  {
    file: 'readings.json', table: 'content_readings', idKey: 'id', levelKey: 'level',
    search: (e) => joinText(e.level, e.category, e.title, e.japanese, e.reading, e.meaning),
    insertCols: ['id', 'level', 'category', 'search_text', 'raw'],
  },
];

function rowVals(item, def) {
  return def.insertCols.map((c) => {
    switch (c) {
      case 'id': return item.id;
      case 'level': return item.level ?? 'N5';
      case 'category': return item.category ?? '';
      case 'word': return item.word ?? '';
      case 'reading': return item.reading ?? '';
      case 'meaning': return item.meaning ?? '';
      case 'pattern': return item.pattern ?? '';
      case 'search_text': return def.search(item);
      case 'raw': return JSON.stringify(item);
      default: return null;
    }
  });
}

async function seedContent() {
  for (const def of defs) {
    const file = path.join(DATA_DIR, def.file);
    if (!fs.existsSync(file)) { console.log(`SKIP ${def.file} (not found)`); continue; }
    const items = JSON.parse(fs.readFileSync(file, 'utf8'));
    const { rows } = await pool.query(`SELECT count(*)::int AS c FROM ${def.table}`);
    if (rows[0].c > 0) { console.log(`SKIP ${def.table} already has data`); continue; }

    const batchSize = 500;
    for (let i = 0; i < items.length; i += batchSize) {
      let n = 0;
      const batch = items.slice(i, i + batchSize);
      const rowsSql = batch.map((item) => {
        const vals = rowVals(item, def);
        return `(${vals.map(() => `$${++n}`).join(',')})`;
      }).join(',');
      const allVals = batch.flatMap((item) => rowVals(item, def));
      await pool.query(`INSERT INTO ${def.table} (${def.insertCols.join(',')}) VALUES ${rowsSql}`, allVals);
    }
    console.log(`SEEDED ${def.table}: ${items.length} rows`);
  }
}

async function seedVocabularies() {
  const file = path.join(DATA_DIR, 'vocabulary.json');
  if (!fs.existsSync(file)) return;
  const items = JSON.parse(fs.readFileSync(file, 'utf8'));
  const { rows } = await pool.query('SELECT count(*)::int AS c FROM vocabularies');
  if (rows[0].c > 0) { console.log('SKIP vocabularies already has data'); return; }
  const batchSize = 500;
  for (let i = 0; i < items.length; i += batchSize) {
      const batch = items.slice(i, i + batchSize);
      const values = batch.map((e) => [e.word, e.reading, e.meaning, e.level ?? 'N5']);
      let n = 0;
      const rowsSql = values.map(() => `($${++n},$${++n},$${++n},$${++n})`).join(',');
    await pool.query('INSERT INTO vocabularies (word,reading,meaning,level) VALUES ' + rowsSql, values.flat());
  }
  console.log(`SEEDED vocabularies: ${items.length} rows`);
}

async function seedAdmin() {
  const { rows } = await pool.query('SELECT count(*)::int AS c FROM admin_users');
  if (rows[0].c > 0) { console.log('SKIP admin_users already has data'); return; }
  await pool.query(`INSERT INTO admin_users (id,name,email,role,level,online,created_at) VALUES
    ('u-admin','Administrator','admin@example.com','admin','N1',true,now()),
    ('u-001','User Pertama','user@example.com','user','N5',false,now()) ON CONFLICT DO NOTHING`);
  await pool.query(`INSERT INTO admin_activities (id,label,type,created_at) VALUES
    ('act-1','Dashboard admin dibuat','system',now()) ON CONFLICT DO NOTHING`);
  console.log('SEEDED admin_users + admin_activities');
}

async function main() {
  await seedContent();
  await seedVocabularies();
  await seedAdmin();
  await pool.end();
  console.log('SEED_COMPLETE');
}

main().catch(async (e) => {
  console.error('SEED_FAILED', e);
  await pool.end();
  process.exit(1);
});
