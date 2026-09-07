// Integration test backend Japanese Study — tanpa dep baru.
// Jalankan: BASE_URL=https://192.168.100.230 ADMIN_TOKEN=xxx node --test test-integration.js
// (node >= 18; self-signed LAN: NODE_TLS_REJECT_UNAUTHORIZED=0)
'use strict';
const { test, before } = require('node:test');
const assert = require('node:assert/strict');

const BASE = (process.env.BASE_URL || 'https://192.168.100.230').replace(/\/+$/, '');
const ADMIN_TOKEN = process.env.ADMIN_TOKEN || '';
process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';

const stamp = Date.now().toString(36);
const EMAIL = `itest-${stamp}@example.com`;
const PASS = 'password123';
let token = '';

async function api(method, path, { body, token: t } = {}) {
  const r = await fetch(`${BASE}${path}`, {
    method,
    headers: {
      'Content-Type': 'application/json',
      ...(t ? { Authorization: `Bearer ${t}` } : {}),
    },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const data = await r.json().catch(() => ({}));
  return { status: r.status, data };
}

test('health ok + database', async () => {
  const { status, data } = await api('GET', '/api/health');
  assert.equal(status, 200);
  assert.equal(data.ok, true);
  assert.equal(data.database, true);
});

test('v1 alias konsisten', async () => {
  const { status, data } = await api('GET', '/api/v1/health');
  assert.equal(status, 200);
  assert.equal(data.ok, true);
});

test('register valid -> 201 + token + user (tanpa password)', async () => {
  const { status, data } = await api('POST', '/api/auth/register', {
    body: { name: 'ITest', email: EMAIL, password: PASS },
  });
  assert.equal(status, 201);
  assert.ok(data.token);
  assert.equal(data.user.email, EMAIL);
  assert.equal(data.user.role, 'user');
  assert.ok(!('password_hash' in data.user));
  token = data.token;
});

test('register duplikat -> 409 AUTH_EMAIL_TAKEN', async () => {
  const { status, data } = await api('POST', '/api/auth/register', {
    body: { name: 'ITest', email: EMAIL, password: PASS },
  });
  assert.equal(status, 409);
  assert.equal(data.error.code, 'AUTH_EMAIL_TAKEN');
  assert.ok(data.message);
});

test('register invalid -> 400 berkode', async () => {
  const bad1 = await api('POST', '/api/auth/register', {
    body: { name: 'X', email: 'bukan-email', password: '123' },
  });
  assert.equal(bad1.status, 400);
  assert.ok(bad1.data.error.code);
});

test('login valid -> 200 + JWT', async () => {
  const { status, data } = await api('POST', '/api/auth/login', {
    body: { email: EMAIL, password: PASS },
  });
  assert.equal(status, 200);
  assert.ok(data.token);
  token = data.token;
});

test('login salah -> 401 AUTH_BAD_CREDENTIALS (tanpa bocor info)', async () => {
  const a = await api('POST', '/api/auth/login', {
    body: { email: EMAIL, password: 'salah1234' },
  });
  assert.equal(a.status, 401);
  assert.equal(a.data.error.code, 'AUTH_BAD_CREDENTIALS');
  const b = await api('POST', '/api/auth/login', {
    body: { email: 'tak-ada@example.com', password: 'salah1234' },
  });
  assert.equal(b.status, 401);
  assert.equal(b.data.error.code, 'AUTH_BAD_CREDENTIALS');
});

test('me tanpa token -> 401; dengan token -> profil', async () => {
  const anon = await api('GET', '/api/me');
  assert.equal(anon.status, 401);
  assert.equal(anon.data.error.code, 'AUTH_MISSING_TOKEN');
  const me = await api('GET', '/api/me', { token });
  assert.equal(me.status, 200);
  assert.equal(me.data.user.email, EMAIL);
});

test('progress PUT lalu GET konsisten', async () => {
  const put = await api('PUT', '/api/me/progress', {
    token,
    body: { xp: 123, learnedKanji: [1, 2, 3] },
  });
  assert.equal(put.status, 200);
  assert.equal(put.data.ok, true);
  const me = await api('GET', '/api/me', { token });
  assert.equal(me.data.progress.xp, 123);
});

test('google tanpa idToken -> 400', async () => {
  const { status, data } = await api('POST', '/api/auth/google', { body: {} });
  assert.equal(status, 400);
  assert.equal(data.error.code, 'AUTH_GOOGLE_NO_TOKEN');
});

test('admin guard: tanpa token 401, user biasa 403', async () => {
  const anon = await api('GET', '/api/admin/users');
  assert.equal(anon.status, 401);
  const user = await api('GET', '/api/admin/users', { token });
  assert.equal(user.status, 403);
  assert.equal(user.data.error.code, 'AUTH_FORBIDDEN');
  if (ADMIN_TOKEN) {
    const adm = await api('GET', '/api/admin/users', { token: ADMIN_TOKEN });
    assert.equal(adm.status, 200);
    assert.ok(Array.isArray(adm.data.users));
  }
});

test('konten publik + tipe tak dikenal 404 berkode', async () => {
  const { status, data } = await api('GET', '/api/content/kanji?limit=2');
  assert.equal(status, 200);
  assert.ok(Array.isArray(data.data));
  const bad = await api('GET', '/api/content/ngawur');
  assert.equal(bad.status, 404);
  assert.equal(bad.data.error.code, 'CONTENT_UNKNOWN');
});

const ATTEMPT_ID = `att-${stamp}`;
let firstXp = 0;

test('attempt benar -> XP + mastery + hasil tersimpan', async () => {
  const { status, data } = await api('POST', '/api/attempts', {
    token,
    body: {
      exerciseId: 'ex-1', questionId: 'q-1', clientAttemptId: ATTEMPT_ID,
      answer: 'に', isCorrect: true, score: 100, durationMs: 4200,
      itemId: 'pelajaran-partikel-ni', skill: 'grammar', kind: 'exercise',
      level: 'N5', title: 'Partikel ni',
    },
  });
  assert.equal(status, 201);
  assert.equal(data.duplicate, false);
  assert.equal(data.xpAwarded, 20);
  assert.ok(data.xpTotal >= 20);
  assert.ok(data.mastery >= 0 && data.mastery <= 100);
  firstXp = data.xpTotal;
});

test('attempt SAMA dikirim ulang -> duplicate, XP tidak ganda', async () => {
  const { status, data } = await api('POST', '/api/attempts', {
    token,
    body: {
      exerciseId: 'ex-1', questionId: 'q-1', clientAttemptId: ATTEMPT_ID,
      answer: 'に', isCorrect: true, score: 100, durationMs: 4200,
      itemId: 'pelajaran-partikel-ni', skill: 'grammar',
    },
  });
  assert.equal(status, 200);
  assert.equal(data.duplicate, true);
  assert.equal(data.xpTotal, firstXp);
});

test('attempt salah -> mistake tercatat, XP 0', async () => {
  const { status, data } = await api('POST', '/api/attempts', {
    token,
    body: {
      exerciseId: 'ex-2', questionId: 'q-2', clientAttemptId: `att2-${stamp}`,
      answer: 'を', isCorrect: false, score: 0, durationMs: 3000,
      itemId: 'pelajaran-partikel-ni', skill: 'grammar',
    },
  });
  assert.equal(status, 201);
  assert.equal(data.xpAwarded, 0);
  assert.equal(data.xpTotal, firstXp);
});

test('learning/next memberi aksi jelas', async () => {
  const { status, data } = await api('GET', '/api/learning/next', { token });
  assert.equal(status, 200);
  assert.ok(['review', 'remedial', 'continue'].includes(data.action));
  assert.ok(typeof data.reason === 'string' && data.reason.length > 0);
});

test('learning/mastery + entitlements konsisten', async () => {
  const m = await api('GET', '/api/learning/mastery', { token });
  assert.equal(m.status, 200);
  assert.ok(Array.isArray(m.data.skills));
  assert.equal(m.data.xpTotal, firstXp);
  const e = await api('GET', '/api/me/entitlements', { token });
  assert.equal(e.status, 200);
  assert.equal(e.data.plan, 'free');
  assert.equal(e.data.isPremium, false);
  assert.equal(e.data.xpTotal, firstXp);
});

test('sessions idempoten + sync dedupe', async () => {
  const today = new Date().toISOString().slice(0, 10);
  const s1 = await api('POST', '/api/sessions', {
    token, body: { date: today, seconds: 600 },
  });
  assert.equal(s1.status, 200);
  assert.ok(s1.data.streak >= 1);
  const s2 = await api('POST', '/api/sessions', {
    token, body: { date: today, seconds: 100 },
  });
  assert.equal(s2.status, 200);
  assert.equal(s2.data.streak, s1.data.streak);
  const o1 = await api('POST', '/api/sync/operations', {
    token, body: { operationId: `op-${stamp}`, entity: 'progress', operation: 'upsert' },
  });
  assert.equal(o1.status, 201);
  assert.equal(o1.data.applied, true);
  const o2 = await api('POST', '/api/sync/operations', {
    token, body: { operationId: `op-${stamp}`, entity: 'progress', operation: 'upsert' },
  });
  assert.equal(o2.status, 200);
  assert.equal(o2.data.applied, false);
});

test('attempt tanpa auth -> 401; tanpa clientAttemptId -> 400', async () => {
  const anon = await api('POST', '/api/attempts', { body: {} });
  assert.equal(anon.status, 401);
  const bad = await api('POST', '/api/attempts', {
    token, body: { answer: 'x', isCorrect: true },
  });
  assert.equal(bad.status, 400);
});

test('hapus akun sendiri (bersih-bersih) -> ok; token jadi yatim 404', async () => {
  const del = await api('DELETE', '/api/me', { token });
  assert.equal(del.status, 200);
  const me = await api('GET', '/api/me', { token });
  assert.equal(me.status, 404);
  assert.equal(me.data.error.code, 'USER_NOT_FOUND');
});
