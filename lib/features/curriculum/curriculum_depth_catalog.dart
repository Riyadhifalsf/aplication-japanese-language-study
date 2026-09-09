import 'curriculum_models.dart';

/// Deep, original chapter blueprints used to extend each JLPT level.
/// Each chapter is deliberately content-heavy: six lessons, explanations,
/// examples, guided practice, listening/reading, recall and a checkpoint.
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
    ) => LessonActivity(
          id: id,
          type: type,
          title: title,
          description: description,
          estimatedMinutes: minutes,
          contentRef: 'level:$level;theme:${topic.tag}',
          routeHint: type.name,
        );

    CurriculumLesson lesson(int n, String title) {
      final lid = '$uid-l${n.toString().padLeft(2, '0')}';
      final focus = switch (n) {
        1 => 'Pahami konsep, bentuk, arti, dan kapan pola ini dipakai.',
        2 => 'Latihan terarah: kenali pola lalu ubah satu unsur kalimat.',
        3 => 'Bandingkan contoh yang benar dan yang terasa tidak alami.',
        4 => 'Gunakan materi dalam dialog atau teks kehidupan nyata.',
        5 => 'Recall aktif tanpa melihat catatan, lalu periksa jawaban.',
        _ => 'Review terpadu dan checkpoint sebelum pindah bab.',
      };
      final contextType = n.isEven
          ? CurriculumActivityType.listening
          : CurriculumActivityType.reading;
      final lines = _examples(level, topic, n);
      final notes = <LessonNote>[
        LessonNote(
          title: 'Penjelasan inti',
          body:
              '${topic.subtitle}. $focus ${topic.description} Pelajari bentuk Jepang terlebih dahulu, kemudian cek romaji dan arti. Setelah itu coba buat satu kalimat baru sendiri.',
          lines: lines,
        ),
        LessonNote(
          title: 'Cara memakai materi',
          body:
              '1) Baca contoh Jepang. 2) Ucapkan pelan. 3) Tutup arti. 4) Jelaskan maksudnya. 5) Ganti satu kata dan ulangi. Jangan hanya menghafal terjemahan; perhatikan pola dan konteks.',
        ),
        LessonNote(
          title: 'Latihan mandiri',
          body:
              'Buat minimal tiga kalimat baru menggunakan pola bab ini. Untuk listening, dengarkan TTS dua kali: pertama untuk menangkap gambaran umum, kedua untuk menangkap kata kunci. Untuk reading, cari siapa, apa, kapan, di mana, dan alasan bila tersedia.',
        ),
        if (n >= 3)
          LessonNote(
            title: 'Kesalahan yang perlu dihindari',
            body:
                'Jangan menerjemahkan kata demi kata dari bahasa Indonesia. Cocokkan partikel, bentuk kata, dan tingkat kesopanan dengan situasi. Bila dua pola mirip, pilih berdasarkan maksud pembicara.',
          ),
        if (n >= 5)
          LessonNote(
            title: 'Checkpoint',
            body:
                'Sebelum menekan Lanjut, pastikan dapat menjelaskan fungsi pola ini dengan kalimat sendiri, mengenali contoh saat dibaca/didengar, dan memperbaiki setidaknya satu kesalahan umum.',
          ),
      ];

      final activities = <LessonActivity>[
        activity(
          '$lid-a1',
          n == 1 ? CurriculumActivityType.grammar : CurriculumActivityType.vocabulary,
          n == 1 ? 'Pelajari konsep' : 'Aktifkan kosakata',
          'Penjelasan langkah demi langkah + contoh Jepang, romaji, dan arti.',
          10,
        ),
        activity(
          '$lid-a2',
          n == 2 || n == 5
              ? CurriculumActivityType.writing
              : CurriculumActivityType.exampleSentences,
          n == 2 || n == 5 ? 'Latihan produksi' : 'Bedah contoh',
          'Ubah bagian kalimat, susun ulang, dan cek apakah maknanya tetap tepat.',
          10,
        ),
        activity(
          '$lid-a3',
          contextType,
          contextType == CurriculumActivityType.reading
              ? 'Reading kontekstual'
              : 'Listening kontekstual',
          'Teks/dialog bertahap dengan pertanyaan pemahaman dan kata kunci.',
          10,
        ),
        activity(
          '$lid-a4',
          CurriculumActivityType.quiz,
          'Kuis retrieval',
          'Soal pilihan ganda, susun kalimat, dan pemilihan konteks.',
          8,
        ),
        if (n >= 3)
          activity(
            '$lid-a5',
            CurriculumActivityType.review,
            'Review kesalahan',
            'Periksa kesalahan yang paling sering muncul dan kerjakan ulang.',
            6,
          ),
      ];

      return CurriculumLesson(
        id: lid,
        unitId: uid,
        levelId: level,
        sequence: n,
        title: title,
        subtitle: switch (n) {
          1 => 'Konsep + Contoh + Fondasi',
          2 => 'Latihan Terarah + Produksi',
          3 => 'Perbandingan + Nuansa',
          4 => 'Dialog + Reading/Listening',
          5 => 'Recall Aktif + Quiz',
          _ => 'Review + Checkpoint',
        },
        objectives: [
          'Memahami ${topic.title.toLowerCase()} dalam konteks.',
          'Menghasilkan kalimat atau respons baru, bukan sekadar menyalin.',
          'Membedakan penggunaan yang tepat dari pola yang mirip.',
          if (n >= 4) 'Memahami informasi utama dari teks atau audio.',
        ],
        activities: activities,
        notes: notes,
        estimatedMinutes: n >= 3 ? 44 : 38,
      );
    }

    final lessons = [
      lesson(1, '${topic.title} — Fondasi'),
      lesson(2, '${topic.title} — Latihan Terarah'),
      lesson(3, '${topic.title} — Bedakan & Pahami'),
      lesson(4, '${topic.title} — Konteks Nyata'),
      lesson(5, '${topic.title} — Recall Aktif'),
      lesson(6, '${topic.title} — Review & Checkpoint'),
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

  static List<LessonLine> _examples(
    String level,
    _Topic topic,
    int lessonNumber,
  ) {
    final examples = _exampleMap[topic.tag];
    if (examples != null && examples.isNotEmpty) {
      return examples
          .map(
            (e) => LessonLine(
              japanese: e.$1,
              reading: e.$2,
              meaning: e.$3,
            ),
          )
          .toList();
    }
    return [
      LessonLine(
        japanese: '${topic.examplePrefix}です。',
        reading: topic.exampleReading,
        meaning: topic.exampleMeaning,
      ),
      LessonLine(
        japanese: '${topic.examplePrefix}ではありません。',
        reading: '${topic.exampleReading} dewa arimasen.',
        meaning: 'Bentuk negatif sebagai contoh perubahan pola.',
      ),
      LessonLine(
        japanese: '${topic.examplePrefix}は どうですか。',
        reading: '${topic.exampleReading} wa dou desu ka.',
        meaning: 'Bagaimana tentang ${topic.exampleMeaning.toLowerCase()}?',
      ),
      LessonLine(
        japanese: 'もういちど おねがいします。',
        reading: 'Mou ichido onegaishimasu.',
        meaning: 'Tolong sekali lagi.',
      ),
    ];
  }

  static const Map<String, List<(String, String, String)>> _exampleMap = {
    'family people relationships': [
      ('わたしの かぞくは 4人です。', 'Watashi no kazoku wa yonin desu.', 'Keluarga saya terdiri dari empat orang.'),
      ('ちちは 会社員です。', 'Chichi wa kaishain desu.', 'Ayah saya karyawan perusahaan.'),
      ('あには 大学生です。', 'Ani wa daigakusei desu.', 'Kakak laki-laki saya mahasiswa.'),
      ('ともだちと いっしょに 勉強します。', 'Tomodachi to issho ni benkyou shimasu.', 'Belajar bersama teman.'),
    ],
    'things ownership': [
      ('これは わたしの かばんです。', 'Kore wa watashi no kaban desu.', 'Ini tas saya.'),
      ('その かさは だれのですか。', 'Sono kasa wa dare no desu ka.', 'Payung itu milik siapa?'),
      ('この ほんを かしてください。', 'Kono hon o kashite kudasai.', 'Tolong pinjamkan buku ini.'),
      ('あれは せんせいの つくえです。', 'Are wa sensei no tsukue desu.', 'Itu meja guru.'),
    ],
    'places directions': [
      ('えきは どこですか。', 'Eki wa doko desu ka.', 'Stasiun di mana?'),
      ('ぎんこうは えきの となりです。', 'Ginkou wa eki no tonari desu.', 'Bank berada di sebelah stasiun.'),
      ('まっすぐ いってください。', 'Massugu itte kudasai.', 'Silakan jalan lurus.'),
      ('みぎに まがってください。', 'Migi ni magatte kudasai.', 'Silakan belok kanan.'),
    ],
    'time schedule': [
      ('7時に おきます。', 'Shichi-ji ni okimasu.', 'Bangun pukul tujuh.'),
      ('月曜日に 学校へ いきます。', 'Getsuyoubi ni gakkou e ikimasu.', 'Pergi ke sekolah pada hari Senin.'),
      ('毎日 日本語を 勉強します。', 'Mainichi nihongo o benkyou shimasu.', 'Belajar bahasa Jepang setiap hari.'),
      ('三時から 五時まで 勉強します。', 'San-ji kara go-ji made benkyou shimasu.', 'Belajar dari pukul tiga sampai lima.'),
    ],
    'transport': [
      ('電車で 学校へ いきます。', 'Densha de gakkou e ikimasu.', 'Pergi ke sekolah naik kereta.'),
      ('バスに のります。', 'Basu ni norimasu.', 'Naik bus.'),
      ('駅で 友だちに あいます。', 'Eki de tomodachi ni aimasu.', 'Bertemu teman di stasiun.'),
      ('何時に つきますか。', 'Nanji ni tsukimasu ka.', 'Tiba pukul berapa?'),
    ],
    'food shopping': [
      ('ラーメンを ひとつ おねがいします。', 'Raamen o hitotsu onegaishimasu.', 'Minta satu ramen.'),
      ('これは いくらですか。', 'Kore wa ikura desu ka.', 'Berapa harga ini?'),
      ('水を ください。', 'Mizu o kudasai.', 'Tolong beri air.'),
      ('これを ください。', 'Kore o kudasai.', 'Saya mau yang ini.'),
    ],
    'routine habits': [
      ('毎朝 6時に おきます。', 'Maiasa roku-ji ni okimasu.', 'Setiap pagi bangun pukul enam.'),
      ('朝ごはんを 食べて、学校へ いきます。', 'Asagohan o tabete, gakkou e ikimasu.', 'Sarapan lalu pergi ke sekolah.'),
      ('夜 日本語を べんきょうします。', 'Yoru nihongo o benkyou shimasu.', 'Belajar bahasa Jepang pada malam hari.'),
      ('週末は うちで 休みます。', 'Shuumatsu wa uchi de yasumimasu.', 'Akhir pekan beristirahat di rumah.'),
    ],
    'adjectives': [
      ('この へやは ひろいです。', 'Kono heya wa hiroi desu.', 'Kamar ini luas.'),
      ('この まちは しずかです。', 'Kono machi wa shizuka desu.', 'Kota ini tenang.'),
      ('きのうは あつくなかったです。', 'Kinou wa atsuku nakatta desu.', 'Kemarin tidak panas.'),
      ('どんな たべものが すきですか。', 'Donna tabemono ga suki desu ka.', 'Makanan seperti apa yang disukai?'),
    ],
    'preferences ability': [
      ('日本語が すきです。', 'Nihongo ga suki desu.', 'Suka bahasa Jepang.'),
      ('すしが すきではありません。', 'Sushi ga suki dewa arimasen.', 'Tidak suka sushi.'),
      ('ひらがなが よめます。', 'Hiragana ga yomemasu.', 'Bisa membaca hiragana.'),
      ('日本語が すこし はなせます。', 'Nihongo ga sukoshi hanasemasu.', 'Bisa berbicara bahasa Jepang sedikit.'),
    ],
    'requests invitations': [
      ('ちょっと まってください。', 'Chotto matte kudasai.', 'Tolong tunggu sebentar.'),
      ('いっしょに たべませんか。', 'Issho ni tabemasen ka.', 'Mau makan bersama?'),
      ('ここで しゃしんを とっても いいですか。', 'Koko de shashin o totte mo ii desu ka.', 'Bolehkah mengambil foto di sini?'),
      ('すみません、もういちど おねがいします。', 'Sumimasen, mou ichido onegaishimasu.', 'Maaf, tolong sekali lagi.'),
    ],
    'experience plans': [
      ('日本へ いったことが あります。', 'Nihon e itta koto ga arimasu.', 'Pernah pergi ke Jepang.'),
      ('らいげつ 旅行する つもりです。', 'Raigetsu ryokou suru tsumori desu.', 'Bulan depan berniat bepergian.'),
      ('日曜日に 友だちに あう よていです。', 'Nichiyoubi ni tomodachi ni au yotei desu.', 'Berencana bertemu teman hari Minggu.'),
      ('もっと 日本語を 勉強したいです。', 'Motto nihongo o benkyou shitai desu.', 'Ingin belajar bahasa Jepang lebih banyak.'),
    ],
    'weather health': [
      ('今日は いい てんきです。', 'Kyou wa ii tenki desu.', 'Hari ini cuacanya bagus.'),
      ('あたまが いたいです。', 'Atama ga itai desu.', 'Kepala saya sakit.'),
      ('くすりを のんでください。', 'Kusuri o nonde kudasai.', 'Silakan minum obat.'),
      ('あしたは あめが ふるでしょう。', 'Ashita wa ame ga furu deshou.', 'Besok mungkin akan hujan.'),
    ],
    'reading': [
      ('スーパーは 9時から 8時までです。', 'Suupaa wa ku-ji kara hachi-ji made desu.', 'Supermarket buka dari jam sembilan sampai delapan.'),
      ('日曜日は やすみです。', 'Nichiyoubi wa yasumi desu.', 'Hari Minggu libur.'),
      ('入口は こちらです。', 'Iriguchi wa kochira desu.', 'Pintu masuk di sini.'),
      ('この おしらせを よんでください。', 'Kono oshirase o yonde kudasai.', 'Silakan baca pengumuman ini.'),
    ],
    'listening': [
      ('もしもし、田中さんですか。', 'Moshi moshi, Tanaka-san desu ka.', 'Halo, apakah ini Tanaka?'),
      ('はい、そうです。', 'Hai, sou desu.', 'Ya, benar.'),
      ('今から 駅へ いきます。', 'Ima kara eki e ikimasu.', 'Sekarang saya pergi ke stasiun.'),
      ('じゃあ、また あした。', 'Jaa, mata ashita.', 'Kalau begitu, sampai besok.'),
    ],
    'plain forms': [
      ('毎日 日本語を 勉強する。', 'Mainichi nihongo o benkyou suru.', 'Belajar bahasa Jepang setiap hari. (bentuk biasa)'),
      ('きのう 学校へ いかなかった。', 'Kinou gakkou e ikanakatta.', 'Kemarin tidak pergi ke sekolah.'),
      ('この 本は おもしろい。', 'Kono hon wa omoshiroi.', 'Buku ini menarik.'),
      ('明日は ひまじゃない。', 'Ashita wa hima janai.', 'Besok tidak senggang.'),
    ],
    'explanations': [
      ('どうして おくれたんですか。', 'Doushite okuretandesu ka.', 'Kenapa terlambat?'),
      ('でんしゃが おくれたんです。', 'Densha ga okuretandesu.', 'Karena keretanya terlambat.'),
      ('時間が なかったので、いきませんでした。', 'Jikan ga nakatta node, ikimasen deshita.', 'Karena tidak punya waktu, saya tidak pergi.'),
      ('雨だったからです。', 'Ame datta kara desu.', 'Karena hujan.'),
    ],
    'potential': [
      ('漢字が よめます。', 'Kanji ga yomemasu.', 'Bisa membaca kanji.'),
      ('日本語で 話せます。', 'Nihongo de hanasemasu.', 'Bisa berbicara dalam bahasa Jepang.'),
      ('ここで 写真が とれます。', 'Koko de shashin ga toremasu.', 'Bisa mengambil foto di sini.'),
      ('明日は 来られないかもしれません。', 'Ashita wa korarenai kamo shiremasen.', 'Besok mungkin tidak bisa datang.'),
    ],
    'plans': [
      ('来年 日本へ いく つもりです。', 'Rainen Nihon e iku tsumori desu.', 'Berniat pergi ke Jepang tahun depan.'),
      ('来週 会う よていです。', 'Raishuu au yotei desu.', 'Berencana bertemu minggu depan.'),
      ('もっと 練習しようと おもいます。', 'Motto renshuu shiyou to omoimasu.', 'Saya pikir akan lebih banyak berlatih.'),
      ('旅行の じゅんびを します。', 'Ryokou no junbi o shimasu.', 'Mempersiapkan perjalanan.'),
    ],
    'completion': [
      ('旅行の 前に ホテルを よやくしておきます。', 'Ryokou no mae ni hoteru o yoyaku shite okimasu.', 'Memesan hotel terlebih dahulu sebelum perjalanan.'),
      ('ドアが あけてあります。', 'Doa ga akete arimasu.', 'Pintu sudah dibuka/ditinggalkan terbuka.'),
      ('宿題を わすれてしまいました。', 'Shukudai o wasurete shimaimashita.', 'Tidak sengaja sampai lupa PR.'),
      ('会議の 前に しりょうを じゅんびしておきます。', 'Kaigi no mae ni shiryou o junbi shite okimasu.', 'Menyiapkan materi terlebih dahulu sebelum rapat.'),
    ],
    'conditionals': [
      ('時間が あったら、いきます。', 'Jikan ga attara, ikimasu.', 'Kalau ada waktu, saya pergi.'),
      ('日本へ いくなら、春が いいです。', 'Nihon e ikunara, haru ga ii desu.', 'Kalau memang pergi ke Jepang, musim semi bagus.'),
      ('ボタンを おすと、ドアが あきます。', 'Botan o osu to, doa ga akimasu.', 'Jika menekan tombol, pintu terbuka.'),
      ('もっと 勉強すれば、じょうずに なります。', 'Motto benkyou sureba, jouzu ni narimasu.', 'Kalau belajar lebih banyak, akan menjadi lebih mahir.'),
    ],
    'permission obligation': [
      ('ここで たべても いいです。', 'Koko de tabete mo ii desu.', 'Boleh makan di sini.'),
      ('ここで しゃしんを とっては いけません。', 'Koko de shashin o totte wa ikemasen.', 'Tidak boleh mengambil foto di sini.'),
      ('あしたまでに ださなければ なりません。', 'Ashita made ni dasanakereba narimasen.', 'Harus menyerahkan sebelum besok.'),
      ('もう かえっても いいですか。', 'Mou kaette mo ii desu ka.', 'Bolehkah saya pulang sekarang?'),
    ],
    'giving receiving': [
      ('友だちに 本を あげました。', 'Tomodachi ni hon o agemashita.', 'Memberi buku kepada teman.'),
      ('友だちが 本を くれました。', 'Tomodachi ga hon o kuremashita.', 'Teman memberi saya buku.'),
      ('先生に 日本語を おしえて もらいました。', 'Sensei ni nihongo o oshiete moraimashita.', 'Mendapat bantuan guru mengajari bahasa Jepang.'),
      ('母に プレゼントを あげます。', 'Haha ni purezento o agemasu.', 'Memberi hadiah kepada ibu.'),
    ],
    'passive transitivity': [
      ('先生に ほめられました。', 'Sensei ni homeraremashita.', 'Dipuji oleh guru.'),
      ('ドアが あきました。', 'Doa ga akimashita.', 'Pintu terbuka.'),
      ('わたしが ドアを あけました。', 'Watashi ga doa o akemashita.', 'Saya membuka pintu.'),
      ('友だちに たすけられました。', 'Tomodachi ni tasukeraremashita.', 'Dibantu oleh teman.'),
    ],
    'nominalization relative': [
      ('日本語を 勉強するのは おもしろいです。', 'Nihongo o benkyou suru no wa omoshiroi desu.', 'Belajar bahasa Jepang itu menarik.'),
      ('本を よむのが すきです。', 'Hon o yomu no ga suki desu.', 'Suka membaca buku.'),
      ('昨日 かった 本を よみました。', 'Kinou katta hon o yomimashita.', 'Membaca buku yang dibeli kemarin.'),
      ('日本で はたらく 人に ききました。', 'Nihon de hataraku hito ni kikimashita.', 'Bertanya kepada orang yang bekerja di Jepang.'),
    ],
    'connectors contrast': [
      ('日本語が すきだし、毎日 勉強しています。', 'Nihongo ga suki dashi, mainichi benkyou shiteimasu.', 'Saya suka bahasa Jepang dan juga belajar setiap hari.'),
      ('雨なので、出かけません。', 'Ame nanode, dekakemasen.', 'Karena hujan, tidak keluar.'),
      ('やすいのに、おいしいです。', 'Yasui noni, oishii desu.', 'Walaupun murah, rasanya enak.'),
      ('いきたいけれど、時間が ありません。', 'Ikitai keredo, jikan ga arimasen.', 'Ingin pergi, tetapi tidak punya waktu.'),
    ],
    'change appearance': [
      ('日本語が すこし はなせるように なりました。', 'Nihongo ga sukoshi hanaseru you ni narimashita.', 'Menjadi bisa berbicara sedikit bahasa Jepang.'),
      ('来月から 東京で はたらくことに なりました。', 'Raigetsu kara Toukyou de hataraku koto ni narimashita.', 'Diputuskan akan bekerja di Tokyo mulai bulan depan.'),
      ('雨が ふりそうです。', 'Ame ga furisou desu.', 'Sepertinya akan hujan.'),
      ('この りょうりは おいしそうです。', 'Kono ryouri wa oishisou desu.', 'Masakan ini terlihat enak.'),
    ],
  };

  static const Map<String, List<_Topic>> _topics = {
    'N5': [
      _Topic('Family & People', 'Keluarga, teman, orang di sekitar', 'family people relationships', 'Materi N5 tentang keluarga dan hubungan sosial dasar.'),
      _Topic('Things & Ownership', 'Benda, kepemilikan, demonstratives', 'things ownership', 'Materi N5 tentang benda, kepemilikan, dan kata penunjuk.'),
      _Topic('Places & Directions', 'Tempat, posisi, arah sederhana', 'places directions', 'Materi N5 tentang lokasi dan arah yang dipakai sehari-hari.'),
      _Topic('Time & Daily Schedule', 'Jam, tanggal, jadwal dan frekuensi', 'time schedule', 'Materi N5 tentang waktu, jadwal, dan frekuensi aktivitas.'),
      _Topic('Going Out & Transport', 'Tujuan, kendaraan, perpindahan', 'transport', 'Materi N5 tentang bepergian dan transportasi.'),
      _Topic('Food & Shopping', 'Menu, harga, ukuran, pesanan', 'food shopping', 'Materi N5 tentang makanan, belanja, harga, dan pesanan.'),
      _Topic('Daily Routines', 'Rutinitas, kebiasaan, urutan aksi', 'routine habits', 'Materi N5 tentang rutinitas dan urutan kegiatan.'),
      _Topic('Adjectives & Description', 'i/na-adjective dan deskripsi', 'adjectives', 'Materi N5 tentang mendeskripsikan orang, benda, tempat, dan kondisi.'),
      _Topic('Likes & Abilities', 'Suka, tidak suka, kemampuan', 'preferences ability', 'Materi N5 tentang preferensi dan kemampuan dasar.'),
      _Topic('Requests & Invitations', 'Permintaan, ajakan, izin', 'requests invitations', 'Materi N5 tentang meminta bantuan, mengajak, dan meminta izin.'),
      _Topic('Experience & Plans', 'Pengalaman, rencana, keinginan', 'experience plans', 'Materi N5 tentang pengalaman dan rencana sederhana.'),
      _Topic('Weather & Health', 'Cuaca, kondisi badan, saran sederhana', 'weather health', 'Materi N5 tentang cuaca, kesehatan, dan respons sederhana.'),
      _Topic('Reading Everyday Texts', 'Pesan, menu, jadwal, pengumuman', 'reading', 'Materi N5 tentang membaca teks pendek kehidupan sehari-hari.'),
      _Topic('Listening Everyday Life', 'Informasi kunci dalam percakapan', 'listening', 'Materi N5 tentang menangkap informasi kunci dalam percakapan.'),
      _Topic('Home & Rooms', 'Rumah, kamar, posisi benda', 'home rooms', 'Materi N5 tentang rumah, ruangan, furnitur, dan posisi benda.'),
      _Topic('School & Study', 'Sekolah, kelas, pelajaran, aktivitas belajar', 'school study', 'Materi N5 tentang sekolah, kelas, pelajaran, dan kebiasaan belajar.'),
      _Topic('Work & Jobs', 'Pekerjaan, tempat kerja, aktivitas sederhana', 'work jobs', 'Materi N5 tentang pekerjaan dan aktivitas di tempat kerja.'),
      _Topic('Clothes & Appearance', 'Pakaian, warna, ukuran, penampilan', 'clothes appearance', 'Materi N5 tentang pakaian, warna, ukuran, dan deskripsi penampilan.'),
      _Topic('Hobbies & Free Time', 'Hobi, akhir pekan, aktivitas santai', 'hobbies leisure', 'Materi N5 tentang hobi dan kegiatan waktu luang.'),
      _Topic('Travel & Hotel', 'Reservasi, check-in, perjalanan', 'travel hotel', 'Materi N5 tentang perjalanan dan situasi hotel sederhana.'),
    ],
    'N4': [
      _Topic('Plain Forms & Verb Control', 'Bentuk biasa, negatif, lampau', 'plain forms', 'Materi N4 tentang perubahan bentuk kata kerja dan kalimat biasa.'),
      _Topic('Reasons & Explanations', 'んです, ので, から', 'explanations', 'Materi N4 tentang menjelaskan alasan dan latar belakang.'),
      _Topic('Potential & Ability', '可能形 dan konteks kemampuan', 'potential', 'Materi N4 tentang kemampuan dan bentuk potensial.'),
      _Topic('Plans & Intentions', 'つもり, 予定, ようと思う', 'plans', 'Materi N4 tentang niat, rencana, dan keputusan.'),
      _Topic('Preparation & Completion', 'ておく, てある, てしまう', 'completion', 'Materi N4 tentang persiapan, keadaan hasil, dan penyelesaian.'),
      _Topic('Conditionals', 'たら, なら, と, ば', 'conditionals', 'Materi N4 tentang berbagai pola kondisi dan konsekuensi.'),
      _Topic('Permission & Obligation', 'てもいい, てはいけない, なければ', 'permission obligation', 'Materi N4 tentang izin, larangan, dan kewajiban.'),
      _Topic('Giving & Receiving', 'あげる, くれる, もらう', 'giving receiving', 'Materi N4 tentang arah tindakan memberi dan menerima.'),
      _Topic('Passive & Transitivity', '受身, 自動詞・他動詞', 'passive transitivity', 'Materi N4 tentang pasif dan pasangan verba transitif/intransitif.'),
      _Topic('Nominalization & Relatives', 'のは, のが, klausa relatif', 'nominalization relative', 'Materi N4 tentang nominalisasi dan klausa yang menerangkan kata benda.'),
      _Topic('Connectors & Contrast', 'し, ので, のに, けれど', 'connectors contrast', 'Materi N4 tentang menghubungkan alasan, tambahan, dan kontras.'),
      _Topic('Change & Appearance', 'ようになる, ことになる, そう', 'change appearance', 'Materi N4 tentang perubahan keadaan dan dugaan dari penampilan.'),
      _Topic('Advice & Suggestions', 'ほうがいい, たほうがいい, なら', 'advice suggestions', 'Materi N4 tentang memberi saran dan memilih opsi.'),
      _Topic('Comparison & Degree', 'より, ほど, いちばん, くらい', 'comparison degree', 'Materi N4 tentang perbandingan dan tingkat.'),
      _Topic('Desire & Emotion', 'ほしい, たい, がる, 感情', 'desire emotion', 'Materi N4 tentang keinginan dan ekspresi emosi.'),
      _Topic('Purpose & Method', 'ために, ように, で, に', 'purpose method', 'Materi N4 tentang tujuan dan cara melakukan sesuatu.'),
      _Topic('Sequence & Simultaneous Actions', 'ながら, あとで, まえに', 'sequence actions', 'Materi N4 tentang urutan dan aksi yang berlangsung bersamaan.'),
      _Topic('Social Situations', 'permintaan sopan, layanan, telepon', 'social situations', 'Materi N4 tentang interaksi sosial dan layanan.'),
      _Topic('Practical Reading', 'petunjuk, formulir, email pendek', 'practical reading', 'Materi N4 tentang dokumen praktis dan instruksi.'),
      _Topic('Everyday Listening', 'percakapan lebih natural', 'everyday listening', 'Materi N4 tentang percakapan dengan informasi tersirat sederhana.'),
      _Topic('Workplace Basics', 'rapat, tugas, laporan sederhana', 'workplace basics', 'Materi N4 tentang komunikasi dasar di tempat kerja.'),
      _Topic('Travel Problems', 'terlambat, hilang, perubahan rencana', 'travel problems', 'Materi N4 tentang menangani masalah saat bepergian.'),
      _Topic('Health & Advice', 'gejala, kunjungan dokter, saran', 'health advice', 'Materi N4 tentang kesehatan dan memberi/menangkap saran.'),
      _Topic('Culture & Customs', 'kebiasaan, aturan, budaya sehari-hari', 'culture customs', 'Materi N4 tentang kebiasaan dan aturan sosial Jepang.'),
      _Topic('N4 Integrated Review', 'review grammar, vocabulary, reading, listening', 'n4 integrated review', 'Review terpadu N4 dengan retrieval practice dan checkpoint.'),
    ],
    'N3': [
      _Topic('Inference & Probability', 'ようだ, らしい, みたい, はず', 'inference', 'Materi N3 tentang dugaan dan probabilitas.'),
      _Topic('Complex Conditions', 'としたら, ものなら, ないことには', 'conditions', 'Materi N3 tentang kondisi kompleks.'),
      _Topic('Cause & Result', 'ため, ことから, 結果', 'causality', 'Materi N3 tentang sebab dan akibat.'),
      _Topic('Contrast & Concession', 'のに, にもかかわらず, それでも', 'contrast', 'Materi N3 tentang kontras dan konsesi.'),
      _Topic('Purpose & Means', 'ために, ように, によって', 'purpose means', 'Materi N3 tentang tujuan dan sarana.'),
      _Topic('Change & Trends', 'につれて, にしたがって, 傾向', 'trends', 'Materi N3 tentang perubahan dan tren.'),
      _Topic('Passive & Causative', '受身・使役・使役受身', 'causative', 'Materi N3 tentang pasif dan kausatif.'),
      _Topic('Reported Speech', 'という, と言われている', 'reported speech', 'Materi N3 tentang pelaporan informasi.'),
      _Topic('Abstract Nouns', 'わけ, もの, こと, はず', 'abstract grammar', 'Materi N3 tentang konsep abstrak.'),
      _Topic('Formal Reading', 'Argumentasi dan paragraf eksposisi', 'formal reading', 'Materi N3 tentang bacaan formal.'),
      _Topic('Practical Documents', 'Email, pengumuman, petunjuk', 'documents', 'Materi N3 tentang dokumen praktis.'),
      _Topic('News Listening', 'Berita singkat dan ringkasan', 'news listening', 'Materi N3 tentang listening berita.'),
    ],
    'N2': [
      _Topic('Formal Vocabulary & Collocation', 'Kolokasi, register profesional', 'formal vocabulary', 'Materi N2 tentang kolokasi formal.'),
      _Topic('Advanced Connectors', '一方, その上, したがって', 'connectors', 'Materi N2 tentang konektor kompleks.'),
      _Topic('Nuance & Degree', 'Tingkat, batas, intensitas', 'nuance', 'Materi N2 tentang nuansa dan tingkat.'),
      _Topic('Complex Conditions', 'ものなら, ないことには, ともなると', 'complex conditions', 'Materi N2 tentang kondisi kompleks.'),
      _Topic('Causality & Consequence', 'Karena, akibat, dasar keputusan', 'causality', 'Materi N2 tentang sebab-akibat.'),
      _Topic('Concession & Counterpoint', 'とはいえ, ものの, にもかかわらず', 'counterpoint', 'Materi N2 tentang konsesi dan counterpoint.'),
      _Topic('Scope & Limitation', 'に限らず, にすぎない, を問わず', 'scope limits', 'Materi N2 tentang batas dan cakupan.'),
      _Topic('Evaluation & Judgement', 'に違いない, わけがない, ことだ', 'judgement', 'Materi N2 tentang evaluasi dan penilaian.'),
      _Topic('Impersonal & Written Style', 'Gaya laporan dan berita', 'written style', 'Materi N2 tentang gaya tulis impersonal.'),
      _Topic('Business Email', 'Permintaan, penjadwalan, follow-up', 'business email', 'Materi N2 tentang email bisnis.'),
      _Topic('News & Editorial', 'Berita, opini, editorial', 'news editorial', 'Materi N2 tentang berita dan editorial.'),
      _Topic('Argument & Synthesis', 'Menyusun alasan dan kesimpulan', 'argument synthesis', 'Materi N2 tentang argumentasi dan sintesis.'),
    ],
    'N1': [
      _Topic('High-Level Vocabulary', 'Kosakata abstrak dan register', 'advanced vocabulary', 'Materi N1 tentang kosakata abstrak.'),
      _Topic('Idioms & Fixed Expressions', 'Idiom, kolokasi, ungkapan tetap', 'idioms', 'Materi N1 tentang idiom.'),
      _Topic('Fine-Grained Nuance', 'Perbedaan makna yang sangat dekat', 'fine nuance', 'Materi N1 tentang nuansa halus.'),
      _Topic('Advanced Conditionals', 'Kondisional dan framing kompleks', 'advanced conditions', 'Materi N1 tentang kondisi kompleks.'),
      _Topic('Concession & Rhetoric', 'Kontras retoris dan sudut pandang', 'rhetoric', 'Materi N1 tentang retorika.'),
      _Topic('Inference & Implication', 'Makna tersirat dan konsekuensi', 'inference', 'Materi N1 tentang implikasi.'),
      _Topic('Writer Attitude', 'Sikap penulis dan tingkat kepastian', 'writer attitude', 'Materi N1 tentang sikap penulis.'),
      _Topic('Academic Register', 'Bahasa akademik dan profesional', 'academic', 'Materi N1 tentang register akademik.'),
      _Topic('Editorial Reading', 'Kritik, opini, dan argumen', 'editorial', 'Materi N1 tentang editorial.'),
      _Topic('Technical & Policy Texts', 'Dokumen teknis dan kebijakan', 'technical', 'Materi N1 tentang dokumen teknis.'),
      _Topic('Fast Natural Listening', 'Kecepatan natural dan reduksi bunyi', 'natural listening', 'Materi N1 tentang listening natural.'),
      _Topic('Debate & Discussion', 'Argumen, bantahan, framing', 'debate', 'Materi N1 tentang debat.'),
      _Topic('Summary & Synthesis', 'Merangkum dan menyintesis beberapa sumber', 'synthesis', 'Materi N1 tentang sintesis.'),
      _Topic('Register Switching', 'Casual, polite, formal, written', 'register', 'Materi N1 tentang pergantian register.'),
    ],
  };
}

class _Topic {
  const _Topic(
    this.title,
    this.subtitle,
    this.tag,
    this.description, {
    this.examplePrefix = 'これは れんしゅう',
    this.exampleReading = 'Kore wa renshuu',
    this.exampleMeaning = 'Latihan ini',
  });

  final String title;
  final String subtitle;
  final String tag;
  final String description;
  final String examplePrefix;
  final String exampleReading;
  final String exampleMeaning;
}
