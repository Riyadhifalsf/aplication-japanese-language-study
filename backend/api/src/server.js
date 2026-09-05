require('dotenv').config();
const crypto = require('crypto');
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const pool = require('./db');

const app = express();
app.disable('x-powered-by');
app.set('trust proxy', 1);
app.use(helmet());
app.use(cors({
  origin: process.env.CORS_ORIGIN === '*' ? true : (process.env.CORS_ORIGIN || true),
}));
app.use(express.json({ limit: '10mb' }));

const JWT_SECRET = process.env.JWT_SECRET || 'dev-secret-change-me';
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '30d';
const ADMIN_TOKEN = (process.env.ADMIN_TOKEN || '').trim();

// ---------- utilitas ----------
const cleanEmail = (v) => String(v || '').trim().toLowerCase();
const publicUser = (u) => ({
  id: u.id, email: u.email, display_name: u.display_name,
  role: u.role, profile: u.profile || {}, created_at: u.created_at,
});
const issueToken = (user) => jwt.sign(
  { sub: user.id, role: user.role, email: user.email },
  JWT_SECRET,
  { expiresIn: JWT_EXPIRES_IN }
);

class HttpError extends Error {
  constructor(status, message) { super(message); this.status = status; }
}

const asyncHandler = (fn) => (req, res, next) =>
  Promise.resolve(fn(req, res, next)).catch(next);

const authRequired = (req, _res, next) => {
  const token = (req.headers.authorization || '').replace(/^Bearer\s+/i, '').trim();
  if (!token) return next(new HttpError(401, 'Token tidak ada.'));
  try { req.auth = jwt.verify(token, JWT_SECRET); return next(); }
  catch (_) { return next(new HttpError(401, 'Token tidak valid atau sudah kedaluwarsa.')); }
};

const adminGuard = (req, _res, next) => {
  const supplied = (req.headers.authorization || '').replace(/^Bearer\s+/i, '').trim();
  if (ADMIN_TOKEN && supplied === ADMIN_TOKEN) return next();
  if (!supplied) return next(new HttpError(401, 'Token admin tidak ada.'));
  try {
    const payload = jwt.verify(supplied, JWT_SECRET);
    if (payload.role === 'admin') return next();
    return next(new HttpError(403, 'Akses admin saja.'));
  } catch (_) {
    return next(new HttpError(401, 'Token admin tidak valid.'));
  }
};

const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 20,
  standardHeaders: true,
  legacyHeaders: false,
  message: { message: 'Terlalu banyak percobaan. Coba lagi dalam beberapa menit.' },
});

const apiLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 240,
  standardHeaders: true,
  legacyHeaders: false,
  message: { message: 'Terlalu banyak permintaan. Coba lagi nanti.' },
});
app.use('/api/', apiLimiter);

const audit = (userId, action, req) =>
  pool.query(
    'INSERT INTO api_audit_logs(user_id, action, ip) VALUES($1,$2,$3)',
    [userId, action, (req.headers['x-forwarded-for'] || req.socket.remoteAddress || '').toString().split(',')[0].trim()]
  ).catch(() => {});

const rawToJson = (row) => ({ ...row, raw: typeof row.raw === 'string' ? JSON.parse(row.raw) : row.raw });

// ---------- health ----------
app.get('/api/health', asyncHandler(async (_req, res) => {
  const r = await pool.query('SELECT now() AS time');
  res.json({ ok: true, database: true, time: r.rows[0].time });
}));

