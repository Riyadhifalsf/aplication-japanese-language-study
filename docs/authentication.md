# Authentication

Satu source of truth: **Firebase Authentication**. Backend memverifikasi
Firebase/Google ID token (RS256 lokal + `aud` bila `FIREBASE_PROJECT_ID`
diisi, fallback tokeninfo), lalu menerbitkan JWT sendiri (30 hari).

```
Flutter → Firebase sign-in → ID token → POST /api/auth/google
→ verifikasi → upsert user (google_subject) → JWT {sub, role, email}
```

Email/password ada dua jalur: Firebase dulu, fallback backend
(`/api/auth/register|login`, bcrypt-12), terakhir akun lokal offline.
Kegagalan config/jaringan Firebase TIDAK divonis gagal — lanjut ke backend.

## Status di Flutter

`AuthStatus`: unknown → guest → authenticating → authenticated.
`expired` bila server menolak token (401/USER_NOT_FOUND);
`error` + `authError` untuk pesan tampil. `isAuthenticated` tetap ada
untuk kompatibilitas.

Startup: prefs → Firebase restore (`restoreFirebaseSession`, susulan
pasca-frame karena Firebase init deferred) → `syncNow()`.

## Kode error (backend `{success:false,error:{code}}`)

`AUTH_EMAIL_TAKEN(409)` `AUTH_BAD_CREDENTIALS(401)`
`AUTH_DISABLED(403)` `AUTH_MISSING_TOKEN(401)` `AUTH_BAD_TOKEN(401)`
`AUTH_FORBIDDEN(403)` `AUTH_GOOGLE_NO_TOKEN(400)`
`AUTH_GOOGLE_INVALID(401)` `USER_NOT_FOUND(404)` `VALIDATION(400)`
`BAD_JSON(400)` `RATE_LIMITED(429)` `ROUTE_NOT_FOUND(404)`
`INTERNAL(500)`. Field `message` level atas tetap ada (kompatibel).

## Aturan

- Jangan percaya `user_id`/`role`/`isPremium` dari client.
- Password: bcrypt-12, min 8, maks 128. Pesan login tidak membocorkan
  user ada/tidak (401 sama untuk keduanya).
- Register race: `UNIQUE(email)` + catch 23505 → 409 (cek-dulu hanya UX).
- Google link race: catch 23505 → baca ulang pemenang.
- Tanpa `JWT_SECRET` server exit(1) (fail-closed).
- Logout: `firebaseAuth.signOut()` + hapus token secure storage + status guest.
