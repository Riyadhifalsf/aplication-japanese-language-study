require('dotenv').config();
const bcrypt = require('bcryptjs');
const pool = require('./db');

async function main() {
  const email = (process.env.ADMIN_EMAIL || '').trim().toLowerCase();
  const password = process.env.ADMIN_PASSWORD || '';
  const name = (process.env.ADMIN_NAME || 'Administrator').trim();
  if (!email || !password) {
    console.log('SKIP create-admin: ADMIN_EMAIL/ADMIN_PASSWORD tidak diatur.');
    return;
  }
  const hash = await bcrypt.hash(password, 12);

  // Upsert ke app_users dengan role admin
  await pool.query(
    `INSERT INTO app_users (email, password_hash, display_name, role, profile)
     VALUES ($1, $2, $3, 'admin', '{}')
     ON CONFLICT (email) DO UPDATE SET
       password_hash = EXCLUDED.password_hash,
       display_name = EXCLUDED.display_name,
       role = 'admin'`,
    [email, hash, name]
  );

  // Pastikan ada baris di admin_users (untuk dashboard)
  const adminId = `u-admin-${email.split('@')[0]}`;
  await pool.query(
    `INSERT INTO admin_users (id, name, email, role, level, online, created_at)
     VALUES ($1, $2, $3, 'admin', 'N1', false, now())
     ON CONFLICT (id) DO UPDATE SET
       name = EXCLUDED.name,
       email = EXCLUDED.email,
       role = 'admin'`,
    [adminId, name, email]
  );
  console.log(`ADMIN_OK: ${email}`);
}

main().catch(async (e) => {
  console.error('CREATE_ADMIN_FAILED', e);
  await pool.end();
  process.exit(1);
}).finally(() => pool.end());