// ---------- auth / akun ----------
app.post('/api/auth/register', authLimiter, asyncHandler(async (req, res) => {
  const name = String(req.body.name || '').trim();
  const email = cleanEmail(req.body.email);
  const password = String(req.body.password || '');
  if (name.length < 2 || name.length > 80) return res.status(400).json({ message: 'Nama minimal 2 karakter (maks 80).' });
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) return res.status(400).json({ message: 'Email tidak valid.' });
  if (password.length < 8) return res.status(400).json({ message: 'Password minimal 8 karakter.' });
  if (password.length > 128) return res.status(400).json({ message: 'Password terlalu panjang.' });
  const exists = await pool.query('SELECT 1 FROM app_users WHERE email=$1', [email]);
  if (exists.rowCount) return res.status(409).json({ message: 'Email sudah terdaftar.' });
  const hash = await bcrypt.hash(password, 12);
  const r = await pool.query(
    `INSERT INTO app_users(email,password_hash,display_name,role,profile)
     VALUES($1,$2,$3,'user',$4) RETURNING *`,
    [email, hash, name, JSON.stringify({})]
  );
  const u = r.rows[0];
  await audit(u.id, 'register', req);
  res.status(201).json({ token: issueToken(u), user: publicUser(u), progress: u.progress || {} });
}));

app.post('/api/auth/login', authLimiter, asyncHandler(async (req, res) => {
  const email = cleanEmail(req.body.email);
  const password = String(req.body.password || '');
  if (!email || !password) return res.status(400).json({ message: 'Email dan password wajib diisi.' });
  const r = await pool.query('SELECT * FROM app_users WHERE email=$1', [email]);
  if (!r.rowCount) return res.status(401).json({ message: 'Email atau password salah.' });
  const u = r.rows[0];
  if (!u.is_active) return res.status(403).json({ message: 'Akun dinonaktifkan. Hubungi admin.' });
  if (!u.password_hash || !(await bcrypt.compare(password, u.password_hash)))
    return res.status(401).json({ message: 'Email atau password salah.' });
  await pool.query('UPDATE app_users SET last_login_at=now() WHERE id=$1', [u.id]);
  await audit(u.id, 'login', req);
  res.json({ token: issueToken(u), user: publicUser(u), progress: u.progress || {} });
}));

// ---------- verifikasi Google/Firebase ID token (tanpa dep baru) ----------
const GOOGLE_CERTS_URL = 'https://www.googleapis.com/oauth2/v3/certs';
const FIREBASE_PROJECT_ID = (process.env.FIREBASE_PROJECT_ID || '').trim();
const cachedCerts = { keys: null, fetchedAt: 0 };

const base64UrlToBuffer = (s) =>
  Buffer.from(String(s).replace(/-/g, '+').replace(/_/g, '/'), 'base64');

async function getGoogleCerts() {
  if (cachedCerts.keys && Date.now() - cachedCerts.fetchedAt < 3600 * 1000) {
    return cachedCerts.keys;
  }
  const r = await fetch(GOOGLE_CERTS_URL);
  if (!r.ok) throw new Error('certs');
  const jwks = await r.json();
  cachedCerts.keys = jwks.keys || [];
  cachedCerts.fetchedAt = Date.now();
  return cachedCerts.keys;
}

async function verifyGoogleIdTokenLocal(idToken) {
  const parts = String(idToken).split('.');
  if (parts.length !== 3) throw new Error('format');
  const header = JSON.parse(base64UrlToBuffer(parts[0]).toString('utf8'));
  if (header.alg !== 'RS256' || !header.kid) throw new Error('alg');
  const keys = await getGoogleCerts();
  const jwk = keys.find((k) => k.kid === header.kid);
  if (!jwk) throw new Error('kid');
  const verifier = crypto.createVerify('RSA-SHA256');
  verifier.update(`${parts[0]}.${parts[1]}`);
  verifier.end();
  const keyObject = crypto.createPublicKey({ key: jwk, format: 'jwk' });
  if (!verifier.verify(keyObject, base64UrlToBuffer(parts[2]))) {
    throw new Error('sig');
  }
  const payload = JSON.parse(base64UrlToBuffer(parts[1]).toString('utf8'));
  const now = Math.floor(Date.now() / 1000);
  if (!payload.sub || !payload.exp || payload.exp < now - 30) {
    throw new Error('exp');
  }
  const issOk = payload.iss === 'https://accounts.google.com' ||
    payload.iss === 'accounts.google.com';
  if (!issOk) throw new Error('iss');
  if (FIREBASE_PROJECT_ID && payload.aud !== FIREBASE_PROJECT_ID) {
    throw new Error('aud');
  }
  return payload;
}

