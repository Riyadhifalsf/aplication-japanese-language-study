# API Contract (`/api/v1`, alias `/api`)

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
