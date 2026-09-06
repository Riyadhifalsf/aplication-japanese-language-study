# Database

16 tabel, PK di semua tabel, UNIQUE(email), UNIQUE(google_subject),
53 index (termasuk trigram `search_text`/`email`).

- Identitas: `app_users(id,email,password_hash,display_name,role,
  google_subject,is_active,profile,progress,created_at,updated_at,
  last_login_at)` + `admin_users` (dashboard) + `api_audit_logs`
  (FK SET NULL, tanpa orphan — terverifikasi 0).
- Konten: `vocabularies`, `content_kanji|vocabulary|grammar|phrases|
  sentences|culture|readings` (kolom `raw` JSONB + `search_text`).
- Komunitas/admin: `community_posts`, `admin_comments` (FK CASCADE),
  `complaint_reports`, `admin_activities`, `admin_announcements`.

Aturan: perubahan skema HANYA via `backend/db/schema.sql` (idempoten,
dieksekusi entrypoint). Sebelum ubahan besar: backup
(`pg_dump`) → migrasi → validasi →rollback = restore file backup.
Duplikat email: 0 (UNIQUE + audit berkala). Progress user = JSONB blob
per-baris (cukup untuk mirror multi-device; mastery granular tetap di
Firestore/SRS app).
