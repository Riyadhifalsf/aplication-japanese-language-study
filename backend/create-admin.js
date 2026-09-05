require('dotenv').config();
const bcrypt=require('bcryptjs');
const pool=require('./src/db');

(async()=>{
  const email=(process.env.ADMIN_EMAIL||'').trim().toLowerCase();
  const password=process.env.ADMIN_PASSWORD||'';
  const name=process.env.ADMIN_NAME||'Administrator';
  if(!email || password.length<12) throw new Error('Set ADMIN_EMAIL dan ADMIN_PASSWORD (minimal 12 karakter).');
  const hash=await bcrypt.hash(password,12);
  await pool.query(
    `INSERT INTO app_users(email,password_hash,display_name,role)
     VALUES($1,$2,$3,'admin')
     ON CONFLICT(email) DO UPDATE SET password_hash=EXCLUDED.password_hash,display_name=EXCLUDED.display_name,role='admin'`,
    [email,hash,name]
  );
  console.log(`Admin siap: ${email}`);
  await pool.end();
})().catch(e=>{console.error(e);process.exit(1);});
