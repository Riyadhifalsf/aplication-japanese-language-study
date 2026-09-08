// Konfigurasi runtime di Postgres + fallback env (tanpa dep baru).
//
// - Bootstrap secret (POSTGRES_PASSWORD/DATABASE_URL, JWT_SECRET,
//   ADMIN_TOKEN) TETAP di env — tanpa itu server tidak bisa konek DB.
// - Allowlist yang boleh dioverride via tabel app_settings: saat ini KOSONG.
//   Kunci AI (GEMINI_*/AI_RATE_MAX) DIHAPUS bersama endpoint /ai/chat
//   (keputusan produk: tanpa LLM eksternal). Migrasi
//   006_remove_ai_settings.sql membersihkan baris lama di DB.
// - Nilai env selalu jadi FALLBACK bila tidak ada override non-kosong di DB.
// - Pembaca TIDAK PERNAH melempar untuk kasus operasional (tabel belum ada,
//   dekripsi gagal -> fallback env + log). Hanya penulis yang memvalidasi.
// - Cache in-memory 30 detik untuk mengurangi query DB.

const crypto = require('crypto');

// Allowlist kosong: tidak ada key yang boleh dioverride via DB saat ini.
// Endpoint admin settings tetap ada tetapi menolak semua key (VALIDATION).
const ALLOWLIST = {};

const ENV_DEFAULTS = {};

const CACHE_TTL_MS = 30 * 1000;
const _cache = new Map(); // key -> { value, fetchedAt }

function configError(status, code, message) {
  const e = new Error(message);
  e.status = status;
  e.code = code;
  return e;
}

// Kunci enkripsi 32 byte dari CONFIG_KEK (hex 64 char). Null = mode
// env-only untuk secret (simpan secret ke DB ditolak eksplisit).
function getKek() {
  const raw = (process.env.CONFIG_KEK || '').trim();
  if (/^[0-9a-fA-F]{64}$/.test(raw)) return Buffer.from(raw, 'hex');
  return null;
}

function encryptSecret(plain) {
  const kek = getKek();
  if (!kek) {
    throw configError(
      503,
      'CONFIG_KEK_MISSING',
      'CONFIG_KEK belum diatur. Isi 32 byte hex di .env untuk menyimpan secret ke database.'
    );
  }
  const iv = crypto.randomBytes(12);
  const cipher = crypto.createCipheriv('aes-256-gcm', kek, iv);
  const ct = Buffer.concat([
    cipher.update(String(plain), 'utf8'),
    cipher.final(),
  ]);
  const tag = cipher.getAuthTag();
  return `enc:v1:${iv.toString('base64')}:${ct.toString('base64')}:${tag.toString('base64')}`;
}

function decryptSecret(stored) {
  const kek = getKek();
  const s = String(stored || '');
  if (!s.startsWith('enc:v1:')) {
    // Legacy plaintext (seharusnya tidak terjadi; didukung agar migrasi
    // tidak mengunci). Tetap dibaca, akan dienkripsi ulang saat PUT.
    return s;
  }
  if (!kek) throw new Error('no-kek');
  const parts = s.split(':');
  if (parts.length !== 5) throw new Error('format');
  const iv = Buffer.from(parts[2], 'base64');
  const ct = Buffer.from(parts[3], 'base64');
  const tag = Buffer.from(parts[4], 'base64');
  const decipher = crypto.createDecipheriv('aes-256-gcm', kek, iv);
  decipher.setAuthTag(tag);
  return Buffer.concat([decipher.update(ct), decipher.final()]).toString(
    'utf8'
  );
}

function maskPreview(plain) {
  const s = String(plain || '');
  if (!s) return '';
  if (s.length <= 4) return '••••';
  return `••••${s.slice(-4)}`;
}

function envValue(key) {
  const fromEnv = (process.env[key] || '').trim();
  if (fromEnv) return fromEnv;
  return ENV_DEFAULTS[key] || '';
}

async function readOverride(pool, key) {
  // { found, value } — value mentah dari kolom DB (masih terenkripsi
  // untuk secret). Gagal DB -> { found:false } agar fallback env.
  try {
    const r = await pool.query('SELECT value FROM app_settings WHERE key=$1', [
      key,
    ]);
    if (!r.rowCount) return { found: false, value: '' };
    return { found: true, value: String(r.rows[0].value || '') };
  } catch (e) {
    if (e && (e.code === '42P01' || /app_settings/i.test(e.message || ''))) {
      console.error('[config] tabel app_settings belum ada (migrasi 004?), pakai env.');
    } else {
      console.error('[config] baca DB gagal, pakai env:', e && e.message ? e.message : e);
    }
    return { found: false, value: '' };
  }
}

