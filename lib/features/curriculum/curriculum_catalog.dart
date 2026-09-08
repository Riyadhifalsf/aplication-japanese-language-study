import 'curriculum_models.dart';

LessonActivity _a(
  String id,
  CurriculumActivityType type,
  String title, {
  String description = '',
  int? xp,
  int minutes = 5,
  String contentRef = '',
  List<String> contentIds = const [],
  String routeHint = '',
  String? reusedLessonId,
}) =>
    LessonActivity(
      id: id,
      type: type,
      title: title,
      description: description,
      xpReward: xp,
      estimatedMinutes: minutes,
      contentRef: contentRef,
      contentIds: contentIds,
      routeHint: routeHint.isEmpty ? type.name : routeHint,
      reusedLessonId: reusedLessonId,
    );

CurriculumLesson _l(
  String id,
  String unitId,
  String levelId,
  int sequence,
  String title,
  List<LessonActivity> activities, {
  String subtitle = '',
  List<String> objectives = const [],
  List<String> vocabularyIds = const [],
  List<String> grammarIds = const [],
  List<String> kanjiIds = const [],
  List<String> phraseIds = const [],
  List<String> questionIds = const [],
  bool isFinalTest = false,
  bool isBossTest = false,
  int requiredScore = 0,
}) =>
    CurriculumLesson(
      id: id,
      unitId: unitId,
      levelId: levelId,
      sequence: sequence,
      title: title,
      subtitle: subtitle,
      activities: activities,
      objectives: objectives,
      vocabularyIds: vocabularyIds,
      grammarIds: grammarIds,
      kanjiIds: kanjiIds,
      phraseIds: phraseIds,
      questionIds: questionIds,
      isFinalTest: isFinalTest,
      isBossTest: isBossTest,
      requiredScore: requiredScore,
      estimatedMinutes:
          activities.fold<int>(0, (s, a) => s + a.estimatedMinutes),
    );

// ---------------------------------------------------------------------------
// N5 — 10 unit sesuai permintaan.
// Unit 1: Japanese Basics, 2: Hiragana, 3: Katakana, 4: Basic Vocabulary,
// 5: Basic Kanji, 6: Basic Grammar, 7: Daily Conversation,
// 8: Reading, 9: Listening, 10: N5 Final Test.
// Setiap lesson punya kombinasi aktivitas yang BERVARIASI.
// ---------------------------------------------------------------------------

