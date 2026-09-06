# Japanese Study — Belajar Bahasa Jepang N5–N1

[![Lisensi MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Flutter CI](https://github.com/Riyadhifalsf/aplication-japanese-language-study/actions/workflows/ci.yml/badge.svg)](https://github.com/Riyadhifalsf/aplication-japanese-language-study/actions/workflows/ci.yml)
[![Versi](https://img.shields.io/badge/version-3.3.0-red.svg)](CHANGELOG.md)
[![Platform](https://img.shields.io/badge/platform-Android-green.svg)](release/)

Aplikasi belajar bahasa Jepang dan kanji JLPT N5–N1 (plus JFT) untuk Android.
Offline-first, bisa dipakai tanpa internet; progres tersinkron ke cloud
saat online via Firebase + backend mandiri.

> Sapaan khas kami: *Irasshaimase, Okyaku-sama!* Tamu boleh intip semua
> latihan dalam mode pratinjau sebelum daftar.

## Unduh

- **Android (disarankan):** `release/japanese-study-v3.3.0-arm64.apk` di repo ini.
- **Play Store:** menyusul (track internal testing). Lihat checklist rilis di bawah.
- **Web demo:** `flutter run -d chrome` dari source.

## Fitur Unggulan

- **Jalur belajar JLPT N5–N1 + JFT** terstruktur dengan placement quiz.
- **Kanji adaptif** (5.000+ kanji): library, stroke order, review SRS, kartu jatuh tempo.
- **Kuis lengkap**: kotoba, kanji→arti, kanji→hiragana, kanji mirip, tema, custom, mistake review.
- **Tata bahasa, kosakata, frasa, kalimat, dialog, bacaan panjang, budaya.**
- **Mode tamu (pratinjau)**: lihat & coba semua latihan, 5 soal per sesi. Daftar untuk sesi penuh + simpan progress.
- **Login fleksibel**: email/password (Firebase), Google; Facebook segera hadir.
- **Sync cloud**: Firestore merge per-field (counter max, set union) — ganti HP tanpa hilang XP. Tombol *Mulai dari nol* menghapus lokal + server.
- **Notifikasi**: pengingat ulangan kanji + inbox update aplikasi/pengumuman (retensi otomatis 90 hari).
- **Premium**: paket Bulanan/Tahunan/Lifetime, harga naik per fase. Metode: QRIS, bank, e-wallet, kartu, crypto, Google Play (integrasi PSP bertahap).
- **AI Coach** (penilaian lokal) + mesin rekomendasi `ai_engine/`; AI Sensei (LLM) dalam roadmap.
- **Admin dashboard**: analitik, konten, pengumuman, user.

## Teknologi

| Bagian | Teknologi |
|---|---|
| Aplikasi | Flutter 3 (Android + Web), Material 3 tema merah |
| Auth & sync | Firebase Auth (email/Google) + Cloud Firestore |
| Backend | Node.js 20 + PostgreSQL 17 + nginx TLS (self-signed LAN) |
| Infra | Docker Compose di Proxmox LXC (`/opt/japanese-study-v2`) |
| Iklan | AdMob (banner, native, interstitial, rewarded) |
| Backup | Google Drive (opsional) + ekspor JSON manual |

## Mulai Cepat (Developer)

```bash
flutter pub get
flutter analyze
flutter test

# Debug di HP (lambat, untuk ngoding saja)
flutter run

# Uji rasa yang benar (cepat, rasa produksi)
flutter run --release
# atau pasang APK dari folder release/
```

### Backend lokal / server

```bash
cd backend
cp .env.example .env   # isi: POSTGRES_PASSWORD, JWT_SECRET, ADMIN_*
docker compose up -d --build
curl -k https://192.168.100.230/api/health
```

Server produksi: `https://192.168.100.230/api` (Proxmox CT100).
Detail kredensial & checklist ada di `checklist-konfigurasi.txt` (**lokal saja, tidak di-push**).

### Firebase (butuh akses Console)

1. Aktifkan Email/Password (+ Google + SHA-1) di Authentication.
2. Buat Firestore (asia-southeast1), publish `firestore.rules`.
3. Taruh `google-services.json` di `android/app/` (**jangan commit**).

## Struktur Proyek

```
lib/            # Flutter: screens, state, services, widgets
assets/         # data JSON bundel (7MB), branding
backend/        # Node API + Postgres schema + nginx proxy
ai_engine/      # FastAPI rekomendasi belajar (opsional)
payment_api/    # stub integrasi PSP (Xendit/Midtrans/BTCPay)
tool/           # deploy.py (Proxmox/Docker)
release/        # APK rilis siap pasang
test/           # unit + widget test
```

## Roadmap

- [ ] Login Facebook + Google (butuh SHA-1 & App ID) — lihat `checklist-konfigurasi.txt`
- [ ] AI Sensei (chat sadar progress, paywall Premium)
- [ ] Pembayaran penuh (QRIS/bank/e-wallet/crypto + Play Billing)
- [ ] Rilis Play Store (internal testing → produksi)
- [ ] Streak pindah ke Beranda, hapus Komunitas, rapikan Belajar

## Keamanan

Jangan commit `.env`, `*.jks`, `key.properties`, `google-services.json`,
atau token apa pun. Baca [SECURITY.md](SECURITY.md) sebelum kontribusi.

## Kontribusi

Terbuka untuk saran, bug, dan kode. Lihat [CONTRIBUTING.md](CONTRIBUTING.md)
dan template issue/PR di `.github/`.

## Lisensi

[MIT](LICENSE). Logo & aset branding milik proyek ini.
