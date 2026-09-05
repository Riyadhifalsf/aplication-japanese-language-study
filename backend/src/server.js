require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const bcrypt = require('bcryptjs');
const pool = require('./db');
const { issueToken, authRequired } = require('./auth');

const app = express();
app.disable('x-powered-by');
app.use(helmet());
app.use(cors({ origin: process.env.CORS_ORIGIN === '*' ? true : process.env.CORS_ORIGIN }));
app.use(express.json({ limit: '10mb' }));

const cleanEmail = (v) => String(v || '').trim().toLowerCase();
const publicUser = (u) => ({
  id: u.id, email: u.email, display_name: u.display_name,
  role: u.role, profile: u.profile || {}, created_at: u.created_at,
});

app.get('/api/health', async (_req,res) => {
  const r = await pool.query('SELECT now() AS time');
  res.json({ ok:true, database:true, time:r.rows[0].time });
});

app.post('/api/auth/register', async (req,res) => {
  try {
    const name = String(req.body.name || '').trim();
    const email = cleanEmail(req.body.email);
    const password = String(req.body.password || '');
    if (name.length < 2) return res.status(400).json({message:'Nama minimal 2 karakter.'});
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) return res.status(400).json({message:'Email tidak valid.'});
    if (password.length < 8) return res.status(400).json({message:'Password minimal 8 karakter.'});
    const exists = await pool.query('SELECT 1 FROM app_users WHERE email=$1',[email]);
    if (exists.rowCount) return res.status(409).json({message:'Email sudah terdaftar.'});
    const hash = await bcrypt.hash(password, 12);
    const r = await pool.query(
      `INSERT INTO app_users(email,password_hash,display_name,role,profile)
       VALUES($1,$2,$3,'user',$4) RETURNING *`,
      [email,hash,name,JSON.stringify({})]
    );
    const u=r.rows[0];
    await pool.query('INSERT INTO api_audit_logs(user_id,action) VALUES($1,$2)',[u.id,'register']);
    res.status(201).json({token:issueToken(u), user:publicUser(u), progress:u.progress || {}});
  } catch(e) { console.error(e); res.status(500).json({message:'Gagal membuat akun.'}); }
});

app.post('/api/auth/login', async (req,res) => {
  try {
    const email=cleanEmail(req.body.email), password=String(req.body.password || '');
    const r=await pool.query('SELECT * FROM app_users WHERE email=$1',[email]);
    if (!r.rowCount) return res.status(401).json({message:'Email atau password salah.'});
    const u=r.rows[0];
    if (!u.password_hash || !(await bcrypt.compare(password,u.password_hash)))
      return res.status(401).json({message:'Email atau password salah.'});
    await pool.query('UPDATE app_users SET last_login_at=now() WHERE id=$1',[u.id]);
    await pool.query('INSERT INTO api_audit_logs(user_id,action) VALUES($1,$2)',[u.id,'login']);
    res.json({token:issueToken(u),user:publicUser(u),progress:u.progress || {}});
  } catch(e) { console.error(e); res.status(500).json({message:'Login gagal.'}); }
});

app.get('/api/me', authRequired, async (req,res) => {
  const r=await pool.query('SELECT * FROM app_users WHERE id=$1',[req.auth.sub]);
  if(!r.rowCount) return res.status(404).json({message:'User tidak ditemukan.'});
  const u=r.rows[0];
  res.json({user:publicUser(u),progress:u.progress || {}});
});

app.put('/api/me/profile', authRequired, async (req,res) => {
  const profile = req.body && typeof req.body === 'object' ? req.body : {};
  const r=await pool.query(
    `UPDATE app_users SET display_name=COALESCE($2,display_name),profile=$3 WHERE id=$1 RETURNING *`,
    [req.auth.sub, profile.display_name ? String(profile.display_name) : null, JSON.stringify(profile)]
  );
  if(!r.rowCount) return res.status(404).json({message:'User tidak ditemukan.'});
  res.json({user:publicUser(r.rows[0])});
});

app.put('/api/me/progress', authRequired, async (req,res) => {
  const progress=req.body && typeof req.body==='object' ? req.body : {};
  const r=await pool.query(
    `UPDATE app_users SET progress=$2 WHERE id=$1 RETURNING updated_at`,
    [req.auth.sub,JSON.stringify(progress)]
  );
  if(!r.rowCount) return res.status(404).json({message:'User tidak ditemukan.'});
  res.json({ok:true,updated_at:r.rows[0].updated_at});
});

app.delete('/api/me', authRequired, async (req,res) => {
  await pool.query('DELETE FROM app_users WHERE id=$1',[req.auth.sub]);
  res.json({ok:true});
});

app.get('/api/admin/users', authRequired, async (req,res) => {
  if(req.auth.role!=='admin') return res.status(403).json({message:'Admin only.'});
  const r=await pool.query('SELECT id,email,display_name,role,profile,created_at,last_login_at FROM app_users ORDER BY created_at DESC');
  res.json({users:r.rows});
});

app.delete('/api/admin/users/:id', authRequired, async (req,res) => {
  if(req.auth.role!=='admin') return res.status(403).json({message:'Admin only.'});
  await pool.query('DELETE FROM app_users WHERE id=$1',[req.params.id]);
  res.json({ok:true});
});

const port=Number(process.env.PORT||8000);
app.listen(port,'0.0.0.0',()=>console.log(`Japanese Study API :${port}`));
