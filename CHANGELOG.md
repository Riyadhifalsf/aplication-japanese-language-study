# Changelog

Semua perubahan penting pada proyek ini dicatat di berkas ini.

## [1.3.0] - 2026-09

- Bab 1 N5 (はじめまして) gaya Duolingo: micro-lesson berurutan dengan
  materi scoped per bab (salam Resmi/Sopan, kotoba, bunpou, kanji Bab 1).
- Listening inline via TTS + reading dari materi yang sudah diajarkan.
- Tes Bab nyata: soal dari pool unit, dinilai otomatis (90 Excellent,
  80 Great, 70 Passed), tanpa input skor manual.
- Semua fitur terbuka; dashboard admin & AI dihapus; ikon Google resmi.

## [1.2.0] - 2026-09

- Navigasi baru: Home / Learn (Learning Path murni) / Practice (Quiz+Review) /
  Library (Independent Study via StudyHub). Profil tetap via avatar.
- Lesson inline content: tujuan + ringkasan vocabulary/grammar/kanji dari
  ContentRepository tampil di dalam lesson (tanpa duplikasi data).
- XP idempotent: aktivitas yang sama tidak memberi XP dua kali.
- Daily goal configurable (20/50/100/150, default 100) + ikut Firebase sync.
- Badge Player Level dibedakan dari JLPT level; subscription/AI tetap nonaktif.
- Semua materi tetap gratis; progres lama aman (backward compatible).

## [1.1.0] - 2026-09

- Kurikulum ala LingoDeer: path melengkung zig-zag (satu node = satu unit),
  garis putus-putus, badge bintang unit aktif, progres done/total per unit.
- Banner promo premium (HEMAT 40% + hitung mundur + tombol upgrade).
- Streak dihapus dari Profil (tetap ada di Beranda).
- Backend: `POST /api/ai/chat` proxy Gemini "Sensei" (JWT + rate limit
  khusus, `GEMINI_API_KEY` ganti `OPENAI_*` yang tak terpakai).
- Flutter: `ApiService.askSensei()` + tes integrasi AI (401 guard).
- Firebase: SHA debug+release terdaftar, `google-services.json` baru
  (oauth_client terisi), `firestore.rules` ter-deploy.

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