# Kontribusi

Terima kasih sudah ingin berkontribusi ke Japanese Study. Proyek ini terbuka untuk laporan bug, saran fitur, perbaikan dokumentasi, dan kontribusi kode.

## Alur Kontribusi

1. Buka atau cari [issue](https://github.com/Riyadhifalsf/aplication-japanese-language-study/issues) yang relevan.
2. Fork repositori lalu buat cabang baru dari `main`.
3. Kerjakan perubahan dengan mengikuti standar di bawah.
4. Ajukan [pull request](https://github.com/Riyadhifalsf/aplication-japanese-language-study/pulls) ke `main` dan jelaskan perubahan serta cara pengujiannya.

## Standar

- Kode Flutter harus lolos `flutter analyze` tanpa error dan `flutter test` harus hijau.
- Perubahan backend harus lolos pemeriksaan sintaks (`node --check`) dan tidak mengubah skema data yang sudah ada tanpa migrasi.
- Pesan commit singkat dan deskriptif, contoh: `feat: tambah kuis kosakata harian`, `fix: perbaiki sinkronisasi progres`.
- Jangan sertakan berkas rahasia atau file `.env` pada pull request. Gunakan variabel lingkungan.
- Esai default branch adalah `main`.

## Melaporkan Bug

Gunakan template [bug report](.github/ISSUE_TEMPLATE/bug_report.md) dan sertakan platform, langkah reproduksi, hasil yang diharapkan, dan bukti (log/tangkapan layar) bila memungkinkan.