async function verifyGoogleIdToken(idToken) {
  // 1. Verifikasi lokal: tanda tangan RS256 + exp + iss + aud (cepat, tahan rate-limit).
  try {
    const p = await verifyGoogleIdTokenLocal(idToken);
    return { sub: p.sub, email: p.email, name: p.name, picture: p.picture };
  } catch (_) {
    // Lanjut ke fallback di bawah.
  }
  // 2. Fallback tokeninfo Google.
  try {
    const r = await fetch(`https://oauth2.googleapis.com/tokeninfo?id_token=${encodeURIComponent(idToken)}`);
    if (!r.ok) throw new HttpError(401, 'Token Google tidak valid.');
    const info = await r.json();
    if (FIREBASE_PROJECT_ID && info.aud && info.aud !== FIREBASE_PROJECT_ID) {
      throw new HttpError(401, 'Token Google tidak valid.');
    }
    return info;
  } catch (e) {
    if (e instanceof HttpError) throw e;
    throw new HttpError(502, 'Gagal verifikasi token Google.');
  }
}

app.post('/api/auth/google', authLimiter, asyncHandler(async (req, res) => {
  const idToken = String(req.body.idToken || req.body.id_token || '').trim();
  if (!idToken) return res.status(400).json({ message: 'idToken wajib diisi.' });
  const info = await verifyGoogleIdToken(idToken);
  const subject = String(info.sub || '').trim();
  const email = cleanEmail(info.email);
  const name = String(info.name || email.split('@')[0] || 'Google User').slice(0, 80);
  if (!subject || !email) return res.status(401).json({ message: 'Token Google tidak valid.' });
  let r = await pool.query('SELECT * FROM app_users WHERE google_subject=$1', [subject]);
  if (!r.rowCount) {
    const byEmail = await pool.query('SELECT * FROM app_users WHERE email=$1', [email]);
    if (byEmail.rowCount) {
      r = await pool.query(
        'UPDATE app_users SET google_subject=$2, display_name=COALESCE(display_name,$3), last_login_at=now() WHERE id=$1 RETURNING *',
        [byEmail.rows[0].id, subject, name]
      );
    } else {
      r = await pool.query(
        `INSERT INTO app_users(email,display_name,role,google_subject,profile)
         VALUES($1,$2,'user',$3,$4) RETURNING *`,
        [email, name, subject, JSON.stringify({ photoUrl: info.picture || '' })]
      );
    }
  } else {
    await pool.query('UPDATE app_users SET last_login_at=now() WHERE id=$1', [r.rows[0].id]);
  }
  const u = r.rows[0];
  if (!u.is_active) return res.status(403).json({ message: 'Akun dinonaktifkan. Hubungi admin.' });
  await audit(u.id, 'login_google', req);
  res.json({ token: issueToken(u), user: publicUser(u), progress: u.progress || {} });
}));

app.get('/api/me', authRequired, asyncHandler(async (req, res) => {
  const r = await pool.query('SELECT * FROM app_users WHERE id=$1', [req.auth.sub]);
  if (!r.rowCount) return res.status(404).json({ message: 'User tidak ditemukan.' });
  const u = r.rows[0];
  res.json({ user: publicUser(u), progress: u.progress || {} });
}));

app.put('/api/me/profile', authRequired, asyncHandler(async (req, res) => {
  const profile = req.body && typeof req.body === 'object' ? req.body : {};
  const r = await pool.query(
    `UPDATE app_users SET display_name=COALESCE($2,display_name),profile=$3 WHERE id=$1 RETURNING *`,
    [req.auth.sub, profile.display_name ? String(profile.display_name).slice(0, 80) : null, JSON.stringify(profile)]
  );
  if (!r.rowCount) return res.status(404).json({ message: 'User tidak ditemukan.' });
  res.json({ user: publicUser(r.rows[0]) });
}));