List<CurriculumUnit> _n5Units() => [
      CurriculumUnit(
        id: 'n5-u01',
        levelId: 'N5',
        sequence: 1,
        title: 'Japanese Basics',
        subtitle: 'Fondasi & salam',
        description: 'Sapaan, perkenalan diri, dan pola です/は/も/の.',
        icon: 'waving',
        lessons: [
          // Lesson kurikulum inline: objectives + referensi konten nyata
          // (terverifikasi di bundled data, tanpa mengarang).
          // Phrases Salam/Perkenalan Resmi + Sopan (kontras kesopanan):
          // ph-0001/0002/0003 (Resmi), ph-0011/0012/0013 (Sopan).
          // Vocab N5: 私 123/124, 学生 313, 先生 377, 名前 405, 人 93.
          // Grammar: n5-wa (～は～です identitas), n5-ka (～ですか tanya).
          // Kanji N5 penyusun kata lesson: 名 前 学 生 先 人.
          _l('n5-u01-l01', 'n5-u01', 'N5', 1, 'Salam & Perkenalan', [
            _a('n5-u01-l01-a1', CurriculumActivityType.vocabulary,
                'Kosakata salam',
                description: 'はじめまして, 学生, 先生, 名前',
                contentRef: 'level:N5;skill:vocabulary;theme:greeting',
                contentIds: ['313', '377', '405'],
                routeHint: 'vocabulary'),
            _a('n5-u01-l01-a2', CurriculumActivityType.quiz,
                'Quiz salam',
                description: '5 soal pilihan ganda',
                contentRef: 'level:N5;quiz:salam',
                routeHint: 'quiz'),
          ],
              subtitle: 'Materi + Latihan + Quiz',
              objectives: [
                'Memilih salam berdasarkan waktu (pagi/siang) dan situasi.',
                'Membedakan salam Resmi dan Sopan serta kapan dipakai.',
                'Menyebutkan identitas dasar (saya, pelajar, guru, nama).',
                'Memahami pola A は B です untuk perkenalan.',
                'Bertanya identitas dengan pola ～ですか.',
                'Mengenali kanji penyusun kata perkenalan.',
              ],
              vocabularyIds: ['123', '124', '313', '377', '405', '93'],
              grammarIds: ['n5-wa', 'n5-ka'],
              kanjiIds: ['56', '48', '42', '41', '40', '29'],
              phraseIds: [
                'ph-0001',
                'ph-0002',
                'ph-0003',
                'ph-0011',
                'ph-0012',
                'ph-0013'
              ]),
          // Micro-lesson: pola identitas. Grammar n5-wa terverifikasi;
          // contoh memakai 私/学生/先生 (vocab N5 123/313/377).
          _l('n5-u01-l02', 'n5-u01', 'N5', 2, 'Pola です & は', [
            _a('n5-u01-l02-a1', CurriculumActivityType.grammar,
                'Materi です & は',
                description: 'Penutup sopan & penanda topik',
                contentRef: 'level:N5;grammar:desu-wa',
                routeHint: 'grammar'),
            _a('n5-u01-l02-a2', CurriculumActivityType.exampleSentences,
                'Contoh kalimat',
                description: 'わたしは がくせいです.',
                contentRef: 'level:N5;sentences:intro',
                routeHint: 'sentences'),
            _a('n5-u01-l02-a3', CurriculumActivityType.quiz,
                'Kuis です & は',
                description: 'Soal dari materi lesson ini',
                contentRef: 'level:N5;quiz:desu-wa',
                routeHint: 'quiz'),
          ],
              subtitle: 'Grammar + Contoh + Kuis',
              objectives: [
                'Memahami fungsi です sebagai penutup sopan.',
                'Memahami は sebagai penanda topik.',
                'Membuat kalimat A は B です sederhana.',
                'Menjawab pertanyaan identitas sederhana.',
              ],
              vocabularyIds: ['123', '313', '377'],
              grammarIds: ['n5-wa'],
              kanjiIds: ['42', '41', '40']),
          // Micro-lesson: orang & profesi. Vocab/kanji penyusun kata verified.
          _l('n5-u01-l03', 'n5-u01', 'N5', 3, 'Orang & Profesi', [
            _a('n5-u01-l03-a1', CurriculumActivityType.vocabulary,
                'Kosakata orang',
                description: 'がくせい, せんせい, ひと',
                contentRef: 'level:N5;skill:vocabulary;theme:people',
                contentIds: ['313', '377', '93'],
                routeHint: 'vocabulary'),
            _a('n5-u01-l03-a2', CurriculumActivityType.conversation,
                'Percakapan perkenalan',
                description: 'Role-play singkat',
                contentRef: 'level:N5;dialog:intro',
                routeHint: 'conversation'),
            _a('n5-u01-l03-a3', CurriculumActivityType.quiz,
                'Kuis orang & profesi',
                description: 'Soal dari materi lesson ini',
                contentRef: 'level:N5;quiz:people',
                routeHint: 'quiz'),
          ],
              subtitle: 'Vocabulary + Conversation + Kuis',
              objectives: [
                'Menyebutkan orang dan profesi dasar.',
                'Menggunakan kosakata orang dalam perkenalan.',
                'Mengenali kanji penyusun kata orang/profesi.',
              ],
              vocabularyIds: ['313', '377', '93'],
              kanjiIds: ['42', '41', '40', '29']),
          // Micro-lesson: partikel の. Tanpa speaking (mic tidak tersedia);
          // aktivitas dengar memakai TTS bawaan aplikasi.
          _l('n5-u01-l04', 'n5-u01', 'N5', 4, 'Asal & Bahasa', [
            _a('n5-u01-l04-a1', CurriculumActivityType.grammar,
                'Materi の',
                description: 'Penghubung kata benda',
                contentRef: 'level:N5;grammar:no',
                routeHint: 'grammar'),
            _a('n5-u01-l04-a2', CurriculumActivityType.listening,
                'Dengarkan: kepemilikan',
                description: 'Dengar via TTS lalu jawab',
                contentRef: 'level:N5;listening:no',
                routeHint: 'listening'),
            _a('n5-u01-l04-a3', CurriculumActivityType.quiz,
                'Kuis の',
                description: 'Soal dari materi lesson ini',
                contentRef: 'level:N5;quiz:no',
                routeHint: 'quiz'),
          ],
              subtitle: 'Grammar + Listening + Kuis',
              objectives: [
                'Memahami の sebagai penghubung kata benda.',
                'Mendengar dan memahami frasa kepemilikan sederhana.',
              ],
              grammarIds: ['n5-no']),
          _l('n5-u01-l05', 'n5-u01', 'N5', 5, 'Review Unit 1', [
            _a('n5-u01-l05-a1', CurriculumActivityType.review,
                'Personal review',
                description: 'Ulangi yang sering salah',
                contentRef: 'review:weak',
                routeHint: 'review'),
          ], subtitle: 'Review'),
          _l('n5-u01-l06', 'n5-u01', 'N5', 6, 'Unit 1 Test', [
            _a('n5-u01-l06-a1', CurriculumActivityType.unitTest,
                'Boss test Unit 1',
                description: 'Lulus ≥70% untuk lanjut',
                contentRef: 'level:N5;test:u01',
                routeHint: 'quiz'),
          ],
              subtitle: 'Unit Test',
              isBossTest: true,
              requiredScore: 70),
        ],
      ),
      CurriculumUnit(
        id: 'n5-u02',
        levelId: 'N5',
        sequence: 2,
        title: 'Hiragana',
        subtitle: 'あ → ん',
        description: '46 hiragana dasar, dakuten, yoon.',
        icon: 'kana',
        lessons: [
          _l('n5-u02-l01', 'n5-u02', 'N5', 1, 'Vokal & K-row', [
            _a('n5-u02-l01-a1', CurriculumActivityType.reading,
                'Kartu hiragana',
                description: 'あいうえお かきくけこ',
                contentRef: 'kana:hiragana-basic',
                routeHint: 'kana'),
            _a('n5-u02-l01-a2', CurriculumActivityType.writing,
                'Latihan menulis',
                description: 'Urutan goresan',
                contentRef: 'kana:hiragana-stroke',
                routeHint: 'kana'),
          ], subtitle: 'Reading + Writing'),
          _l('n5-u02-l02', 'n5-u02', 'N5', 2, 'S-Z-T-N rows', [
            _a('n5-u02-l02-a1', CurriculumActivityType.reading,
                'Kartu hiragana II',
                contentRef: 'kana:hiragana-szn',
                routeHint: 'kana'),
            _a('n5-u02-l02-a2', CurriculumActivityType.quiz, 'Quiz tebakan',
                contentRef: 'kana:quiz-hiragana',
                routeHint: 'quiz'),
          ], subtitle: 'Reading + Quiz'),
          _l('n5-u02-l03', 'n5-u02', 'N5', 3, 'Dakuten & Yoon', [
            _a('n5-u02-l03-a1', CurriculumActivityType.reading,
                'がざだばぱ + きゃきゅきょ',
                contentRef: 'kana:hiragana-dakuten-yoon',
                routeHint: 'kana'),
            _a('n5-u02-l03-a2', CurriculumActivityType.listening,
                'Dengar & pilih',
                description: 'Bedakan bunyi mirip',
                contentRef: 'kana:listening-hiragana',
                routeHint: 'listening'),
          ], subtitle: 'Reading + Listening'),
          _l('n5-u02-l04', 'n5-u02', 'N5', 4, 'Review Hiragana', [
            _a('n5-u02-l04-a1', CurriculumActivityType.review,
                'Weak kana review',
                contentRef: 'review:kana',
                routeHint: 'review'),
          ], subtitle: 'Review'),
          _l('n5-u02-l05', 'n5-u02', 'N5', 5, 'Unit 2 Test', [
            _a('n5-u02-l05-a1', CurriculumActivityType.unitTest,
                'Boss test Hiragana',
                contentRef: 'level:N5;test:u02',
                routeHint: 'quiz'),
          ],
              subtitle: 'Unit Test',
              isBossTest: true,
              requiredScore: 70),
        ],
      ),
      CurriculumUnit(
        id: 'n5-u03',
        levelId: 'N5',
        sequence: 3,
        title: 'Katakana',
        subtitle: 'ア → ン',
        description: 'Katakana untuk kata serapan & nama asing.',
        icon: 'kana',
        lessons: [
          _l('n5-u03-l01', 'n5-u03', 'N5', 1, 'Katakana dasar', [
            _a('n5-u03-l01-a1', CurriculumActivityType.reading,
                'Kartu katakana',
                contentRef: 'kana:katakana-basic',
                routeHint: 'kana'),
            _a('n5-u03-l01-a2', CurriculumActivityType.vocabulary,
                'Kata serapan',
                description: 'パン, コーヒー, インドネシア',
                contentRef: 'level:N5;skill:vocabulary;theme:loanwords',
                routeHint: 'vocabulary'),
          ], subtitle: 'Reading + Vocabulary'),
          _l('n5-u03-l02', 'n5-u03', 'N5', 2, 'Katakana lanjut', [
            _a('n5-u03-l02-a1', CurriculumActivityType.listening,
                'Dengar katakana',
                contentRef: 'kana:listening-katakana',
                routeHint: 'listening'),
            _a('n5-u03-l02-a2', CurriculumActivityType.quiz, 'Quiz katakana',
                contentRef: 'kana:quiz-katakana', routeHint: 'quiz'),
          ], subtitle: 'Listening + Quiz'),
          _l('n5-u03-l03', 'n5-u03', 'N5', 3, 'Unit 3 Test', [
            _a('n5-u03-l03-a1', CurriculumActivityType.unitTest,
                'Boss test Katakana',
                contentRef: 'level:N5;test:u03',
                routeHint: 'quiz'),
          ],
              subtitle: 'Unit Test',
              isBossTest: true,
              requiredScore: 70),
        ],
      ),
      CurriculumUnit(
        id: 'n5-u04',
        levelId: 'N5',
        sequence: 4,
        title: 'Basic Vocabulary',
        subtitle: 'Keluarga, benda, waktu',
        description: 'Kosakata inti N5 bertema kehidupan sehari-hari.',
        icon: 'vocab',
        lessons: [
          _l('n5-u04-l01', 'n5-u04', 'N5', 1, 'Keluarga & Orang', [
            _a('n5-u04-l01-a1', CurriculumActivityType.vocabulary,
                'Kosakata keluarga',
                contentRef: 'level:N5;skill:vocabulary;theme:family',
                routeHint: 'vocabulary'),
            _a('n5-u04-l01-a2', CurriculumActivityType.quiz, 'Quiz kilat',
                contentRef: 'level:N5;quiz:family', routeHint: 'quiz'),
          ], subtitle: 'Vocabulary + Quiz'),
          _l('n5-u04-l02', 'n5-u04', 'N5', 2, 'Benda & Tempat', [
            _a('n5-u04-l02-a1', CurriculumActivityType.vocabulary,
                'ここ・そこ・あそこ',
                contentRef: 'level:N5;skill:vocabulary;theme:place',
                routeHint: 'vocabulary'),
            _a('n5-u04-l02-a2', CurriculumActivityType.exampleSentences,
                'Kalimat lokasi',
                contentRef: 'level:N5;sentences:place',
                routeHint: 'sentences'),
          ], subtitle: 'Vocabulary + Contoh'),
          _l('n5-u04-l03', 'n5-u04', 'N5', 3, 'Waktu & Jadwal', [
            _a('n5-u04-l03-a1', CurriculumActivityType.vocabulary,
                'Jam, hari, tanggal',
                contentRef: 'level:N5;skill:vocabulary;theme:time',
                routeHint: 'vocabulary'),
            _a('n5-u04-l03-a2', CurriculumActivityType.listening,
                'Dengar jadwal',
                contentRef: 'level:N5;listening:schedule',
                routeHint: 'listening'),
          ], subtitle: 'Vocabulary + Listening'),
          _l('n5-u04-l04', 'n5-u04', 'N5', 4, 'Makan & Transport', [
            _a('n5-u04-l04-a1', CurriculumActivityType.vocabulary,
                'Makanan & kendaraan',
                contentRef: 'level:N5;skill:vocabulary;theme:food-transport',
                routeHint: 'vocabulary'),
            _a('n5-u04-l04-a2', CurriculumActivityType.speaking,
                'Pesan makanan',
                contentRef: 'level:N5;speaking:order',
                routeHint: 'speaking'),
          ], subtitle: 'Vocabulary + Speaking'),
          _l('n5-u04-l05', 'n5-u04', 'N5', 5, 'Vocabulary Review', [
            _a('n5-u04-l05-a1', CurriculumActivityType.review,
                'Weak vocabulary',
                contentRef: 'review:vocabulary',
                routeHint: 'review'),
          ], subtitle: 'Review'),
          _l('n5-u04-l06', 'n5-u04', 'N5', 6, 'Unit 4 Test', [
            _a('n5-u04-l06-a1', CurriculumActivityType.unitTest,
                'Boss test kosakata',
                contentRef: 'level:N5;test:u04',
                routeHint: 'quiz'),
          ],
              subtitle: 'Unit Test',
              isBossTest: true,
              requiredScore: 70),
        ],
      ),
      CurriculumUnit(
        id: 'n5-u05',
        levelId: 'N5',
        sequence: 5,
        title: 'Basic Kanji',
        subtitle: 'Angka, waktu, orang',
        description: 'Kanji N5 frekuensi tinggi dalam kata nyata.',
        icon: 'kanji',
        lessons: [
          _l('n5-u05-l01', 'n5-u05', 'N5', 1, 'Angka & Waktu', [
            _a('n5-u05-l01-a1', CurriculumActivityType.kanji, '日月火水木金土',
                description: 'Arti + bacaan',
                contentRef: 'level:N5;kanji:numbers-time',
                routeHint: 'kanji'),
            _a('n5-u05-l01-a2', CurriculumActivityType.writing,
                'Latihan goresan',
                contentRef: 'level:N5;kanji:stroke',
                routeHint: 'kanji'),
          ], subtitle: 'Kanji + Writing'),
          _l('n5-u05-l02', 'n5-u05', 'N5', 2, 'Orang & Tempat', [
            _a('n5-u05-l02-a1', CurriculumActivityType.kanji, '人日本語学校',
                contentRef: 'level:N5;kanji:people-place',
                routeHint: 'kanji'),
            _a('n5-u05-l02-a2', CurriculumActivityType.quiz, 'Quiz bacaan',
                contentRef: 'level:N5;quiz:kanji-reading',
                routeHint: 'quiz'),
          ], subtitle: 'Kanji + Quiz'),
          _l('n5-u05-l03', 'n5-u05', 'N5', 3, 'Kanji Review', [
            _a('n5-u05-l03-a1', CurriculumActivityType.review, 'Weak kanji',
                contentRef: 'review:kanji', routeHint: 'review'),
          ], subtitle: 'Review'),
          _l('n5-u05-l04', 'n5-u05', 'N5', 4, 'Unit 5 Test', [
            _a('n5-u05-l04-a1', CurriculumActivityType.unitTest,
                'Boss test kanji',
                contentRef: 'level:N5;test:u05',
                routeHint: 'quiz'),
          ],
              subtitle: 'Unit Test',
              isBossTest: true,
              requiredScore: 70),
        ],
      ),
      CurriculumUnit(
        id: 'n5-u06',
        levelId: 'N5',
        sequence: 6,
        title: 'Basic Grammar',
        subtitle: 'Pola inti N5',
        description: 'ます, て-form, あります/います, adjektiva, たい.',
        icon: 'grammar',
        lessons: [
          _l('n5-u06-l01', 'n5-u06', 'N5', 1, 'Kata kerja ます', [
            _a('n5-u06-l01-a1', CurriculumActivityType.grammar, 'Materi ます',
                contentRef: 'level:N5;grammar:masu', routeHint: 'grammar'),
            _a('n5-u06-l01-a2', CurriculumActivityType.exampleSentences,
                'Contoh ます',
                contentRef: 'level:N5;sentences:masu',
                routeHint: 'sentences'),
          ], subtitle: 'Grammar + Contoh'),
          _l('n5-u06-l02', 'n5-u06', 'N5', 2, 'Bentuk て', [
            _a('n5-u06-l02-a1', CurriculumActivityType.grammar,
                'Materi てください',
                contentRef: 'level:N5;grammar:te-form',
                routeHint: 'grammar'),
            _a('n5-u06-l02-a2', CurriculumActivityType.quiz, 'Quiz て-form',
                contentRef: 'level:N5;quiz:te-form', routeHint: 'quiz'),
          ], subtitle: 'Grammar + Quiz'),
          _l('n5-u06-l03', 'n5-u06', 'N5', 3, 'Ada & Sifat', [
            _a('n5-u06-l03-a1', CurriculumActivityType.grammar,
                'あります・います + adjektiva',
                contentRef: 'level:N5;grammar:exist-adj',
                routeHint: 'grammar'),
            _a('n5-u06-l03-a2', CurriculumActivityType.conversation,
                'Deskripsikan kamarmu',
                contentRef: 'level:N5;dialog:describe',
                routeHint: 'conversation'),
          ], subtitle: 'Grammar + Conversation'),
          _l('n5-u06-l04', 'n5-u06', 'N5', 4, 'Keinginan たい', [
            _a('n5-u06-l04-a1', CurriculumActivityType.grammar, 'Materi たい',
                contentRef: 'level:N5;grammar:tai', routeHint: 'grammar'),
            _a('n5-u06-l04-a2', CurriculumActivityType.speaking,
                'Ceritakan keinginanmu',
                contentRef: 'level:N5;speaking:wish',
                routeHint: 'speaking'),
          ], subtitle: 'Grammar + Speaking'),
          _l('n5-u06-l05', 'n5-u06', 'N5', 5, 'Grammar Review', [
            _a('n5-u06-l05-a1', CurriculumActivityType.review, 'Weak grammar',
                contentRef: 'review:grammar', routeHint: 'review'),
          ], subtitle: 'Review'),
          _l('n5-u06-l06', 'n5-u06', 'N5', 6, 'Unit 6 Test', [
            _a('n5-u06-l06-a1', CurriculumActivityType.unitTest,
                'Boss test grammar',
                contentRef: 'level:N5;test:u06',
                routeHint: 'quiz'),
          ],
              subtitle: 'Unit Test',
              isBossTest: true,
              requiredScore: 70),
        ],
      ),
      CurriculumUnit(
        id: 'n5-u07',
        levelId: 'N5',
        sequence: 7,
        title: 'Daily Conversation',
        subtitle: 'Kaiwa sehari-hari',
        description: 'Percakapan belanja, stasiun, restoran.',
        icon: 'chat',
        lessons: [
          _l('n5-u07-l01', 'n5-u07', 'N5', 1, 'Belanja', [
            _a('n5-u07-l01-a1', CurriculumActivityType.conversation,
                'Dialog belanja',
                contentRef: 'level:N5;dialog:shopping',
                routeHint: 'conversation'),
            _a('n5-u07-l01-a2', CurriculumActivityType.shadowing,
                'Shadowing belanja',
                contentRef: 'level:N5;shadowing:shopping',
                routeHint: 'speaking'),
          ], subtitle: 'Conversation + Shadowing'),
          _l('n5-u07-l02', 'n5-u07', 'N5', 2, 'Stasiun & Restoran', [
            _a('n5-u07-l02-a1', CurriculumActivityType.listening,
                'Dengar pengumuman',
                contentRef: 'level:N5;listening:station',
                routeHint: 'listening'),
            _a('n5-u07-l02-a2', CurriculumActivityType.speaking,
                'Pesan & tanya arah',
                contentRef: 'level:N5;speaking:station',
                routeHint: 'speaking'),
          ], subtitle: 'Listening + Speaking'),
          _l('n5-u07-l03', 'n5-u07', 'N5', 3, 'Unit 7 Test', [
            _a('n5-u07-l03-a1', CurriculumActivityType.unitTest,
                'Boss test kaiwa',
                contentRef: 'level:N5;test:u07',
                routeHint: 'quiz'),
          ],
              subtitle: 'Unit Test',
              isBossTest: true,
              requiredScore: 70),
        ],
      ),
      CurriculumUnit(
        id: 'n5-u08',
        levelId: 'N5',
        sequence: 8,
        title: 'Reading',
        subtitle: 'Cerita pendek',
        description: 'Membaca cerita pendek & menemukan gagasan utama.',
        icon: 'reading',
        lessons: [
          _l('n5-u08-l01', 'n5-u08', 'N5', 1, 'Cerita pendek I', [
            _a('n5-u08-l01-a1', CurriculumActivityType.reading,
                'Bacaan: Hariku',
                contentRef: 'level:N5;reading:daily',
                routeHint: 'reading'),
            _a('n5-u08-l01-a2', CurriculumActivityType.quiz, 'Quiz pemahaman',
                contentRef: 'level:N5;quiz:reading-1',
                routeHint: 'quiz'),
          ], subtitle: 'Reading + Quiz'),
          _l('n5-u08-l02', 'n5-u08', 'N5', 2, 'Cerita pendek II', [
            _a('n5-u08-l02-a1', CurriculumActivityType.reading,
                'Bacaan: Liburan',
                contentRef: 'level:N5;reading:holiday',
                routeHint: 'reading'),
            _a('n5-u08-l02-a2', CurriculumActivityType.vocabulary,
                'Kosakata cerita',
                contentRef: 'level:N5;skill:vocabulary;theme:story',
                routeHint: 'vocabulary'),
          ], subtitle: 'Reading + Vocabulary'),
          _l('n5-u08-l03', 'n5-u08', 'N5', 3, 'Unit 8 Test', [
            _a('n5-u08-l03-a1', CurriculumActivityType.unitTest,
                'Boss test reading',
                contentRef: 'level:N5;test:u08',
                routeHint: 'quiz'),
          ],
              subtitle: 'Unit Test',
              isBossTest: true,
              requiredScore: 70),
        ],
      ),
      CurriculumUnit(
        id: 'n5-u09',
        levelId: 'N5',
        sequence: 9,
        title: 'Listening',
        subtitle: 'Choukai dasar',
        description: 'Menangkap kata kunci, angka, waktu dari audio lambat.',
        icon: 'listening',
        lessons: [
          _l('n5-u09-l01', 'n5-u09', 'N5', 1, 'Angka & Waktu', [
            _a('n5-u09-l01-a1', CurriculumActivityType.listening,
                'Dengar angka',
                contentRef: 'level:N5;listening:numbers',
                routeHint: 'listening'),
            _a('n5-u09-l01-a2', CurriculumActivityType.quiz, 'Quiz choukai',
                contentRef: 'level:N5;quiz:listening-1',
                routeHint: 'quiz'),
          ], subtitle: 'Listening + Quiz'),
          _l('n5-u09-l02', 'n5-u09', 'N5', 2, 'Dialog sehari-hari', [
            _a('n5-u09-l02-a1', CurriculumActivityType.listening,
                'Dialog lambat',
                contentRef: 'level:N5;listening:dialog',
                routeHint: 'listening'),
            _a('n5-u09-l02-a2', CurriculumActivityType.speaking,
                'Tirukan dialog',
                contentRef: 'level:N5;speaking:repeat',
                routeHint: 'speaking'),
          ], subtitle: 'Listening + Speaking'),
          _l('n5-u09-l03', 'n5-u09', 'N5', 3, 'Unit 9 Test', [
            _a('n5-u09-l03-a1', CurriculumActivityType.unitTest,
                'Boss test listening',
                contentRef: 'level:N5;test:u09',
                routeHint: 'quiz'),
          ],
              subtitle: 'Unit Test',
              isBossTest: true,
              requiredScore: 70),
        ],
      ),
      CurriculumUnit(
        id: 'n5-u10',
        levelId: 'N5',
        sequence: 10,
        title: 'N5 Final Test',
        subtitle: 'JLPT Practice + Simulasi',
        description:
            'Reading, listening, grammar, vocab & kanji review + mock test N5.',
        icon: 'trophy',
        lessons: [
          _l('n5-u10-l01', 'n5-u10', 'N5', 1, 'Vocabulary Review', [
            _a('n5-u10-l01-a1', CurriculumActivityType.review,
                'Vocabulary review',
                contentRef: 'review:vocabulary',
                routeHint: 'review'),
          ], subtitle: 'Review'),
          _l('n5-u10-l02', 'n5-u10', 'N5', 2, 'Kanji Review', [
            _a('n5-u10-l02-a1', CurriculumActivityType.review, 'Kanji review',
                contentRef: 'review:kanji', routeHint: 'review'),
          ], subtitle: 'Review'),
          _l('n5-u10-l03', 'n5-u10', 'N5', 3, 'Grammar Review', [
            _a('n5-u10-l03-a1', CurriculumActivityType.review,
                'Grammar review',
                contentRef: 'review:grammar', routeHint: 'review'),
          ], subtitle: 'Review'),
          _l('n5-u10-l04', 'n5-u10', 'N5', 4, 'Reading Practice', [
            _a('n5-u10-l04-a1', CurriculumActivityType.reading,
                'Latihan dokkai N5',
                contentRef: 'level:N5;reading:jlpt',
                routeHint: 'reading'),
            _a('n5-u10-l04-a2', CurriculumActivityType.quiz, 'Quiz dokkai',
                contentRef: 'level:N5;quiz:jlpt-reading',
                routeHint: 'quiz'),
          ], subtitle: 'Reading + Quiz'),
          _l('n5-u10-l05', 'n5-u10', 'N5', 5, 'Listening Practice', [
            _a('n5-u10-l05-a1', CurriculumActivityType.listening,
                'Latihan choukai N5',
                contentRef: 'level:N5;listening:jlpt',
                routeHint: 'listening'),
            _a('n5-u10-l05-a2', CurriculumActivityType.quiz, 'Quiz choukai',
                contentRef: 'level:N5;quiz:jlpt-listening',
                routeHint: 'quiz'),
          ], subtitle: 'Listening + Quiz'),
          _l('n5-u10-l06', 'n5-u10', 'N5', 6, 'JLPT N5 Mock Test', [
            _a('n5-u10-l06-a1', CurriculumActivityType.mockTest,
                'Simulasi N5',
                description: 'Mojis, bunpou, dokkai, choukai',
                contentRef: 'level:N5;mock:jlpt',
                routeHint: 'exam'),
          ],
              subtitle: 'Mock Test',
              isFinalTest: true,
              requiredScore: 70),
          _l('n5-u10-l07', 'n5-u10', 'N5', 7, 'N5 Final Boss', [
            _a('n5-u10-l07-a1', CurriculumActivityType.finalTest,
                'Ujian akhir N5',
                description: 'Lulus ≥70% membuka N4 + tampilkan N5 Completed',
                contentRef: 'level:N5;final:boss',
                routeHint: 'exam'),
          ],
              subtitle: 'Final Test',
              isFinalTest: true,
              requiredScore: 70),
        ],
      ),
    ];

