import 'curriculum_models.dart';

/// Research-informed chapter blueprints for the extended JLPT path.
///
/// The curriculum is authored for this project. External references inform
/// sequencing, skill coverage and real-life context; textbook wording is not
/// copied. Every generated chapter contains an explanation, guided practice,
/// contextual comprehension, active recall, review and a checkpoint so the
/// roadmap feels like a real course rather than placeholder cards.
class CurriculumDepthCatalog {
  const CurriculumDepthCatalog._();

  static List<CurriculumUnit> forLevel(String level, {required int startSequence}) {
    final topics = _topics[level] ?? const <_Topic>[];
    return [
      for (var i = 0; i < topics.length; i++)
        _unit(level, startSequence + i, topics[i]),
    ];
  }

  static CurriculumUnit _unit(String level, int sequence, _Topic topic) {
    final uid = '${level.toLowerCase()}-deep-u${sequence.toString().padLeft(2, '0')}';
    LessonActivity activity(
      String id,
      CurriculumActivityType type,
      String title,
      String description,
      int minutes,
    ) {
      return LessonActivity(
        id: id,
        type: type,
        title: title,
        description: description,
        estimatedMinutes: minutes,
        contentRef: 'level:$level;theme:${topic.tag}',
        routeHint: switch (type) {
          CurriculumActivityType.grammar => 'grammar',
          CurriculumActivityType.vocabulary => 'vocabulary',
          CurriculumActivityType.kanji => 'kanji',
          CurriculumActivityType.reading => 'reading',
          CurriculumActivityType.listening => 'listening',
          CurriculumActivityType.speaking ||
          CurriculumActivityType.shadowing ||
          CurriculumActivityType.conversation => 'speaking',
          CurriculumActivityType.review => 'review',
          _ => type.name,
        },
      );
    }

    LessonNote note(String title, String body, [List<LessonLine> lines = const []]) =>
        LessonNote(title: title, body: body, lines: lines);

    CurriculumLesson lesson(int n, String title, CurriculumActivityType contextType) {
      final lid = '$uid-l${n.toString().padLeft(2, '0')}';
      final isReading = contextType == CurriculumActivityType.reading;
      final phaseTitle = switch (n) {
        1 => 'Kenali konsep',
        2 => 'Latihan terarah',
        3 => 'Bandingkan nuansa',
        4 => 'Konteks nyata',
        5 => 'Recall aktif',
        _ => 'Review & checkpoint',
      };
      final phaseDescription = switch (n) {
        1 => 'Pahami arti, bentuk, kapan dipakai, dan kesalahan umum.',
        2 => 'Latih dari mudah ke sulit dengan perubahan satu unsur per soal.',
        3 => 'Bandingkan bentuk yang mirip agar pilihan terasa masuk akal.',
        4 => 'Terapkan pada dialog, dokumen, atau situasi kehidupan nyata.',
        5 => 'Coba dari ingatan tanpa membuka catatan terlebih dahulu.',
        _ => 'Ulangi materi yang rapuh lalu pastikan siap pindah ke bab berikutnya.',
      };
      final primaryType = switch (n) {
        1 => CurriculumActivityType.grammar,
        2 => CurriculumActivityType.vocabulary,
        3 => CurriculumActivityType.exampleSentences,
        4 => contextType,
        5 => CurriculumActivityType.writing,
        _ => CurriculumActivityType.review,
      };
      final secondaryType = switch (n) {
        2 => CurriculumActivityType.exampleSentences,
        3 => CurriculumActivityType.quiz,
        4 => contextType,
        5 => CurriculumActivityType.quiz,
        _ => CurriculumActivityType.review,
      };

      final examples = topic.examples;
      final exampleLines = [
        for (final example in examples)
          LessonLine(
            japanese: example.japanese,
            reading: example.reading,
            meaning: example.meaning,
          ),
      ];

      final activities = <LessonActivity>[
        activity('$lid-a1', primaryType, phaseTitle, phaseDescription, 8),
        activity(
          '$lid-a2',
          secondaryType,
          n == 2
              ? 'Uji pemahaman'
              : n == 3
                  ? 'Bedah contoh'
                  : n == 4
                      ? (isReading ? 'Baca & simpulkan' : 'Dengar & tangkap inti')
                      : n == 5
                          ? 'Uji tanpa contekan'
                          : 'Perbaiki kesalahan',
          n == 4
              ? 'Fokus pada maksud utama, bukan menerjemahkan setiap kata.'
              : 'Kerjakan lalu cek alasan jawabannya sebelum lanjut.',
          9,
        ),
        if (n >= 3)
          activity(
            '$lid-a3',
            CurriculumActivityType.listening,
            'Paparan audio',
            'Dengar kalimat contoh dengan TTS dan tangkap kata kunci.',
            7,
          ),
        if (n >= 5)
          activity(
            '$lid-a4',
            CurriculumActivityType.quiz,
            'Retrieval cepat',
            'Recall campuran untuk menguji apakah materi benar-benar melekat.',
            7,
          ),
      ];

      return CurriculumLesson(
        id: lid,
        unitId: uid,
        levelId: level,
        sequence: n,
        title: title,
        subtitle: phaseTitle,
        objectives: [
          topic.goal,
          'Mengenali penggunaan yang tepat dalam konteks baru.',
          'Menghasilkan minimal satu contoh sendiri.',
        ],
        activities: activities,
        notes: [
          note(
            'Inti materi',
            '${topic.subtitle}. $phaseDescription ${topic.explanation}',
            exampleLines,
          ),
          note(
            'Pola utama',
            topic.patterns.join(' · '),
          ),
          if (n >= 4)
            note(
              'Checkpoint',
              'Tutup catatan. Jelaskan dengan kata-katamu sendiri kapan pola ini digunakan dan kapan sebaiknya tidak digunakan.',
            ),
        ],
        estimatedMinutes: 31 + (n >= 3 ? 5 : 0),
      );
    }

    final lessons = [
      lesson(1, '${topic.title} — Fondasi', CurriculumActivityType.reading),
      lesson(2, '${topic.title} — Latihan', CurriculumActivityType.listening),
      lesson(3, '${topic.title} — Nuansa', CurriculumActivityType.reading),
      lesson(4, '${topic.title} — Konteks', CurriculumActivityType.listening),
      lesson(5, '${topic.title} — Recall', CurriculumActivityType.reading),
      lesson(6, '${topic.title} — Review', CurriculumActivityType.listening),
    ];

    return CurriculumUnit(
      id: uid,
      levelId: level,
      sequence: sequence,
      title: topic.title,
      subtitle: topic.subtitle,
      description: topic.description,
      icon: sequence.isEven ? 'book' : 'compass',
      lessons: lessons,
    );
  }

