import '../domain/learning_models.dart';

/// Katalog kurikulum yang original dan versionable.
///
/// `lesson_mnn_*` adalah penanda urutan/rujukan pedagogis, bukan salinan isi
/// buku. Konten, contoh, dan pertanyaan di bawah dibuat khusus untuk aplikasi.
class JapaneseCurriculum {
  const JapaneseCurriculum._();

  static final catalog = CurriculumCatalog(
    units: const [
      UnitDefinition(
        id: 'unit_n5_01_identity',
        level: 'N5',
        sequence: 1,
        title: 'Unit 1 · Memulai percakapan',
        objective:
            'Mengenalkan diri, menanyakan identitas dasar, dan merespons dengan sopan.',
        lessonIds: [
          'lesson_mnn_001',
          'lesson_mnn_002',
          'lesson_mnn_003',
        ],
      ),
    ],
    lessons: [
      LessonDefinition(
        id: 'lesson_mnn_001',
        unitId: 'unit_n5_01_identity',
        level: 'N5',
        sequence: 1,
        title: 'Salam dan perkenalan',
        summary: 'Bangun kalimat perkenalan sederhana dengan gaya sopan.',
        whyNow:
            'Ini fondasi untuk meminta dan memberi informasi identitas sebelum masuk ke topik benda, tempat, dan aktivitas.',
        objectives: const [
          LearningObjective(
            id: 'objective_n5_001_intro',
            description:
                'Setelah lesson ini, kamu dapat memperkenalkan diri singkat dan memilih respons sopan yang tepat dalam percakapan awal.',
            assessedSkills: {
              LearningSkill.vocabulary,
              LearningSkill.grammar,
              LearningSkill.reading,
            },
          ),
        ],
        contents: const [
          CurriculumContent(
            id: 'vocab_n5_001_watashi',
            title: 'わたし · watashi',
            explanation:
                'Kata netral untuk menyebut diri sendiri dalam konteks sopan.',
            skill: LearningSkill.vocabulary,
          ),
          CurriculumContent(
            id: 'vocab_n5_002_namae',
            title: 'なまえ · namae',
            explanation:
                'Berarti nama; sering dipakai untuk menanyakan identitas.',
            skill: LearningSkill.vocabulary,
          ),
          CurriculumContent(
            id: 'grammar_n5_001_desu',
            title: '～です',
            explanation:
                'Penutup sopan untuk menyatakan identitas atau informasi dasar.',
            skill: LearningSkill.grammar,
            relatedIds: ['grammar_n5_002_wa_topic'],
          ),
          CurriculumContent(
            id: 'grammar_n5_002_wa_topic',
            title: '～は',
            explanation:
                'Menandai topik yang sedang dibicarakan. Dibaca “wa” saat menjadi partikel.',
            skill: LearningSkill.grammar,
            relatedIds: ['grammar_n5_001_desu'],
          ),
          CurriculumContent(
            id: 'expression_n5_001_hajimemashite',
            title: 'はじめまして',
            explanation: 'Sapaan saat pertama kali berkenalan.',
            skill: LearningSkill.vocabulary,
            tier: ContentTier.extension,
          ),
        ],
        questions: const [
          LessonQuestion(
            id: 'question_n5_001_guided_desu',
            phase: LessonPhase.guidedPractice,
            prompt: 'Pilih penutup sopan yang tepat: わたしは Rina ___。',
            options: ['です', 'を', 'に', 'から'],
            correctIndex: 0,
            conceptId: 'grammar_n5_001_desu',
            skills: {LearningSkill.grammar, LearningSkill.reading},
            explanation: 'です menutup pernyataan identitas dengan sopan.',
          ),
          LessonQuestion(
            id: 'question_n5_001_recall_watashi',
            phase: LessonPhase.recall,
            prompt: 'Kata わたし paling tepat berarti…',
            options: ['saya', 'nama', 'guru', 'sampai jumpa'],
            correctIndex: 0,
            conceptId: 'vocab_n5_001_watashi',
            skills: {LearningSkill.vocabulary, LearningSkill.reading},
            explanation: 'わたし adalah kata netral untuk “saya”.',
          ),
          LessonQuestion(
            id: 'question_n5_001_application_intro',
            phase: LessonPhase.application,
            scenario:
                'Kamu baru bertemu rekan kelas dan ingin mengenalkan diri secara sopan.',
            prompt: 'Kalimat mana yang paling sesuai?',
            options: [
              'はじめまして。わたしは Dini です。',
              'わたしを Dini に。',
              'Dini はじめまして を。',
              'なまえ ですか を。',
            ],
            correctIndex: 0,
            conceptId: 'grammar_n5_002_wa_topic',
            skills: {
              LearningSkill.grammar,
              LearningSkill.vocabulary,
              LearningSkill.reading
            },
            explanation:
                'Kalimat ini memakai salam, topik わたしは, dan penutup です.',
          ),
          LessonQuestion(
            id: 'question_n5_001_assessment_name',
            phase: LessonPhase.assessment,
            prompt: 'Apa arti なまえ?',
            options: ['nama', 'negara', 'kelas', 'angka'],
            correctIndex: 0,
            conceptId: 'vocab_n5_002_namae',
            skills: {LearningSkill.vocabulary, LearningSkill.reading},
            explanation: 'なまえ berarti nama.',
          ),
          LessonQuestion(
            id: 'question_n5_001_assessment_topic',
            phase: LessonPhase.assessment,
            prompt: 'Partikel は pada わたしは Rina です berfungsi untuk…',
            options: [
              'menandai topik',
              'menandai objek',
              'menandai tujuan',
              'menandai alat',
            ],
            correctIndex: 0,
            conceptId: 'grammar_n5_002_wa_topic',
            skills: {LearningSkill.grammar, LearningSkill.reading},
            explanation: 'は memperkenalkan topik yang akan dijelaskan.',
          ),
          LessonQuestion(
            id: 'question_n5_001_assessment_response',
            phase: LessonPhase.assessment,
            prompt:
                'Pilih respons pembuka yang paling alami saat pertama berkenalan.',
            options: ['はじめまして。', 'おやすみなさい。', 'いただきます。', 'いってきます。'],
            correctIndex: 0,
            conceptId: 'expression_n5_001_hajimemashite',
            skills: {LearningSkill.vocabulary, LearningSkill.reading},
            explanation: 'はじめまして digunakan saat pertama kali berkenalan.',
          ),
        ],
        masteryGate: const MasteryGate(minimumBySkill: {
          LearningSkill.vocabulary: 80,
          LearningSkill.grammar: 80,
          LearningSkill.reading: 70,
        }),
        nextLessonId: 'lesson_mnn_002',
      ),
      LessonDefinition(
        id: 'lesson_mnn_002',
        unitId: 'unit_n5_01_identity',
        level: 'N5',
        sequence: 2,
        title: 'Orang dan profesi',
        summary: 'Menyebut orang lain dan peran mereka dalam percakapan dasar.',
        whyNow:
            'Setelah dapat memperkenalkan diri, kamu perlu dapat membicarakan orang lain untuk memperluas percakapan awal.',
        objectives: const [
          LearningObjective(
            id: 'objective_n5_002_people',
            description:
                'Setelah lesson ini, kamu dapat menyebut profesi dasar dan menambahkan informasi dengan も.',
            assessedSkills: {LearningSkill.vocabulary, LearningSkill.grammar},
          ),
        ],
        contents: const [
          CurriculumContent(
            id: 'vocab_n5_003_gakusei',
            title: 'がくせい · gakusei',
            explanation: 'Siswa atau mahasiswa.',
            skill: LearningSkill.vocabulary,
          ),
          CurriculumContent(
            id: 'grammar_n5_003_mo',
            title: '～も',
            explanation:
                'Berarti “juga”; menggantikan は saat menambahkan topik serupa.',
            skill: LearningSkill.grammar,
            relatedIds: ['grammar_n5_002_wa_topic'],
          ),
        ],
        questions: const [
          LessonQuestion(
            id: 'question_n5_002_guided_mo',
            phase: LessonPhase.guidedPractice,
            prompt: 'Lengkapi kalimat: Rina は がくせい です。Dini ___ がくせい です。',
            options: ['も', 'を', 'に', 'で'],
            correctIndex: 0,
            conceptId: 'grammar_n5_003_mo',
            skills: {LearningSkill.grammar, LearningSkill.reading},
            explanation:
                'も berarti “juga” untuk menambahkan informasi yang sama.',
          ),
          LessonQuestion(
            id: 'question_n5_002_recall_gakusei',
            phase: LessonPhase.recall,
            prompt: 'がくせい berarti…',
            options: ['siswa/mahasiswa', 'guru', 'dokter', 'teman'],
            correctIndex: 0,
            conceptId: 'vocab_n5_003_gakusei',
            skills: {LearningSkill.vocabulary, LearningSkill.reading},
            explanation: 'がくせい digunakan untuk siswa atau mahasiswa.',
          ),
          LessonQuestion(
            id: 'question_n5_002_application_people',
            phase: LessonPhase.application,
            scenario: 'Dua temanmu sama-sama mahasiswa.',
            prompt: 'Kalimat mana yang menyatakan bahwa Dini juga mahasiswa?',
            options: [
              'Dini も がくせい です。',
              'Dini を がくせい です。',
              'Dini に がくせい です。',
              'Dini で がくせい です。',
            ],
            correctIndex: 0,
            conceptId: 'grammar_n5_003_mo',
            skills: {
              LearningSkill.grammar,
              LearningSkill.vocabulary,
              LearningSkill.reading
            },
            explanation: 'も menggantikan は ketika menyatakan “Dini juga”.',
          ),
          LessonQuestion(
            id: 'question_n5_002_assessment_mo',
            phase: LessonPhase.assessment,
            prompt: 'Fungsi も dalam kalimat Dini も がくせい です adalah…',
            options: [
              'menambahkan “juga”',
              'menandai objek',
              'menandai waktu',
              'menunjukkan kepemilikan'
            ],
            correctIndex: 0,
            conceptId: 'grammar_n5_003_mo',
            skills: {LearningSkill.grammar, LearningSkill.reading},
            explanation:
                'も menambahkan subjek atau topik yang memiliki informasi serupa.',
          ),
          LessonQuestion(
            id: 'question_n5_002_assessment_gakusei',
            phase: LessonPhase.assessment,
            prompt: 'Pilih kata Jepang untuk “siswa/mahasiswa”.',
            options: ['がくせい', 'なまえ', 'わたし', 'インドネシア'],
            correctIndex: 0,
            conceptId: 'vocab_n5_003_gakusei',
            skills: {LearningSkill.vocabulary, LearningSkill.reading},
            explanation: 'がくせい berarti siswa atau mahasiswa.',
          ),
        ],
        masteryGate: const MasteryGate(minimumBySkill: {
          LearningSkill.vocabulary: 80,
          LearningSkill.grammar: 80,
        }),
        prerequisiteLessonIds: const ['lesson_mnn_001'],
        nextLessonId: 'lesson_mnn_003',
      ),
      LessonDefinition(
        id: 'lesson_mnn_003',
        unitId: 'unit_n5_01_identity',
        level: 'N5',
        sequence: 3,
        title: 'Asal dan bahasa',
        summary: 'Menyebut negara asal dan bahasa yang digunakan.',
        whyNow:
            'Lesson ini menyatukan perkenalan diri menjadi percakapan yang lebih lengkap dan menyiapkan topik tempat.',
        objectives: const [
          LearningObjective(
            id: 'objective_n5_003_origin',
            description:
                'Setelah lesson ini, kamu dapat menyatakan asal dan bahasa secara sederhana.',
            assessedSkills: {LearningSkill.vocabulary, LearningSkill.grammar},
          ),
        ],
        contents: const [
          CurriculumContent(
            id: 'vocab_n5_004_indonesia',
            title: 'インドネシア · Indoneshia',
            explanation: 'Indonesia.',
            skill: LearningSkill.vocabulary,
          ),
          CurriculumContent(
            id: 'grammar_n5_004_no_possessive',
            title: '～の',
            explanation:
                'Menghubungkan dua kata benda, misalnya bahasa dari suatu negara.',
            skill: LearningSkill.grammar,
          ),
        ],
        questions: const [
          LessonQuestion(
            id: 'question_n5_003_guided_no',
            phase: LessonPhase.guidedPractice,
            prompt: 'Lengkapi frasa: インドネシア ___ にほんご',
            options: ['の', 'を', 'も', 'で'],
            correctIndex: 0,
            conceptId: 'grammar_n5_004_no_possessive',
            skills: {LearningSkill.grammar, LearningSkill.reading},
            explanation: 'の menghubungkan dua kata benda: “bahasa Indonesia”.',
          ),
          LessonQuestion(
            id: 'question_n5_003_recall_indonesia',
            phase: LessonPhase.recall,
            prompt: 'インドネシア berarti…',
            options: ['Indonesia', 'Jepang', 'bahasa Jepang', 'sekolah'],
            correctIndex: 0,
            conceptId: 'vocab_n5_004_indonesia',
            skills: {LearningSkill.vocabulary, LearningSkill.reading},
            explanation: 'インドネシア adalah Indonesia.',
          ),
          LessonQuestion(
            id: 'question_n5_003_application_origin',
            phase: LessonPhase.application,
            scenario: 'Kamu ingin menyebut bahasa dari suatu negara.',
            prompt: 'Frasa mana yang memakai の dengan benar?',
            options: [
              'インドネシアの にほんご',
              'インドネシアを にほんご',
              'インドネシアも にほんご',
              'インドネシアで にほんご'
            ],
            correctIndex: 0,
            conceptId: 'grammar_n5_004_no_possessive',
            skills: {
              LearningSkill.grammar,
              LearningSkill.vocabulary,
              LearningSkill.reading
            },
            explanation: 'の menghubungkan negara dengan kata benda berikutnya.',
          ),
          LessonQuestion(
            id: 'question_n5_003_assessment_no',
            phase: LessonPhase.assessment,
            prompt: 'Partikel の paling sering digunakan untuk…',
            options: [
              'menghubungkan kata benda',
              'menandai tujuan',
              'menolak ajakan',
              'menyatakan waktu'
            ],
            correctIndex: 0,
            conceptId: 'grammar_n5_004_no_possessive',
            skills: {LearningSkill.grammar, LearningSkill.reading},
            explanation:
                'Pada level ini, の berfungsi menghubungkan atau menunjukkan relasi antarkata benda.',
          ),
          LessonQuestion(
            id: 'question_n5_003_assessment_country',
            phase: LessonPhase.assessment,
            prompt: 'Pilih penulisan Jepang untuk Indonesia.',
            options: ['インドネシア', 'がくせい', 'なまえ', 'はじめまして'],
            correctIndex: 0,
            conceptId: 'vocab_n5_004_indonesia',
            skills: {LearningSkill.vocabulary, LearningSkill.reading},
            explanation: 'インドネシア adalah Indonesia.',
          ),
        ],
        masteryGate: const MasteryGate(minimumBySkill: {
          LearningSkill.vocabulary: 80,
          LearningSkill.grammar: 80,
        }),
        prerequisiteLessonIds: const ['lesson_mnn_002'],
      ),
    ],
  );
}
