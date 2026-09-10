// N5 RESEARCH CURRICULUM
// -----------------------------------------------------------------------------
// Purpose: authoritative, beginner-first content blueprint for the Japanese Path.
//
// Pedagogical basis:
// - JLPT N5 task domains: reading/listening at basic level.
// - Japan Foundation/JF Standard & Irodori: Can-do, real-life situations,
//   gradual skill integration, listening/speaking context.
// - Minna no Nihongo beginner sequence: identity -> objects -> time/location ->
//   daily activities -> requests/permissions -> descriptions -> experiences.
// - NHK Easy / Easy Japanese style: short, contextual sentences and audio.
//
// Important scope rule:
// JLPT does not publish a single official fixed vocabulary/kanji list.
// Therefore this file is a WORKING CONTENT SET for an N5-oriented course,
// curated for beginner usefulness. Target vocabulary is assigned to exactly one
// chapter. Old vocabulary may reappear in examples/review but must NOT be added
// again to another chapter's `vocabulary` list.
//
// Romanization is intentionally absent from the curriculum data. UI may show
// romaji only during the earliest kana onboarding and should fade it out.
// -----------------------------------------------------------------------------

class N5Vocab {
  const N5Vocab(this.jp, this.reading, this.meaning);
  final String jp;
  final String reading;
  final String meaning;
}

class N5Chapter {
  const N5Chapter({
    required this.id,
    required this.title,
    required this.goal,
    required this.vocabulary,
    required this.grammar,
    required this.kanji,
    required this.kanaFocus,
    required this.activities,
    required this.review,
    this.prerequisite,
  });

  final String id;
  final String title;
  final String goal;
  final List<N5Vocab> vocabulary;
  final List<String> grammar;
  final List<String> kanji;
  final List<String> kanaFocus;
  final List<String> activities;
  final List<String> review;
  final String? prerequisite;
}

class N5ResearchCurriculum {
  const N5ResearchCurriculum._();

  static const sourceNotes = <String>[
    'JLPT official: N5 measures understanding of some basic Japanese, especially simple reading and listening.',
    'Japan Foundation Irodori Starter: beginner Can-do tasks and everyday communication.',
    'JF Standard / Can-do approach: progress from recognition to controlled production and real-life use.',
    'Minna no Nihongo Beginner: grammar progression used as a cross-check, not copied as the only syllabus.',
    'NHK Easy Japanese: short contextual listening/dialogue model for beginners.',
  ];

