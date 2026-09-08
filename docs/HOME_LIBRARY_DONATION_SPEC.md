# Home, Library, Activity & Donation Specification

- Aktivitas terakhir tetap berada di Profile dan memiliki dropdown tahun di samping judul.
- Filter tahun membaca timestamp aktivitas, dengan opsi Semua tahun.
- Ikon shortcut Kanji memakai simbol matahari/日 (`Icons.wb_sunny_rounded`) agar selaras dengan makna Kanji 日.
- Library hanya berisi materi/ruang belajar. Quiz, ujian, dan assessment tetap berada di Quiz Center.
- Settings memiliki entry Donasi yang membuka halaman donasi.
- Halaman Donasi menampilkan jumlah orang berdonasi, total nominal donasi, dan leaderboard dari nominal terbesar ke terkecil.
- `DonationConfig.donors` adalah fallback lokal; untuk produksi sebaiknya diisi dari backend/server yang sudah diautentikasi dan tidak menyimpan data pembayaran sensitif di client.
