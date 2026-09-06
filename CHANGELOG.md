# Changelog

Semua perubahan penting pada proyek ini dicatat di berkas ini.

## [3.3.0] - 2026-09

- Tema merah Japanese Study + splash logo anti-kepotong + logo login transparan.
- Mode tamu (pratinjau): Quiz & Kanji terbuka, 5 soal per sesi + spanduk ajakan masuk.
- Auth: session restore Firebase, pesan error jelas (termasuk error 10 SHA-1 Google), ikon brand Google/Facebook, badge Terverifikasi.
- Notifikasi: inbox update/pengumuman retensi 90 hari + sinkron pengumuman admin otomatis.
- Reset progres lokal + server ("Mulai dari nol"); merge union terdokumentasi via test.
- Backend v2 di Proxmox CT100 (192.168.100.230): API+Postgres+proxy TLS 443, seed 10rb vocab, admin JWT.
- Startup: parse JSON di isolate, Firebase/Ads/notifikasi deferred; release cold start 0,6-1,9 dtk; ProGuard WorkManager (perbaiki crash release).
- Premium: paket fase harga naik + layar langganan (QRIS/bank/e-wallet/kartu/crypto/Play).
- Keamanan: untrack google-services.json, JWT fallback warning, token di secure storage.

## [3.2.0] — 2026-09

- Backend canonical: analitik admin, autentikasi server-first dengan fallback offline, rate limiting, dan healthcheck.
- Dashboard admin versi analitik (overview, konten, dan pengaturan).
- Login dan registrasi berbasis server dengan akun admin aman.
- Integrasi iklan AdMob (banner, interstisial, rewarded, native).
- Deployment cross-platform melalui `tool/deploy.py` (Proxmox LXC atau host Docker generik).
- Repositori dikelola sebagai open source (lisensi MIT) dengan rilis via GitHub Releases.

## [3.1.0] — 2026-08

- Jalur JLPT/JFT, kuis kanji ke hiragana, dialog Jepang berbahasa Indonesia.
- Long story reader, tool penerjemahan, dan AI coach.

Versi sebelumnya tidak didokumentasikan; lihat riwayat commit.