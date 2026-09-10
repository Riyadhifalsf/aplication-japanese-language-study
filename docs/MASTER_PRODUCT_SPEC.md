# Japanese Study — Master Product & Implementation Specification

## 0. Purpose

Dokumen ini adalah kontrak sumber-kebenaran (source of truth) untuk mengonsolidasikan requirement produk yang sudah diberikan sebelumnya ke repository `japanese_study`.

Tujuan produk:
- aplikasi belajar bahasa Jepang N5→N1 untuk Android/Web;
- offline-first dengan sinkronisasi;
- jalur belajar bergaya RPG;
- adaptive learning/SRS;
- AI Sensei;
- speaking + shadowing;
- simulasi JLPT/JFT;
- mode kerja Jepang/SSW Manufacturing;
- monetisasi Free/Premium;
- backend Node/Express + PostgreSQL;
- Firebase Auth/Firestore untuk identitas/sync.

> Catatan: requirement bisnis yang belum mempunyai provider/credential nyata harus tetap berupa adapter/stub yang jujur, bukan simulasi pembayaran atau AI palsu.

---

## 1. Learning ladder

Level utama:
- N5 — fondasi
- N4 — dasar lanjutan
- N3 — intermediate
- N2 — upper-intermediate
- N1 — advanced

Target konten awal yang pernah ditetapkan:
- Kanji N5 ≈ 200
- Kanji N4 ≈ 350
- Kanji N3 ≈ 600
- Kanji N2 ≈ 350
- Kanji N1 ≈ 2.000
- Kosakata N5 ≈ 800
- Kosakata kumulatif N4 ≈ 1.500
- Kosakata N3 ≈ 2.250
- Kosakata N2 ≈ 6.000

Angka di atas adalah target produk/content-planning, bukan klaim jumlah resmi JLPT.

Setiap level harus memiliki:
1. vocabulary;
2. kanji;
3. grammar;
4. particles;
5. example sentences;
6. reading;
7. listening;
8. speaking;
9. dialogue;
10. culture/context;
11. quizzes;
12. review/SRS;
13. level assessment;
14. final assessment;
15. remedial path.

---

## 2. Curriculum architecture

Setiap level harus dapat dipecah menjadi ≥30 bab/unit untuk versi kurikulum lengkap. Setiap unit mengikuti pola:

1. Orientasi
2. Learn
3. Guided practice
4. Recall
5. Application
6. Listening
7. Speaking
8. Reading
9. Quiz
10. Assessment
11. Remedial bila gagal
12. Mastery gate

Lesson model minimal:
- `id`
- `levelId`
- `unitId`
- `sequence`
- `title`
- `subtitle`
- `objectives`
- `vocabularyIds`
- `grammarIds`
- `kanjiIds`
- `phraseIds`
- `questionIds`
- `activities`
- `estimatedMinutes`
- `requiredScore`
- `isFinalTest`
- `isBossTest`

Aktivitas yang didukung:
`introduction`, `vocabulary`, `kanji`, `grammar`, `exampleSentences`, `reading`, `listening`, `speaking`, `shadowing`, `conversation`, `quiz`, `review`, `assessment`, `application`, `culture`, `workScenario`.

---

## 3. Minna no Nihongo integration

Konten Minna no Nihongo 1 & 2 digunakan sebagai salah satu jalur pedagogi, tetapi data aplikasi harus memakai konten yang berizin/ditulis sendiri atau metadata yang legal.

Integrasi:
- mapping lesson → tema grammar/vocabulary;
- latihan pola kalimat;
- dialog;
- particles;
- listening;
- review;
- quiz.

Jangan menyalin teks buku berhak cipta secara massal.

---

## 4. Adaptive learning engine

Engine harus membedakan:
- completion;
- mastery;
- recall stability;
- accuracy;
- speed;
- repeated mistakes;
- due review.

Input:
- jawaban benar/salah;
- confidence;
- response time;
- review interval;
- lesson completion;
- mistake history;
- skill tags.

Output:
- next lesson;
- review queue;
- remedial topic;
- difficulty;
- estimated readiness;
- daily plan.

