# Japanese Study — Belajar Bahasa Jepang dan Kanji

[![Lisensi MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Flutter CI](https://github.com/Riyadhifalsf/aplication-japanese-language-study/actions/workflows/ci.yml/badge.svg)](https://github.com/Riyadhifalsf/aplication-japanese-language-study/actions/workflows/ci.yml)
[![Rilis Terbaru](https://img.shields.io/github/v/release/Riyadhifalsf/aplication-japanese-language-study?sort=semver)](https://github.com/Riyadhifalsf/aplication-japanese-language-study/releases)

Aplikasi belajar bahasa Jepang dan kanji N5–N1 untuk Android (dan web), dengan jalur belajar JLPT/JFT yang terstruktur, kosakata dan contoh kalimat, kanji adaptif, tata bahasa, dialog Jepang, bacaan panjang, tool penerjemahan, dan AI coach.

Aplikasi ini didukung backend mandiri (Node.js, PostgreSQL, dan nginx) yang berjalan sendiri dan tidak bergantung pada layanan pihak ketiga untuk konten utama.

## Fitur Unggulan

- Jalur belajar terstruktur **JLPT N5–N1** dan **JFT** dengan progres tersimpan.
- **Kosakata** lengkap dengan contoh kalimat, konjugasi, dan kuis.
- **Kanji adaptif** disusun berdasarkan level, dari goresan dasar hingga kanji lanjutan.
- **Kuis kanji → hiragana** dan latihan cepat untuk hafalan harian.
- **Tata bahasa (grammar)** berjenjang sesuai level JLPT.
- **Kalimat & dialog** sehari-hari bergaya bahasa Indonesia, plus **long story reader**.
- **Tool penerjemahan** dan **AI coach** sebagai pendamping belajar.
- **Statistik & identitas** progres (Web3 identity) untuk memantau perkembangan.
- **Dashboard admin analitik** untuk pengelola konten dan insight pengguna.
- Bisa dipakai **offline**; didukung iklan (AdMob) agar tetap gratis.

## Galeri

Tangkapan layar dapat dilihat di folder `docs/screenshots/` (menyusul pada rilis berikutnya).

## Unduh

Versi terbaru APK untuk instalasi langsung di perangkat Android tersedia di [GitHub Releases](https://github.com/Riyadhifalsf/aplication-japanese-language-study/releases).

## Teknologi

| Bagian     | Teknologi                          |
| ---------- | ---------------------------------- |
| Aplikasi   | Flutter (Android + Web)            |
| Backend    | Node.js, PostgreSQL, nginx         |
| Infrastruktur | Docker Compose, deploy otomatis via `tool/deploy.py` (Proxmox LXC / host Docker) |

## Kontribusi

Terbuka untuk saran, laporan bug, dan kontribusi kode. Silakan lihat [CONTRIBUTING.md](CONTRIBUTING.md) untuk panduan bergabung.

## Lisensi

Didistribusikan di bawah lisensi [MIT](LICENSE).