  static const Map<String, List<_Topic>> _topics = {
    'N5': [
      _Topic('Family & People', 'Keluarga dan orang sekitar', 'family', 'Pelajari orang, hubungan keluarga dan cara menyebut identitas dengan konteks sederhana.', 'Bisa memperkenalkan anggota keluarga dan mendeskripsikan orang terdekat.', ['家族（かぞく）', '兄（あに）／姉（あね）', '～さん／～人（じん）'], [
        _Example('わたしの かぞくです。', 'わたしの かぞくです。', 'Ini keluarga saya.'),
        _Example('あには せんせいです。', 'あには せんせいです。', 'Kakak laki-laki saya seorang guru.'),
      ]),
      _Topic('Things & Ownership', 'Benda, kepemilikan, penunjuk', 'things ownership', 'Menghubungkan benda dengan pemilik dan memilih これ／それ／あれ／この／その／あの sesuai jarak konteks.', 'Bisa menunjuk benda dan menjelaskan kepemilikannya.', ['これ／それ／あれ', 'この／その／あの + noun', 'N の N'], [
        _Example('これは わたしの ほんです。', 'これは わたしの ほんです。', 'Ini buku saya.'),
        _Example('その かばんは だれのですか。', 'その かばんは だれのですか。', 'Tas itu milik siapa?'),
      ]),
      _Topic('Places & Directions', 'Tempat, posisi, arah', 'places directions', 'Latih lokasi sederhana, posisi relatif, dan pertanyaan arah yang sering dipakai pemula.', 'Bisa bertanya dan menjelaskan lokasi tempat sederhana.', ['～に あります／います', 'ここ／そこ／あそこ', 'みぎ／ひだり／まえ／うしろ'], [
        _Example('えきは どこですか。', 'えきは どこですか。', 'Stasiunnya di mana?'),
        _Example('コンビニは えきの まえです。', 'コンビニは えきの まえです。', 'Minimarket ada di depan stasiun.'),
      ]),
      _Topic('Time & Daily Schedule', 'Jam, tanggal, frekuensi', 'time schedule', 'Bangun kemampuan menyebut waktu, jadwal, frekuensi, dan urutan kegiatan sehari-hari.', 'Bisa menceritakan jadwal harian dan menanyakan waktu kegiatan.', ['～時／～分', '～から～まで', '毎日／よく／ときどき'], [
        _Example('七時に おきます。', 'しちじに おきます。', 'Saya bangun pukul tujuh.'),
        _Example('九時から 五時まで はたらきます。', 'くじから ごじまで はたらきます。', 'Saya bekerja dari jam sembilan sampai lima.'),
      ]),
      _Topic('Going Out & Transport', 'Pergi, kendaraan, tujuan', 'transport', 'Menyatakan tujuan, alat transportasi, keberangkatan, dan kepulangan dalam konteks sehari-hari.', 'Bisa menjelaskan perjalanan sederhana.', ['N に 行きます／来ます／帰ります', 'N で 行きます', 'と + transport / person'], [
        _Example('バスで しごとへ 行きます。', 'バスで しごとへ いきます。', 'Saya pergi kerja naik bus.'),
        _Example('ともだちと えきへ 行きます。', 'ともだちと えきへ いきます。', 'Saya pergi ke stasiun bersama teman.'),
      ]),
      _Topic('Food & Shopping', 'Menu, harga, pesanan', 'food shopping', 'Berlatih menyebut makanan, jumlah, harga, dan permintaan sederhana saat membeli atau memesan.', 'Bisa memesan makanan dan menanyakan harga.', ['いくらですか', '～を ください', '～を おねがいします'], [
        _Example('これを ください。', 'これを ください。', 'Tolong yang ini.'),
        _Example('これは いくらですか。', 'これは いくらですか。', 'Ini berapa harganya?'),
      ]),
      _Topic('Daily Routines', 'Rutinitas dan kebiasaan', 'routine habits', 'Bangun kalimat rangkaian kegiatan dengan partikel waktu dan objek yang sederhana.', 'Bisa menceritakan rutinitas pagi sampai malam.', ['V-ます', 'V-て、V-ます', 'それから'], [
        _Example('あさ ごはんを たべて、がっこうへ 行きます。', 'あさ ごはんを たべて、がっこうへ いきます。', 'Pagi saya sarapan lalu pergi ke sekolah.'),
      ]),
      _Topic('Adjectives & Description', 'i-adjective dan na-adjective', 'adjectives', 'Mendeskripsikan orang, tempat, benda, rasa dan suasana dengan bentuk afirmatif/negatif dasar.', 'Bisa mendeskripsikan sesuatu dengan adjective yang tepat.', ['い-adjective', 'な-adjective + です', '～くない／～じゃないです'], [
        _Example('この まちは しずかです。', 'この まちは しずかです。', 'Kota ini tenang.'),
        _Example('この りんごは あまくないです。', 'この りんごは あまくないです。', 'Apel ini tidak manis.'),
      ]),
      _Topic('Likes & Abilities', 'Suka, kemampuan', 'preferences ability', 'Menyatakan preferensi dan kemampuan dasar tanpa membuat pengguna bergantung pada terjemahan kata per kata.', 'Bisa mengatakan apa yang disukai dan bisa dilakukan.', ['N が すきです', 'N が じょうずです', 'N が できます'], [
        _Example('日本語が すきです。', 'にほんごが すきです。', 'Saya suka bahasa Jepang.'),
        _Example('ひらがなが できます。', 'ひらがなが できます。', 'Saya bisa hiragana.'),
      ]),
      _Topic('Requests & Invitations', 'Permintaan, ajakan, izin', 'requests invitations', 'Menggunakan bentuk て untuk permintaan, ajakan, dan izin pada situasi sederhana.', 'Bisa meminta bantuan dan mengajak orang dengan sopan.', ['V-てください', 'V-ませんか', 'V-ても いいですか'], [
        _Example('ちょっと まってください。', 'ちょっと まってください。', 'Tolong tunggu sebentar.'),
        _Example('いっしょに たべませんか。', 'いっしょに たべませんか。', 'Mau makan bersama?'),
      ]),
      _Topic('Experience & Plans', 'Pengalaman dan rencana dasar', 'experience plans', 'Memperkenalkan pengalaman sederhana, rencana dekat, dan kegiatan yang ingin dilakukan.', 'Bisa menceritakan pengalaman dan rencana sederhana.', ['V-たことがあります', 'V-つもりです', 'V-たいです'], [
        _Example('日本へ 行ったことがあります。', 'にほんへ いったことがあります。', 'Saya pernah pergi ke Jepang.'),
        _Example('らいしゅう べんきょうする つもりです。', 'らいしゅう べんきょうする つもりです。', 'Minggu depan saya berniat belajar.'),
      ]),
      _Topic('Weather & Health', 'Cuaca dan kondisi badan', 'weather health', 'Menyebut cuaca, keluhan dasar dan respons sederhana ketika badan tidak enak.', 'Bisa menyampaikan kondisi badan dan berbicara singkat tentang cuaca.', ['～です／～でした', 'あたまが いたいです', 'どうしましたか'], [
        _Example('きょうは あついです。', 'きょうは あついです。', 'Hari ini panas.'),
        _Example('あたまが いたいです。', 'あたまが いたいです。', 'Kepala saya sakit.'),
      ]),
      _Topic('Reading Everyday Texts', 'Menu, pesan, jadwal, pengumuman', 'reading everyday', 'Membaca teks pendek autentik bergaya kehidupan sehari-hari dan mencari informasi yang diperlukan.', 'Bisa menemukan informasi penting tanpa menerjemahkan semua kata.', ['judul → konteks', 'kata waktu/tempat', 'siapa melakukan apa'], [
        _Example('しめきり：金曜日', 'しめきり：きんようび', 'Batas waktu: Jumat'),
      ]),
      _Topic('Listening Everyday Life', 'Informasi inti percakapan', 'listening everyday', 'Melatih menangkap kata kunci, angka, waktu, nama dan tujuan dalam percakapan lambat.', 'Bisa menangkap inti percakapan singkat.', ['kata kunci', 'angka/waktu', 'tujuan/permintaan'], [
        _Example('七時に えきで あいましょう。', 'しちじに えきで あいましょう。', 'Mari bertemu di stasiun jam tujuh.'),
      ]),
      _Topic('Japanese Particles Mastery', 'は・が・を・に・で', 'particles', 'Bab penguatan khusus untuk partikel yang paling sering membuat pemula salah.', 'Bisa memilih partikel berdasarkan fungsi, bukan hafalan terpisah.', ['は = topik', 'が = subjek/fokus', 'を = objek', 'に = waktu/tujuan/lokasi keberadaan', 'で = tempat aksi/alat'], [
        _Example('学校で 日本語を 勉強します。', 'がっこうで にほんごを べんきょうします。', 'Saya belajar bahasa Jepang di sekolah.'),
      ]),
      _Topic('Verb Forms Starter', 'Masu, te, nai, ta dasar', 'verb forms', 'Membuat jembatan dari bentuk ます ke bentuk lain secara bertahap dan konsisten.', 'Bisa mengenali transformasi kata kerja dasar.', ['ます → て', 'ます → ない', 'ます → た'], [
        _Example('たべます → たべて', 'たべます → たべて', 'Makan → bentuk て'),
      ]),
      _Topic('Counters & Quantities', 'Kata bantu bilangan', 'counters', 'Latihan hitungan yang benar untuk benda, orang, waktu dan frekuensi.', 'Bisa menyebut jumlah sederhana dengan counter yang tepat.', ['～人', '～本', '～枚', '～個'], [
        _Example('りんごを 三つ ください。', 'りんごを みっつ ください。', 'Tolong tiga buah apel.'),
      ]),
      _Topic('Polite Conversation', 'Sopan santun dasar', 'polite conversation', 'Menyelaraskan bentuk bahasa dengan konteks interaksi agar pengguna tidak hanya hafal grammar.', 'Bisa mempertahankan percakapan sopan sederhana.', ['おはようございます', 'ありがとうございます', 'よろしく おねがいします'], [
        _Example('よろしく おねがいします。', 'よろしく おねがいします。', 'Mohon bantuannya / salam kerja sama.'),
      ]),
      _Topic('N5 Reading Stories', 'Narasi pendek', 'reading stories', 'Membaca narasi sangat pendek dengan tokoh, waktu, tempat, dan urutan kejadian.', 'Bisa menemukan siapa, kapan, di mana, dan apa yang terjadi.', ['だれ', 'いつ', 'どこ', 'なにをした'], [
        _Example('きのう ともだちと えいがを みました。', 'きのう ともだちと えいがを みました。', 'Kemarin saya menonton film bersama teman.'),
      ]),
      _Topic('N5 Listening Dialogues', 'Percakapan terarah', 'dialogues', 'Menyatukan grammar, kosakata dan listening dalam dialog pendek dengan tujuan yang jelas.', 'Bisa mengikuti percakapan pendek sampai ke keputusan akhirnya.', ['permintaan', 'jawaban', 'konfirmasi'], [
        _Example('はい、わかりました。', 'はい、わかりました。', 'Baik, saya mengerti.'),
      ]),
    ],
    'N4': [
      _Topic('Plain Forms & Verb Control', 'Bentuk biasa', 'plain forms', 'Meningkatkan kelancaran dari bentuk sopan menuju bentuk biasa yang dibutuhkan pada bacaan dan percakapan.', 'Bisa berpindah antara bentuk sopan dan biasa.', ['V-る／V-ない／V-た', 'Aい／Aな + plain', 'Nだ／Nじゃない'], [
        _Example('今日は ひまだから、えいがを みます。', 'きょうは ひまだから、えいがを みます。', 'Karena hari ini senggang, saya menonton film.'),
      ]),
      _Topic('Reasons & Explanations', 'んです・ので・から', 'explanations', 'Membedakan cara memberi alasan dan nuansa penjelasan yang lebih natural.', 'Bisa menjelaskan alasan tanpa terdengar kaku.', ['んです', 'ので', 'から'], [
        _Example('どうして おくれたんですか。', 'どうして おくれたんですか。', 'Kenapa terlambat?'),
      ]),
      _Topic('Potential & Ability', 'Bentuk potensial', 'potential', 'Mengubah kata kerja ke bentuk potensial dan menggunakannya pada kemampuan praktis.', 'Bisa mengatakan bisa/tidak bisa melakukan sesuatu.', ['可能形', '～ことができます', 'が + potential ability'], [
        _Example('漢字が 読めます。', 'かんじが よめます。', 'Saya bisa membaca kanji.'),
      ]),
      _Topic('Plans & Intentions', 'つもり・予定・ようと思う', 'plans', 'Membentuk rencana dan niat dengan tingkat kepastian yang berbeda.', 'Bisa membedakan rencana pasti dan niat pribadi.', ['つもり', '予定', 'ようと思う'], [
        _Example('来月 日本へ 行く予定です。', 'らいげつ にほんへ いくよていです。', 'Bulan depan saya berencana pergi ke Jepang.'),
      ]),
      _Topic('Preparation & Completion', 'ておく・てある・てしまう', 'completion', 'Memahami nuansa persiapan, keadaan hasil, dan tindakan yang terlanjur/selesai.', 'Bisa menjelaskan keadaan hasil atau persiapan.', ['V-ておく', 'V-てある', 'V-てしまう'], [
        _Example('ホテルを 予約しておきます。', 'ホテルを よやくしておきます。', 'Saya akan memesan hotel terlebih dahulu.'),
      ]),
      _Topic('Conditionals', 'たら・なら・ば・と', 'conditionals', 'Membandingkan empat pola kondisional berdasarkan hubungan sebab-akibat dan konteks.', 'Bisa memilih conditional yang paling natural.', ['たら', 'なら', 'ば', 'と'], [
        _Example('雨だったら、行きません。', 'あめだったら、いきません。', 'Kalau hujan, saya tidak pergi.'),
      ]),
      _Topic('Permission & Obligation', 'Izin dan kewajiban', 'permission obligation', 'Menggunakan larangan, izin, kewajiban dan pengecualian.', 'Bisa memahami aturan dan menyampaikan kewajiban.', ['てもいい', 'てはいけない', 'なければならない'], [
        _Example('ここで 写真を とっても いいですか。', 'ここで しゃしんを とっても いいですか。', 'Bolehkah mengambil foto di sini?'),
      ]),
      _Topic('Giving & Receiving', 'あげる・くれる・もらう', 'giving receiving', 'Memahami arah pemberian dan sudut pandang penutur.', 'Bisa menjelaskan siapa memberi kepada siapa.', ['あげる', 'くれる', 'もらう'], [
        _Example('友だちが 本を くれました。', 'ともだちが ほんを くれました。', 'Teman memberi saya buku.'),
      ]),
      _Topic('Passive & Transitivity', '受身・自他動詞', 'passive transitivity', 'Memperkenalkan pasif dan pasangan verba transitif-intransitif melalui situasi konkret.', 'Bisa membedakan pelaku, objek dan perubahan keadaan.', ['受身', '自動詞・他動詞', '～ています untuk keadaan'], [
        _Example('ドアが 開きました。', 'ドアが あきました。', 'Pintunya terbuka.'),
      ]),
      _Topic('Relative Clauses', 'Klausa relatif', 'relative clauses', 'Membangun noun phrase yang lebih panjang untuk membaca teks menengah.', 'Bisa memahami noun yang dijelaskan oleh klausa di depannya.', ['plain clause + noun', 'modifier before noun'], [
        _Example('昨日 買った 本', 'きのう かった ほん', 'Buku yang dibeli kemarin.'),
      ]),
      _Topic('Connectors & Contrast', 'し・ので・のに・けれど', 'connectors contrast', 'Mengikat beberapa kalimat menjadi alasan, tambahan atau kontras.', 'Bisa membuat jawaban dan paragraf lebih koheren.', ['し', 'ので', 'のに', 'けれど'], [
        _Example('安いし、おいしいです。', 'やすいし、おいしいです。', 'Murah dan juga enak.'),
      ]),
      _Topic('Change & Appearance', 'ようになる・そう', 'change appearance', 'Menyatakan perubahan kemampuan, kebiasaan, keadaan, dan penampakan.', 'Bisa menjelaskan perubahan dari waktu ke waktu.', ['ようになる', 'ことになる', 'そうだ'], [
        _Example('日本語が 話せるように なりました。', 'にほんごが はなせるように なりました。', 'Saya menjadi bisa berbicara bahasa Jepang.'),
      ]),
      _Topic('N4 Workplace Basics', 'Bahasa kerja dasar', 'workplace', 'Membuat jembatan menuju bahasa kerja: permintaan, laporan singkat, jadwal dan etika dasar.', 'Bisa berkomunikasi di lingkungan kerja sederhana.', ['お願いします', '確認します', '少々お待ちください'], [
        _Example('確認してから ご連絡します。', 'かくにんしてから ごれんらくします。', 'Saya akan menghubungi setelah memeriksa.'),
      ]),
      _Topic('N4 Reading Stories', 'Narasi menengah', 'reading stories', 'Melatih identifikasi urutan, sebab, tokoh dan perubahan keadaan dalam bacaan pendek.', 'Bisa merangkum isi utama sebuah cerita.', ['urutan kejadian', 'sebab-akibat', 'perubahan tokoh'], [
        _Example('そのあと、駅へ 行きました。', 'そのあと、えきへ いきました。', 'Setelah itu, saya pergi ke stasiun.'),
      ]),
      _Topic('N4 Listening Situations', 'Situasi nyata', 'listening situations', 'Melatih informasi tersurat dan maksud sederhana dalam pengumuman, telepon dan percakapan.', 'Bisa menangkap tujuan pembicara.', ['apa', 'kapan', 'apa yang diminta'], [
        _Example('会議は 三時からです。', 'かいぎは さんじからです。', 'Rapat mulai pukul tiga.'),
      ]),
      _Topic('N4 Review Weakness', 'Review personal', 'review weakness', 'Bab review yang menyatukan grammar, vocabulary, kanji, reading dan listening berdasarkan error paling sering.', 'Bisa memperbaiki kesalahan berulang sebelum naik level.', ['weakest skill', 'mistake frequency', 'retrieval'], [
        _Example('もう一度 やってみましょう。', 'もういちど やってみましょう。', 'Mari coba sekali lagi.'),
      ]),
    ],
    'N3': [
      _Topic('Inference & Probability', 'ようだ・らしい・みたい・はず', 'inference', 'Menyatakan dugaan, bukti tidak langsung, kesan dan ekspektasi.', 'Bisa membedakan tingkat kepastian dan sumber informasi.', ['ようだ', 'らしい', 'みたい', 'はず'], [_Example('彼は もう 帰ったようです。', 'かれは もう かえったようです。', 'Sepertinya dia sudah pulang.')]),
      _Topic('Complex Conditions', 'Syarat kompleks', 'complex conditions', 'Kondisional kompleks untuk hipotesis dan kondisi pembatas.', 'Bisa membaca hubungan kondisi pada teks menengah.', ['としたら', 'ものなら', 'ないことには'], [_Example('もし 本当だとしたら、問題です。', 'もし ほんとうだとしたら、もんだいです。', 'Kalau memang benar, itu masalah.')]),
      _Topic('Cause & Result', 'Sebab dan akibat', 'causality', 'Menyusun alasan, latar, dampak dan hasil pada paragraf lebih panjang.', 'Bisa mengikuti rantai sebab-akibat.', ['ため', 'ことから', '結果'], [_Example('大雨のため、電車が 遅れました。', 'おおあめのため、でんしゃが おくれました。', 'Kereta terlambat karena hujan lebat.')]),
      _Topic('Contrast & Concession', 'Kontras dan konsesi', 'contrast', 'Menangani hubungan “meskipun”, “namun”, dan perubahan ekspektasi.', 'Bisa mengenali argumen yang berlawanan.', ['のに', 'にもかかわらず', 'それでも'], [_Example('努力したのに、結果が 出ませんでした。', 'どりょくしたのに、けっかが でませんでした。', 'Meskipun berusaha, hasilnya tidak keluar.')]),
      _Topic('Purpose & Means', 'Tujuan dan cara', 'purpose means', 'Menghubungkan tujuan dengan sarana dan perubahan hasil.', 'Bisa menjelaskan tujuan serta cara mencapai sesuatu.', ['ために', 'ように', 'によって'], [_Example('忘れないように、メモします。', 'わすれないように、メモします。', 'Saya mencatat agar tidak lupa.')]),
      _Topic('Change & Trends', 'Perubahan dan tren', 'trends', 'Membaca perubahan bertahap dan kecenderungan dalam berita atau laporan sederhana.', 'Bisa menjelaskan tren utama.', ['につれて', 'にしたがって', '傾向'], [_Example('人口が 増えるにつれて、町も 変わりました。', 'じんこうが ふえるにつれて、まちも かわりました。', 'Seiring populasi bertambah, kota juga berubah.')]),
      _Topic('Passive & Causative', 'Pasif dan kausatif', 'causative', 'Menguasai 受身・使役 dan menggabungkannya dengan konteks sosial yang realistis.', 'Bisa mengidentifikasi peran pelaku dan pihak yang terdampak.', ['受身', '使役', '使役受身'], [_Example('先生に ほめられました。', 'せんせいに ほめられました。', 'Saya dipuji guru.')]),
      _Topic('Reported Speech', 'Pelaporan informasi', 'reported speech', 'Membedakan kutipan langsung, laporan, rumor dan informasi yang belum diverifikasi.', 'Bisa mengikuti siapa mengatakan apa.', ['という', 'と言われている', 'そうだ'], [_Example('来週は 忙しいと 言っていました。', 'らいしゅうは いそがしいと いっていました。', 'Dia bilang minggu depan sibuk.')]),
      _Topic('Abstract Nouns', 'わけ・もの・こと・はず', 'abstract grammar', 'Mengubah kalimat menjadi konsep dan alasan yang lebih abstrak.', 'Bisa memahami noun abstrak yang sering muncul di bacaan.', ['わけ', 'もの', 'こと', 'はず'], [_Example('そんなはずは ありません。', 'そんなはずは ありません。', 'Tidak mungkin seperti itu.')]),
      _Topic('Formal Reading', 'Eksposisi dan argumentasi', 'formal reading', 'Membaca paragraf eksposisi dan menemukan gagasan utama, bukti, serta kesimpulan.', 'Bisa memetakan struktur argumentasi pendek.', ['main claim', 'support', 'conclusion'], [_Example('一方で、別の問題もあります。', 'いっぽうで、べつのもんだいもあります。', 'Di sisi lain, ada masalah lain juga.')]),
      _Topic('Practical Documents', 'Email dan pengumuman', 'documents', 'Membaca email, petunjuk, formulir, pengumuman dan instruksi yang lebih padat.', 'Bisa mengambil tindakan yang diminta dari sebuah dokumen.', ['sender', 'purpose', 'deadline', 'action'], [_Example('ご確認のうえ、ご返信ください。', 'ごかくにんのうえ、ごへんしんください。', 'Mohon periksa lalu balas.')]),
      _Topic('News Listening', 'Berita singkat', 'news listening', 'Menangkap topik, siapa, kapan, apa yang terjadi dan dampak dari berita sederhana.', 'Bisa membuat ringkasan satu sampai dua kalimat.', ['who/what/when', 'cause', 'impact'], [_Example('政府は 新しい制度を 発表しました。', 'せいふは あたらしいせいどを はっぴょうしました。', 'Pemerintah mengumumkan sistem baru.')]),
    ],
    'N2': [
      _Topic('Formal Vocabulary & Collocation', 'Kolokasi profesional', 'formal vocabulary', 'Memperluas leksikon abstrak dan pasangan kata yang lazim dalam bahasa formal.', 'Bisa memilih kombinasi kata yang natural dalam konteks formal.', ['kolokasi', 'register', 'nominal vocabulary'], [_Example('課題を 解決する必要があります。', 'かだいを かいけつする ひつようがあります。', 'Perlu menyelesaikan masalah.')]),
      _Topic('Advanced Connectors', 'Konektor formal', 'connectors', 'Membedakan hubungan tambahan, perbandingan, kesimpulan, dan pergeseran sudut pandang.', 'Bisa mengikuti logika antar kalimat.', ['一方', 'その上', 'したがって', 'つまり'], [_Example('したがって、別の方法が 必要です。', 'したがって、べつのほうほうが ひつようです。', 'Karena itu, diperlukan cara lain.')]),
      _Topic('Nuance & Degree', 'Tingkat dan intensitas', 'nuance', 'Membaca pembatas, penekanan, tingkat, dan ekspresi yang tidak hitam-putih.', 'Bisa menangkap nuansa “sedikit”, “cukup”, “sangat”, dan “hanya”.', ['程度', '限度', '強調'], [_Example('必ずしも 簡単では ありません。', 'かならずしも かんたんでは ありません。', 'Tidak selalu mudah.')]),
      _Topic('Complex Conditions', 'Kondisional formal', 'complex conditions', 'Menangani syarat kompleks pada opini, peraturan, dan penjelasan argumentatif.', 'Bisa menafsirkan syarat pada kalimat panjang.', ['ものなら', 'ないことには', 'ともなると'], [_Example('この条件を 満たさないことには、申請できません。', 'このじょうけんを みたさないことには、しんせいできません。', 'Tanpa memenuhi syarat ini, tidak bisa mengajukan.')]),
      _Topic('Causality & Consequence', 'Dasar keputusan', 'causality', 'Membaca alasan formal, penyebab, dan akibat kebijakan atau keputusan.', 'Bisa menelusuri alasan di balik suatu keputusan.', ['ことから', 'ことによって', '結果として'], [_Example('需要の増加により、価格が 上昇しました。', 'じゅようのぞうかにより、かかくが じょうしょうしました。', 'Harga naik akibat peningkatan permintaan.')]),
      _Topic('Concession & Counterpoint', 'Kontra-argumen', 'counterpoint', 'Membedakan pengakuan, bantahan, dan kontras retoris.', 'Bisa memahami bagian yang mengubah arah argumen.', ['とはいえ', 'ものの', 'にもかかわらず'], [_Example('便利とはいえ、問題も あります。', 'べんりとはいえ、もんだいも あります。', 'Meski praktis, ada masalah juga.')]),
      _Topic('Scope & Limitation', 'Batas dan cakupan', 'scope limits', 'Memahami pembatasan, pengecualian dan generalisasi dalam tulisan formal.', 'Bisa membaca apa yang termasuk dan tidak termasuk.', ['に限らず', 'にすぎない', 'を問わず'], [_Example('年齢を 問わず 利用できます。', 'ねんれいを とわず りようできます。', 'Bisa digunakan tanpa memandang usia.')]),
      _Topic('Evaluation & Judgement', 'Penilaian dan keyakinan', 'judgement', 'Membaca kepastian, keraguan, evaluasi dan kewajaran suatu kesimpulan.', 'Bisa membedakan fakta, inferensi, dan opini.', ['に違いない', 'わけがない', 'ことだ'], [_Example('彼なら 成功するに違いありません。', 'かれなら せいこうするにちがいありません。', 'Kalau dia, pasti berhasil.')]),
      _Topic('Impersonal & Written Style', 'Gaya tulisan impersonal', 'written style', 'Berpindah dari bahasa percakapan ke struktur tulisan formal yang lebih padat.', 'Bisa memahami gaya laporan dan berita.', ['nominalization', 'passive', 'ellipsis'], [_Example('調査の結果、改善が 見られました。', 'ちょうさのけっか、かいぜんが みられました。', 'Hasil survei menunjukkan perbaikan.')]),
      _Topic('Business Email', 'Email profesional', 'business email', 'Mempraktikkan permintaan, penjadwalan, follow-up dan penutupan email profesional.', 'Bisa menulis dan membaca email kerja singkat.', ['件名', '依頼', '確認', '返信'], [_Example('ご確認いただけますと 幸いです。', 'ごかくにんいただけますと さいわいです。', 'Kami akan sangat menghargai konfirmasinya.')]),
      _Topic('News & Editorial', 'Berita dan editorial', 'news editorial', 'Membaca fakta dan opini pada berita/editorial dengan fokus pada posisi penulis.', 'Bisa membedakan fakta, opini, dan evaluasi.', ['fact', 'opinion', 'stance'], [_Example('専門家によれば、影響は 長期化する 可能性があります。', 'せんもんかによれば、えいきょうは ちょうきかする かのうせいがあります。', 'Menurut pakar, dampaknya mungkin berlangsung lama.')]),
      _Topic('Argument & Synthesis', 'Sintesis alasan', 'argument synthesis', 'Menyatukan beberapa paragraf menjadi kesimpulan yang terstruktur.', 'Bisa merangkum posisi utama dari beberapa informasi.', ['claim', 'evidence', 'synthesis'], [_Example('以上の点から、対策が 必要だと 考えられます。', 'いじょうのてんから、たいさくが ひつようだと かんがえられます。', 'Dari poin-poin di atas, langkah penanganan dianggap perlu.')]),
    ],
    'N1': [
      _Topic('High-Level Vocabulary', 'Kosakata abstrak dan register', 'advanced vocabulary', 'Memperluas kosakata abstrak yang umum pada esai, opini, laporan, dan diskusi tingkat lanjut.', 'Bisa memahami makna kata berdasarkan konteks, register dan kolokasi.', ['抽象語彙', 'collocation', 'register'], [_Example('事態は 深刻さを 増しています。', 'じたいは しんこくさを ましています。', 'Situasinya semakin serius.')]),
      _Topic('Idioms & Fixed Expressions', 'Idiom dan ungkapan tetap', 'idioms', 'Membaca ungkapan idiomatis dan ekspresi tetap tanpa menerjemahkan secara literal.', 'Bisa menafsirkan idiom dari konteks.', ['idiom', '四字熟語', 'fixed expressions'], [_Example('一筋縄では いきません。', 'ひとすじなわでは いきません。', 'Tidak bisa diselesaikan dengan cara sederhana.')]),
      _Topic('Fine-Grained Nuance', 'Perbedaan makna halus', 'fine nuance', 'Membedakan sinonim yang dekat berdasarkan sikap, kekuatan, formalitas dan implikasi.', 'Bisa memilih kata berdasarkan nuansa bukan sekadar kamus.', ['synonym contrast', 'stance', 'implication'], [_Example('単に 結果だけを 見るべきでは ありません。', 'たんに けっかだけを みるべきでは ありません。', 'Tidak seharusnya hanya melihat hasilnya.')]),
      _Topic('Advanced Conditionals', 'Kondisional tingkat lanjut', 'advanced conditions', 'Membaca framing hipotetis dan syarat yang digunakan untuk menimbang alternatif.', 'Bisa mengikuti argumen bersyarat kompleks.', ['としたら', 'ものなら', 'かりに'], [_Example('仮に そうだとしたら、前提から 見直す必要があります。', 'かりに そうだとしたら、ぜんていから みなおすひつようがあります。', 'Kalau anggapannya begitu, kita perlu meninjau ulang premisnya.')]),
      _Topic('Concession & Rhetoric', 'Retorika dan konsesi', 'rhetoric', 'Menganalisis kalimat yang mengakui poin lawan lalu mengarahkan pembaca ke kesimpulan baru.', 'Bisa mengikuti gerak retoris dalam esai.', ['とはいうものの', 'もっとも', 'とはいえ'], [_Example('もっとも、それだけで 判断するのは 早計です。', 'もっとも、それだけで はんだんするのは そうけいです。', 'Namun, terlalu dini menilai hanya berdasarkan itu.')]),
      _Topic('Inference & Implication', 'Makna tersirat', 'inference', 'Menggali implikasi, asumsi, dan informasi yang sengaja tidak dinyatakan secara langsung.', 'Bisa menyimpulkan maksud yang tersirat.', ['implication', 'presupposition', 'inference'], [_Example('彼の沈黙は、賛成を 意味しているとは 限りません。', 'かれのちんもくは、さんせいを いみしているとは かぎりません。', 'Diamnya tidak berarti ia setuju.')]),
      _Topic('Writer Attitude', 'Sikap penulis', 'writer attitude', 'Mendeteksi tingkat keyakinan, skeptisisme, kritik, kehati-hatian dan evaluasi penulis.', 'Bisa mengidentifikasi posisi penulis terhadap topik.', ['certainty', 'hedging', 'critique'], [_Example('必ずしも 妥当だとは 言い切れません。', 'かならずしも だとうだとは いいきれません。', 'Tidak bisa dikatakan sepenuhnya tepat.')]),
      _Topic('Academic Register', 'Register akademik', 'academic', 'Memahami gaya bahasa akademik/profesional, nominalisasi, pasif dan struktur argumentasi yang padat.', 'Bisa membaca paragraf akademik dengan strategi skimming dan scanning.', ['nominalization', 'formal connective', 'objective tone'], [_Example('本研究は、影響を 明らかにすることを 目的とします。', 'ほんけんきゅうは、えいきょうを あきらかにすることを もくてきとします。', 'Penelitian ini bertujuan memperjelas dampaknya.')]),
      _Topic('Editorial Reading', 'Editorial dan kritik', 'editorial', 'Menganalisis klaim, bukti, sanggahan, dan asumsi dalam tulisan opini.', 'Bisa memetakan struktur editorial secara kritis.', ['claim', 'counterargument', 'evidence'], [_Example('この見解には、なお 検討の余地が あります。', 'このけんかいには、なお けんとうのよちがあります。', 'Pandangan ini masih memiliki ruang untuk dikaji.')]),
      _Topic('Technical & Policy Texts', 'Teknis dan kebijakan', 'technical', 'Membaca dokumen teknis dan kebijakan yang menuntut akurasi istilah dan hubungan logis.', 'Bisa menemukan ketentuan, pengecualian dan implikasi kebijakan.', ['scope', 'exception', 'definition'], [_Example('原則として、申請は オンラインで 行うものとします。', 'げんそくとして、しんせいは オンラインで おこなうものとします。', 'Pada prinsipnya, pengajuan dilakukan secara daring.')]),
      _Topic('Fast Natural Listening', 'Listening cepat natural', 'natural listening', 'Meningkatkan ketahanan terhadap kecepatan bicara, reduksi bunyi dan ide yang saling bertumpuk.', 'Bisa menangkap struktur utama tanpa memahami seluruh kata.', ['keyword listening', 'discourse markers', 'speaker stance'], [_Example('まあ、そういう見方も できなくは ないですね。', 'まあ、そういうみかたも できなくは ないですね。', 'Yah, pandangan seperti itu juga bukan tidak mungkin.')]),
      _Topic('Debate & Discussion', 'Debat dan diskusi', 'debate', 'Melatih setuju, tidak setuju, mengklarifikasi, memberi bukti dan membangun sanggahan.', 'Bisa mempertahankan posisi dalam diskusi terstruktur.', ['agreement', 'counterpoint', 'clarification'], [_Example('その点については、別の角度から 考える必要があります。', 'そのてんについては、べつのかくどから かんがえるひつようがあります。', 'Mengenai hal itu, perlu dipertimbangkan dari sudut lain.')]),
      _Topic('Summary & Synthesis', 'Ringkasan dan sintesis', 'synthesis', 'Menyatukan informasi dari beberapa bagian teks dan membangun ringkasan yang tidak sekadar menyalin.', 'Bisa menyintesis informasi dengan mempertahankan inti dan nuansa.', ['main idea', 'supporting detail', 'synthesis'], [_Example('要するに、問題の核心は 資源配分に あります。', 'ようするに、もんだいのかくしんは しげんはいぶんに あります。', 'Singkatnya, inti masalahnya terletak pada alokasi sumber daya.')]),
    ],
  };
}

class _Topic {
  const _Topic(
    this.title,
    this.subtitle,
    this.tag,
    this.description,
    this.goal,
    this.patterns,
    this.examples,
  );

  final String title;
  final String subtitle;
  final String tag;
  final String description;
  final String goal;
  final List<String> patterns;
  final List<_Example> examples;

  // Backward-compatible alias for code that still refers to the field
  // as `explanation`. Keeping the canonical field as `description` prevents
  // duplicate curriculum text while allowing older callers to compile.
  String get explanation => description;
}

class _Example {
  const _Example(this.japanese, this.reading, this.meaning);
  final String japanese;
  final String reading;
  final String meaning;
}
