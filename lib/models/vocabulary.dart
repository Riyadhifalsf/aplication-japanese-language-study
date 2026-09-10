import '../services/meaning_localizer.dart';

enum VocabularyGenderUse { neutral, masculine, feminine, both }

class Vocabulary {
  const Vocabulary({
    required this.id,
    required this.word,
    required this.reading,
    required this.meaning,
    required this.level,
  });

  final int id;
  final String word;
  final String reading;
  final String meaning;
  final String level;

  Map<String, dynamic> toJson() => {
        'id': id,
        'word': word,
        'reading': reading,
        'meaning': meaning,
        'level': level,
      };

  /// Japanese does not have grammatical gender for ordinary nouns.
  /// This describes gender/register nuance when the word has one.
  VocabularyGenderUse get genderUse {
    const masculine = {
      '俺', 'おれ', '僕', 'ぼく', '俺たち', '俺ら', '兄貴', '親父', '父ちゃん',
    };
    const feminine = {
      'あたし', '私たち', 'うち', '姉貴', 'お母さん', '母ちゃん',
    };
    const both = {'私', 'わたし', '自分'};
    if (masculine.contains(word)) return VocabularyGenderUse.masculine;
    if (feminine.contains(word)) return VocabularyGenderUse.feminine;
    if (both.contains(word)) return VocabularyGenderUse.both;
    return VocabularyGenderUse.neutral;
  }

  String get genderLabel => switch (genderUse) {
        VocabularyGenderUse.masculine => 'Maskulin · cenderung laki-laki',
        VocabularyGenderUse.feminine => 'Feminin · cenderung perempuan',
        VocabularyGenderUse.both => 'Umum · laki-laki & perempuan',
        VocabularyGenderUse.neutral => 'Netral · tidak bergender',
      };

  /// Lightweight POS classification used by the conjugation lab.
  String get inferredPartOfSpeech {
    if (word.endsWith('する') || meaning.contains('melakukan')) return 'する動詞';
    if (word.endsWith('く') || word.endsWith('ぐ') || word.endsWith('す') ||
        word.endsWith('つ') || word.endsWith('ぬ') || word.endsWith('ぶ') ||
        word.endsWith('む') || word.endsWith('る')) {
      return '動詞 / kemungkinan verba';
    }
    if (word.endsWith('い') && !word.endsWith('ない')) return 'い形容詞 / kemungkinan';
    if (meaning.contains('kata sifat') || meaning.contains('bersifat')) return 'な形容詞 / kemungkinan';
    return '名詞 / kata benda';
  }

  factory Vocabulary.fromJson(Map<String, dynamic> json) => Vocabulary(
        id: (json['id'] as num).toInt(),
        word: json['word'] as String? ?? '',
        reading: json['reading'] as String? ?? '',
        meaning: MeaningLocalizer.cleanId(json['meaning'] as String? ?? ''),
        level: json['level'] as String? ?? 'N5',
      );
}