// Nilai efektif: override DB non-kosong menang, sisanya env/default.
async function get(pool, key) {
  if (!ALLOWLIST[key]) throw configError(400, 'VALIDATION', `Key tidak dikenal: ${key}`);
  const cached = _cache.get(key);
  if (cached && Date.now() - cached.fetchedAt < CACHE_TTL_MS) return cached.value;
  const meta = ALLOWLIST[key];
  const { found, value } = await readOverride(pool, key);
  let effective = '';
  if (found && value) {
    if (meta.secret) {
      try {
        effective = decryptSecret(value);
      } catch (e) {
        console.error('[config] dekripsi gagal, pakai env fallback.');
        effective = envValue(key);
      }
    } else {
      effective = value;
    }
  } else {
    effective = envValue(key);
  }
  _cache.set(key, { value: effective, fetchedAt: Date.now() });
  return effective;
}

// Daftar untuk admin: secret TIDAK PERNAH plaintext (preview mask saja).
async function listSettings(pool) {
  const out = [];
  for (const key of Object.keys(ALLOWLIST)) {
    const meta = ALLOWLIST[key];
    let dbValue = '';
    let dbFound = false;
    let updatedAt = null;
    try {
      const r = await pool.query(
        'SELECT value, updated_at FROM app_settings WHERE key=$1',
        [key]
      );
      if (r.rowCount) {
        dbFound = true;
        dbValue = String(r.rows[0].value || '');
        updatedAt = r.rows[0].updated_at || null;
      }
    } catch (_) {
      // Tabel belum ada -> semua dari env.
    }
    const env = envValue(key);
    let source = 'none';
    let preview = '';
    if (dbFound && dbValue) {
      source = 'db';
      if (meta.secret) {
        try {
          preview = maskPreview(decryptSecret(dbValue));
        } catch (_) {
          preview = '•••• (tak terbaca)';
        }
      } else {
        preview = dbValue;
      }
    } else if (env) {
      source = 'env';
      preview = meta.secret ? maskPreview(env) : env;
    }
    out.push({
      key,
      is_secret: meta.secret,
      configured: source !== 'none',
      source,
      preview,
      updated_at: updatedAt,
    });
  }
  return out;
}

// Simpan override. value kosong/whitespace = hapus override (fallback env).
async function setSetting(pool, key, value, updatedBy) {
  if (!ALLOWLIST[key]) throw configError(400, 'VALIDATION', `Key tidak dikenal: ${key}`);
  const meta = ALLOWLIST[key];
  const raw = value == null ? '' : String(value);
  if (!raw.trim()) {
    await pool.query(
      `INSERT INTO app_settings(key, value, is_secret, updated_at, updated_by)
       VALUES($1,'',$2,now(),$3)
       ON CONFLICT (key) DO UPDATE SET value='', updated_at=now(), updated_by=$3`,
      [key, meta.secret, String(updatedBy || '').slice(0, 200)]
    );
    _cache.delete(key);
    return { key, configured: !!envValue(key), source: envValue(key) ? 'env' : 'none' };
  }
  let stored = raw.trim();
  if (meta.secret) {
    if (stored.length > 500) {
      throw configError(400, 'VALIDATION', 'Secret terlalu panjang.');
    }
    stored = encryptSecret(stored);
  } else {
    stored = ALLOWLIST[key].validate(stored);
  }
  await pool.query(
    `INSERT INTO app_settings(key, value, is_secret, updated_at, updated_by)
     VALUES($1,$2,$3,now(),$4)
     ON CONFLICT (key) DO UPDATE SET value=$2, is_secret=$3, updated_at=now(), updated_by=$4`,
    [key, stored, meta.secret, String(updatedBy || '').slice(0, 200)]
  );
  _cache.delete(key);
  return { key, configured: true, source: 'db' };
}

function invalidate(key) {
  if (key) _cache.delete(key);
  else _cache.clear();
}

module.exports = {
  ALLOWLIST,
  get,
  listSettings,
  setSetting,
  invalidate,
  maskPreview,
};
