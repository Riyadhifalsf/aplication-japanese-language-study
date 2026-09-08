const { Pool } = require('pg');

const connectionString = process.env.DATABASE_URL;
if (!connectionString) {
  throw new Error('DATABASE_URL is required');
}

const rejectUnauthorized = process.env.PGSSL_REJECT_UNAUTHORIZED !== 'false';
const sslCa = (process.env.PGSSL_CA || '').trim();

const pool = new Pool({
  connectionString,
  max: Math.max(1, Math.min(Number(process.env.PG_POOL_MAX || 15), 50)),
  idleTimeoutMillis: Math.max(5000, Number(process.env.PG_IDLE_TIMEOUT_MS || 30000)),
  connectionTimeoutMillis: Math.max(1000, Number(process.env.PG_CONNECT_TIMEOUT_MS || 10000)),
  ssl: process.env.PGSSL === 'true'
    ? {
        rejectUnauthorized,
        ...(sslCa ? { ca: sslCa } : {}),
      }
    : undefined,
  application_name: 'japanese-study-api',
});

pool.on('error', (error) => {
  console.error('[db] idle client error:', error && error.message ? error.message : error);
});

module.exports = pool;
