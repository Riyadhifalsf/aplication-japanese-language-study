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
- Batas evaluasi jujur: fase 1 memakai `isCorrect` terobservasi client
  (user hanya bisa curang ke dirinya sendiri); evaluasi jawaban penuh
  butuh bank jawaban server (roadmap).

Auth: `POST /auth/register|login|google` → `{token,user,progress}`.
`GET /me`, `PUT /me/profile`, `PUT /me/progress` (blob milik sendiri),
`DELETE /me`. Admin (ADMIN_TOKEN atau JWT admin): `GET|DELETE
/admin/users`, CRUD `/admin/data/:collection`, `GET /admin/analytics`,
CRUD `/vocabulary`. Publik: `GET /content/:type?level&search&limit&offset`
(pagination, maks 20000), `GET /health` → `{ok,database,time}`.

Error selalu `{success:false,message,error:{code,message}}`.
Test: `BASE_URL=... ADMIN_TOKEN=... node --test backend/api/test-integration.js`
(13 kasus: register/duplikat/validasi/login/me/progress/google/guard/
konten/hapus-akun).
