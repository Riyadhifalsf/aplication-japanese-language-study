# Japanese Study Intelligence Engine

Mesin ini sengaja tidak mempunyai halaman AI di aplikasi. Ia dipakai sebagai lapisan rekomendasi di belakang layar: memilih materi berikutnya, mendeteksi topik lemah, dan memperkirakan risiko lupa dari progress pengguna.

`app.py` menyediakan API kecil yang bisa dijalankan terpisah. Flutter tetap berjalan tanpa server AI, sehingga aplikasi tidak rusak saat backend belum hidup.

Untuk produksi, hubungkan endpoint ini ke backend utama dan ganti heuristik dengan model yang ditraining dari data anonim seperti akurasi, waktu jawab, interval review, dan frekuensi belajar.