// ---------------------------------------------------------------------------
// N4 — 8 unit: Vocabulary, Kanji, Grammar, Reading, Listening,
// Conversation, Review, Final Test.
// ---------------------------------------------------------------------------

List<CurriculumUnit> _n4Units() {
  CurriculumUnit unit(
    int seq,
    String uid,
    String title,
    String subtitle,
    String desc,
    String icon,
    List<CurriculumLesson> lessons,
  ) =>
      CurriculumUnit(
          id: uid,
          levelId: 'N4',
          sequence: seq,
          title: title,
          subtitle: subtitle,
          description: desc,
          icon: icon,
          lessons: lessons);

  CurriculumLesson lesson(
    String lid,
    String uid,
    int seq,
    String title,
    String subtitle,
    List<LessonActivity> acts, {
    bool boss = false,
    bool fin = false,
  }) =>
      _l(lid, uid, 'N4', seq, title, acts,
          subtitle: subtitle,
          isBossTest: boss,
          isFinalTest: fin,
          requiredScore: (boss || fin) ? 70 : 0);

  return [
    unit(1, 'n4-u01', 'Vocabulary', 'Kata kerja & kehidupan',
        'Kosakata N4: rutinitas, pengalaman, perubahan.', 'vocab', [
      lesson('n4-u01-l01', 'n4-u01', 1, 'Rutinitas & Pengalaman',
          'Vocabulary + Quiz', [
        _a('n4-u01-l01-a1', CurriculumActivityType.vocabulary,
            'Kosakata rutinitas',
            contentRef: 'level:N4;skill:vocabulary;theme:routine',
            routeHint: 'vocabulary'),
        _a('n4-u01-l01-a2', CurriculumActivityType.quiz, 'Quiz kilat',
            contentRef: 'level:N4;quiz:routine', routeHint: 'quiz'),
      ]),
      lesson('n4-u01-l02', 'n4-u01', 2, 'Dua aksi & Alasan',
          'Vocabulary + Contoh', [
        _a('n4-u01-l02-a1', CurriculumActivityType.vocabulary,
            'ながら, し, ために',
            contentRef: 'level:N4;skill:vocabulary;theme:reason',
            routeHint: 'vocabulary'),
        _a('n4-u01-l02-a2', CurriculumActivityType.exampleSentences,
            'Contoh kalimat',
            contentRef: 'level:N4;sentences:reason',
            routeHint: 'sentences'),
      ]),
      lesson('n4-u01-l03', 'n4-u01', 3, 'Unit Test Vocabulary',
          'Unit Test', [
        _a('n4-u01-l03-a1', CurriculumActivityType.unitTest,
            'Boss test vocab N4',
            contentRef: 'level:N4;test:u01', routeHint: 'quiz'),
      ], boss: true),
    ]),
    unit(2, 'n4-u02', 'Kanji', 'Kanji kehidupan',
        'Kanji N4: keadaan, selesai, persiapan.', 'kanji', [
      lesson('n4-u02-l01', 'n4-u02', 1, 'Keadaan & Selesai',
          'Kanji + Writing', [
        _a('n4-u02-l01-a1', CurriculumActivityType.kanji, 'Kanji ています系',
            contentRef: 'level:N4;kanji:state', routeHint: 'kanji'),
        _a('n4-u02-l01-a2', CurriculumActivityType.writing, 'Latihan goresan',
            contentRef: 'level:N4;kanji:stroke', routeHint: 'kanji'),
      ]),
      lesson('n4-u02-l02', 'n4-u02', 2, 'Kanji Review', 'Review', [
        _a('n4-u02-l02-a1', CurriculumActivityType.review, 'Weak kanji',
            contentRef: 'review:kanji', routeHint: 'review'),
      ]),
      lesson('n4-u02-l03', 'n4-u02', 3, 'Unit Test Kanji', 'Unit Test', [
        _a('n4-u02-l03-a1', CurriculumActivityType.unitTest,
            'Boss test kanji N4',
            contentRef: 'level:N4;test:u02', routeHint: 'quiz'),
      ], boss: true),
    ]),
    unit(3, 'n4-u03', 'Grammar', 'Pola menengah',
        'んです, 可能形, てある/ておく, つもり, ば.', 'grammar', [
      lesson('n4-u03-l01', 'n4-u03', 1, 'Alasan & Kemungkinan',
          'Grammar + Contoh', [
        _a('n4-u03-l01-a1', CurriculumActivityType.grammar, 'んです & 可能形',
            contentRef: 'level:N4;grammar:ndesu-kanou',
            routeHint: 'grammar'),
        _a('n4-u03-l01-a2', CurriculumActivityType.exampleSentences,
            'Contoh kalimat',
            contentRef: 'level:N4;sentences:ndesu',
            routeHint: 'sentences'),
      ]),
      lesson('n4-u03-l02', 'n4-u03', 2, 'Persiapan & Rencana',
          'Grammar + Quiz', [
        _a('n4-u03-l02-a1', CurriculumActivityType.grammar,
            'てある・ておく・つもり',
            contentRef: 'level:N4;grammar:prep-plan',
            routeHint: 'grammar'),
        _a('n4-u03-l02-a2', CurriculumActivityType.quiz, 'Quiz pola',
            contentRef: 'level:N4;quiz:grammar-2', routeHint: 'quiz'),
      ]),
      lesson('n4-u03-l03', 'n4-u03', 3, 'Pasif & Nominalisasi',
          'Grammar + Speaking', [
        _a('n4-u03-l03-a1', CurriculumActivityType.grammar, '受身・のは・のが',
            contentRef: 'level:N4;grammar:passive-nom',
            routeHint: 'grammar'),
        _a('n4-u03-l03-a2', CurriculumActivityType.speaking, 'Jelaskan situasimu',
            contentRef: 'level:N4;speaking:passive',
            routeHint: 'speaking'),
      ]),
      lesson('n4-u03-l04', 'n4-u03', 4, 'Grammar Review', 'Review', [
        _a('n4-u03-l04-a1', CurriculumActivityType.review, 'Weak grammar',
            contentRef: 'review:grammar', routeHint: 'review'),
      ]),
      lesson('n4-u03-l05', 'n4-u03', 5, 'Unit Test Grammar', 'Unit Test', [
        _a('n4-u03-l05-a1', CurriculumActivityType.unitTest,
            'Boss test grammar N4',
            contentRef: 'level:N4;test:u03', routeHint: 'quiz'),
      ], boss: true),
    ]),
    unit(4, 'n4-u04', 'Reading', 'Cerita & prosedur',
        'Bacaan menengah: urutan kejadian, instruksi.', 'reading', [
      lesson('n4-u04-l01', 'n4-u04', 1, 'Cerita berurutan', 'Reading + Quiz', [
        _a('n4-u04-l01-a1', CurriculumActivityType.reading, 'Bacaan: Prosedur',
            contentRef: 'level:N4;reading:procedure',
            routeHint: 'reading'),
        _a('n4-u04-l01-a2', CurriculumActivityType.quiz, 'Quiz pemahaman',
            contentRef: 'level:N4;quiz:reading-1', routeHint: 'quiz'),
      ]),
      lesson('n4-u04-l02', 'n4-u04', 2, 'Unit Test Reading', 'Unit Test', [
        _a('n4-u04-l02-a1', CurriculumActivityType.unitTest,
            'Boss test reading N4',
            contentRef: 'level:N4;test:u04', routeHint: 'quiz'),
      ], boss: true),
    ]),
    unit(5, 'n4-u05', 'Listening', 'Choukai situasional',
        'Percakapan natural: saran, dugaan, instruksi.', 'listening', [
      lesson('n4-u05-l01', 'n4-u05', 1, 'Saran & Dugaan', 'Listening + Quiz', [
        _a('n4-u05-l01-a1', CurriculumActivityType.listening, 'Dengar saran',
            contentRef: 'level:N4;listening:advice',
            routeHint: 'listening'),
        _a('n4-u05-l01-a2', CurriculumActivityType.quiz, 'Quiz choukai',
            contentRef: 'level:N4;quiz:listening-1', routeHint: 'quiz'),
      ]),
      lesson('n4-u05-l02', 'n4-u05', 2, 'Unit Test Listening', 'Unit Test', [
        _a('n4-u05-l02-a1', CurriculumActivityType.unitTest,
            'Boss test listening N4',
            contentRef: 'level:N4;test:u05', routeHint: 'quiz'),
      ], boss: true),
    ]),
    unit(6, 'n4-u06', 'Conversation', 'Sopan & formal',
        'Memberi/menerima tindakan, keigo dasar.', 'chat', [
      lesson('n4-u06-l01', 'n4-u06', 1, 'Memberi & Menerima',
          'Conversation + Shadowing', [
        _a('n4-u06-l01-a1', CurriculumActivityType.conversation,
            'いただきます・くださいます',
            contentRef: 'level:N4;dialog:give-receive',
            routeHint: 'conversation'),
        _a('n4-u06-l01-a2', CurriculumActivityType.shadowing, 'Shadowing sopan',
            contentRef: 'level:N4;shadowing:polite',
            routeHint: 'speaking'),
      ]),
      lesson('n4-u06-l02', 'n4-u06', 2, 'Unit Test Kaiwa', 'Unit Test', [
        _a('n4-u06-l02-a1', CurriculumActivityType.unitTest,
            'Boss test kaiwa N4',
            contentRef: 'level:N4;test:u06', routeHint: 'quiz'),
      ], boss: true),
    ]),
    unit(7, 'n4-u07', 'Review', 'Review terpadu',
        'Personal review otomatis dari kesalahanmu.', 'review', [
      lesson('n4-u07-l01', 'n4-u07', 1, 'Personal Review', 'Review', [
        _a('n4-u07-l01-a1', CurriculumActivityType.review, 'Weak review N4',
            contentRef: 'review:weak', routeHint: 'review'),
      ]),
    ]),
    unit(8, 'n4-u08', 'N4 Final Test', 'JLPT Practice + Simulasi',
        'Vocab/kanji/grammar/reading/listening review + mock N4.',
        'trophy', [
      lesson('n4-u08-l01', 'n4-u08', 1, 'Review Terpadu', 'Review', [
        _a('n4-u08-l01-a1', CurriculumActivityType.review, 'Review N4',
            contentRef: 'review:weak', routeHint: 'review'),
      ]),
      lesson('n4-u08-l02', 'n4-u08', 2, 'Reading + Listening Practice',
          'Reading + Listening', [
        _a('n4-u08-l02-a1', CurriculumActivityType.reading, 'Dokkai N4',
            contentRef: 'level:N4;reading:jlpt', routeHint: 'reading'),
        _a('n4-u08-l02-a2', CurriculumActivityType.listening, 'Choukai N4',
            contentRef: 'level:N4;listening:jlpt',
            routeHint: 'listening'),
      ]),
      lesson('n4-u08-l03', 'n4-u08', 3, 'JLPT N4 Mock Test', 'Mock Test', [
        _a('n4-u08-l03-a1', CurriculumActivityType.mockTest, 'Simulasi N4',
            contentRef: 'level:N4;mock:jlpt', routeHint: 'exam'),
      ], fin: true),
      lesson('n4-u08-l04', 'n4-u08', 4, 'N4 Final Boss', 'Final Test', [
        _a('n4-u08-l04-a1', CurriculumActivityType.finalTest, 'Ujian akhir N4',
            contentRef: 'level:N4;final:boss', routeHint: 'exam'),
      ], fin: true),
    ]),
  ];
}

