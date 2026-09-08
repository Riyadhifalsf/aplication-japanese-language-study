import 'curriculum_models.dart';

/// Deep, original chapter blueprints used to extend each JLPT level.
/// The wording is authored for this project; references inform structure,
/// not copied textbook content.
class CurriculumDepthCatalog {
  const CurriculumDepthCatalog._();

  static List<CurriculumUnit> forLevel(String level, {required int startSequence}) {
    final topics = _topics[level] ?? const <_Topic>[];
    return [
      for (var i = 0; i < topics.length; i++) _unit(level, startSequence + i, topics[i]),
    ];
  }

  static CurriculumUnit _unit(String level, int sequence, _Topic topic) {
    final uid = '${level.toLowerCase()}-deep-u${sequence.toString().padLeft(2, '0')}';
    LessonActivity a(String id, CurriculumActivityType type, String title, String description, int minutes) => LessonActivity(
      id: id, type: type, title: title, description: description, estimatedMinutes: minutes,
      contentRef: 'level:$level;theme:${topic.tag}', routeHint: type == CurriculumActivityType.grammar ? 'grammar' : (type == CurriculumActivityType.vocabulary ? 'vocabulary' : (type == CurriculumActivityType.reading ? 'reading' : (type == CurriculumActivityType.listening ? 'listening' : type.name))),
    );
    CurriculumLesson l(int n, String title, CurriculumActivityType contextType) {
      final lid = '$uid-l${n.toString().padLeft(2, '0')}';
      final contextLabel = contextType == CurriculumActivityType.reading ? 'Reading' : 'Listening';
      final lessonFocus = switch (n) {
        1 => 'Kenali bentuk, makna, dan pola yang sering muncul.',
        2 => 'Latih pengenalan dan produksi dengan contoh bertahap.',
        3 => 'Bandingkan penggunaan yang mirip agar nuansanya terasa.',
        4 => 'Pakai materi dalam dialog, teks, atau situasi nyata.',
        5 => 'Kerjakan retrieval practice tanpa melihat catatan.',
        _ => 'Review ringkas dan cek kesiapan sebelum berpindah topik.',
      };
      final lessonBody = '${topic.subtitle}. $lessonFocus Fokuskan perhatian pada maksud pembicara/penulis, bukan sekadar bentuk kata. Setelah contoh pertama, ubah satu unsur kalimat dan lihat apakah maknanya tetap masuk akal.';
      return CurriculumLesson(
        id: lid, unitId: uid, levelId: level, sequence: n, title: title,
        subtitle: n == 1 ? 'Pahami dasar dan contohnya' : n == 2 ? 'Latihan aktif' : n == 3 ? 'Bandingkan nuansa' : n == 4 ? '$contextLabel dalam konteks' : n == 5 ? 'Recall tanpa contekan' : 'Review dan checkpoint',
        objectives: [
          'Memahami ${topic.title.toLowerCase()} dan alasan penggunaannya dalam konteks.',
          'Menghasilkan contoh sederhana sendiri tanpa hanya menyalin pola.',
          'Membedakan penggunaan yang tepat dari bentuk yang terasa janggal.',
        ],
        activities: [
          a('$lid-a1', n == 1 ? CurriculumActivityType.grammar : CurriculumActivityType.vocabulary, n == 1 ? 'Bangun fondasi' : 'Aktifkan kosakata', 'Mulai dari konteks, perhatikan bentuk, lalu cek pemahaman.', 8),
          a('$lid-a2', n == 2 || n == 5 ? CurriculumActivityType.writing : CurriculumActivityType.exampleSentences, n == 2 || n == 5 ? 'Latihan dari ingatan' : 'Bedah contoh', 'Ubah sebagian kalimat dan pastikan maknanya tetap konsisten.', 10),
          a('$lid-a3', contextType, contextType == CurriculumActivityType.reading ? 'Baca dan simpulkan' : 'Dengar dan tangkap inti', 'Cari informasi penting dan abaikan detail yang belum perlu dihafal.', 10),
          if (n >= 3) LessonActivity(id: '$lid-a4', type: CurriculumActivityType.review, title: 'Check cepat', description: 'Cek satu kesalahan yang paling sering terjadi dan perbaiki dengan contoh baru.', estimatedMinutes: 6, contentRef: 'level:$level;theme:${topic.tag};review'),
        ],
        notes: [
          LessonNote(title: 'Inti materi', body: lessonBody),
          LessonNote(title: 'Belajar lebih efektif', body: 'Baca contoh dengan suara pelan, tutup terjemahan, lalu jelaskan kembali maksudnya dengan kata-katamu sendiri. Bila masih ragu, simpan contoh itu untuk review berikutnya.'),
          if (n >= 4) LessonNote(title: 'Checkpoint', body: 'Sebelum lanjut, pastikan kamu bisa mengenali pola ini pada contoh baru dan menjelaskan kapan pola itu terdengar wajar.'),
        ],
        estimatedMinutes: n >= 3 ? 34 : 30,
      );
    }
    final lessons = [
      l(1, '${topic.title} — Inti Konsep', CurriculumActivityType.reading),
      l(2, '${topic.title} — Latihan Terarah', CurriculumActivityType.listening),
      l(3, '${topic.title} — Bedakan Nuansanya', CurriculumActivityType.reading),
      l(4, '${topic.title} — Konteks Nyata', CurriculumActivityType.listening),
      l(5, '${topic.title} — Recall Aktif', CurriculumActivityType.reading),
      l(6, '${topic.title} — Review & Checkpoint', CurriculumActivityType.listening),
    ];
    return CurriculumUnit(id: uid, levelId: level, sequence: sequence, title: topic.title, subtitle: topic.subtitle, description: topic.description, icon: sequence.isEven ? 'book' : 'compass', lessons: lessons);
  }

