# Learning architecture MVP

MVP ini sengaja memulai dari satu loop akademik yang lengkap, bukan dari kumpulan fitur: **daily plan → lesson berfase → assessment → mastery gate → SRS/remedial → next lesson**.

## Tanggung jawab sistem

| Sistem | Tanggung jawab |
| --- | --- |
| Curriculum catalog | Menentukan lesson, objective, urutan, dan prerequisite. |
| Learning engine | Menjalankan state phase lesson, mastery, error notebook, dan gate. |
| SRS | Menjadwalkan review berdasarkan stability, difficulty, lapse, dan waktu review. |
| Daily planner | Memilih prioritas harian yang dapat dijelaskan tanpa mengubah urutan kurikulum. |
| UI | Menampilkan alasan rekomendasi dan mengirim intent pengguna ke engine. |

## Data model dan state transition

Setiap content dan lesson memakai stable ID (`lesson_mnn_001`, `grammar_n5_001_desu`, dan seterusnya). `LearnerState` menyimpan `LessonProgress`, `MasteryRecord`, `ReviewState`, dan `MistakeRecord` secara lokal sehingga tetap dapat digunakan offline.

```text
introduction → learn → guidedPractice → recall → application → assessment
                                                        ↓
                                             mastery gate passed?
                                              ↙                 ↘
                                  schedule SRS + next lesson     targeted remedial
```

Mastery dipisahkan dari completion. Completion hanya diberikan bila gate untuk skill yang benar-benar dinilai di lesson terpenuhi. Speaking tidak diberi skor otomatis karena MVP ini belum melakukan pengukuran suara yang valid.

## Sync dan evolusi data

State baru dibuat serializable. Penyimpanan lokal menggunakan `SharedPreferences` melalui `AppController` saat ini; batas antarmuka domain tidak bergantung pada SharedPreferences sehingga dapat dipindahkan ke SQLite/Drift tanpa mengubah aturan learning engine. State disertai timestamp per entitas untuk mendukung merge per-record pada sync berikutnya.
