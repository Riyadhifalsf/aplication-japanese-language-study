# API Contract (`/api/v1`, alias `/api`)

## Learning engine (server-authoritative)

- `POST /attempts` — kirim fakta attempt + `clientAttemptId*`; idempoten
  (retry = hasil sama, XP tunggal). Server hitung XP/mastery/SRS/mistake
  dalam SATU transaksi. → `{duplicate,xpAwarded,xpTotal,mastery,
  nextReviewInDays}`.
- `GET /learning/next` — keputusan: review jatuh tempo → remedial skill
  terlemah → lanjutkan. Selalu ada `reason` yang bisa ditampilkan.
- `GET /learning/mastery` — rata-rata mastery per skill + `xpTotal` ledger.
- `GET /me/entitlements` — `{plan,active,role,isPremium,xpTotal}`.
- `POST /sessions` — `{date,sessions}` idempoten per tanggal → `{streak}`.
- `POST /sync/operations` — ledger dedupe `{applied,serverTs}`.
- `POST /ai/chat` (JWT) — proxy Gemini "Sensei": `{message,history?,level?}`
  → `{reply,model}`. Tanpa key (DB maupun env) = 503 `AI_DISABLED`.
  Rate limit dinamis `AI_RATE_MAX` (DB/env, hard-cap 300/menit). Tanpa token = 401 seperti `/me`.
- `GET /admin/settings` (admin) — daftar allowlist `{key,is_secret,configured,
  source:db|env|none,preview,updated_at}`. Secret hanya mask (`••••abcd`).
- `PUT /admin/settings/:key` (admin) — `{value}`; secret dienkripsi
  AES-256-GCM (`CONFIG_KEK` wajib, kalau tidak = 503 `CONFIG_KEK_MISSING`).
  Value kosong = hapus override (fallback env). `DELETE` sama.
  Allowlist: `GEMINI_API_KEY`, `GEMINI_MODEL`, `AI_RATE_MAX`, `GEMINI_TIMEOUT_MS`.
- Batas evaluasi jujur: fase 1 memakai `isCorrect` terobservasi client
  (user hanya bisa curang ke dirinya sendiri); evaluasi jawaban penuh
  butuh bank jawaban server (roadmap).

Auth: `POST /auth/register|login|google` → `{token,user,progress}`.
Password: `POST /me/password` (JWT, wajib `currentPassword`, limiter ketat)
→ token lama mati otomatis (`password_changed_at` vs `iat` → 401
`AUTH_PASSWORD_CHANGED`); `POST /auth/forgot {email}` → selalu 200 generik
+ kode 6 digit ke Gmail; `POST /auth/reset {email,code,newPassword}` →
sekali pakai. Error berkode: `AUTH_WRONG_PASSWORD`, `AUTH_WEAK_PASSWORD`,
`AUTH_SAME_PASSWORD`, `AUTH_NO_PASSWORD` (akun Google), `RESET_INVALID`.
`GET /me`, `PUT /me/profile`, `PUT /me/progress` (blob milik sendiri),
`DELETE /me`. Admin (ADMIN_TOKEN atau JWT admin): `GET|DELETE
/admin/users`, CRUD `/admin/data/:collection`, `GET /admin/analytics`,
CRUD `/vocabulary`. Publik: `GET /content/:type?level&search&limit&offset`
(pagination, maks 20000), `GET /health` → `{ok,database,time}`.

Error selalu `{success:false,message,error:{code,message}}`.
Test: `BASE_URL=... ADMIN_TOKEN=... node --test backend/api/test-integration.js`
(14 kasus: register/duplikat/validasi/login/me/progress/google/ai-guard/
konten/hapus-akun).
