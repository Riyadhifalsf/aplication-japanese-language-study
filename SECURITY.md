# Kebijakan Keamanan

## Lapor Celah

Temukan bug keamanan? **Jangan** buat issue publik. Hubungi maintainer
langsung (lihat profil repo) dengan subjek `[SECURITY]` + langkah reproduksi.
Kami targetkan respons awal 1×7 hari.

## Yang Tidak Boleh Masuk Repo

File berikut **di-ignore dan tidak pernah di-commit**:

- `.env` dalam bentuk apa pun (`backend/.env`, `payment_api/.env`)
- `android/app/google-services.json` (berisi API key)
- `*.jks`, `*.keystore`, `android/key.properties`
- Token, password, private key, service account

Contoh yang AMAN di-commit: `backend/.env.example` (placeholder saja).

## Praktik di Kode

- Token akses API disimpan di **flutter_secure_storage**, bukan SharedPreferences.
- JWT backend kedaluwarsa 30 hari; endpoint admin & sensitif ber-rate-limit + helmet.
- `usesCleartextTraffic=false`; backend hanya HTTPS (TLS 1.2/1.3).
- Release build: R8 minify + shrink + **obfuscate**. `proguard-rules.pro`
  wajib menjaga WorkManager/Room (tanpanya aplikasi crash saat start).
- Entitlement Premium harus validasi server-side (jangan percaya klaim aplikasi).

## Insiden yang Diketahui

- `google-services.json` sempat ter-commit di riwayat lama. File sudah
  di-untrack + ignore; **API key-nya wajib dibatasi/dirotasi** di Google
  Cloud Console (batasi ke package + SHA-1).

## Rotasi Rutin

Ganti berkala: password SSH server, `ADMIN_PASSWORD`, `JWT_SECRET`,
`POSTGRES_PASSWORD`, dan kunci PSP. Kredensial sementara dicatat di
`checklist-konfigurasi.txt` (lokal, tidak di-push) — bukan tempat permanen.
