# Changelog

## 1.7.1+9 — Repository cleanup

- Membersihkan artefak build, credential lokal, cache dependency, ZIP/patch cadangan, dan binary release dari source tree.
- Menghapus duplikasi schema PostgreSQL yang tidak dipakai langsung oleh Docker build.
- Menyamakan label notifikasi misi tersembunyi dengan versi GitHub terbaru.

## 1.7.1+9 — Security + on-demand content

- Firebase Android API key no longer committed: injected at build time via `--dart-define=FIREBASE_ANDROID_API_KEY` (see `docs/firebase-config.md`).
- New `GET /api/v1/content/packs` manifest endpoint on the backend.
- New in-app Content Downloads screen: per-pack on-demand refresh (Kanji, Vocabulary, Grammar, Phrases, Sentences, Culture, Readings) with bundled offline fallback.
- Custom Quiz: removed dead per-question timer setting; start now verifies the level pool is non-empty.
- Donation leaderboard shows an explicitly labeled Demo mock until the real feed is connected.
- Learning Path: linear BAB numbering, Lanjut buttons, N5–N1 switcher with honest empty states.
- Kana-first ordering (Hiragana → Katakana → Japanese Basics) + onboarding kana branching.
- Tier system removed from UI; progress shown via mastery, focus minutes, streak, and quiz accuracy.

## 1.7.0+8 — Industrial quality upgrade

- Expanded JLPT curriculum depth with six-part sub-lessons across N5-N1.
- Refined Learning terminology and visual level separation.
- Improved lesson copy and removed cosmetic editing-style UI cues.
- Hardened password reset for Google-only accounts and fixed reset transaction atomicity.
- Added stricter Firestore ownership rules and payload validation.
- Added API/proxy body limits, throttling, security headers and non-root Node 24 container baseline.
- Added curriculum reference, security hardening and product roadmap documentation.
- Added backend CI syntax checks.

Semua perubahan penting pada proyek ini dicatat di berkas ini.

## [1.6.0] - 2026-09-09

- Menambahkan sistem pencapaian/milestone berdasarkan progres nyata pengguna.
- Menambahkan Weekly Learning Pulse untuk melihat konsistensi aktivitas selama 7 hari.
- Memperkaya Profil dengan statistik Kanji, kosakata, quiz, hari aktif, waktu aktif, grammar selesai, dan galeri pencapaian.
- Memperkaya ruang latihan pintar agar mistake review dan statistik lebih mudah ditemukan.
- Menjaga Activity History + filter tahun sebagai bagian permanen dari Profil.
- Menjadikan Library fokus pada materi, sedangkan Quiz/Exam tetap berada di Quiz Center.
- Menyelaraskan dokumentasi dengan aturan Learning level aktif N5–N1 dan Library full catalog.

## [1.5.0] - 2026-09

- Audio TTS nyata (flutter_tts): listening lesson berbunyi beneran.
- Final Tes Bab 1: 26+ soal (grammar 5, listening 4, reading, susun 2).
- Soal susun-kalimat interaktif + soal grammar lengkap Bab 1.
- Mastery per item (●/◑/○) tersimpan + tersinkron; best latihan.
- XP anti-farm: tes ulang hanya dapat XP bila skor terbaik baru.
- UI Home, Library, Activity, dan Donation diperbarui.
- Dropdown tahun ditambahkan di Activity History tanpa menghapus riwayat.
- Donasi mendapat ringkasan jumlah donatur, total dukungan, dan leaderboard nominal terbesar yang siap menerima data backend.

## [1.4.0] - 2026-09

- Bab 1 N5 menjadi micro-lesson scoped per bab.
- Library Kotoba dapat difilter per Bab.
- Mastery jujur ●/○/◑ dari data user; XP tetap hanya saat selesai.

## [1.3.0] - 2026-09

- Bab 1 N5 dengan micro-lesson, listening, reading, dan tes bab.
- Semua materi inti dapat dijelajahi tanpa paywall.

## [1.2.0] - 2026-09

- Navigasi Home / Learn / Practice / Library.
- Daily goal configurable 20/50/100/150 XP.
- Badge player level, streak, XP, dan sinkronisasi progres.

## [1.1.0] - 2026-09

- Jalur kurikulum, rekomendasi adaptif, backend AI Sensei, dan notifikasi.

## 3.x dan sebelumnya

Lihat riwayat commit Git untuk detail implementasi backend, Firebase, AdMob, dan deployment.
