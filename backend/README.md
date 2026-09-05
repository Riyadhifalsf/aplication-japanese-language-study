Japanese Study Backend
=====================
Produksi satu-node: API + DB + reverse proxy (nginx TLS) pada satu
Docker Compose di LXC/VM.

Isi file .env (lihat .env.example) lalu:
  docker compose up -d --build

Health check:
  curl -k https://192.168.100.11/api/health

Backup database:
  docker compose exec -T db pg_dump -U japanese_study japanese_study > backup.sql

Restore:
  docker compose exec -T db psql -U japanese_study japanese_study < backup.sql

Admin account:
  Set ADMIN_EMAIL & ADMIN_PASSWORD di .env, lalu rebuild:
  docker compose up -d --build api
  Akun admin akan dibuat otomatis (bcrypt, role admin).
  Gunakan email & password tersebut untuk login di Flutter.

Catatan keamanan
- Sertifikat self-signed hanya untuk IP/LAN.
- Jangan buka PostgreSQL ke internet.
- ADMIN_TOKEN digunakan untuk endpoint admin tooling (bukan login user).