// ---------------------------------------------------------------------------
// N3 / N2 / N1 — kerangka scalable dengan kesulitan meningkat.
// Struktur unit sama (8 unit), isi bertambah sulit via contentRef & estimasi.
// Menambah lesson baru tidak mengubah UI.
// ---------------------------------------------------------------------------

List<CurriculumUnit> _upperUnits(
  String level,
  List<String> unitTitles,
  String focus,
) {
  final units = <CurriculumUnit>[];
  for (var u = 0; u < unitTitles.length; u++) {
    final uid = '${level.toLowerCase()}-u${(u + 1).toString().padLeft(2, '0')}';
    final lessons = <CurriculumLesson>[];
    final isFinal = u == unitTitles.length - 1;
    if (!isFinal) {
      lessons.add(_l('$uid-l01', uid, level, 1, '${unitTitles[u]} I', [
        _a('$uid-l01-a1', CurriculumActivityType.vocabulary, 'Kosakata $level',
            contentRef: 'level:$level;skill:vocabulary;theme:${u + 1}',
            routeHint: 'vocabulary'),
        _a('$uid-l01-a2', CurriculumActivityType.grammar, 'Bunpou $level',
            contentRef: 'level:$level;grammar:unit${u + 1}',
            routeHint: 'grammar'),
      ], subtitle: 'Vocabulary + Grammar'));
      lessons.add(_l('$uid-l02', uid, level, 2, '${unitTitles[u]} II', [
        _a('$uid-l02-a1',
            u.isEven
                ? CurriculumActivityType.reading
                : CurriculumActivityType.listening,
            u.isEven ? 'Bacaan $level' : 'Choukai $level',
            contentRef:
                'level:$level;${u.isEven ? 'reading' : 'listening'}:unit${u + 1}',
            routeHint: u.isEven ? 'reading' : 'listening'),
        _a('$uid-l02-a2', CurriculumActivityType.quiz, 'Quiz pemahaman',
            contentRef: 'level:$level;quiz:unit${u + 1}',
            routeHint: 'quiz'),
      ], subtitle: 'Skill + Quiz'));
      lessons.add(_l('$uid-l03', uid, level, 3, 'Unit Test', [
        _a('$uid-l03-a1', CurriculumActivityType.unitTest,
            'Boss test ${unitTitles[u]}',
            contentRef: 'level:$level;test:$uid', routeHint: 'quiz'),
      ],
          subtitle: 'Unit Test',
          isBossTest: true,
          requiredScore: 70));
    } else {
      lessons.add(_l('$uid-l01', uid, level, 1, 'Review Terpadu $level', [
        _a('$uid-l01-a1', CurriculumActivityType.review, 'Personal review',
            contentRef: 'review:weak', routeHint: 'review'),
      ], subtitle: 'Review'));
      lessons.add(_l('$uid-l02', uid, level, 2, 'JLPT $level Mock Test', [
        _a('$uid-l02-a1', CurriculumActivityType.mockTest, 'Simulasi $level',
            contentRef: 'level:$level;mock:jlpt', routeHint: 'exam'),
      ],
          subtitle: 'Mock Test', isFinalTest: true, requiredScore: 70));
      lessons.add(_l('$uid-l03', uid, level, 3, '$level Final Boss', [
        _a('$uid-l03-a1', CurriculumActivityType.finalTest, 'Ujian akhir $level',
            contentRef: 'level:$level;final:boss', routeHint: 'exam'),
      ],
          subtitle: 'Final Test', isFinalTest: true, requiredScore: 70));
    }
    units.add(CurriculumUnit(
      id: uid,
      levelId: level,
      sequence: u + 1,
      title: unitTitles[u],
      subtitle: '$focus · Unit ${u + 1}',
      description: 'Materi $level: ${unitTitles[u]} ($focus).',
      icon: isFinal
          ? 'trophy'
          : (u % 3 == 0
              ? 'vocab'
              : (u % 3 == 1 ? 'grammar' : 'reading')),
      lessons: lessons,
    ));
  }
  return units;
}

