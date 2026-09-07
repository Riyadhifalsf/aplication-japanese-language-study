// Runner migrasi versioned (tanpa dep baru).
// - Tabel schema_migrations mencatat versi yang sudah teraplikasi.
// - Setiap file NNN_*.sql di ../db/migrations dieksekusi SEKALI, urut nama.
// - Seluruh migrasi idempoten (IF NOT EXISTS / DO-guard) sehingga aman retry.
// Dipanggil entrypoint SEBELUM server start; gagal = container crash (lebih
// baik daripada jalan dengan skema basi).
require('dotenv').config();
const fs = require('fs');
const path = require('path');
const pool = require('./db');

async function main() {
  const dir = path.join(__dirname, '..', 'db', 'migrations');
  const files = fs
    .readdirSync(dir)
    .filter((f) => f.endsWith('.sql'))
    .sort();
  await pool.query(`CREATE TABLE IF NOT EXISTS schema_migrations(
    version TEXT PRIMARY KEY, applied_at TIMESTAMPTZ NOT NULL DEFAULT now())`);
  const done = new Set(
    (await pool.query('SELECT version FROM schema_migrations')).rows.map(
      (r) => r.version
    )
  );
  for (const f of files) {
    if (done.has(f)) {
      console.log(`MIGRATE skip ${f}`);
      continue;
    }
    console.log(`MIGRATE apply ${f}`);
    const sql = fs.readFileSync(path.join(dir, f), 'utf8');
    await pool.query('BEGIN');
    try {
      await pool.query(sql);
      await pool.query('INSERT INTO schema_migrations(version) VALUES($1)', [
        f,
      ]);
      await pool.query('COMMIT');
      console.log(`MIGRATE ok ${f}`);
    } catch (e) {
      await pool.query('ROLLBACK');
      throw e;
    }
  }
  await pool.end();
  console.log('MIGRATE_COMPLETE');
}

main().catch(async (e) => {
  console.error('MIGRATE_FAILED', e && e.message ? e.message : e);
  try {
    await pool.end();
  } catch (_) {}
  process.exit(1);
});
