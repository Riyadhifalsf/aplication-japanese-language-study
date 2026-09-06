# Troubleshooting

- Daftar email gagal `operation-not-allowed` → enable Email/Password
  di Firebase Console (app otomatis fallback ke backend).
- `Recaptcha ... CONFIGURATION_NOT_FOUND` → enable reCAPTCHA Enterprise
  API + daftarkan SHA-1/SHA-256 aplikasi.
- Google error 10/`DEVELOPER_ERROR` → SHA-1 keystore belum terdaftar →
  download ulang `google-services.json`.
- `INSTALL_FAILED_UPDATE_INCOMPATIBLE` → `adb uninstall
  com.babeh.japanese_study` (bentrok signature debug vs release).
- API 401 terus → token kedaluwarsa (30d) → login ulang; cek `JWT_SECRET`
  sama antara deploy (ganti = semua token mati).
- Release crash `WorkDatabase` → pastikan `proguard-rules.pro` dipakai.
- Debug >10 dtk wajar (JIT); ukur release (`am start -W`, target <2 dtk).
- Server 000/timeout → cek `docker compose ps` di CT100; proxy wajib
  listen 443; health lokal `curl -k https://127.0.0.1/api/health`.
