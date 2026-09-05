const { Pool } = require('pg');
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  max: 15,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 10000,
  ssl: process.env.PGSSL === 'true' ? { rejectUnauthorized: false } : undefined,
});
module.exports = pool;