// ---------------------------------------------------------------------------
// Work in Japan Path — memakai ulang materi Japanese Path (tanpa duplikasi).
// ---------------------------------------------------------------------------

List<CurriculumUnit> _jftUnits() => [
      CurriculumUnit(
        id: 'jft-u01',
        levelId: 'JFT-A1',
        sequence: 1,
        title: 'JFT A1 Prep',
        subtitle: 'Fondasi kehidupan',
        description:
            'Persiapan sebelum JFT-Basic: salam, belanja, waktu. Memakai ulang materi N5.',
        icon: 'waving',
        lessons: [
          _l('jft-u01-l01', 'jft-u01', 'JFT-A1', 1, 'Salam & Belanja (N5 reuse)',
              [
                _a('jft-u01-l01-a1', CurriculumActivityType.vocabulary,
                    'Kosakata salam',
                    routeHint: 'vocabulary',
                    reusedLessonId: 'n5-u01-l01'),
              ],
              subtitle: 'Reuse N5'),
          _l('jft-u01-l02', 'jft-u01', 'JFT-A1', 2, 'Hiragana cepat', [
            _a('jft-u01-l02-a1', CurriculumActivityType.reading, 'Kana kilat',
                routeHint: 'kana', reusedLessonId: 'n5-u02-l01'),
          ], subtitle: 'Reuse N5'),
          _l('jft-u01-l03', 'jft-u01', 'JFT-A1', 3, 'Unit Test A1 Prep', [
            _a('jft-u01-l03-a1', CurriculumActivityType.unitTest, 'Test A1 Prep',
                contentRef: 'level:JFT-A1;test:u01', routeHint: 'quiz'),
          ],
              subtitle: 'Unit Test',
              isBossTest: true,
              requiredScore: 70),
        ],
      ),
      CurriculumUnit(
        id: 'jft-u02',
        levelId: 'JFT-A2',
        sequence: 2,
        title: 'JFT A2 (Basic)',
        subtitle: 'Target JFT-Basic',
        description:
            'Komunikasi sehari-hari + listening situasional. Target resmi JFT-Basic.',
        icon: 'badge',
        lessons: [
          _l('jft-u02-l01', 'jft-u02', 'JFT-A2', 1, 'Kehidupan sehari-hari', [
            _a('jft-u02-l01-a1', CurriculumActivityType.conversation,
                'Dialog harian',
                routeHint: 'conversation',
                reusedLessonId: 'n5-u07-l01'),
            _a('jft-u02-l01-a2', CurriculumActivityType.listening,
                'Choukai harian',
                routeHint: 'listening',
                reusedLessonId: 'n5-u09-l02'),
          ], subtitle: 'Conversation + Listening'),
          _l('jft-u02-l02', 'jft-u02', 'JFT-A2', 2, 'Mock JFT-Basic', [
            _a('jft-u02-l02-a1', CurriculumActivityType.mockTest,
                'Simulasi JFT-Basic',
                contentRef: 'level:JFT-A2;mock:jft', routeHint: 'exam'),
          ],
              subtitle: 'Mock Test',
              isFinalTest: true,
              requiredScore: 70),
        ],
      ),
      CurriculumUnit(
        id: 'ssw-u01',
        levelId: 'SSW',
        sequence: 3,
        title: 'Workplace Japanese',
        subtitle: 'Bahasa kerja',
        description: 'Keigo dasar, laporan, izin, permintaan di tempat kerja.',
        icon: 'work',
        lessons: [
          _l('ssw-u01-l01', 'ssw-u01', 'SSW', 1, 'Lapor & Izin', [
            _a('ssw-u01-l01-a1', CurriculumActivityType.conversation,
                'ほうれんそう dasar',
                contentRef: 'level:SSW;dialog:hourensou',
                routeHint: 'conversation'),
            _a('ssw-u01-l01-a2', CurriculumActivityType.grammar, 'Keigo kerja',
                contentRef: 'level:N4;grammar:keigo',
                routeHint: 'grammar',
                reusedLessonId: 'n4-u06-l01'),
          ], subtitle: 'Conversation + Grammar'),
          _l('ssw-u01-l02', 'ssw-u01', 'SSW', 2, 'SSW Vocabulary', [
            _a('ssw-u01-l02-a1', CurriculumActivityType.vocabulary,
                'Istilah manufaktur',
                contentRef: 'level:SSW;skill:vocabulary;theme:manufacturing',
                routeHint: 'vocabulary'),
            _a('ssw-u01-l02-a2', CurriculumActivityType.quiz, 'Quiz istilah',
                contentRef: 'level:SSW;quiz:manufacturing',
                routeHint: 'quiz'),
          ], subtitle: 'Vocabulary + Quiz'),
          _l('ssw-u01-l03', 'ssw-u01', 'SSW', 3, 'Interview Japanese', [
            _a('ssw-u01-l03-a1', CurriculumActivityType.speaking,
                'Jiko PR & motivasi',
                contentRef: 'level:SSW;speaking:interview',
                routeHint: 'speaking'),
            _a('ssw-u01-l03-a2', CurriculumActivityType.mockTest,
                'Simulasi interview',
                contentRef: 'level:SSW;mock:interview',
                routeHint: 'exam'),
          ], subtitle: 'Speaking + Mock'),
        ],
      ),
    ];