Aturan awal:
- mastery tidak boleh diberikan hanya karena lesson selesai;
- review jatuh tempo harus diprioritaskan;
- accuracy rendah memicu remedial;
- kesalahan berulang menaikkan prioritas review;
- streak menjaga kebiasaan tetapi tidak boleh mengalahkan kebutuhan remedial.

SRS disarankan diimplementasikan sebagai adapter agar algoritme dapat ditingkatkan tanpa mengubah UI.

---

## 5. RPG learning path

Jalur belajar harus terasa seperti game:
- XP;
- level;
- streak;
- badge/achievement;
- chapter unlock;
- boss/final test;
- mission harian;
- reward;
- skill tree;
- progress map.

Unlock rule:
- lesson sebelumnya selesai;
- mastery gate terpenuhi;
- assessment score mencapai ambang;
- remedial selesai bila diperlukan.

Jangan membuat unlock hanya berdasarkan tanggal atau pembelian.

---

## 6. Home/dashboard

Home harus mempertahankan konsep:
- greeting;
- current learning;
- XP;
- level;
- streak;
- daily goal;
- today's mission;
- Kanji hari ini;
- due review;
- quick action;
- continue learning;
- notification.

Kanji hari ini:
- card/carousel;
- tap → detail;
- arti, bacaan, contoh;
- progress/mastery;
- gambar/mnemonic bila tersedia.

Jangan menampilkan label Senin–Minggu pada komponen yang sebelumnya diminta tanpa label hari.

---

## 7. Kanji requirements

Fitur:
- library;
- flashcard;
- flip card;
- stroke order;
- stroke library;
- kanji detail;
- quiz;
- theme quiz;
- similar kanji quiz;
- hiragana reading quiz;
- mastery quiz;
- review;
- kanji slider;
- kanji hari ini.

Furigana:
- N5: furigana tampil default;
- N4 ke atas: furigana disembunyikan default, dengan toggle bantuan.

---

## 8. Speaking & shadowing

Buat domain/adapter terpisah untuk speaking:
- prompt sentence;
- TTS;
- play/slow/replay;
- record;
- playback;
- shadowing loop;
- self-assessment;
- optional pronunciation scoring provider.

MVP tidak boleh mengklaim akurasi pronunciation yang belum tersedia.

Struktur yang disarankan:
`lib/screens/speaking/`
`lib/services/speaking_service.dart`
`lib/services/shadowing_service.dart`
`lib/models/speaking_exercise.dart`

---

## 9. AI Sensei

AI Sensei harus berada di backend agar API key tidak masuk APK.

Kapabilitas:
- grammar explanation;
- vocabulary explanation;
- correction;
- role-play;
- conversation;
- personalized hints;
- study planning;
- remedial explanation;
- SSW/work role-play.

Arsitektur:
Flutter → `/api/ai/*` → provider adapter → response normalization.

Wajib:
- timeout;
- rate limit;
- audit logging minimal;
- input size limit;
- no secret in client;
- provider-independent interface;
- graceful offline fallback.

---

## 10. SSW Manufacturing Mode

Mode `Kerja Jepang` harus mempunyai jalur khusus manufaktur/SSW:
- workplace vocabulary;
- safety phrases;
- factory rules;
- instructions;
- tools/equipment vocabulary;
- quality control;
- reporting;
- shift/handover;
- asking clarification;
- supervisor communication;
- emergency communication;
- interview simulation;
- workplace listening;
- role-play;
- work-document reading.

Skenario minimal:
1. masuk shift;
2. briefing;
3. menerima instruksi;
4. meminta pengulangan;
5. melaporkan masalah;
6. quality check;
7. safety incident;
8. pergantian shift;
9. izin;
10. interview.

Konten harus dipisahkan dari JLPT sehingga user dapat belajar work-Japanese tanpa mengacaukan progress akademik.

---

## 11. JLPT & JFT

Exam engine harus mendukung:
- N5/N4/N3/N2/N1;
- JFT-style practice;
- timer;
- section;
- answer review;
- score;
- mistake analysis;
- history;
- retake;
- difficulty tags.

