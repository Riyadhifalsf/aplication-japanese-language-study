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

// Request ID + access log ringan (observability; health tidak dilog).
app.use((req, res, next) => {
  try {
    req.id = crypto.randomUUID();
  } catch (_) {
    req.id = `${Date.now()}-${Math.floor(Math.random() * 1e6)}`;
  }
  const started = Date.now();
  res.on('finish', () => {
    if (req.path === '/api/health' || req.path === '/api/v1/health') return;
    console.log(
      `[api] ${req.id} ${req.method} ${req.path} ${res.statusCode} ${Date.now() - started}ms`
    );
  });
  next();
});

const JWT_SECRET = process.env.JWT_SECRET || '';
if (!JWT_SECRET) {
  console.error('[auth] FATAL: JWT_SECRET tidak diatur. Isi di .env, server tidak boleh jalan tanpa itu.');
  process.exit(1);
}
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
  constructor(status, message, code) {
    super(message);
    this.status = status;
    this.code = code || 'INTERNAL';
  }
}

/// Bentuk error terstruktur (aditif & kompatibel):
/// { success:false, message, error:{code,message} }.
/// Field `message` level atas dipertahankan agar klien lama tetap jalan.
const fail = (res, status, code, message) =>
  res.status(status).json({ success: false, message, error: { code, message } });

const asyncHandler = (fn) => (req, res, next) =>
  Promise.resolve(fn(req, res, next)).catch(next);

const authRequired = (req, _res, next) => {
  const token = (req.headers.authorization || '').replace(/^Bearer\s+/i, '').trim();
  if (!token) return next(new HttpError(401, 'Token tidak ada.', 'AUTH_MISSING_TOKEN'));
  try { req.auth = jwt.verify(token, JWT_SECRET); return next(); }
  catch (_) { return next(new HttpError(401, 'Token tidak valid atau sudah kedaluwarsa.', 'AUTH_BAD_TOKEN')); }
};

const timingSafeEqualHex = (a, b) => {
  try {
    const ba = Buffer.from(String(a));
    const bb = Buffer.from(String(b));
    return ba.length === bb.length && crypto.timingSafeEqual(ba, bb);
  } catch (_) {
    return false;
  }
};

const adminGuard = (req, _res, next) => {
  const supplied = (req.headers.authorization || '').replace(/^Bearer\s+/i, '').trim();
  if (ADMIN_TOKEN && timingSafeEqualHex(supplied, ADMIN_TOKEN)) return next();
  if (!supplied) return next(new HttpError(401, 'Token admin tidak ada.', 'AUTH_MISSING_TOKEN'));
  try {
    const payload = jwt.verify(supplied, JWT_SECRET);
    if (payload.role === 'admin') {
      req.auth = payload;
      return next();
    }
    return next(new HttpError(403, 'Akses admin saja.', 'AUTH_FORBIDDEN'));
  } catch (_) {
    return next(new HttpError(401, 'Token admin tidak valid.', 'AUTH_BAD_TOKEN'));
  }
};

const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: Number(process.env.AUTH_RATE_MAX || 20),
  standardHeaders: true,
  legacyHeaders: false,
  message: { success: false, message: 'Terlalu banyak percobaan. Coba lagi dalam beberapa menit.', error: { code: 'RATE_LIMITED', message: 'Terlalu banyak percobaan. Coba lagi dalam beberapa menit.' } },
});

const apiLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: Number(process.env.API_RATE_MAX || 240),
  standardHeaders: true,
  legacyHeaders: false,
  message: { success: false, message: 'Terlalu banyak permintaan. Coba lagi nanti.', error: { code: 'RATE_LIMITED', message: 'Terlalu banyak permintaan. Coba lagi nanti.' } },
});
app.use('/api', apiLimiter);
app.use('/api/v1', apiLimiter);

const api = require('express').Router();

const audit = (userId, action, req) =>
  pool.query(
    'INSERT INTO api_audit_logs(user_id, action, ip) VALUES($1,$2,$3)',
    [userId, action, (req.headers['x-forwarded-for'] || req.socket.remoteAddress || '').toString().split(',')[0].trim()]
  ).catch(() => {});