app.put('/api/me/progress', authRequired, asyncHandler(async (req, res) => {
  const progress = req.body && typeof req.body === 'object' ? req.body : {};
  const r = await pool.query(
    `UPDATE app_users SET progress=$2 WHERE id=$1 RETURNING updated_at`,
    [req.auth.sub, JSON.stringify(progress)]
  );
  if (!r.rowCount) return res.status(404).json({ message: 'User tidak ditemukan.' });
  res.json({ ok: true, updated_at: r.rows[0].updated_at });
}));

app.delete('/api/me', authRequired, asyncHandler(async (req, res) => {
  await pool.query('DELETE FROM app_users WHERE id=$1', [req.auth.sub]);
  res.json({ ok: true });
}));

app.get('/api/admin/users', adminGuard, asyncHandler(async (_req, res) => {
  const r = await pool.query('SELECT id,email,display_name,role,is_active,profile,created_at,last_login_at FROM app_users ORDER BY created_at DESC');
  res.json({ users: r.rows.map((u) => ({ ...u, display_name: u.display_name })) });
}));

app.delete('/api/admin/users/:id', adminGuard, asyncHandler(async (req, res) => {
  await pool.query('DELETE FROM app_users WHERE id=$1', [req.params.id]);
  res.json({ ok: true });
}));

// ---------- vocabulary (katalog admin; dipakai tooling / CLI) ----------
const vocabFromRow = (r) => ({ id: Number(r.id), word: r.word, reading: r.reading, meaning: r.meaning, level: r.level });

app.get('/api/vocabulary', adminGuard, asyncHandler(async (req, res) => {
  const { level, search, limit = '200', offset = '0' } = req.query;
  const params = [];
  const where = [];
  if (level && level !== 'Semua') { params.push(level); where.push(`level = $${params.length}`); }
  if (search && String(search).trim()) {
    params.push(`%${String(search).trim()}%`);
    const i = params.length;
    where.push(`(word ILIKE $${i} OR reading ILIKE $${i} OR meaning ILIKE $${i})`);
  }
  params.push(Math.min(Number(limit) || 200, 500));
  params.push(Math.max(Number(offset) || 0, 0));
  const result = await pool.query(
    `SELECT * FROM vocabularies ${where.length ? 'WHERE ' + where.join(' AND ') : ''} ORDER BY id LIMIT $${params.length - 1} OFFSET $${params.length}`,
    params
  );
  res.json({ data: result.rows.map(vocabFromRow) });
}));

app.post('/api/vocabulary', adminGuard, asyncHandler(async (req, res) => {
  const { word, reading, meaning, level = 'N5' } = req.body || {};
  if (!word || !reading || !meaning) return res.status(400).json({ message: 'word, reading, dan meaning wajib diisi.' });
  const r = await pool.query(
    'INSERT INTO vocabularies(word,reading,meaning,level) VALUES($1,$2,$3,$4) RETURNING *',
    [String(word).trim().slice(0, 120), String(reading).trim().slice(0, 120), String(meaning).trim().slice(0, 500), level]
  );
  res.status(201).json({ data: vocabFromRow(r.rows[0]) });
}));

app.put('/api/vocabulary/:id', adminGuard, asyncHandler(async (req, res) => {
  const { word, reading, meaning, level } = req.body || {};
  const r = await pool.query(
    'UPDATE vocabularies SET word=$1,reading=$2,meaning=$3,level=$4,updated_at=NOW() WHERE id=$5 RETURNING *',
    [String(word ?? '').trim().slice(0, 120), String(reading ?? '').trim().slice(0, 120), String(meaning ?? '').trim().slice(0, 500), level || 'N5', req.params.id]
  );
  if (!r.rowCount) return res.status(404).json({ message: 'Kotoba tidak ditemukan.' });
  res.json({ data: vocabFromRow(r.rows[0]) });
}));

app.delete('/api/vocabulary/:id', adminGuard, asyncHandler(async (req, res) => {
  const r = await pool.query('DELETE FROM vocabularies WHERE id=$1 RETURNING id', [req.params.id]);
  if (!r.rowCount) return res.status(404).json({ message: 'Kotoba tidak ditemukan.' });
  res.json({ ok: true });
}));

