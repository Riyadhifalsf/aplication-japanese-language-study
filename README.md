# Japanese Study — Belajar Bahasa Jepang N5–N1 (+ JFT)

[![Lisensi MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Flutter CI](https://github.com/Riyadhifalsf/aplication-japanese-language-study/actions/workflows/ci.yml/badge.svg)](https://github.com/Riyadhifalsf/aplication-japanese-language-study/actions/workflows/ci.yml)
[![Versi](https://img.shields.io/badge/version-1.1.0-red.svg)](CHANGELOG.md)
[![Platform](https://img.shields.io/badge/platform-Android-green.svg)](../../releases)

Aplikasi Android untuk belajar bahasa Jepang dari nol sampai JLPT N1
(plus jalur kerja JFT/SSW). Dibuat offline-first: semua materi bawaan bisa
dibuka tanpa internet, progres tersimpan di HP, lalu disinkronkan ke cloud
saat online. Ganti HP tidak menghilangkan XP.

> Sapaan khas aplikasi ini: *Irasshaimase, Okyaku-sama!* Pengunjung yang
> belum daftar disapa "Okyaku-sama" dan boleh mencoba semua latihan dalam
> mode pratinjau (5 soal per sesi) sebelum memutuskan bikin akun.

## Daftar isi

- [Unduh & pasang](#unduh--pasang)
- [Fitur](#fitur)
  - [Jalur belajar (kurikulum)](#jalur-belajar-kurikulum)
  - [Kanji](#kanji)
  - [Kuis, review & exam](#kuis-review--exam)
  - [Materi lain](#materi-lain)
  - [Akun, sync & streak](#akun-sync--streak)
  - [Premium & iklan](#premium--iklan)
  - [AI](#ai)
  - [Admin](#admin)
- [Cara memakai (alur pengguna baru)](#cara-memakai-alur-pengguna-baru)
- [Arsitektur](#arsitektur)
- [Untuk developer](#untuk-developer)
- [Pengujian](#pengujian)
- [Rilis](#rilis)
- [Batasan & roadmap](#batasan--roadmap)
- [Troubleshooting](#troubleshooting)
- [Keamanan](#keamanan)
- [Kontribusi](#kontribusi)
- [Lisensi](#lisensi)

## Unduh & pasang

- **Halaman [Releases](../../releases)** — unduh
  `japanese-study-vX.Y.Z-arm64.apk` (±27 MB), pasang langsung di HP
  (Android 8+). APK ditandatangani kunci rilis resmi.
- **Play Store** — menyusul, disiapkan lewat track internal testing
  (berkas AAB ikut dibangun tiap rilis, lihat [Rilis](#rilis)).

Spesifikasi singkat: cold start 0,6–1,9 detik di build release
(build debug memang >10 detik karena JIT — itu normal, bukan bug).

## Fitur

### Jalur belajar (kurikulum)

Layar Belajar memakai path melengkung ala aplikasi kursus modern: node
lingkaran zig-zag kiri-kanan yang dihubungkan garis putus-putus. Satu node
= satu unit (mis. “Perkenalan”, “Bentuk て”, “Pasif”). Node aktif berwarna
dengan badge bintang, selesai jadi hijau, terkunci abu-abu, dan tiap node
menampilkan progresnya (mis. 0/4 lesson).

- Dua trek: **Japanese Path** (Beginner → N5 → N4 → N3 → N2 → N1) dan
  **Work Path** (JFT-A1 → JFT-A2 → SSW, memakai ulang materi Japanese Path
  agar tidak duplikasi).
- Lesson berikutnya terbuka setelah lesson sebelumnya selesai; Unit Test &
  Final Test butuh skor ≥70%.
- **Placement test** untuk yang tidak mau mulai dari nol: skor ≥80% bisa
  membuka level langsung.
- Rekomendasi adaptif + strip Daily Review untuk materi yang sering salah.

### Kanji

- Library ribuan kanji per level, lengkap dengan arti dan bacaan.
- Urutan goresan (stroke order) + latihan menulis.
- Flashcard, kuis kanji→arti, kanji→hiragana, kanji mirip, kuis per tema.
- Review terjadwal (SRS): kartu yang hampir lupa dimunculkan duluan, badge
  di ikon notifikasi menunjukkan jumlah kartu jatuh tempo.

### Kuis, review & exam

- Kuis kosakata, kuis custom (pilih level/jumlah soal sendiri), dan
  **mistake review** — soal yang pernah salah dikumpulkan jadi satu sesi.
- Simulasi ujian (exam hub + sesi timed) dan latihan per bab.
- Semua skor ikut menghitung XP, mastery per skill, dan streak.

### Materi lain

Tata bahasa (pola per bab N5–N4 dst.), kosakata tematik, frasa, contoh
kalimat, dialog kaiwa, bacaan panjang (reader), budaya, counter/kounter
bilangan, speaking practice, shadowing, dan mini-game — dijelajahi lewat
4 tab bawah (Beranda, Belajar, Quiz, Kanji) plus halaman-halaman khusus
(exam, streak, profil, admin).

### Akun, sync & streak

- Daftar/masuk via **email + password** atau **Google** (Firebase Auth).
  Facebook masih tahap tombol (segera hadir).
- Sync cloud dua arah: Firestore menyimpan `users/{uid}/progress/main`,
  digabung per-field dengan data lokal (counter ambil nilai terbesar, set
  di-union, skor ambil yang terbaik) — belajar offline di dua HP lalu
  online tidak saling menimpa.
- Tombol *Mulai dari nol* menghapus progres lokal + server sekaligus.
- Streak harian (kalender kanji 月火水木金土日 di Beranda), rekor, XP/level,
  6 misi tersembunyi, inbox pengumuman + changelog (retensi 90 hari),
  pengingat review, dan backup opsional ke Google Drive / ekspor JSON.

### Premium & iklan

- Paket **Bulanan / Tahunan / Lifetime**, harga naik tiap fase penjualan.
  Status premium dicek ke server (bukan klaim lokal) sehingga tidak bisa
  dipalsukan dari aplikasi.
- Metode bayar disiapkan untuk QRIS, transfer bank, e-wallet, kartu,
  crypto, dan Google Play Billing (bertahap — lihat
  [Batasan & roadmap](#batasan--roadmap)).
- Iklan AdMob (banner, native, interstitial tiap 4 pindah tab, rewarded
  untuk bonus XP). Catatan jujur: di akun AdMob baru status “No fill”
  itu masalah sisi akun/penayangan, bukan bug kode.

### AI

Tiga lapis, dari yang tanpa server sampai LLM:

1. **AI Coach lokal** — penilaian deterministik dari akurasi, progres
   harian, dan kosakata dikuasai. Tanpa internet, tanpa biaya.
2. **AI Sensei (Gemini)** — `POST /api/ai/chat` di backend meneruskan
   pertanyaan ke Gemini dengan persona tutor (“Sensei”) berbahasa
   Indonesia. API key hanya di server, aplikasi cukup membawa JWT;
   tanpa key, endpoint menjawab 503 yang jelas, bukan error misterius.
   Layar chat-nya sendiri belum dibuat (baru API + client-nya).
3. **`ai_engine/` (opsional)** — microservice FastAPI untuk skor risiko
   lupa & rekomendasi aksi dari sinyal belajar. Tidak wajib jalan agar
   aplikasi berfungsi.

### Admin

Dashboard admin di aplikasi (khusus role admin): ringkasan pengguna,
konten, analitik pendaftaran/login, pengumuman, dan manajemen user.
Backend juga menyediakan endpoint admin ber-token terpisah.

## Cara memakai (alur pengguna baru)

1. Pasang APK, buka aplikasi — kamu disapa sebagai Okyaku-sama.
2. Coba-coba dulu dalam mode pratinjau, atau langsung daftar (email /
   Google) untuk progres penuh + sync.
3. Ikut placement test kalau sudah bisa bahasa Jepang, atau mulai dari
   Beginner dan ikuti node path satu per satu.
4. Kerjakan misi hari ini, pertahankan streak, review kartu jatuh tempo.

## Arsitektur

```
                 ┌──────────────┐
                 │  Flutter app │  offline-first (SharedPreferences),
                 │  (Android)   │  state via AppController
                 └──────┬───────┘
                        │ HTTPS (JWT)               ┌──────────────┐
                        ├──────────────────────────►│ Firebase Auth│
                        │ Firestore merge           │ + Firestore  │
                        │                           └──────────────┘
                        ▼
                 ┌──────────────┐    ┌────────────┐
                 │  nginx proxy │───►│ Node.js API│───► PostgreSQL 17
                 │  TLS (443)   │    │ (33 route) │
                 └──────────────┘    └────────────┘
                        ▲                  │ Gemini (AI Sensei,
                        │                  │ opsional, key di server)
                   Docker Compose
                   (Proxmox LXC)
```

| Bagian | Teknologi |
|---|---|
| Aplikasi | Flutter 3.47 stable, Material 3 (tema merah), Android arm64 |
| Auth & sync | Firebase Auth (email/Google) + Cloud Firestore |
| Backend | Node.js 20 (Express) + PostgreSQL 17 + nginx TLS |
| Infra | Docker Compose di Proxmox LXC |
| Iklan | google_mobile_ads (banner, native, interstitial, rewarded) |
| AI | Gemini via backend, FastAPI `ai_engine/` (opsional) |
| Data bawaan | 7 berkas JSON ±7,2 MB di `assets/data` |
| Backup | Google Drive (opsional) + ekspor JSON manual |

Struktur repo (ringkas):

```
lib/
  screens/     # 23 grup layar (home, study, curriculum, kanji, quiz, ...)
  state/       # AppController (satu sumber state + persistence)
  services/    # auth, sync, api, ads, notifikasi, AI, ...
  features/    # curriculum engine + katalog (murni Dart, testable)
  widgets/     # kartu, slot iklan, banner, ...
  config/      # server_config, ads_config, ...
assets/        # data JSON + branding
backend/       # API Node, schema/migrasi Postgres, nginx, compose
ai_engine/     # FastAPI rekomendasi (opsional)
payment_api/   # rencana stub PSP (belum implementasi)
tool/          # deploy.py (Proxmox/Docker generik)
docs/          # kontrak API, auth, sync, environment, deployment, ...
test/          # unit + widget test
release/       # APK/AAB rilis (di-ignore git, distribusi via Releases)
```

Dokumentasi rinci per topik ada di [`docs/`](docs/)
(api.md, authentication.md, sync.md, environment.md, deployment.md,
troubleshooting.md, ...).

## Untuk developer

Syarat: Flutter SDK 3.47+ (channel stable), Android SDK + JDK 17,
Node 18+ dan Docker untuk backend, akses Firebase Console untuk config.

```bash
flutter pub get
flutter analyze
flutter test

# Rasakan versi produksi (jangan nilai performa dari debug)
flutter run --release
```

### Backend (lokal / server)

```bash
cd backend
cp .env.example .env   # isi minimal: POSTGRES_PASSWORD, JWT_SECRET,
                       # ADMIN_TOKEN, ADMIN_EMAIL, ADMIN_PASSWORD
docker compose up -d --build
curl -k https://192.168.100.230/api/health
```

Daftar variabel lengkap + penjelasannya ada di
[`docs/environment.md`](docs/environment.md). Aturan main: `JWT_SECRET`
kosong = API menolak start; `GEMINI_API_KEY` kosong = AI Sensei nonaktif
dengan pesan jelas; jangan pernah commit `.env`.

Tes integrasi backend (butuh server jalan):

```bash
BASE_URL=https://192.168.100.230 ADMIN_TOKEN=xxx \
  node --test backend/api/test-integration.js
```

### Firebase (butuh akses Console)

1. Authentication → Sign-in method → nyalakan Email/Password dan Google.
2. Daftarkan SHA-1 (+ SHA-256) debug dan rilis di Project settings.
3. Buat Firestore (disarankan asia-southeast1), publish `firestore.rules`
   (`firebase deploy --only firestore:rules`).
4. Unduh `google-services.json` → taruh di `android/app/`
   (**jangan commit** — sudah di-ignore).

## Pengujian

- `flutter test` — 24 kasus (merge sync offline-online, learning engine,
  kurikulum, pratinjau tamu, notifikasi, widget startup). Semua hijau
  sebelum tiap commit.
- `flutter analyze` — wajib bersih.
- `node --test backend/api/test-integration.js` — 14 kasus API
  (register/duplikat/validasi/login/me/progress/google/ai-guard/konten/
  hapus-akun).
- Rasa akhir selalu diuji di **APK release**, bukan debug.

CI GitHub (`ci.yml`) menjalankan analyze + test di tiap push/PR ke
`main`.

## Rilis

APK/AAB tidak disimpan di repo (di-ignore) — yang didistribusikan hanya
lewat halaman GitHub Releases.

1. Naikkan `version:` di `pubspec.yaml` + catat di `CHANGELOG.md`.
2. `flutter build apk --release --target-platform android-arm64`
   (dan `flutter build appbundle --release` untuk Play).
3. Verifikasi tanda tangan cocok dengan kunci rilis, mis. via `apksigner
   verify --print-certs`.
4. Commit + tag `vX.Y.Z`, push branch + tag, lalu buat Release di GitHub
   dan lampirkan APK/AAB-nya:
   `gh release create vX.Y.Z release/japanese-study-vX.Y.Z-arm64.apk ...`
   (Workflow `release.yml` tersedia untuk build manual bila perlu.)

## Batasan & roadmap

Yang diakui belum beres (bukan disembunyikan):

- Login Facebook: tombol + ikon sudah ada, provider-nya belum dibuka.
- Play Store: belum tayang, disiapkan internal testing dulu.
- Pembayaran: layar + paket + entitlement server sudah ada, koneksi ke
  PSP (Xendit/Midtrans/BTCPay) dan Play Billing masih bertahap.
- Layar chat AI Sensei belum dibuat (API + client sudah ada).
- Firebase terkonfigurasi untuk Android; Web/iOS belum.
- `payment_api/` masih berupa rencana, belum implementasi.

## Troubleshooting

| Gejala | Penyebab umum | Obat |
|---|---|---|
| Login Google gagal “error 10” | SHA-1 HP/keystore belum terdaftar | Daftarkan SHA di Console, unduh ulang `google-services.json`, rebuild |
| Daftar gagal `CONFIGURATION_NOT_FOUND` | reCAPTCHA Enterprise belum aktif | Aktifkan di Cloud Console |
| `operation-not-allowed` | Provider belum di-Enable | Nyalakan di Authentication |
| Iklan tidak muncul (“No fill : 0”) | Akun AdMob baru / serving dibatasi | Verifikasi app + app-ads.txt + pembayaran di AdMob Console |
| Debug lambat (>10 dtk) | JIT mode debug | Normal; uji rasa selalu pakai `--release` |
| Backend 503 `AI_DISABLED` | `GEMINI_API_KEY` kosong | Isi key di `.env` + restart stack |

## Keamanan

Jangan commit `.env`, `*.jks`, `key.properties`, `google-services.json`,
atau token apa pun. Kunci API Android sebaiknya dibatasi ke package +
SHA-1, dan kredensial yang pernah bocor harus dirotasi. Baca
[SECURITY.md](SECURITY.md) sebelum kontribusi; aturan repo yang lebih
tegas ada di `checklist-konfigurasi.txt` (lokal, tidak di-push).

## Kontribusi

Terbuka untuk saran, laporan bug, dan kode. Alurnya standar GitHub:
fork → branch → PR dengan deskripsi jelas. Lihat
[CONTRIBUTING.md](CONTRIBUTING.md) dan template issue/PR di `.github/`.
Pastikan `flutter analyze` bersih dan `flutter test` hijau sebelum push.

## Lisensi

[MIT](LICENSE). Logo & aset branding milik proyek ini.

## Consolidated product specification

Requirement dan kontrak implementasi yang dikonsolidasikan dari requirement produk sebelumnya tersedia di:

- `docs/MASTER_PRODUCT_SPEC.md`
- `docs/IMPLEMENTATION_CONTRACT.md`
- `docs/DATA_MIGRATION_PLAN.md`
- `docs/FILE_IMPLEMENTATION_PLAN.md`
- `docs/REPOSITORY_AUDIT_TEMPLATE.md`
- `docs/CURRICULUM_N5_N1_BLUEPRINT.md`
- `docs/PRODUCT_REQUIREMENTS.json`

Dokumen tersebut menjadi acuan sebelum melakukan perubahan besar pada learning engine, curriculum, speaking, SSW, AI, sync, atau billing.
