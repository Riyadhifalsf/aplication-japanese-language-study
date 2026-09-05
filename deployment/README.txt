DEPLOYMENT DI PROXMOX

Jangan jalankan aplikasi di host Proxmox (pve). Buat VM/LXC Debian 12/13 atau
Ubuntu 24.04 khusus aplikasi, lalu pasang Docker Engine dan Docker Compose di
VM tersebut.

1. Salin source proyek ini ke VM, misalnya /opt/japanese-study.
2. Di folder proyek: cp deployment.env.example .env
3. Edit .env, isi POSTGRES_PASSWORD dan ADMIN_TOKEN dengan nilai acak panjang.
   Jangan commit file .env.
4. Jalankan: docker compose up -d --build
5. Buka http://IP-VM:8081
6. Cek: docker compose ps dan docker compose logs -f --tail=100

Web Flutter dibangun dengan API_BASE_URL=/api. Nginx meneruskan /api ke
container API, sehingga tidak perlu alamat IP API ditulis di aplikasi.

BACKUP DATABASE
docker compose exec -T db pg_dump -U japanese_study japanese_study > backup.sql

RESTORE DATABASE
docker compose exec -T db psql -U japanese_study japanese_study < backup.sql

CATATAN KEAMANAN
- Gunakan reverse proxy HTTPS (mis. Caddy atau Nginx) untuk domain publik.
- Jangan membuka PostgreSQL ke internet.
- ADMIN_TOKEN wajib dirahasiakan; aplikasi admin mengirimkannya saat build.
- Endpoint AI code fixer sebaiknya tidak dipakai pada container produksi karena
  fitur tersebut memang didesain untuk mengubah source code checkout lokal.