/// Katalog utama. UI tidak boleh hardcode level/unit di widget —
/// selalu baca dari sini agar N5..N1/JFT/SSW bisa ditambah tanpa ubah UI.
class CurriculumCatalogData {
  const CurriculumCatalogData._();

  static List<CurriculumLevel> get levels => [
        CurriculumLevel(
          id: 'N5',
          title: 'JLPT N5',
          subtitle: 'Fondasi komunikasi',
          sequence: 1,
          track: 'jlpt',
          description: 'Pemula → N5: kana, kosakata, kanji, grammar, kaiwa.',
          units: [],
        ),
        CurriculumLevel(
          id: 'N4',
          title: 'JLPT N4',
          subtitle: 'Kalimat praktis',
          sequence: 2,
          track: 'jlpt',
          description: 'Penguatan pola menengah & komunikasi natural.',
          requiredPreviousLevelId: 'N5',
          units: [],
        ),
        CurriculumLevel(
          id: 'N3',
          title: 'JLPT N3',
          subtitle: 'Mandiri menengah',
          sequence: 3,
          track: 'jlpt',
          description: 'Bacaan menengah, diskusi, berita sederhana.',
          requiredPreviousLevelId: 'N4',
          units: [],
        ),
        CurriculumLevel(
          id: 'N2',
          title: 'JLPT N2',
          subtitle: 'Formal & argumentasi',
          sequence: 4,
          track: 'jlpt',
          description: 'Bahasa formal, berita, argumentasi.',
          requiredPreviousLevelId: 'N3',
          units: [],
        ),
        CurriculumLevel(
          id: 'N1',
          title: 'JLPT N1',
          subtitle: 'Tingkat lanjut',
          sequence: 5,
          track: 'jlpt',
          description: 'Nuansa, keigo terapan, bacaan panjang.',
          requiredPreviousLevelId: 'N2',
          units: [],
        ),
        CurriculumLevel(
          id: 'JFT-A1',
          title: 'JFT A1 Prep',
          subtitle: 'Fondasi kerja',
          sequence: 101,
          track: 'work',
          description: 'Jalur persiapan sebelum JFT-Basic (fondasi).',
          units: [],
        ),
        CurriculumLevel(
          id: 'JFT-A2',
          title: 'JFT A2 Basic',
          subtitle: 'Target JFT-Basic',
          sequence: 102,
          track: 'work',
          description: 'Target resmi JFT-Basic (CEFR A2).',
          requiredPreviousLevelId: 'JFT-A1',
          units: [],
        ),
        CurriculumLevel(
          id: 'SSW',
          title: 'SSW & Kerja',
          subtitle: 'Workplace + Interview',
          sequence: 103,
          track: 'work',
          description: 'Workplace, SSW vocabulary, interview.',
          requiredPreviousLevelId: 'JFT-A2',
          units: [],
        ),
      ];