  static const Map<String, List<_Topic>> _topics = {
    'N5': [
      _Topic('Family & People', 'Keluarga, teman, orang di sekitar', 'family people relationships', 'Materi N5 yang membangun family & people melalui penjelasan, contoh, latihan aktif, dan konteks nyata.'),
      _Topic('Things & Ownership', 'Benda, kepemilikan, demonstratives', 'things ownership', 'Materi N5 yang membangun things & ownership melalui penjelasan, contoh, latihan aktif, dan konteks nyata.'),
      _Topic('Places & Directions', 'Tempat, posisi, arah sederhana', 'places directions', 'Materi N5 yang membangun places & directions melalui penjelasan, contoh, latihan aktif, dan konteks nyata.'),
      _Topic('Time & Daily Schedule', 'Jam, tanggal, jadwal dan frekuensi', 'time schedule', 'Materi N5 yang membangun time & daily schedule melalui penjelasan, contoh, latihan aktif, dan konteks nyata.'),
      _Topic('Going Out & Transport', 'Tujuan, kendaraan, perpindahan', 'transport', 'Materi N5 yang membangun going out & transport melalui penjelasan, contoh, latihan aktif, dan konteks nyata.'),
      _Topic('Food & Shopping', 'Menu, harga, ukuran, pesanan', 'food shopping', 'Materi N5 yang membangun food & shopping melalui penjelasan, contoh, latihan aktif, dan konteks nyata.'),
      _Topic('Daily Routines', 'Rutinitas, kebiasaan, urutan aksi', 'routine habits', 'Materi N5 yang membangun daily routines melalui penjelasan, contoh, latihan aktif, dan konteks nyata.'),
      _Topic('Adjectives & Description', 'i/na-adjective dan deskripsi', 'adjectives', 'Materi N5 yang membangun adjectives & description melalui penjelasan, contoh, latihan aktif, dan konteks nyata.'),
      _Topic('Likes & Abilities', 'Suka, tidak suka, kemampuan', 'preferences ability', 'Materi N5 yang membangun likes & abilities melalui penjelasan, contoh, latihan aktif, dan konteks nyata.'),
      _Topic('Requests & Invitations', 'Permintaan, ajakan, izin', 'requests invitations', 'Materi N5 yang membangun requests & invitations melalui penjelasan, contoh, latihan aktif, dan konteks nyata.'),
      _Topic('Experience & Plans', 'Pengalaman, rencana, kewajiban dasar', 'experience plans', 'Materi N5 yang membangun experience & plans melalui penjelasan, contoh, latihan aktif, dan konteks nyata.'),
      _Topic('Weather & Health', 'Cuaca, kondisi badan, saran sederhana', 'weather health', 'Materi N5 yang membangun weather & health melalui penjelasan, contoh, latihan aktif, dan konteks nyata.'),
      _Topic('Reading Everyday Texts', 'Pesan, menu, jadwal, pengumuman', 'reading', 'Materi N5 yang membangun reading everyday texts melalui penjelasan, contoh, latihan aktif, dan konteks nyata.'),
      _Topic('Listening Everyday Life', 'Informasi kunci dalam percakapan', 'listening', 'Materi N5 yang membangun listening everyday life melalui penjelasan, contoh, latihan aktif, dan konteks nyata.'),
    ],
    'N4': [
      _Topic('Plain Forms & Verb Control', 'Bentuk biasa, negatif, lampau', 'plain forms', 'Materi N4 yang membangun plain forms & verb control melalui penjelasan, contoh, latihan aktif, dan konteks nyata.'),
      _Topic('Reasons & Explanations', 'んです, ので, から', 'explanations', 'Materi N4 yang membangun reasons & explanations melalui penjelasan, contoh, latihan aktif, dan konteks nyata.'),
      _Topic('Potential & Ability', '可能形 dan konteks kemampuan', 'potential', 'Materi N4 yang membangun potential & ability melalui penjelasan, contoh, latihan aktif, dan konteks nyata.'),
      _Topic('Plans & Intentions', 'つもり, 予定, ようと思う', 'plans', 'Materi N4 yang membangun plans & intentions melalui penjelasan, contoh, latihan aktif, dan konteks nyata.'),
      _Topic('Preparation & Completion', 'ておく, てある, てしまう', 'completion', 'Materi N4 yang membangun preparation & completion melalui penjelasan, contoh, latihan aktif, dan konteks nyata.'),
      _Topic('Conditionals', 'たら, なら, と, ば', 'conditionals', 'Materi N4 yang membangun conditionals melalui penjelasan, contoh, latihan aktif, dan konteks nyata.'),
      _Topic('Permission & Obligation', 'てもいい, てはいけない, なければ', 'permission obligation', 'Materi N4 yang membangun permission & obligation melalui penjelasan, contoh, latihan aktif, dan konteks nyata.'),
      _Topic('Giving & Receiving', 'あげる, くれる, もらう', 'giving receiving', 'Materi N4 yang membangun giving & receiving melalui penjelasan, contoh, latihan aktif, dan konteks nyata.'),
      _Topic('Passive & Transitivity', '受身, 自動詞・他動詞', 'passive transitivity', 'Materi N4 yang membangun passive & transitivity melalui penjelasan, contoh, latihan aktif, dan konteks nyata.'),
      _Topic('Nominalization & Relatives', 'のは, のが, relative clauses', 'nominalization relative', 'Materi N4 yang membangun nominalization & relatives melalui penjelasan, contoh, latihan aktif, dan konteks nyata.'),
      _Topic('Connectors & Contrast', 'し, ので, のに, けれど', 'connectors contrast', 'Materi N4 yang membangun connectors & contrast melalui penjelasan, contoh, latihan aktif, dan konteks nyata.'),
      _Topic('Change & Appearance', 'ようになる, ことになる, そう', 'change appearance', 'Materi N4 yang membangun change & appearance melalui penjelasan, contoh, latihan aktif, dan konteks nyata.'),
    ],
    'N3': [
      _Topic('Inference & Probability', 'ようだ, らしい, みたい, はず', 'inference', 'Materi N3 yang membangun inference & probability melalui penjelasan, contoh, latihan aktif, dan konteks nyata.'),
      _Topic('Complex Conditions', 'としたら, ものなら, ないことには', 'conditions', 'Materi N3 yang membangun complex conditions melalui penjelasan, contoh, latihan aktif, dan konteks nyata.'),
      _Topic('Cause & Result', 'ため, ことから, 結果', 'causality', 'Materi N3 yang membangun cause & result melalui penjelasan, contoh, latihan aktif, dan konteks nyata.'),
      _Topic('Contrast & Concession', 'のに, にもかかわらず, それでも', 'contrast', 'Materi N3 yang membangun contrast & concession melalui penjelasan, contoh, latihan aktif, dan konteks nyata.'),
      _Topic('Purpose & Means', 'ために, ように, によって', 'purpose means', 'Materi N3 yang membangun purpose & means melalui penjelasan, contoh, latihan aktif, dan konteks nyata.'),
      _Topic('Change & Trends', 'につれて, にしたがって, 傾向', 'trends', 'Materi N3 yang membangun change & trends melalui penjelasan, contoh, latihan aktif, dan konteks nyata.'),
      _Topic('Passive & Causative', '受身・使役・使役受身', 'causative', 'Materi N3 yang membangun passive & causative melalui penjelasan, contoh, latihan aktif, dan konteks nyata.'),
      _Topic('Reported Speech', 'という, と言われている', 'reported speech', 'Materi N3 yang membangun reported speech melalui penjelasan, contoh, latihan aktif, dan konteks nyata.'),
      _Topic('Abstract Nouns', 'わけ, もの, こと, はず', 'abstract grammar', 'Materi N3 yang membangun abstract nouns melalui penjelasan, contoh, latihan aktif, dan konteks nyata.'),
      _Topic('Formal Reading', 'Argumentasi dan paragraf eksposisi', 'formal reading', 'Materi N3 yang membangun formal reading melalui penjelasan, contoh, latihan aktif, dan konteks nyata.'),
      _Topic('Practical Documents', 'Email, pengumuman, petunjuk', 'documents', 'Materi N3 yang membangun practical documents melalui penjelasan, contoh, latihan aktif, dan konteks nyata.'),
      _Topic('News Listening', 'Berita singkat dan ringkasan', 'news listening', 'Materi N3 yang membangun news listening melalui penjelasan, contoh, latihan aktif, dan konteks nyata.'),
    ],
    'N2': [
      _Topic('Formal Vocabulary & Collocation', 'Kolokasi, register profesional', 'formal vocabulary', 'Materi N2 yang membangun formal vocabulary & collocation melalui penjelasan, contoh, latihan aktif, dan konteks nyata.'),
      _Topic('Advanced Connectors', '一方, その上, したがって', 'connectors', 'Materi N2 yang membangun advanced connectors melalui penjelasan, contoh, latihan aktif, dan konteks nyata.'),
      _Topic('Nuance & Degree', 'Tingkat, batas, intensitas', 'nuance', 'Materi N2 yang membangun nuance & degree melalui penjelasan, contoh, latihan aktif, dan konteks nyata.'),
      _Topic('Complex Conditions', 'ものなら, ないことには, ともなると', 'complex conditions', 'Materi N2 yang membangun complex conditions melalui penjelasan, contoh, latihan aktif, dan konteks nyata.'),
      _Topic('Causality & Consequence', 'Karena, akibat, dasar keputusan', 'causality', 'Materi N2 yang membangun causality & consequence melalui penjelasan, contoh, latihan aktif, dan konteks nyata.'),
      _Topic('Concession & Counterpoint', 'とはいえ, ものの, にもかかわらず', 'counterpoint', 'Materi N2 yang membangun concession & counterpoint melalui penjelasan, contoh, latihan aktif, dan konteks nyata.'),
      _Topic('Scope & Limitation', 'に限らず, にすぎない, を問わず', 'scope limits', 'Materi N2 yang membangun scope & limitation melalui penjelasan, contoh, latihan aktif, dan konteks nyata.'),
      _Topic('Evaluation & Judgement', 'に違いない, わけがない, ことだ', 'judgement', 'Materi N2 yang membangun evaluation & judgement melalui penjelasan, contoh, latihan aktif, dan konteks nyata.'),
      _Topic('Impersonal & Written Style', 'Gaya laporan dan berita', 'written style', 'Materi N2 yang membangun impersonal & written style melalui penjelasan, contoh, latihan aktif, dan konteks nyata.'),
      _Topic('Business Email', 'Permintaan, penjadwalan, follow-up', 'business email', 'Materi N2 yang membangun business email melalui penjelasan, contoh, latihan aktif, dan konteks nyata.'),
      _Topic('News & Editorial', 'Berita, opini, editorial', 'news editorial', 'Materi N2 yang membangun news & editorial melalui penjelasan, contoh, latihan aktif, dan konteks nyata.'),
      _Topic('Argument & Synthesis', 'Menyusun alasan dan kesimpulan', 'argument synthesis', 'Materi N2 yang membangun argument & synthesis melalui penjelasan, contoh, latihan aktif, dan konteks nyata.'),
    ],
    'N1': [
      _Topic('High-Level Vocabulary', 'Kosakata abstrak dan register', 'advanced vocabulary', 'Materi N1 yang membangun high-level vocabulary melalui penjelasan, contoh, latihan aktif, dan konteks nyata.'),
      _Topic('Idioms & Fixed Expressions', 'Idiom, kolokasi, ungkapan tetap', 'idioms', 'Materi N1 yang membangun idioms & fixed expressions melalui penjelasan, contoh, latihan aktif, dan konteks nyata.'),
      _Topic('Fine-Grained Nuance', 'Perbedaan makna yang sangat dekat', 'fine nuance', 'Materi N1 yang membangun fine-grained nuance melalui penjelasan, contoh, latihan aktif, dan konteks nyata.'),
      _Topic('Advanced Conditionals', 'Kondisional dan framing kompleks', 'advanced conditions', 'Materi N1 yang membangun advanced conditionals melalui penjelasan, contoh, latihan aktif, dan konteks nyata.'),
      _Topic('Concession & Rhetoric', 'Kontras retoris dan sudut pandang', 'rhetoric', 'Materi N1 yang membangun concession & rhetoric melalui penjelasan, contoh, latihan aktif, dan konteks nyata.'),
      _Topic('Inference & Implication', 'Makna tersirat dan konsekuensi', 'inference', 'Materi N1 yang membangun inference & implication melalui penjelasan, contoh, latihan aktif, dan konteks nyata.'),
      _Topic('Writer Attitude', 'Sikap penulis dan tingkat kepastian', 'writer attitude', 'Materi N1 yang membangun writer attitude melalui penjelasan, contoh, latihan aktif, dan konteks nyata.'),
      _Topic('Academic Register', 'Bahasa akademik dan profesional', 'academic', 'Materi N1 yang membangun academic register melalui penjelasan, contoh, latihan aktif, dan konteks nyata.'),
      _Topic('Editorial Reading', 'Kritik, opini, dan argumen', 'editorial', 'Materi N1 yang membangun editorial reading melalui penjelasan, contoh, latihan aktif, dan konteks nyata.'),
      _Topic('Technical & Policy Texts', 'Dokumen teknis dan kebijakan', 'technical', 'Materi N1 yang membangun technical & policy texts melalui penjelasan, contoh, latihan aktif, dan konteks nyata.'),
      _Topic('Fast Natural Listening', 'Kecepatan natural dan reduksi bunyi', 'natural listening', 'Materi N1 yang membangun fast natural listening melalui penjelasan, contoh, latihan aktif, dan konteks nyata.'),
      _Topic('Debate & Discussion', 'Argumen, bantahan, framing', 'debate', 'Materi N1 yang membangun debate & discussion melalui penjelasan, contoh, latihan aktif, dan konteks nyata.'),
      _Topic('Summary & Synthesis', 'Merangkum dan menyintesis beberapa sumber', 'synthesis', 'Materi N1 yang membangun summary & synthesis melalui penjelasan, contoh, latihan aktif, dan konteks nyata.'),
      _Topic('Register Switching', 'Casual, polite, formal, written', 'register', 'Materi N1 yang membangun register switching melalui penjelasan, contoh, latihan aktif, dan konteks nyata.'),
    ],
  };
}

class _Topic {
  const _Topic(this.title, this.subtitle, this.tag, this.description);
  final String title;
  final String subtitle;
  final String tag;
  final String description;
}