// ---------- konten belajar (dipakai ContentRepository Flutter) ----------
const contentDefs = {
  kanji:      { table: 'content_kanji',       extraWhere: (q, p) => addLevel(q, p) },
  vocabulary: { table: 'content_vocabulary',  extraWhere: (q, p) => addLevel(q, p) },
  grammar:    { table: 'content_grammar',     extraWhere: (q, p) => addLevel(q, p) },
  phrases:    { table: 'content_phrases',     extraWhere: (q, p) => addCategory(q, p) },
  sentences:  { table: 'content_sentences',   extraWhere: (q, p) => { addLevel(q, p); addCategory(q, p); } },
  culture:    { table: 'content_culture',     extraWhere: (q, p) => addCategory(q, p) },
  readings:   { table: 'content_readings',    extraWhere: (q, p) => { addLevel(q, p); addCategory(q, p); } },
};

function addLevel(q, p) {
  const level = q.level;
  if (level && level !== 'Semua') { p.push(level); return `level = $${p.length}`; }
  return '';
}
function addCategory(q, p) {
  const cat = q.category;
  if (cat && cat !== 'Semua') { p.push(cat); return `category = $${p.length}`; }
  return '';
}

app.get('/api/content/:type', asyncHandler(async (req, res) => {
  const type = String(req.params.type).toLowerCase();
  const def = contentDefs[type];
  if (!def) return res.status(404).json({ message: `Konten tidak dikenal: ${type}` });
  const params = [];
  const wheres = [];
  const w = def.extraWhere(req.query, params);
  if (w) wheres.push(w);
  const search = req.query.search;
  if (search && String(search).trim()) {
    params.push(`%${String(search).trim()}%`);
    const i = params.length;
    wheres.push(`search_text ILIKE $${i}`);
  }
  const limit = Math.min(Number(req.query.limit) || 10000, 20000);
  params.push(limit);
  const offset = Math.max(Number(req.query.offset) || 0, 0);
  params.push(offset);
  const sql = `SELECT raw FROM ${def.table} ${wheres.length ? 'WHERE ' + wheres.join(' AND ') : ''} ORDER BY id LIMIT $${params.length - 1} OFFSET $${params.length}`;
  const result = await pool.query(sql, params);
  res.json({ data: result.rows.map((r) => (typeof r.raw === 'string' ? JSON.parse(r.raw) : r.raw)) });
}));

// ---------- data admin / komunitas (AdminDataService Flutter) ----------
const collections = {
  users: {
    table: 'admin_users',
    toDb: (i) => ({ id: i.id, name: i.name, email: i.email, role: i.role, level: i.level, online: !!i.online, created_at: i.createdAt || new Date().toISOString() }),
    toApi: (r) => ({ id: r.id, name: r.name, email: r.email, role: r.role, level: r.level, online: r.online, createdAt: r.created_at }),
  },
  posts: {
    table: 'community_posts',
    toDb: (i) => ({ id: i.id, author: i.author, text: i.text, likes: Number(i.likes || 0), comments_count: Number(i.comments || 0), status: i.status || 'published', created_at: i.createdAt || new Date().toISOString() }),
    toApi: (r) => ({ id: r.id, author: r.author, text: r.text, likes: Number(r.likes), comments: Number(r.comments_count), status: r.status, createdAt: r.created_at }),
  },
  comments: {
    table: 'admin_comments',
    toDb: (i) => ({ id: i.id, post_id: i.postId, author: i.author, text: i.text, status: i.status || 'published', created_at: i.createdAt || new Date().toISOString() }),
    toApi: (r) => ({ id: r.id, postId: r.post_id, author: r.author, text: r.text, status: r.status, createdAt: r.created_at }),
  },
  reports: {
    table: 'complaint_reports',
    toDb: (i) => ({ id: i.id, reporter: i.reporter, category: i.category, message: i.message, status: i.status || 'open', created_at: i.createdAt || new Date().toISOString() }),
    toApi: (r) => ({ id: r.id, reporter: r.reporter, category: r.category, message: r.message, status: r.status, createdAt: r.created_at }),
  },
  activities: {
    table: 'admin_activities',
    toDb: (i) => ({ id: i.id, label: i.label, type: i.type || 'system', created_at: i.createdAt || new Date().toISOString() }),
    toApi: (r) => ({ id: r.id, label: r.label, type: r.type, createdAt: r.created_at }),
  },
  announcements: {
    table: 'admin_announcements',
    toDb: (i) => ({ id: i.id, title: i.title, body: i.body, type: i.type || 'announcement', active: i.active !== false, free_only: !!i.freeOnly, cta_label: i.ctaLabel || '', created_at: i.createdAt || new Date().toISOString() }),
    toApi: (r) => ({ id: r.id, title: r.title, body: r.body, type: r.type, active: r.active, freeOnly: r.free_only, ctaLabel: r.cta_label, createdAt: r.created_at }),
  },
};