  /// Level lengkap dengan unit & lesson. Dipisah dari [levels] agar
  /// metadata ringan bisa dipakai tanpa membangun seluruh pohon.
  static List<CurriculumLevel> get fullLevels {
    final n3Units = _upperUnits('N3', const [
      'Kosakata Menengah',
      'Kanji Menengah',
      'Bunpou Menengah',
      'Dokkai Menengah',
      'Choukai Menengah',
      'Diskusi & Pendapat',
      'Review Terpadu',
      'N3 Final Test',
    ], 'komunikasi mandiri');
    final n2Units = _upperUnits('N2', const [
      'Kosakata Formal',
      'Kanji Formal',
      'Bunpou Formal',
      'Berita & Informasi',
      'Choukai Formal',
      'Argumen & Alasan',
      'Review Terpadu',
      'N2 Final Test',
    ], 'bahasa formal');
    final n1Units = _upperUnits('N1', const [
      'Nuansa Makna',
      'Kanji Lanjut',
      'Keigo Terapan',
      'Bacaan Panjang',
      'Choukai Cepat',
      'Diskusi Lanjut',
      'Review Terpadu',
      'N1 Final Test',
    ], 'tingkat lanjut');
    final jft = _jftUnits();
    return [
      CurriculumLevel(
          id: 'N5',
          title: 'JLPT N5',
          subtitle: 'Fondasi komunikasi',
          sequence: 1,
          track: 'jlpt',
          description: 'Pemula → N5.',
          units: _n5Units()),
      CurriculumLevel(
          id: 'N4',
          title: 'JLPT N4',
          subtitle: 'Kalimat praktis',
          sequence: 2,
          track: 'jlpt',
          description: 'Penguatan menengah.',
          requiredPreviousLevelId: 'N5',
          units: _n4Units()),
      CurriculumLevel(
          id: 'N3',
          title: 'JLPT N3',
          subtitle: 'Mandiri menengah',
          sequence: 3,
          track: 'jlpt',
          description: 'Komunikasi mandiri.',
          requiredPreviousLevelId: 'N4',
          units: n3Units),
      CurriculumLevel(
          id: 'N2',
          title: 'JLPT N2',
          subtitle: 'Formal & argumentasi',
          sequence: 4,
          track: 'jlpt',
          description: 'Bahasa formal & berita.',
          requiredPreviousLevelId: 'N3',
          units: n2Units),
      CurriculumLevel(
          id: 'N1',
          title: 'JLPT N1',
          subtitle: 'Tingkat lanjut',
          sequence: 5,
          track: 'jlpt',
          description: 'Nuansa & bacaan panjang.',
          requiredPreviousLevelId: 'N2',
          units: n1Units),
      CurriculumLevel(
          id: 'JFT-A1',
          title: 'JFT A1 Prep',
          subtitle: 'Fondasi kerja',
          sequence: 101,
          track: 'work',
          description: 'Persiapan JFT-Basic.',
          units: jft.where((u) => u.levelId == 'JFT-A1').toList()),
      CurriculumLevel(
          id: 'JFT-A2',
          title: 'JFT A2 Basic',
          subtitle: 'Target JFT-Basic',
          sequence: 102,
          track: 'work',
          description: 'Target resmi A2.',
          requiredPreviousLevelId: 'JFT-A1',
          units: jft.where((u) => u.levelId == 'JFT-A2').toList()),
      CurriculumLevel(
          id: 'SSW',
          title: 'SSW & Kerja',
          subtitle: 'Workplace + Interview',
          sequence: 103,
          track: 'work',
          description: 'Bahasa kerja & SSW.',
          requiredPreviousLevelId: 'JFT-A2',
          units: jft.where((u) => u.levelId == 'SSW').toList()),
    ];
  }

  static CurriculumLevel? levelById(String id) {
    for (final level in fullLevels) {
      if (level.id == id) return level;
    }
    return null;
  }

  static CurriculumLesson? lessonById(String id) {
    for (final level in fullLevels) {
      for (final lesson in level.allLessons) {
        if (lesson.id == id) return lesson;
      }
    }
    return null;
  }

  static CurriculumUnit? unitById(String id) {
    for (final level in fullLevels) {
      for (final unit in level.units) {
        if (unit.id == id) return unit;
      }
    }
    return null;
  }

  static List<CurriculumLevel> levelsForTrack(String track) =>
      fullLevels.where((l) => l.track == track).toList()
        ..sort((a, b) => a.sequence.compareTo(b.sequence));
}