Mode ujian:
- practice;
- timed;
- full simulation;
- weak-topic drill.

Jangan mengklaim soal resmi jika sumbernya bukan soal resmi berlisensi.

---

## 12. Offline-first & sync

Prinsip:
- local read/write dulu;
- belajar tetap berfungsi tanpa internet;
- sync di background/debounce ketika online;
- merge per-record/field berdasarkan timestamp dan konflik yang terdefinisi;
- remote failure tidak boleh menghapus data lokal.

Current repository uses `SharedPreferences` abstraction. Target evolusi:
`SharedPreferences/domain adapter → SQLite/Drift` tanpa mengubah learning rules.

Data minimal:
- profile;
- lesson progress;
- mastery;
- review state;
- mistakes;
- XP/streak;
- settings;
- downloads/offline packs;
- exam history;
- speaking history.

---

## 13. Offline content packs

Pisahkan:
- core content;
- optional pack;
- level pack;
- SSW pack;
- exam pack.

Pack manifest:
- version;
- schemaVersion;
- contentVersion;
- checksum;
- level;
- locale;
- dependencies.

Update pack harus atomic dan reversible.

---

## 14. Payments & monetization

Produk:
- Free;
- Premium;
- lifetime.

Pernah direncanakan:
- trial 30 hari;
- lifetime option;
- harga bertahap per fase;
- payment melalui Google Play untuk digital goods di Play Store;
- web/backend dapat memakai PSP resmi.

Metode yang pernah diminta:
- QRIS;
- GoPay;
- DANA;
- Mastercard;
- bank;
- crypto/Bitcoin.

Implementasi wajib adapter:
- `BillingProvider`;
- `WebPaymentProvider`;
- `PurchaseVerifier`.

Jangan mengaktifkan metode yang belum benar-benar terhubung. UI harus menandai `coming soon`/`not configured`.

---

## 15. Authentication & account

Dukungan:
- email/password;
- Google sign-in;
- forgot password;
- secure session;
- change password;
- account deletion flow;
- privacy;
- profile.

Secrets:
- server only;
- jangan commit `.env`;
- jangan distribusikan keystore;
- jangan commit API keys.

---

## 16. Admin

Admin layer harus mendukung:
- content management;
- announcements;
- app settings;
- analytics;
- reports;
- audit;
- user support;
- migration status.

Admin endpoint wajib:
- auth;
- role check;
- input validation;
- rate limiting;
- audit log.

---

## 17. Data/content quality

Setiap konten harus memiliki:
- stable id;
- source/license metadata bila relevan;
- JLPT level;
- tags;
- reading;
- meaning;
- examples;
- difficulty;
- reviewed status.

Quality gates:
- no duplicate IDs;
- no broken references;
- no malformed JSON;
- no empty required fields;
- no impossible foreign references;
- no unsupported character encoding;
- no quiz with invalid correct index.

Gunakan `tool/validate_data.mjs` sebagai gate CI.

---

## 18. Engineering constraints

Flutter:
- maintainable feature folders;
- services/domain separated;
- avoid putting business logic in widgets;
- no secrets;
- test critical engine rules.

Backend:
- Node.js/Express;
- PostgreSQL;
- parameterized SQL;
- auth middleware;
- rate-limit;
- helmet;
- versioned API.

Firebase:
- Auth for identity;
- Firestore only for approved sync documents;
- strict ownership rules.

---

## 19. Release quality gates

Sebelum release:
1. `flutter analyze`
2. `flutter test`
3. content validator
4. backend integration test
5. migration rehearsal
6. offline smoke test
7. sync conflict test
8. auth test
9. payment stub/config test
10. Android build
11. web build
12. security scan
13. repository audit.

---

## 20. Definition of Done

Feature dianggap selesai hanya jika:
- model/domain ada;
- UI ada;
- state management terhubung;
- offline behavior terdefinisi;
- sync behavior terdefinisi;
- loading/error/empty state ada;
- analytics/audit relevan tersedia;
- test minimal ada;
- dokumentasi diperbarui;
- tidak ada secret;
- tidak ada klaim provider yang belum aktif.

