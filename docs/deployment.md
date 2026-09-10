# Deployment

Target: Proxmox CT100 (`web-server`, 192.168.100.230).
`/opt/japanese-study-v2/`: `docker-compose.yml` + `.env` (chmod 600) +
`backend/` dari repo.

```bash
# di CT100
cd /opt/japanese-study-v2
docker compose up -d --build   # db → api (migrasi+seed+admin) → proxy
curl -k https://127.0.0.1/api/health
```

Stack lama `/opt/japanese-study` (web :8081) JANGAN dimatikan.
Proxy hanya publish 443 (80 dipakai nginx host). Healthcheck tiap 10 dtk,
`restart: unless-stopped`. Backup: `backups/pg-*.sql.gz` + `env-*.bak`.
Restore: `gunzip -c backups/pg-....sql.gz | docker compose exec -T db
psql -U japanese_study japanese_study` (stop api dulu bila perlu).