const rawToJson = (row) => ({ ...row, raw: typeof row.raw === 'string' ? JSON.parse(row.raw) : row.raw });

// ---------- health ----------
api.get('/health', asyncHandler(async (_req, res) => {
  const r = await pool.query('SELECT now() AS time');
  res.json({ ok: true, database: true, time: r.rows[0].time });
}));

// ---------- auth / akun ----------
api.post('/auth/register', authLimiter, asyncHandler(async (req, res) => {
  const name = String(req.body.name || '').trim();
  const email = cleanEmail(req.body.email);
  const password = String(req.body.password || '');
  if (name.length < 2 || name.length > 80) return fail(res, 400, 'AUTH_INVALID_NAME', 'Nama minimal 2 karakter (maks 80).');
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) return fail(res, 400, 'AUTH_INVALID_EMAIL', 'Email tidak valid.');
  if (password.length < 8) return fail(res, 400, 'AUTH_WEAK_PASSWORD', 'Password minimal 8 karakter.');
  if (password.length > 128) return fail(res, 400, 'AUTH_WEAK_PASSWORD', 'Password terlalu panjang.');
  const hash = await bcrypt.hash(password, 12);
  let r;
  try {
    r = await pool.query(
      `INSERT INTO app_users(email,password_hash,display_name,role,profile)
       VALUES($1,$2,$3,'user',$4) RETURNING *`,
      [email, hash, name, JSON.stringify({})]
    );
  } catch (e) {
    // Race registrasi ganda: UNIQUE(email) yang memutuskan, bukan cek di atas.
    if (e && e.code === '23505') return fail(res, 409, 'AUTH_EMAIL_TAKEN', 'Email sudah terdaftar.');
    throw e;
  }
  const u = r.rows[0];
  await audit(u.id, 'register', req);
  res.status(201).json({ token: issueToken(u), user: publicUser(u), progress: u.progress || {} });
}));