  static const chapters = <N5Chapter>[
    // -----------------------------------------------------------------------
    // PHASE 0 — LITERACY FIRST
    // -----------------------------------------------------------------------
    N5Chapter(
      id: 'n5-01',
      title: 'Mulai dari Nol: Bunyi & Hiragana',
      goal: 'Mengenal sistem tulisan Jepang, lima vokal, ritme mora, dan mulai membaca hiragana tanpa bergantung pada romaji.',
      vocabulary: [
        N5Vocab('あさ', 'asa', 'pagi'), N5Vocab('いえ', 'ie', 'rumah'),
        N5Vocab('うえ', 'ue', 'atas'), N5Vocab('えき', 'eki', 'stasiun'),
        N5Vocab('おと', 'oto', 'suara'),
      ],
      grammar: ['あ・い・う・え・お', 'Mora dan panjang-pendek bunyi', 'Pengenalan kata tanpa analisis tata bahasa'],
      kanji: [],
      kanaFocus: ['あいうえお', 'かきくけこ', 'Baca per mora', 'Latihan menulis stroke order'],
      activities: ['Dengar dan pilih bunyi', 'Tracing kana', 'Baca kata 2–3 mora', 'Mini-quiz identifikasi kana'],
      review: ['Ulang 5 vokal setelah 10 menit, 1 hari, 3 hari, 7 hari'],
    ),
    N5Chapter(
      id: 'n5-02',
      title: 'Hiragana Lengkap & Kombinasi Bunyi',
      goal: 'Membaca hiragana dasar, dakuten/handakuten, yōon, dan sokuon secara akurat.',
      vocabulary: [
        N5Vocab('がくせい', 'gakusei', 'pelajar'), N5Vocab('せんせい', 'sensei', 'guru'),
        N5Vocab('でんわ', 'denwa', 'telepon'), N5Vocab('ざっし', 'zasshi', 'majalah'),
        N5Vocab('きって', 'kitte', 'perangko'), N5Vocab('ちょっと', 'chotto', 'sebentar/sedikit'),
      ],
      grammar: ['Dakuten がざだば', 'Handakuten ぱ', 'Yōon きゃ/しゅ/ちょ', 'Sokuon っ', 'Partikel sebagai unit bunyi'],
      kanji: [],
      kanaFocus: ['さ〜わ', 'が/ざ/だ/ば/ぱ', 'ゃゅょ kecil', 'っ kecil'],
      activities: ['Minimal-pair listening', 'Baca cepat kata', 'Dikte kana', 'Susun mora menjadi kata'],
      review: ['Review kana 1 + 2 sebelum setiap bab berikutnya sampai akurasi ≥90%'],
      prerequisite: 'n5-01',
    ),
    N5Chapter(
      id: 'n5-03',
      title: 'Katakana dari Nol',
      goal: 'Membaca katakana untuk kata serapan, nama, benda modern, dan istilah sehari-hari.',
      vocabulary: [
        N5Vocab('テレビ', 'terebi', 'televisi'), N5Vocab('ホテル', 'hoteru', 'hotel'),
        N5Vocab('バス', 'basu', 'bus'), N5Vocab('タクシー', 'takushii', 'taksi'),
        N5Vocab('コーヒー', 'koohii', 'kopi'), N5Vocab('ケーキ', 'keeki', 'kue'),
        N5Vocab('スマートフォン', 'sumaato fon', 'smartphone'),
      ],
      grammar: ['ー vokal panjang', 'ッ pada kata serapan', 'Kombinasi ファ/ティ/ディ', 'Alih aksara sebagai bantuan, bukan target akhir'],
      kanji: [],
      kanaFocus: ['ア〜ワ', 'dakuten/handakuten katakana', 'ー', 'ャュョ/ッ'],
      activities: ['Tracing', 'Dikte katakana', 'Cari katakana di lingkungan', 'Baca menu/tanda sederhana'],
      review: ['Campur hiragana + katakana mulai bab ini; romaji hanya mode bantuan opsional'],
      prerequisite: 'n5-02',
    ),
    N5Chapter(
      id: 'n5-04',
      title: 'Salam & Etika Dasar',
      goal: 'Menggunakan salam dasar sesuai waktu dan situasi serta memahami pola sopan paling awal.',
      vocabulary: [
        N5Vocab('おはようございます', 'ohayou gozaimasu', 'selamat pagi'),
        N5Vocab('こんにちは', 'konnichiwa', 'halo/selamat siang'),
        N5Vocab('こんばんは', 'konbanwa', 'selamat malam'),
        N5Vocab('ありがとう', 'arigatou', 'terima kasih'),
        N5Vocab('すみません', 'sumimasen', 'permisi/maaf'),
        N5Vocab('さようなら', 'sayounara', 'selamat tinggal'),
        N5Vocab('よろしく', 'yoroshiku', 'mohon bantuannya'),
      ],
      grammar: ['です sebagai kopula sopan', 'Kalimat ungkapan tetap', 'Intonasi pertanyaan dasar'],
      kanji: [],
      kanaFocus: ['Membaca ungkapan utuh', 'Partikel は dibaca wa'],
      activities: ['Listening greeting', 'Pilih salam sesuai situasi', 'Shadowing', 'Dialog 20 detik'],
      review: ['Spaced review berbasis situasi, bukan hafalan terjemahan saja'],
      prerequisite: 'n5-03',
    ),
    // -----------------------------------------------------------------------
    // PHASE 1 — CORE SURVIVAL JAPANESE
    // -----------------------------------------------------------------------
    N5Chapter(
      id: 'n5-05',
      title: 'Perkenalan Diri & Identitas',
      goal: 'Memperkenalkan nama, status, kebangsaan, dan menanyakan identitas.',
      vocabulary: [
        N5Vocab('わたし', 'watashi', 'saya'), N5Vocab('なまえ', 'namae', 'nama'),
        N5Vocab('ひと', 'hito', 'orang'), N5Vocab('かいしゃいん', 'kaishain', 'pegawai perusahaan'),
        N5Vocab('いしゃ', 'isha', 'dokter'), N5Vocab('けんきゅうしゃ', 'kenkyuusha', 'peneliti'),
        N5Vocab('インドネシアじん', 'Indoneshia-jin', 'orang Indonesia'),
      ],
      grammar: ['A は B です', 'A は B じゃありません', 'A は B ですか', 'も = juga', 'N の N'],
      kanji: ['私', '名', '前', '人', '学', '生', '先', '医', '者'],
      kanaFocus: ['Peralihan kana -> kanji dengan furigana'],
      activities: ['Buat kartu identitas', 'Listening perkenalan', 'Susun kalimat', 'Speaking 30 detik'],
      review: ['Recall tanpa romaji; kanji cukup recognition + kosakata terkait'],
      prerequisite: 'n5-04',
    ),
    N5Chapter(
      id: 'n5-06',
      title: 'Benda di Sekitar & Demonstratif',
      goal: 'Menunjuk benda dan membedakan これ/それ/あれ serta ここ/そこ/あそこ.',
      vocabulary: [
        N5Vocab('ほん', 'hon', 'buku'), N5Vocab('じしょ', 'jisho', 'kamus'),
        N5Vocab('かさ', 'kasa', 'payung'), N5Vocab('かばん', 'kaban', 'tas'),
        N5Vocab('つくえ', 'tsukue', 'meja'), N5Vocab('いす', 'isu', 'kursi'),
        N5Vocab('えんぴつ', 'enpitsu', 'pensil'), N5Vocab('とけい', 'tokei', 'jam'),
      ],
      grammar: ['これ/それ/あれ', 'この/その/あの + N', 'ここ/そこ/あそこ', 'N は N です'],
      kanji: ['本', '時', '計', '机'],
      kanaFocus: ['Partikel は/へ dibaca wa/e'],
      activities: ['Point-and-say', 'Object hunt', 'Listening demonstrative', 'Quiz jarak'],
      review: ['Campurkan benda Bab 5 sebagai konteks, bukan target vocab baru'],
      prerequisite: 'n5-05',
    ),
    N5Chapter(
      id: 'n5-07',
      title: 'Angka, Harga & Counter Dasar',
      goal: 'Mengucapkan angka, harga, jumlah benda, dan memahami counter dasar.',
      vocabulary: [
        N5Vocab('えん', 'en', 'yen'), N5Vocab('おかね', 'okane', 'uang'),
        N5Vocab('いくら', 'ikura', 'berapa harga'), N5Vocab('ひとつ', 'hitotsu', 'satu buah'),
        N5Vocab('ふたつ', 'futatsu', 'dua buah'), N5Vocab('みっつ', 'mittsu', 'tiga buah'),
        N5Vocab('ぜんぶ', 'zenbu', 'semuanya'), N5Vocab('はんぶん', 'hanbun', 'setengah'),
      ],
      grammar: ['Angka + 円', '何個/何人 sebagai pola jumlah', 'いくらですか', '〜ください'],
      kanji: ['円', '百', '千', '万'],
      kanaFocus: ['Baca angka dalam kana dan digit'],
      activities: ['Price listening', 'Simulasi kasir', 'Number dictation', 'Counter matching'],
      review: ['Angka pendek setiap hari; angka sulit masuk remedial listening'],
      prerequisite: 'n5-06',
    ),
    N5Chapter(
      id: 'n5-08',
      title: 'Waktu, Hari & Jadwal',
      goal: 'Menyebut jam, menit, hari, tanggal, dan rentang waktu sederhana.',
      vocabulary: [
        N5Vocab('いま', 'ima', 'sekarang'), N5Vocab('じかん', 'jikan', 'waktu'),
        N5Vocab('きょう', 'kyou', 'hari ini'), N5Vocab('あした', 'ashita', 'besok'),
        N5Vocab('きのう', 'kinou', 'kemarin'), N5Vocab('げつようび', 'getsuyoubi', 'Senin'),
        N5Vocab('しゅうまつ', 'shuumatsu', 'akhir pekan'), N5Vocab('よてい', 'yotei', 'rencana/jadwal'),
      ],
      grammar: ['N時に V', 'Nから Nまで', 'いつ', '毎日/毎週', 'に untuk titik waktu'],
      kanji: ['日', '月', '火', '水', '木', '金', '土', '時', '分', '半'],
      kanaFocus: ['Tanggal dengan pembacaan khusus'],
      activities: ['Baca jadwal', 'Listening time', 'Atur kalender', 'Tanya-jawab jadwal'],
      review: ['Tanggal/jam diulang dalam listening dan reading'],
      prerequisite: 'n5-07',
    ),
    N5Chapter(
      id: 'n5-09',
      title: 'Keluarga & Hubungan',
      goal: 'Menyebut anggota keluarga dan menjelaskan hubungan sederhana.',
      vocabulary: [
        N5Vocab('かぞく', 'kazoku', 'keluarga'), N5Vocab('ちち', 'chichi', 'ayah sendiri'),
        N5Vocab('はは', 'haha', 'ibu sendiri'), N5Vocab('あに', 'ani', 'kakak laki-laki sendiri'),
        N5Vocab('あね', 'ane', 'kakak perempuan sendiri'), N5Vocab('おとうと', 'otouto', 'adik laki-laki'),
        N5Vocab('いもうと', 'imouto', 'adik perempuan'), N5Vocab('きょうだい', 'kyoudai', 'saudara kandung'),
      ],
      grammar: ['N の N', 'N は N 人です', 'います untuk orang', '〜さん sebagai sapaan'],
      kanji: ['父', '母', '兄', '姉', '弟', '妹', '家'],
      kanaFocus: ['Long vowel おう/えい pada kosakata'],
      activities: ['Family tree', 'Listening family description', 'Sentence builder', 'Speaking'],
      review: ['Bedakan kata untuk keluarga sendiri vs keluarga orang lain pada materi lanjutan'],
      prerequisite: 'n5-08',
    ),
    N5Chapter(
      id: 'n5-10',
      title: 'Tempat & Lokasi',
      goal: 'Menyebut lokasi benda/orang dan bertanya tempat dengan pola yang stabil.',
      vocabulary: [
        N5Vocab('がっこう', 'gakkou', 'sekolah'), N5Vocab('かいしゃ', 'kaisha', 'perusahaan/kantor'),
        N5Vocab('えき', 'eki', 'stasiun'), N5Vocab('ぎんこう', 'ginkou', 'bank'),
        N5Vocab('びょういん', 'byouin', 'rumah sakit'), N5Vocab('みせ', 'mise', 'toko'),
        N5Vocab('こうえん', 'kouen', 'taman'), N5Vocab('トイレ', 'toire', 'toilet'),
      ],
      grammar: ['N は tempat です', 'N は N の うえ/した/なか', 'あります/います', 'どこですか'],
      kanji: ['校', '会', '社', '駅', '銀', '行', '病', '院', '店', '園'],
      kanaFocus: ['Furigana pada kanji tempat'],
      activities: ['Map labeling', 'Where is it?', 'Listening location', 'Picture description'],
      review: ['Location review dengan benda Bab 6'],
      prerequisite: 'n5-09',
    ),
    // -----------------------------------------------------------------------
    // PHASE 2 — ACTIONS & DAILY LIFE
    // -----------------------------------------------------------------------
    N5Chapter(
      id: 'n5-11',
      title: 'Kata Kerja ます: Aktivitas Dasar',
      goal: 'Membangun kalimat aktivitas sopan dan memahami objek langsung.',
      vocabulary: [
        N5Vocab('たべます', 'tabemasu', 'makan'), N5Vocab('のみます', 'nomimasu', 'minum'),
        N5Vocab('みます', 'mimasu', 'melihat/menonton'), N5Vocab('ききます', 'kikimasu', 'mendengar/bertanya'),
        N5Vocab('よみます', 'yomimasu', 'membaca'), N5Vocab('かきます', 'kakimasu', 'menulis'),
        N5Vocab('かいます', 'kaimasu', 'membeli'), N5Vocab('します', 'shimasu', 'melakukan'),
      ],
      grammar: ['Vます', 'Vません', 'N を V', 'か sebagai pertanyaan', 'は vs を secara fungsi'],
      kanji: ['食', '飲', '見', '聞', '読', '書', '買'],
      kanaFocus: ['Infleksi ます dibaca utuh'],
      activities: ['Verb picture cards', 'Object matching', 'Conjugation drill', 'Listening'],
      review: ['Interleaving verb + noun dari bab sebelumnya'],
      prerequisite: 'n5-10',
    ),
    N5Chapter(
      id: 'n5-12',
      title: 'Rutinitas Harian',
      goal: 'Menceritakan urutan aktivitas harian dari bangun sampai tidur.',
      vocabulary: [
        N5Vocab('おきます', 'okimasu', 'bangun'), N5Vocab('ねます', 'nemasu', 'tidur'),
        N5Vocab('はたらきます', 'hatarakimasu', 'bekerja'), N5Vocab('やすみます', 'yasumimasu', 'beristirahat/libur'),
        N5Vocab('べんきょうします', 'benkyou shimasu', 'belajar'), N5Vocab('おわります', 'owarimasu', 'selesai'),
        N5Vocab('はじまります', 'hajimarimasu', 'mulai'), N5Vocab('シャワー', 'shawaa', 'shower'),
      ],
      grammar: ['Time に V', 'から/まで', 'それから', 'まいにち', 'Sequence sederhana'],
      kanji: ['起', '寝', '働', '休', '勉', '強', '始', '終'],
      kanaFocus: ['Partikel に dibaca ni secara konsisten'],
      activities: ['Timeline', 'Daily diary', 'Listening routine', 'Speaking 45 detik'],
      review: ['Retrieval pagi/malam untuk kata kerja'],
      prerequisite: 'n5-11',
    ),
    N5Chapter(
      id: 'n5-13',
      title: 'Transportasi & Pergi ke Tempat',
      goal: 'Mengatakan tujuan, alat transportasi, dan keberangkatan/kedatangan dasar.',
      vocabulary: [
        N5Vocab('いきます', 'ikimasu', 'pergi'), N5Vocab('きます', 'kimasu', 'datang'),
        N5Vocab('かえります', 'kaerimasu', 'pulang'), N5Vocab('でんしゃ', 'densha', 'kereta'),
        N5Vocab('じてんしゃ', 'jitensha', 'sepeda'), N5Vocab('ひこうき', 'hikouki', 'pesawat'),
        N5Vocab('くるま', 'kuruma', 'mobil'), N5Vocab('あるいて', 'aruite', 'dengan berjalan kaki'),
      ],
      grammar: ['Tempat へ/に 行きます', 'Transportasi で', 'Orang と 行きます', 'どこへ'],
      kanji: ['行', '来', '帰', '電', '車', '自', '転', '飛', '機'],
      kanaFocus: ['へ sebagai e saat partikel'],
      activities: ['Route planner', 'Listening transport', 'Map dialogue', 'Role-play'],
      review: ['Campur tempat + waktu + transportasi'],
      prerequisite: 'n5-12',
    ),
    N5Chapter(
      id: 'n5-14',
      title: 'Makan, Minum & Restoran',
      goal: 'Memesan makanan/minuman dan memahami konteks makan sederhana.',
      vocabulary: [
        N5Vocab('ごはん', 'gohan', 'nasi/makanan'), N5Vocab('あさごはん', 'asagohan', 'sarapan'),
        N5Vocab('ひるごはん', 'hirugohan', 'makan siang'), N5Vocab('ばんごはん', 'bangohan', 'makan malam'),
        N5Vocab('みず', 'mizu', 'air'), N5Vocab('おちゃ', 'ocha', 'teh'),
        N5Vocab('さかな', 'sakana', 'ikan'), N5Vocab('にく', 'niku', 'daging'),
        N5Vocab('やさい', 'yasai', 'sayur'), N5Vocab('くだもの', 'kudamono', 'buah'),
      ],
      grammar: ['N を ください', 'N を 食べます/飲みます', 'と = dan dalam daftar sederhana', '何を'],
      kanji: ['飯', '水', '茶', '魚', '肉', '野', '菜', '果', '物'],
      kanaFocus: ['Campuran kana/kanji pada menu'],
      activities: ['Menu reading', 'Ordering role-play', 'Listening order', 'Food sorting'],
      review: ['Kosakata makanan lama hanya sebagai konteks review'],
      prerequisite: 'n5-13',
    ),
    N5Chapter(
      id: 'n5-15',
      title: 'Hobi & Waktu Luang',
      goal: 'Menyatakan aktivitas favorit dan bertanya kegiatan yang disukai.',
      vocabulary: [
        N5Vocab('おんがく', 'ongaku', 'musik'), N5Vocab('えいが', 'eiga', 'film'),
        N5Vocab('どくしょ', 'dokusho', 'membaca buku'), N5Vocab('スポーツ', 'supootsu', 'olahraga'),
        N5Vocab('サッカー', 'sakkaa', 'sepak bola'), N5Vocab('りょこう', 'ryokou', 'perjalanan'),
        N5Vocab('しゃしん', 'shashin', 'foto/fotografi'), N5Vocab('ゲーム', 'geemu', 'game'),
      ],
      grammar: ['N が 好きです', 'N が きらいです', 'どんな N', 'よく/ときどき/あまり'],
      kanji: ['音', '楽', '映', '画', '旅', '真', '好'],
      kanaFocus: ['Kata serapan dengan vokal panjang'],
      activities: ['Preference cards', 'Class survey', 'Listening likes', 'Speaking'],
      review: ['Frequency adverbs dipakai lintas topik'],
      prerequisite: 'n5-14',
    ),
    N5Chapter(
      id: 'n5-16',
      title: 'Adjektiva い',
      goal: 'Mendeskripsikan benda/orang menggunakan kata sifat い dalam bentuk dasar, negatif, dan lampau.',
      vocabulary: [
        N5Vocab('おおきい', 'ookii', 'besar'), N5Vocab('ちいさい', 'chiisai', 'kecil'),
        N5Vocab('あたらしい', 'atarashii', 'baru'), N5Vocab('ふるい', 'furui', 'lama'),
        N5Vocab('たかい', 'takai', 'mahal/tinggi'), N5Vocab('やすい', 'yasui', 'murah'),
        N5Vocab('おいしい', 'oishii', 'enak'), N5Vocab('おもしろい', 'omoshiroi', 'menarik'),
      ],
      grammar: ['い-adjective です', '〜くないです', '〜かったです', '〜くなかったです'],
      kanji: ['大', '小', '新', '古', '高', '安', '面', '白'],
      kanaFocus: ['Akhiran い sebagai bagian infleksi'],
      activities: ['Picture description', 'Opposite matching', 'Conjugation cards', 'Reading'],
      review: ['Adjective form retrieval 1/3/7 hari'],
      prerequisite: 'n5-15',
    ),
    N5Chapter(
      id: 'n5-17',
      title: 'Adjektiva な & Deskripsi',
      goal: 'Menggunakan な-adjective untuk orang, tempat, dan benda serta menggabungkannya dengan noun.',
      vocabulary: [
        N5Vocab('きれい', 'kirei', 'indah/bersih'), N5Vocab('しずか', 'shizuka', 'tenang'),
        N5Vocab('にぎやか', 'nigiyaka', 'ramai'), N5Vocab('ゆうめい', 'yuumei', 'terkenal'),
        N5Vocab('しんせつ', 'shinsetsu', 'baik/ramah'), N5Vocab('げんき', 'genki', 'sehat/bersemangat'),
        N5Vocab('べんり', 'benri', 'praktis'), N5Vocab('ひま', 'hima', 'senggang'),
      ],
      grammar: ['な-adjective + N', 'N は きれいです', 'じゃありません', 'でした/じゃありませんでした'],
      kanji: ['静', '名', '親', '元', '気', '便', '利'],
      kanaFocus: ['Kata きれい bukan い-adjective meski berakhir い'],
      activities: ['Place rating', 'Description listening', 'Error correction', 'Speaking'],
      review: ['Campur い/な adjective dalam satu quiz'],
      prerequisite: 'n5-16',
    ),
    // -----------------------------------------------------------------------
    // PHASE 3 — PARTICLES, EXISTENCE, REQUESTS
    // -----------------------------------------------------------------------
    N5Chapter(
      id: 'n5-18',
      title: 'Partikel Inti: は・が・を・に・で・へ・と・も・の',
      goal: 'Memahami fungsi partikel melalui makna kalimat, bukan menghafal terjemahan satu kata.',
      vocabulary: [
        N5Vocab('りんご', 'ringo', 'apel'), N5Vocab('えんぴつ', 'enpitsu', 'pensil'),
        N5Vocab('こうえん', 'kouen', 'taman'), N5Vocab('ともだち', 'tomodachi', 'teman'),
        N5Vocab('でんわばんごう', 'denwa bangou', 'nomor telepon'), N5Vocab('しゅくだい', 'shukudai', 'pekerjaan rumah'),
      ],
      grammar: ['Topik は', 'Subjek/fokus が', 'Objek を', 'Titik waktu/tujuan に', 'Tempat aktivitas で', 'Arah へ', 'Teman/bersama と', 'Juga も', 'Relasi の'],
      kanji: ['番', '号', '宿', '題'],
      kanaFocus: ['は/へ sebagai partikel'],
      activities: ['Particle sorting', 'Minimal-pair sentences', 'Cloze test', 'Listening discrimination'],
      review: ['Error log partikel; remedial berbasis pola yang salah'],
      prerequisite: 'n5-17',
    ),
    N5Chapter(
      id: 'n5-19',
      title: 'Ada: あります・います',
      goal: 'Menyatakan keberadaan benda dan makhluk hidup serta lokasi keberadaan.',
      vocabulary: [
        N5Vocab('ねこ', 'neko', 'kucing'), N5Vocab('いぬ', 'inu', 'anjing'),
        N5Vocab('とり', 'tori', 'burung'), N5Vocab('き', 'ki', 'pohon'),
        N5Vocab('はな', 'hana', 'bunga'), N5Vocab('くるま', 'kuruma', 'mobil'),
        N5Vocab('へや', 'heya', 'kamar'), N5Vocab('にわ', 'niwa', 'halaman'),
      ],
      grammar: ['N が あります', 'N が います', 'Place に N が あります/います', 'N は Place にあります/います'],
      kanji: ['犬', '鳥', '木', '花', '庭', '室'],
      kanaFocus: ['あります/います sebagai unit pola'],
      activities: ['Find-the-object', 'Picture location', 'Listening', 'Sentence builder'],
      review: ['Bedakan benda vs makhluk hidup secara visual'],
      prerequisite: 'n5-18',
    ),
    N5Chapter(
      id: 'n5-20',
      title: 'Mengundang & Mengajak',
      goal: 'Mengajak orang melakukan kegiatan dan menerima/menolak secara sederhana.',
      vocabulary: [
        N5Vocab('いっしょに', 'issho ni', 'bersama'), N5Vocab('えいがかん', 'eigakan', 'bioskop'),
        N5Vocab('まつり', 'matsuri', 'festival'), N5Vocab('パーティー', 'paatii', 'pesta'),
        N5Vocab('こんしゅう', 'konshuu', 'minggu ini'), N5Vocab('らいしゅう', 'raishuu', 'minggu depan'),
        N5Vocab('どうですか', 'dou desu ka', 'bagaimana?'),
      ],
      grammar: ['Vませんか', 'Vましょう', '〜ましょうか', 'どうですか'],
      kanji: ['週', '今', '来', '館'],
      kanaFocus: ['Kata serapan + dialog pendek'],
      activities: ['Invitation dialogue', 'Choice response', 'Listening intent', 'Speaking role-play'],
      review: ['Reuse vocabulary lama sebagai isi ajakan'],
      prerequisite: 'n5-19',
    ),
    N5Chapter(
      id: 'n5-21',
      title: 'Permintaan Sopan & Kebutuhan',
      goal: 'Meminta benda, meminta bantuan sederhana, dan menggunakan ungkapan kebutuhan dasar.',
      vocabulary: [
        N5Vocab('ください', 'kudasai', 'tolong berikan'), N5Vocab('おねがいします', 'onegaishimasu', 'mohon/tolong'),
        N5Vocab('もういちど', 'mou ichido', 'sekali lagi'), N5Vocab('ゆっくり', 'yukkuri', 'pelan-pelan'),
        N5Vocab('だいじょうぶ', 'daijoubu', 'tidak apa-apa'), N5Vocab('わかります', 'wakarimasu', 'mengerti'),
        N5Vocab('わかりません', 'wakarimasen', 'tidak mengerti'),
      ],
      grammar: ['N を ください', 'Vて ください sebagai pengayaan N5', 'もう一度〜', '〜てもいいですか sebagai jembatan ke bab 23'],
      kanji: ['度', '分', '理'],
      kanaFocus: ['Ungkapan tetap dibaca sebagai chunks'],
      activities: ['Help-seeking dialogue', 'Listening repair', 'Politeness choice', 'Speaking'],
      review: ['Review grammar request sebelum te-form formal'],
      prerequisite: 'n5-20',
    ),
    N5Chapter(
      id: 'n5-22',
      title: 'Bentuk Lampau: ました・でした',
      goal: 'Menceritakan kegiatan dan keadaan yang sudah terjadi.',
      vocabulary: [
        N5Vocab('せんしゅう', 'senshuu', 'minggu lalu'), N5Vocab('せんげつ', 'sengetsu', 'bulan lalu'),
        N5Vocab('きょねん', 'kyonen', 'tahun lalu'), N5Vocab('たんじょうび', 'tanjoubi', 'ulang tahun'),
        N5Vocab('りょうり', 'ryouri', 'masakan/memasak'), N5Vocab('かいもの', 'kaimono', 'belanja'),
        N5Vocab('しごと', 'shigoto', 'pekerjaan'),
      ],
      grammar: ['Vました', 'Vませんでした', 'Nでした', 'Adjective lampau review', 'いつ〜ましたか'],
      kanji: ['去', '年', '月', '誕', '生', '料', '理', '仕', '事'],
      kanaFocus: ['Baca ました sebagai pola infleksi'],
      activities: ['Yesterday timeline', 'Listening past', 'Sentence transformation', 'Short diary'],
      review: ['Present vs past mixed retrieval'],
      prerequisite: 'n5-21',
    ),
    // -----------------------------------------------------------------------
    // PHASE 4 — TE FORM, ABILITY, COMPARISON, SEQUENCE
    // -----------------------------------------------------------------------
    N5Chapter(
      id: 'n5-23',
      title: 'Te-form: Fondasi Pola Penting',
      goal: 'Mengenali dan membentuk te-form kata kerja secara bertahap untuk kebutuhan N5.',
      vocabulary: [
        N5Vocab('あけます', 'akemasu', 'membuka'), N5Vocab('しめます', 'shimemasu', 'menutup'),
        N5Vocab('つかいます', 'tsukaimasu', 'menggunakan'), N5Vocab('つくります', 'tsukurimasu', 'membuat'),
        N5Vocab('もっていきます', 'motte ikimasu', 'membawa pergi'), N5Vocab('もってきます', 'motte kimasu', 'membawa datang'),
        N5Vocab('まちます', 'machimasu', 'menunggu'),
      ],
      grammar: ['て-form grup 1/2/irregular', '〜てください', '〜ています pengantar', 'Urutan tindakan sederhana'],
      kanji: ['開', '閉', '使', '作', '持', '待'],
      kanaFocus: ['Perhatikan perubahan bunyi sebelum て'],
      activities: ['Conjugation sort', 'Drag-and-drop te-form', 'Listening', 'Request role-play'],
      review: ['Te-form retrieval harian; kata kerja sulit masuk remedial'],
      prerequisite: 'n5-22',
    ),
    N5Chapter(
      id: 'n5-24',
      title: 'Sedang Melakukan: ています',
      goal: 'Memahami aksi yang sedang berlangsung dan kebiasaan sederhana sesuai konteks.',
      vocabulary: [
        N5Vocab('よんでいます', 'yonde imasu', 'sedang membaca'), N5Vocab('たべています', 'tabete imasu', 'sedang makan'),
        N5Vocab('はなしています', 'hanashite imasu', 'sedang berbicara'), N5Vocab('みています', 'mite imasu', 'sedang melihat'),
        N5Vocab('すんでいます', 'sunde imasu', 'tinggal/berdomisili'), N5Vocab('しっています', 'shitte imasu', 'mengetahui'),
      ],
      grammar: ['Vています untuk progresif', 'Vています untuk keadaan/kebiasaan tertentu', '何をしていますか'],
      kanji: ['話', '住', '知'],
      kanaFocus: ['Kontraksi tidak perlu diajarkan sebagai target'],
      activities: ['What are they doing?', 'Listening action', 'Picture narration', 'Speaking'],
      review: ['Present simple vs progressive dengan gambar'],
      prerequisite: 'n5-23',
    ),
    N5Chapter(
      id: 'n5-25',
      title: 'Bisa & Tidak Bisa',
      goal: 'Menyatakan kemampuan dasar dan mengenali pola kemampuan pada level pemula.',
      vocabulary: [
        N5Vocab('できます', 'dekimasu', 'bisa/dapat'), N5Vocab('およぎます', 'oyogimasu', 'berenang'),
        N5Vocab('うたいます', 'utaimasu', 'bernyanyi'), N5Vocab('ひきます', 'hikimasu', 'memainkan alat musik'),
        N5Vocab('はなします', 'hanashimasu', 'berbicara'), N5Vocab('よく', 'yoku', 'sering/dengan baik'),
        N5Vocab('すこし', 'sukoshi', 'sedikit'),
      ],
      grammar: ['N が できます', 'V辞書形 + ことができます sebagai pengayaan terkontrol', 'できますか'],
      kanji: ['泳', '歌', '弾', '少'],
      kanaFocus: ['Bentuk kamus diperkenalkan dengan contoh terbatas'],
      activities: ['Ability survey', 'Listening ability', 'Controlled production', 'Quiz'],
      review: ['Jangan campur kemampuan dengan 好き tanpa konteks'],
      prerequisite: 'n5-24',
    ),
    N5Chapter(
      id: 'n5-26',
      title: 'Perbandingan & Pilihan',
      goal: 'Membandingkan dua hal dan memilih sesuatu secara sederhana.',
      vocabulary: [
        N5Vocab('ほう', 'hou', 'pihak/sisi'), N5Vocab('いちばん', 'ichiban', 'paling'),
        N5Vocab('どちら', 'dochira', 'yang mana dari dua'), N5Vocab('どれ', 'dore', 'yang mana'),
        N5Vocab('くらべます', 'kurabemasu', 'membandingkan'), N5Vocab('りょうほう', 'ryouhou', 'keduanya'),
      ],
      grammar: ['A と B と どちらが〜', 'A のほうが〜', 'N の中で〜が一番〜', 'どれ/どちら'],
      kanji: ['方', '中', '一', '番', '比'],
      kanaFocus: ['Pertanyaan panjang dibaca per chunk'],
      activities: ['Compare pictures', 'Listening choice', 'Survey', 'Sentence building'],
      review: ['Gunakan adjective Bab 16–17 sebagai isi perbandingan'],
      prerequisite: 'n5-25',
    ),
    N5Chapter(
      id: 'n5-27',
      title: 'Keinginan & Rencana Sederhana',
      goal: 'Menyatakan keinginan dasar dan rencana dekat dengan bahasa sopan.',
      vocabulary: [
        N5Vocab('ほしい', 'hoshii', 'ingin/menginginkan benda'), N5Vocab('ほしがります', 'hoshigarimasu', 'tampak menginginkan'),
        N5Vocab('つもり', 'tsumori', 'niat/rencana'), N5Vocab('よてい', 'yotei', 'rencana/jadwal'),
        N5Vocab('いつか', 'itsuka', 'suatu hari'), N5Vocab('らいげつ', 'raigetsu', 'bulan depan'),
      ],
      grammar: ['N が ほしいです', 'Vたいです sebagai pola keinginan tindakan', 'Vるつもりです sebagai pengayaan', '予定です'],
      kanji: ['欲', '意', '定', '来'],
      kanaFocus: ['Bentuk kamus hanya sebagai input bertahap'],
      activities: ['Wish list', 'Plan calendar', 'Listening intention', 'Speaking'],
      review: ['Bedakan keinginan benda vs tindakan'],
      prerequisite: 'n5-26',
    ),
    N5Chapter(
      id: 'n5-28',
      title: 'Alasan & Hubungan Kalimat',
      goal: 'Menghubungkan kalimat sederhana dengan から dan memberi alasan singkat.',
      vocabulary: [
        N5Vocab('から', 'kara', 'karena/dari'), N5Vocab('だから', 'dakara', 'oleh karena itu'),
        N5Vocab('でも', 'demo', 'tetapi'), N5Vocab('そして', 'soshite', 'dan kemudian'),
        N5Vocab('ちょっと', 'chotto', 'agak/sebentar'), N5Vocab('とても', 'totemo', 'sangat'),
      ],
      grammar: ['〜からです', 'Sentence + から', 'でも', 'そして', 'Adverb intensitas'],
      kanji: [],
      kanaFocus: ['Connector chunks'],
      activities: ['Why? Because...', 'Listening reason', 'Connector choice', 'Short paragraph'],
      review: ['Pastikan から tidak disamakan dengan から = dari'],
      prerequisite: 'n5-27',
    ),
    // -----------------------------------------------------------------------
    // PHASE 5 — REAL-LIFE N5 INTEGRATION
    // -----------------------------------------------------------------------
    N5Chapter(
      id: 'n5-29',
      title: 'Reading N5: Pesan, Tanda & Pengumuman',
      goal: 'Membaca teks pendek praktis dan menemukan informasi yang diminta tanpa menerjemahkan semuanya.',
      vocabulary: [
        N5Vocab('おしらせ', 'oshirase', 'pengumuman'), N5Vocab('ちゅうい', 'chuui', 'perhatian'),
        N5Vocab('きんえん', 'kinen', 'dilarang merokok'), N5Vocab('じゅぎょう', 'jugyou', 'pelajaran/kelas'),
        N5Vocab('やすみ', 'yasumi', 'libur/istirahat'), N5Vocab('うけつけ', 'uketsuke', 'resepsionis/penerimaan'),
        N5Vocab('しめきり', 'shimekiri', 'batas waktu'),
      ],
      grammar: ['Review pola N5 dalam teks', '〜ない sebagai recognition dasar', 'Kata kunci waktu/tempat'],
      kanji: ['知', '注', '意', '禁', '煙', '業', '受', '付'],
      kanaFocus: ['Furigana berkurang bertahap'],
      activities: ['Scan for information', 'True/false', 'Multiple choice', 'Timed reading'],
      review: ['Error analysis berdasarkan kata kunci yang terlewat'],
      prerequisite: 'n5-28',
    ),
    N5Chapter(
      id: 'n5-30',
      title: 'Listening N5: Percakapan Sehari-hari',
      goal: 'Menangkap siapa, kapan, di mana, apa, dan keputusan utama dari dialog pendek.',
      vocabulary: [
        N5Vocab('あとで', 'ato de', 'nanti'), N5Vocab('すぐ', 'sugu', 'segera'),
        N5Vocab('また', 'mata', 'lagi/sampai jumpa'), N5Vocab('もちろん', 'mochiron', 'tentu saja'),
        N5Vocab('ほんとうに', 'hontou ni', 'benar-benar'), N5Vocab('いそがしい', 'isogashii', 'sibuk'),
        N5Vocab('むずかしい', 'muzukashii', 'sulit'),
      ],
      grammar: ['Review semua pola inti melalui audio', 'Pertanyaan siapa/apa/kapan/di mana', 'Distractor sederhana'],
      kanji: ['後', '難', '忙', '本', '当'],
      kanaFocus: ['Listening tidak bergantung pada visual romaji'],
      activities: ['Listen once', 'Listen twice with targeted question', 'Dictation keyword', 'Shadowing'],
      review: ['Kesalahan listening diberi audio ulang dengan tingkat bantuan bertahap'],
      prerequisite: 'n5-29',
    ),
    N5Chapter(
      id: 'n5-31',
      title: 'N5 Final: Integrasi & Mastery Check',
      goal: 'Mengintegrasikan kana, kanji dasar, vocabulary, grammar, reading, listening, dan komunikasi dasar.',
      vocabulary: [],
      grammar: ['Comprehensive N5 review', 'Tidak ada grammar baru'],
      kanji: [],
      kanaFocus: ['100% tanpa romaji kecuali accessibility mode'],
      activities: [
        'Kana mastery test', 'Vocabulary recognition test', 'Grammar cloze',
        'Kanji reading test', 'Reading task', 'Listening task',
        'Speaking self-introduction', 'Practical mini-scenario',
      ],
      review: [
        'Remedial otomatis per skill: kana/vocabulary/kanji/grammar/reading/listening.',
        'Mastery hanya diberikan jika skor konsisten, bukan sekali benar.',
        'Item salah masuk review 1 hari -> 3 hari -> 7 hari -> 14 hari.',
      ],
      prerequisite: 'n5-30',
    ),
  ];

  static Set<String> get allTargetVocabulary => {
        for (final chapter in chapters)
          ...chapter.vocabulary.map((item) => item.jp),
      };

  /// QC: returns duplicate target vocabulary. Expected result = empty set.
  static Set<String> get duplicateTargetVocabulary {
    final seen = <String>{};
    final duplicates = <String>{};
    for (final chapter in chapters) {
      for (final item in chapter.vocabulary) {
        if (!seen.add(item.jp)) duplicates.add(item.jp);
      }
    }
    return duplicates;
  }

  /// UI helper: chapter by sequence (1-based).
  static N5Chapter? chapter(int number) {
    if (number < 1 || number > chapters.length) return null;
    return chapters[number - 1];
  }

  /// Review schedule for the app's review engine.
  static const reviewIntervalsDays = <int>[0, 1, 3, 7, 14, 30];
}
