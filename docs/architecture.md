# Architecture

```
Flutter (offline-first, SharedPreferences lokal)
  │  Firebase Auth (identitas) + Firestore (sync progress merge per-field)
  ▼
HTTPS :443 (nginx proxy, TLS self-signed LAN, TLSv1.2/1.3)
  ▼
Node 20 API (Express 5, helmet, rate-limit, JWT)
  ▼
PostgreSQL 17 (private, tanpa port publik)
```

Kontrak kanonis `/api/v1/*`; prefix `/api/*` dipertahankan kompatibel
(router Express yang sama di-mount dua kali — mount array dihindari
karena tidak cocok di Express 5, pakai dua `app.use` eksplisit).

Lapisan backend: routes (validasi + auth context) → query SQL
berparameter di handler → pool `pg` (maks 15). Tanpa ORM; skema via
`backend/db/schema.sql` idempoten (entrypoint jalan otomatis).

Sync Flutter: lokal dulu → push debounce → pull → merge → push balik.
Firestore aturan ownership `request.auth.uid == userId` untuk
`users/{uid}/progress/*` dan `users/{uid}`.

AI Sensei (nanti): Flutter → backend `/api/ai/*` → provider.
Kunci AI TIDAK PERNAH di APK. Play Store wajib Play Billing untuk digital.