app.get('/api/admin/data', adminGuard, asyncHandler(async (_req, res) => {
  const out = {};
  for (const [name, def] of Object.entries(collections)) {
    const { rows } = await pool.query(`SELECT * FROM ${def.table} ORDER BY created_at DESC`);
    out[name] = rows.map(def.toApi);
  }
  res.json(out);
}));

app.post('/api/admin/data/:collection', adminGuard, asyncHandler(async (req, res) => {
  const def = collections[req.params.collection];
  if (!def) return res.status(404).json({ message: 'Koleksi tidak dikenal.' });
  const item = req.body && req.body.item ? req.body.item : req.body;
  if (!item) return res.status(400).json({ message: 'Data item wajib diisi.' });
  const db = def.toDb(item);
  const keys = Object.keys(db);
  const cols = keys.join(',');
  const params = keys.map((_, idx) => `$${idx + 1}`);
  const r = await pool.query(`INSERT INTO ${def.table} (${cols}) VALUES (${params}) RETURNING *`, keys.map((k) => db[k]));
  res.status(201).json({ data: def.toApi(r.rows[0]) });
}));

app.put('/api/admin/data/:collection/:id', adminGuard, asyncHandler(async (req, res) => {
  const def = collections[req.params.collection];
  if (!def) return res.status(404).json({ message: 'Koleksi tidak dikenal.' });
  const item = req.body && req.body.item ? req.body.item : req.body;
  if (!item) return res.status(400).json({ message: 'Data item wajib diisi.' });
  const db = def.toDb({ ...item, id: req.params.id });
  const keys = Object.keys(db).filter((k) => k !== 'id');
  const sets = keys.map((k, idx) => `${k} = $${idx + 2}`).join(', ');
  const r = await pool.query(`UPDATE ${def.table} SET ${sets} WHERE id = $1 RETURNING *`, [req.params.id, ...keys.map((k) => db[k])]);
  if (!r.rowCount) return res.status(404).json({ message: 'Item tidak ditemukan.' });
  res.json({ data: def.toApi(r.rows[0]) });
}));

app.delete('/api/admin/data/:collection/:id', adminGuard, asyncHandler(async (req, res) => {
  const def = collections[req.params.collection];
  if (!def) return res.status(404).json({ message: 'Koleksi tidak dikenal.' });
  await pool.query(`DELETE FROM ${def.table} WHERE id = $1`, [req.params.id]);
  res.json({ ok: true });
}));