api.post('/auth/login', authLimiter, asyncHandler(async (req, res) => {
  const email = cleanEmail(req.body.email);
  const password = String(req.body.password || '');
  if (!email || !password) return fail(res, 400, 'AUTH_MISSING_FIELDS', 'Email dan password wajib diisi.');
  const r = await pool.query('SELECT * FROM app_users WHERE email=$1', [email]);
  if (!r.rowCount) return fail(res, 401, 'AUTH_BAD_CREDENTIALS', 'Email atau password salah.');
  const u = r.rows[0];
  if (!u.is_active) return fail(res, 403, 'AUTH_DISABLED', 'Akun dinonaktifkan. Hubungi admin.');
  if (!u.password_hash || !(await bcrypt.compare(password, u.password_hash)))
    return fail(res, 401, 'AUTH_BAD_CREDENTIALS', 'Email atau password salah.');
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

api.post('/auth/google', authLimiter, asyncHandler(async (req, res) => {
  const idToken = String(req.body.idToken || req.body.id_token || '').trim();
  if (!idToken) return fail(res, 400, 'AUTH_GOOGLE_NO_TOKEN', 'idToken wajib diisi.');
  const info = await verifyGoogleIdToken(idToken);
  const subject = String(info.sub || '').trim();
  const email = cleanEmail(info.email);
  const name = String(info.name || email.split('@')[0] || 'Google User').slice(0, 80);
  if (!subject || !email) return fail(res, 401, 'AUTH_GOOGLE_INVALID', 'Token Google tidak valid.');
  const linkOrCreate = async () => {
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
    return r;
  };
  let r;
  try {
    r = await linkOrCreate();
  } catch (e) {
    // Race link ganda: UNIQUE yang memutuskan; baca ulang hasil pemenang.
    if (e && e.code === '23505') {
      r = await pool.query('SELECT * FROM app_users WHERE google_subject=$1', [subject]);
      if (!r.rowCount) r = await pool.query('SELECT * FROM app_users WHERE email=$1', [email]);
    } else {
      throw e;
    }
  }
  const u = r.rows[0];
  if (!u) return fail(res, 401, 'AUTH_GOOGLE_INVALID', 'Token Google tidak valid.');
  if (!u.is_active) return fail(res, 403, 'AUTH_DISABLED', 'Akun dinonaktifkan. Hubungi admin.');
  await audit(u.id, 'login_google', req);
  res.json({ token: issueToken(u), user: publicUser(u), progress: u.progress || {} });
}));

api.get('/me', authRequired, asyncHandler(async (req, res) => {
  const r = await pool.query('SELECT * FROM app_users WHERE id=$1', [req.auth.sub]);
  if (!r.rowCount) return fail(res, 404, 'USER_NOT_FOUND', 'User tidak ditemukan.');
  const u = r.rows[0];
  res.json({ user: publicUser(u), progress: u.progress || {} });
}));

api.put('/me/profile', authRequired, asyncHandler(async (req, res) => {
  const profile = req.body && typeof req.body === 'object' ? req.body : {};
  const r = await pool.query(
    `UPDATE app_users SET display_name=COALESCE($2,display_name),profile=$3 WHERE id=$1 RETURNING *`,
    [req.auth.sub, profile.display_name ? String(profile.display_name).slice(0, 80) : null, JSON.stringify(profile)]
  );
  if (!r.rowCount) return fail(res, 404, 'USER_NOT_FOUND', 'User tidak ditemukan.');
  res.json({ user: publicUser(r.rows[0]) });
}));

api.put('/me/progress', authRequired, asyncHandler(async (req, res) => {
  const progress = req.body && typeof req.body === 'object' ? req.body : {};
  const r = await pool.query(
    `UPDATE app_users SET progress=$2 WHERE id=$1 RETURNING updated_at`,
    [req.auth.sub, JSON.stringify(progress)]
  );
  if (!r.rowCount) return fail(res, 404, 'USER_NOT_FOUND', 'User tidak ditemukan.');
  res.json({ ok: true, updated_at: r.rows[0].updated_at });
}));

api.delete('/me', authRequired, asyncHandler(async (req, res) => {
  await pool.query('DELETE FROM app_users WHERE id=$1', [req.auth.sub]);
  res.json({ ok: true });
}));

api.get('/admin/users', adminGuard, asyncHandler(async (_req, res) => {
  const r = await pool.query('SELECT id,email,display_name,role,is_active,profile,created_at,last_login_at FROM app_users ORDER BY created_at DESC');
  res.json({ users: r.rows.map((u) => ({ ...u, display_name: u.display_name })) });
}));

api.delete('/admin/users/:id', adminGuard, asyncHandler(async (req, res) => {
  const targetId = String(req.params.id || '');
  // Cegah bunuh diri admin & hapus admin terakhir (P0).
  if (req.auth && req.auth.sub && req.auth.sub === targetId) {
    return fail(res, 403, 'AUTH_CANNOT_DELETE_SELF', 'Tidak dapat menghapus akun sendiri.');
  }
  const target = await pool.query('SELECT role FROM app_users WHERE id=$1', [targetId]);
  if (!target.rowCount) return fail(res, 404, 'USER_NOT_FOUND', 'User tidak ditemukan.');
  if (target.rows[0].role === 'admin') {
    const admins = await pool.query(`SELECT count(*)::int AS c FROM app_users WHERE role='admin'`);
    if (Number(admins.rows[0].c) <= 1) {
      return fail(res, 403, 'AUTH_LAST_ADMIN', 'Tidak dapat menghapus satu-satunya admin.');
    }
  }
  await pool.query('DELETE FROM app_users WHERE id=$1', [targetId]);
  res.json({ ok: true });
}));

// ---------- vocabulary (katalog admin; dipakai tooling / CLI) ----------
const vocabFromRow = (r) => ({ id: Number(r.id), word: r.word, reading: r.reading, meaning: r.meaning, level: r.level });

api.get('/vocabulary', adminGuard, asyncHandler(async (req, res) => {
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

api.post('/vocabulary', adminGuard, asyncHandler(async (req, res) => {
  const { word, reading, meaning, level = 'N5' } = req.body || {};
  if (!word || !reading || !meaning) return fail(res, 400, 'VALIDATION', 'word, reading, dan meaning wajib diisi.');
  const r = await pool.query(
    'INSERT INTO vocabularies(word,reading,meaning,level) VALUES($1,$2,$3,$4) RETURNING *',
    [String(word).trim().slice(0, 120), String(reading).trim().slice(0, 120), String(meaning).trim().slice(0, 500), level]
  );
  res.status(201).json({ data: vocabFromRow(r.rows[0]) });
}));

api.put('/vocabulary/:id', adminGuard, asyncHandler(async (req, res) => {
  const { word, reading, meaning, level } = req.body || {};
  const r = await pool.query(
    'UPDATE vocabularies SET word=$1,reading=$2,meaning=$3,level=$4,updated_at=NOW() WHERE id=$5 RETURNING *',
    [String(word ?? '').trim().slice(0, 120), String(reading ?? '').trim().slice(0, 120), String(meaning ?? '').trim().slice(0, 500), level || 'N5', req.params.id]
  );
  if (!r.rowCount) return fail(res, 404, 'VOCAB_NOT_FOUND', 'Kotoba tidak ditemukan.');
  res.json({ data: vocabFromRow(r.rows[0]) });
}));

api.delete('/vocabulary/:id', adminGuard, asyncHandler(async (req, res) => {
  const r = await pool.query('DELETE FROM vocabularies WHERE id=$1 RETURNING id', [req.params.id]);
  if (!r.rowCount) return fail(res, 404, 'VOCAB_NOT_FOUND', 'Kotoba tidak ditemukan.');
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

api.get('/content/:type', asyncHandler(async (req, res) => {
  const type = String(req.params.type).toLowerCase();
  const def = contentDefs[type];
  if (!def) return fail(res, 404, 'CONTENT_UNKNOWN', `Konten tidak dikenal: ${type}`);
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

api.get('/admin/data', adminGuard, asyncHandler(async (_req, res) => {
  const out = {};
  for (const [name, def] of Object.entries(collections)) {
    const { rows } = await pool.query(`SELECT * FROM ${def.table} ORDER BY created_at DESC`);
    out[name] = rows.map(def.toApi);
  }
  res.json(out);
}));

api.post('/admin/data/:collection', adminGuard, asyncHandler(async (req, res) => {
  const def = collections[req.params.collection];
  if (!def) return fail(res, 404, 'COLLECTION_UNKNOWN', 'Koleksi tidak dikenal.');
  const item = req.body && req.body.item ? req.body.item : req.body;
  if (!item) return fail(res, 400, 'VALIDATION', 'Data item wajib diisi.');
  const db = def.toDb(item);
  const keys = Object.keys(db);
  const cols = keys.join(',');
  const params = keys.map((_, idx) => `$${idx + 1}`);
  const r = await pool.query(`INSERT INTO ${def.table} (${cols}) VALUES (${params}) RETURNING *`, keys.map((k) => db[k]));
  res.status(201).json({ data: def.toApi(r.rows[0]) });
}));

api.put('/admin/data/:collection/:id', adminGuard, asyncHandler(async (req, res) => {
  const def = collections[req.params.collection];
  if (!def) return fail(res, 404, 'COLLECTION_UNKNOWN', 'Koleksi tidak dikenal.');
  const item = req.body && req.body.item ? req.body.item : req.body;
  if (!item) return fail(res, 400, 'VALIDATION', 'Data item wajib diisi.');
  const db = def.toDb({ ...item, id: req.params.id });
  const keys = Object.keys(db).filter((k) => k !== 'id');
  const sets = keys.map((k, idx) => `${k} = $${idx + 2}`).join(', ');
  const r = await pool.query(`UPDATE ${def.table} SET ${sets} WHERE id = $1 RETURNING *`, [req.params.id, ...keys.map((k) => db[k])]);
  if (!r.rowCount) return fail(res, 404, 'ITEM_NOT_FOUND', 'Item tidak ditemukan.');
  res.json({ data: def.toApi(r.rows[0]) });
}));

api.delete('/admin/data/:collection/:id', adminGuard, asyncHandler(async (req, res) => {
  const def = collections[req.params.collection];
  if (!def) return fail(res, 404, 'COLLECTION_UNKNOWN', 'Koleksi tidak dikenal.');
  await pool.query(`DELETE FROM ${def.table} WHERE id = $1`, [req.params.id]);
  res.json({ ok: true });
}));

// ---------- analitik admin (dipakai dashboard admin Flutter) ----------
api.get('/admin/analytics', adminGuard, asyncHandler(async (_req, res) => {
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

// ---------- learning engine (server-authoritative, fase 1) ----------
// Kontrak: client mengirim FAKTA attempt terobservasi
// {exerciseId,questionId,answer,isCorrect,score,durationMs,
//  clientAttemptId*,itemId,skill,kind,level,title}.
// Server menghitung: XP, mastery (EMA), SRS, mistake, streak-seed.
// Idempoten via UNIQUE(user_id, client_attempt_id): retry mengembalikan
// hasil yang SAMA tanpa XP ganda.
api.post('/attempts', authRequired, asyncHandler(async (req, res) => {
  const b = req.body && typeof req.body === 'object' ? req.body : {};
  const exerciseId = String(b.exerciseId || '').slice(0, 120);
  const questionId = String(b.questionId || '').slice(0, 200);
  const clientAttemptId = String(b.clientAttemptId || '').slice(0, 120);
  const answer = String(b.answer ?? '').slice(0, 2000);
  const isCorrect = b.isCorrect === true;
  const score = Math.max(0, Math.min(100, Number(b.score ?? (isCorrect ? 100 : 0)) || 0));
  const durationMs = Math.max(0, Math.min(3600000, Number(b.durationMs || 0) || 0));
  const itemId = String(b.itemId || questionId || exerciseId || 'unknown').slice(0, 200);
  const skill = ['kanji', 'vocabulary', 'grammar', 'listening', 'reading', 'speaking'].includes(b.skill)
    ? b.skill : 'vocabulary';
  const kind = ['kanji', 'vocabulary', 'grammar', 'listening', 'reading', 'speaking', 'exercise', 'lesson'].includes(b.kind)
    ? b.kind : 'exercise';
  const level = ['N5', 'N4', 'N3', 'N2', 'N1'].includes(b.level) ? b.level : 'N5';
  const title = String(b.title || itemId).slice(0, 200);
  if (!clientAttemptId) return fail(res, 400, 'VALIDATION', 'clientAttemptId wajib diisi (idempotency).');
  const uid = req.auth.sub;
  await pool.query('BEGIN');
  try {
    await pool.query(
      `INSERT INTO learning_items(id,kind,level,title) VALUES($1,$2,$3,$4)
       ON CONFLICT (id) DO NOTHING`,
      [itemId, kind, level, title]
    );
    const ins = await pool.query(
      `INSERT INTO attempts(user_id,exercise_id,question_id,client_attempt_id,
        item_id,skill,answer,is_correct,score,duration_ms,result)
       VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,'{}') ON CONFLICT (user_id, client_attempt_id)
       DO NOTHING RETURNING id`,
      [uid, exerciseId, questionId, clientAttemptId, itemId, skill, answer, isCorrect, score, durationMs]
    );
    if (!ins.rowCount) {
      // Retry/duplikat: kembalikan hasil tersimpan, tanpa efek ganda.
      const prev = await pool.query(
        'SELECT result FROM attempts WHERE user_id=$1 AND client_attempt_id=$2',
        [uid, clientAttemptId]
      );
      await pool.query('COMMIT');
      return res.json({ duplicate: true, ...(prev.rows[0]?.result || {}) });
    }
    const attemptDbId = ins.rows[0].id;
    // Mastery EMA: benar -> mendekati 100, salah -> turun.
    const m = await pool.query(
      `INSERT INTO user_item_mastery(user_id,item_id,skill,mastery_score,confidence,
        attempt_count,correct_count,incorrect_count,consecutive_correct,
        consecutive_wrong,last_seen_at,last_correct_at)
       VALUES($1,$2,$3,0,0,0,0,0,0,0,now(),NULL) ON CONFLICT (user_id, item_id)
       DO UPDATE SET skill=EXCLUDED.skill RETURNING *`,
      [uid, itemId, skill]
    );
    const cur = m.rows[0];
    const target = isCorrect ? 100 : 0;
    const mastery = Math.round(Number(cur.mastery_score) + (target - Number(cur.mastery_score)) * 0.2);
    const attemptCount = Number(cur.attempt_count) + 1;
    const correctCount = Number(cur.correct_count) + (isCorrect ? 1 : 0);
    const incorrectCount = Number(cur.incorrect_count) + (isCorrect ? 0 : 1);
    const cc = isCorrect ? Number(cur.consecutive_correct) + 1 : 0;
    const cw = isCorrect ? 0 : Number(cur.consecutive_wrong) + 1;
    await pool.query(
      `UPDATE user_item_mastery SET mastery_score=$3, confidence=LEAST(100, $4*10),
        attempt_count=$4, correct_count=$5, incorrect_count=$6,
        consecutive_correct=$7, consecutive_wrong=$8, last_seen_at=now(),
        last_correct_at=CASE WHEN $9 THEN now() ELSE last_correct_at END
       WHERE user_id=$1 AND item_id=$2`,
      [uid, itemId, mastery, attemptCount, correctCount, incorrectCount, cc, cw, isCorrect]
    );
    // SRS sederhana (abstraksi; algoritma dapat diganti tanpa ubah skema).
    let nextDays = 1;
    if (isCorrect) {
      const prev = await pool.query(
        'SELECT interval_days FROM review_states WHERE user_id=$1 AND item_id=$2',
        [uid, itemId]
      );
      const base = prev.rowCount ? Number(prev.rows[0].interval_days) : 1;
      nextDays = Math.min(base * 2.2 + 1, 180);
      await pool.query(
        `INSERT INTO review_states(user_id,item_id,stability_days,difficulty,
          interval_days,next_review_at,repetitions,last_reviewed_at)
         VALUES($1,$2,GREATEST(1.0,$3),5,$3,now()+($3 * interval '1 day'),1,now())
         ON CONFLICT (user_id, item_id) DO UPDATE SET
           stability_days=GREATEST(1,review_states.stability_days*1.4),
           interval_days=EXCLUDED.interval_days,
           next_review_at=EXCLUDED.next_review_at,
           repetitions=review_states.repetitions+1, last_reviewed_at=now()`,
        [uid, itemId, nextDays]
      );
    } else {
      await pool.query(
        `INSERT INTO review_states(user_id,item_id,stability_days,difficulty,
          interval_days,next_review_at,lapses,last_reviewed_at)
         VALUES($1,$2,1,5.8,1,now()+interval '1 day',1,now())
         ON CONFLICT (user_id, item_id) DO UPDATE SET
           difficulty=LEAST(10,review_states.difficulty+0.8),
           stability_days=GREATEST(0.5,review_states.stability_days*0.55),
           interval_days=1, next_review_at=now()+interval '1 day',
           lapses=review_states.lapses+1, last_reviewed_at=now()`,
        [uid, itemId]
      );
    }
    // Error notebook.
    if (!isCorrect) {
      await pool.query(
        `INSERT INTO user_mistakes(user_id,item_id,skill,prompt,user_answer,
          correct_answer,mistake_count,last_occurred_at)
         VALUES($1,$2,$3,$4,$5,$6,1,now())
         ON CONFLICT (user_id, item_id, skill) DO UPDATE SET
           mistake_count=user_mistakes.mistake_count+1,
           user_answer=EXCLUDED.user_answer,
           correct_answer=EXCLUDED.correct_answer,
           last_occurred_at=now()`,
        [uid, itemId, skill, '', answer, '']
      );
    }
    // XP ledger (sumber audit; total = SUM).
    const xpAwarded = isCorrect ? (score >= 100 ? 20 : 10) : 0;
    if (xpAwarded > 0) {
      await pool.query(
        `INSERT INTO xp_transactions(user_id,amount,reason,ref_type,ref_id)
         VALUES($1,$2,'exercise_correct','attempt',$3)`,
        [uid, xpAwarded, String(attemptDbId)]
      );
    }
    const total = await pool.query(
      'SELECT COALESCE(SUM(amount),0)::int AS total FROM xp_transactions WHERE user_id=$1',
      [uid]
    );
    const result = {
      xpAwarded,
      xpTotal: Number(total.rows[0].total),
      mastery,
      nextReviewInDays: Math.round(nextDays * 10) / 10,
    };
    await pool.query('UPDATE attempts SET result=$2 WHERE id=$1', [
      attemptDbId,
      JSON.stringify(result),
    ]);
    await pool.query('COMMIT');
    res.status(201).json({ duplicate: false, ...result });
  } catch (e) {
    await pool.query('ROLLBACK');
    throw e;
  }
}));

// Decision engine: apa yang harus dipelajari user ini SEKARANG?
// Urutan: review jatuh tempo -> remedial skill terlemah -> lanjutkan.
api.get('/learning/next', authRequired, asyncHandler(async (req, res) => {
  const uid = req.auth.sub;
  const due = await pool.query(
    `SELECT r.item_id, COALESCE(m.skill, 'vocabulary') AS skill
     FROM review_states r LEFT JOIN user_item_mastery m
       ON m.user_id=r.user_id AND m.item_id=r.item_id
     WHERE r.user_id=$1 AND r.next_review_at <= now()
     ORDER BY r.next_review_at ASC LIMIT 5`,
    [uid]
  );
  const weak = await pool.query(
    `SELECT skill, ROUND(AVG(mastery_score))::int AS avg FROM user_item_mastery
     WHERE user_id=$1 AND attempt_count > 0 GROUP BY skill
     ORDER BY avg ASC LIMIT 1`,
    [uid]
  );
  const mistakes = await pool.query(
    'SELECT count(*)::int AS c FROM user_mistakes WHERE user_id=$1',
    [uid]
  );
  if (due.rowCount) {
    return res.json({
      action: 'review',
      itemIds: due.rows.map((r) => r.item_id),
      reason: `${due.rowCount} review jatuh tempo — pertahankan sebelum hilang.`,
      dueCount: due.rowCount,
      mistakeCount: Number(mistakes.rows[0].c),
    });
  }
  if (weak.rowCount && Number(weak.rows[0].avg) < 80) {
    return res.json({
      action: 'remedial',
      skill: weak.rows[0].skill,
      reason: `Skor ${weak.rows[0].skill} ${weak.rows[0].avg}% — perkuat dulu sebelum lanjut.`,
      dueCount: 0,
      mistakeCount: Number(mistakes.rows[0].c),
    });
  }
  return res.json({
    action: 'continue',
    reason: 'Tidak ada review jatuh tempo. Lanjutkan kurikulum.',
    dueCount: 0,
    mistakeCount: Number(mistakes.rows[0].c),
  });
}));

// Ringkasan mastery per skill + XP ledger + streak server.
api.get('/learning/mastery', authRequired, asyncHandler(async (req, res) => {
  const uid = req.auth.sub;
  const bySkill = await pool.query(
    `SELECT skill, ROUND(AVG(mastery_score))::int AS avg,
       count(*)::int AS items, SUM(attempt_count)::int AS attempts
     FROM user_item_mastery WHERE user_id=$1 GROUP BY skill ORDER BY skill`,
    [uid]
  );
  const xp = await pool.query(
    'SELECT COALESCE(SUM(amount),0)::int AS total FROM xp_transactions WHERE user_id=$1',
    [uid]
  );
  res.json({
    skills: bySkill.rows,
    xpTotal: Number(xp.rows[0].total),
  });
}));

// Entitlement: sumber kebenaran premium (jangan percaya klaim aplikasi).
api.get('/me/entitlements', authRequired, asyncHandler(async (req, res) => {
  const uid = req.auth.sub;
  const me = await pool.query('SELECT role FROM app_users WHERE id=$1', [uid]);
  if (!me.rowCount) return fail(res, 404, 'USER_NOT_FOUND', 'User tidak ditemukan.');
  const sub = await pool.query('SELECT plan, status, expires_at FROM subscriptions WHERE user_id=$1', [uid]);
  const plan = sub.rowCount ? sub.rows[0].plan : 'free';
  const active = sub.rowCount
    ? sub.rows[0].status === 'active' &&
      (!sub.rows[0].expires_at || new Date(sub.rows[0].expires_at) > new Date())
    : true;
  const role = me.rows[0].role;
  const isPremium =
    role === 'admin' || role === 'premium' || (plan !== 'free' && active);
  const xp = await pool.query(
    'SELECT COALESCE(SUM(amount),0)::int AS total FROM xp_transactions WHERE user_id=$1',
    [uid]
  );
  res.json({
    plan, active, role, isPremium,
    xpTotal: Number(xp.rows[0].total),
  });
}));

// Sesi belajar harian (streak server-side; idempoten per tanggal).
api.post('/sessions', authRequired, asyncHandler(async (req, res) => {
  const b = req.body && typeof req.body === 'object' ? req.body : {};
  const date = String(b.date || '').slice(0, 10);
  const seconds = Math.max(0, Math.min(86400, Number(b.seconds || 0) || 0));
  if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) {
    return fail(res, 400, 'VALIDATION', 'Format date harus YYYY-MM-DD.');
  }
  await pool.query(
    `INSERT INTO study_sessions(user_id,session_date,seconds) VALUES($1,$2,$3)
     ON CONFLICT (user_id, session_date) DO UPDATE SET
       seconds = LEAST(86400, study_sessions.seconds + EXCLUDED.seconds)`,
    [req.auth.sub, date, seconds]
  );
  const streak = await pool.query(
    `WITH RECURSIVE s(d, n) AS (
       SELECT CURRENT_DATE, 1
       UNION ALL
       SELECT d - 1, n + 1 FROM s WHERE EXISTS (
         SELECT 1 FROM study_sessions
         WHERE user_id=$1 AND session_date = s.d - 1)
         AND n < 365
     ) SELECT CASE WHEN EXISTS (
       SELECT 1 FROM study_sessions WHERE user_id=$1
         AND session_date IN (CURRENT_DATE, CURRENT_DATE - 1)
     ) THEN (SELECT COALESCE(MAX(n),0) FROM s WHERE EXISTS (
       SELECT 1 FROM study_sessions WHERE user_id=$1 AND session_date = s.d))
     ELSE 0 END AS streak`,
    [req.auth.sub]
  );
  res.json({ ok: true, streak: Number(streak.rows[0].streak) });
}));

// Ledger operasi sync (dedupe retry offline).
api.post('/sync/operations', authRequired, asyncHandler(async (req, res) => {
  const b = req.body && typeof req.body === 'object' ? req.body : {};
  const operationId = String(b.operationId || '').slice(0, 120);
  if (!operationId) return fail(res, 400, 'VALIDATION', 'operationId wajib diisi.');
  const r = await pool.query(
    `INSERT INTO sync_operations(user_id,operation_id,entity,entity_id,
      operation,client_ts) VALUES($1,$2,$3,$4,$5,$6)
     ON CONFLICT (user_id, operation_id) DO NOTHING RETURNING server_ts`,
    [
      req.auth.sub,
      operationId,
      String(b.entity || '').slice(0, 60),
      String(b.entityId || '').slice(0, 200),
      String(b.operation || '').slice(0, 30),
      b.clientTs ? new Date(b.clientTs) : null,
    ]
  );
  if (!r.rowCount) {
    const prev = await pool.query(
      'SELECT server_ts FROM sync_operations WHERE user_id=$1 AND operation_id=$2',
      [req.auth.sub, operationId]
    );
    return res.json({ applied: false, serverTs: prev.rows[0]?.server_ts || null });
  }
  res.status(201).json({ applied: true, serverTs: r.rows[0].server_ts });
}));

// Versioning: kontrak kanonis /api/v1, alias /api dipertahankan kompatibel.
app.use('/api', api);
app.use('/api/v1', api);

// ---------- 404 & error ----------
app.use((req, res) => fail(res, 404, 'ROUTE_NOT_FOUND', `Rute tidak ditemukan: ${req.method} ${req.path}`));

app.use((err, _req, res, _next) => {
  if (err instanceof HttpError) {
    return fail(res, err.status, err.code, err.message);
  }
  if (err.type === 'entity.parse.failed') {
    return fail(res, 400, 'BAD_JSON', 'Format JSON tidak valid.');
  }
  console.error('[error]', err);
  fail(res, 500, 'INTERNAL', 'Terjadi kesalahan pada server.');
});

// ---------- run ----------
const port = Number(process.env.PORT || 3000);
app.listen(port, '0.0.0.0', () => console.log(`Japanese Study API :${port}`));