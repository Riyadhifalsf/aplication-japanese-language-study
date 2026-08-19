import '../models/vocabulary.dart';
import 'morphology_service.dart';

class VocabularyExample {
  const VocabularyExample({
    required this.japanese,
    required this.reading,
    required this.meaning,
    required this.particle,
    required this.grammarLevel,
    this.source = 'template',
  });

  final String japanese;
  final String reading;
  final String meaning;
  final String particle;
  final String grammarLevel;
  final String source;
}

class VocabularyExamplesService {
  static List<VocabularyExample> build(Vocabulary v) {
    final x = v.word;
    final r = v.reading.isEmpty ? x : v.reading;
    final pos = v.inferredPartOfSpeech;
    final examples = <VocabularyExample>[];

    if (pos.contains('動詞')) {
      final masu = MorphologyService.forms(v)
          .firstWhere((f) => f.label == 'Masu', orElse: () => MorphologyForm('Masu', '$xます', ''))
          .value;
      examples.addAll([
        VocabularyExample(japanese: '私は$masu。', reading: 'わたしは $masu。', meaning: 'Saya melakukan 「$x」.', particle: 'は', grammarLevel: 'N5'),
        VocabularyExample(japanese: '私が$masu。', reading: 'わたしが $masu。', meaning: 'Saya yang melakukan 「$x」.', particle: 'が', grammarLevel: 'N5'),
        VocabularyExample(japanese: '毎日$masu。', reading: 'まいにち $masu。', meaning: 'Setiap hari saya 「$x」.', particle: '—', grammarLevel: 'N5'),
        VocabularyExample(japanese: 'これを$masu。', reading: 'これを $masu。', meaning: 'Saya melakukan 「$x」 terhadap ini.', particle: 'を', grammarLevel: 'N5'),
        VocabularyExample(japanese: '学校で$masu。', reading: 'がっこうで $masu。', meaning: 'Saya melakukan 「$x」 di sekolah.', particle: 'で', grammarLevel: 'N5'),
        VocabularyExample(japanese: '友達と$masu。', reading: 'ともだちと $masu。', meaning: 'Saya melakukan 「$x」 bersama teman.', particle: 'と', grammarLevel: 'N5'),
        VocabularyExample(japanese: '明日も$masu。', reading: 'あしたも $masu。', meaning: 'Besok juga saya 「$x」.', particle: 'も', grammarLevel: 'N4'),
        VocabularyExample(japanese: '九時から$masu。', reading: 'くじから $masu。', meaning: 'Saya mulai 「$x」 dari jam sembilan.', particle: 'から', grammarLevel: 'N4'),
        VocabularyExample(japanese: '五時まで$masu。', reading: 'ごじまで $masu。', meaning: 'Saya 「$x」 sampai jam lima.', particle: 'まで', grammarLevel: 'N4'),
        VocabularyExample(japanese: '$xについて勉強します。', reading: '$r について べんきょうします。', meaning: 'Saya belajar tentang kata 「$x」.', particle: 'について', grammarLevel: 'N3'),
      ]);
    } else if (pos.contains('い形容詞') || pos.contains('な形容詞')) {
      examples.addAll([
        VocabularyExample(japanese: 'これは$xです。', reading: 'これは $rです。', meaning: 'Ini bersifat 「$x」.', particle: 'は', grammarLevel: 'N5'),
        VocabularyExample(japanese: '$x が好きです。', reading: '$r が すきです。', meaning: 'Saya suka 「$x」.', particle: 'が', grammarLevel: 'N5'),
        VocabularyExample(japanese: '$x を覚えます。', reading: '$r を おぼえます。', meaning: 'Saya menghafal kata 「$x」.', particle: 'を', grammarLevel: 'N5'),
        VocabularyExample(japanese: '学校で$xを使います。', reading: 'がっこうで $rを つかいます。', meaning: 'Saya menggunakan 「$x」 di sekolah.', particle: 'で', grammarLevel: 'N5'),
        VocabularyExample(japanese: '$xな人です。', reading: '$rな ひとです。', meaning: 'Dia orang yang 「$x」.', particle: 'な', grammarLevel: 'N5'),
        VocabularyExample(japanese: 'とても$xです。', reading: 'とても $rです。', meaning: 'Sangat 「$x」.', particle: '—', grammarLevel: 'N5'),
        VocabularyExample(japanese: '$xでも大丈夫です。', reading: '$rでも だいじょうぶです。', meaning: 'Bahkan kalau 「$x」, tidak masalah.', particle: 'でも', grammarLevel: 'N4'),
        VocabularyExample(japanese: '$xだから好きです。', reading: '$rだから すきです。', meaning: 'Saya suka karena 「$x」.', particle: 'から', grammarLevel: 'N4'),
        VocabularyExample(japanese: '$xなら分かります。', reading: '$rなら わかります。', meaning: 'Kalau 「$x」, saya mengerti.', particle: 'なら', grammarLevel: 'N4'),
        VocabularyExample(japanese: '$xについて話します。', reading: '$rについて はなします。', meaning: 'Saya berbicara tentang 「$x」.', particle: 'について', grammarLevel: 'N3'),
      ]);
    } else {
      examples.addAll([
        VocabularyExample(japanese: 'これは$xです。', reading: 'これは $rです。', meaning: 'Ini adalah 「$x」.', particle: 'は', grammarLevel: 'N5'),
        VocabularyExample(japanese: '$xがあります。', reading: '$rが あります。', meaning: 'Ada 「$x」.', particle: 'が', grammarLevel: 'N5'),
        VocabularyExample(japanese: '$xを見ます。', reading: '$rを みます。', meaning: 'Saya melihat 「$x」.', particle: 'を', grammarLevel: 'N5'),
        VocabularyExample(japanese: '$xに行きます。', reading: '$rに いきます。', meaning: 'Saya pergi ke 「$x」.', particle: 'に', grammarLevel: 'N5'),
        VocabularyExample(japanese: '$xで勉強します。', reading: '$rで べんきょうします。', meaning: 'Saya belajar dengan/di 「$x」.', particle: 'で', grammarLevel: 'N5'),
        VocabularyExample(japanese: '$xと話します。', reading: '$rと はなします。', meaning: 'Saya berbicara dengan 「$x」.', particle: 'と', grammarLevel: 'N5'),
        VocabularyExample(japanese: '$xもあります。', reading: '$rも あります。', meaning: 'Ada 「$x」 juga.', particle: 'も', grammarLevel: 'N5'),
        VocabularyExample(japanese: '$xから始めます。', reading: '$rから はじめます。', meaning: 'Saya mulai dari 「$x」.', particle: 'から', grammarLevel: 'N4'),
        VocabularyExample(japanese: '$xまで行きます。', reading: '$rまで いきます。', meaning: 'Saya pergi sampai 「$x」.', particle: 'まで', grammarLevel: 'N4'),
        VocabularyExample(japanese: '$xについて勉強します。', reading: '$rについて べんきょうします。', meaning: 'Saya belajar tentang 「$x」.', particle: 'について', grammarLevel: 'N3'),
      ]);
    }

    return examples;
  }
}