// ---------- analitik admin (dipakai dashboard admin Flutter) ----------
app.get('/api/admin/analytics', adminGuard, asyncHandler(async (_req, res) => {
  const since14 = `date_trunc('day', created_at) >= now() - interval '14 days'`;

  const count = (sql, params = []) => pool.query(sql, params).then((r) => Number(r.rows[0].c));

  const [users, admins, posts, comments, reports, announcements, vocab, kanji, vocabC, grammar, phrases, sentences, culture, readings] = await Promise.all([
    count('SELECT count(*)::int AS c FROM app_users'),
    count('SELECT count(*)::int AS c FROM admin_users'),
    count('SELECT count(*)::int AS c FROM community_posts'),
    count('SELECT count(*)::int AS c FROM admin_comments'),
    count('SELECT count(*)::int AS c FROM complaint_reports WHERE status = \'open\''),
    count('SELECT count(*)::int AS c FROM admin_announcements'),
    count('SELECT count(*)::int AS c FROM vocabularies'),
    count('SELECT count(*)::int AS c FROM content_kanji'),
    count('SELECT count(*)::int AS c FROM content_vocabulary'),
    count('SELECT count(*)::int AS c FROM content_grammar'),
    count('SELECT count(*)::int AS c FROM content_phrases'),
    count('SELECT count(*)::int AS c FROM content_sentences'),
    count('SELECT count(*)::int AS c FROM content_culture'),
    count('SELECT count(*)::int AS c FROM content_readings'),
  ]);

  const { rows: registrations } = await pool.query(
    `SELECT to_char(date_trunc('day', created_at), 'YYYY-MM-DD') AS day, count(*)::int AS c
     FROM app_users WHERE ${since14} GROUP BY 1 ORDER BY 1`
  );
  const { rows: logins } = await pool.query(
    `SELECT to_char(date_trunc('day', created_at), 'YYYY-MM-DD') AS day, count(*)::int AS c
     FROM api_audit_logs WHERE action = 'login' AND ${since14.replace('created_at', 'created_at')} GROUP BY 1 ORDER BY 1`
  );
  const { rows: events } = await pool.query(
    `SELECT action, count(*)::int AS c FROM api_audit_logs
     WHERE created_at >= now() - interval '14 days' GROUP BY 1 ORDER BY 2 DESC`
  );
  const { rows: roles } = await pool.query(
    `SELECT role, count(*)::int AS c FROM app_users GROUP BY 1 ORDER BY 2 DESC`
  );
  const { rows: contentByLevel } = await pool.query(`
    SELECT level, sum(cnt)::int AS total FROM (
      SELECT level, count(*)::int AS cnt FROM content_kanji GROUP BY 1
      UNION ALL SELECT level, count(*)::int FROM content_vocabulary GROUP BY 1
      UNION ALL SELECT level, count(*)::int FROM content_grammar GROUP BY 1
      UNION ALL SELECT level, count(*)::int FROM content_sentences GROUP BY 1
      UNION ALL SELECT level, count(*)::int FROM content_readings GROUP BY 1
    ) t GROUP BY 1 ORDER BY 1
  `);
  const { rows: recentActivities } = await pool.query(
    'SELECT id, label, type, created_at FROM admin_activities ORDER BY created_at DESC LIMIT 10'
  );
  const { rows: dashboardUsers } = await pool.query(
    'SELECT id, name, email, role, online FROM admin_users ORDER BY created_at DESC LIMIT 8'
  );

  res.json({
    ok: true,
    totals: {
      users, admins, posts, comments, openReports: reports, announcements, vocabularies: vocab,
      content: { kanji, vocabulary: vocabC, grammar, phrases, sentences, culture, readings },
    },
    contentByLevel,
    series: {
      registrations,
      logins,
      events: events.map((e) => ({ action: e.action, count: e.c })),
    },
    roles,
    recentActivities,
    dashboardUsers,
  });
}));

// ---------- 404 & error ----------
app.use((req, res) => res.status(404).json({ message: `Rute tidak ditemukan: ${req.method} ${req.path}` }));

app.use((err, _req, res, _next) => {
  if (err instanceof HttpError) {
    return res.status(err.status).json({ message: err.message });
  }
  if (err.type === 'entity.parse.failed') {
    return res.status(400).json({ message: 'Format JSON tidak valid.' });
  }
  console.error('[error]', err);
  res.status(500).json({ message: 'Terjadi kesalahan pada server.' });
});

// ---------- run ----------
const port = Number(process.env.PORT || 3000);
app.listen(port, '0.0.0.0', () => console.log(`Japanese Study API :${port}`));