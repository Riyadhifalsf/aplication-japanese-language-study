import '../services/meaning_localizer.dart';

class Kanji {
  const Kanji({
    required this.id,
    required this.character,
    required this.level,
    required this.meaning,
    required this.onyomi,
    required this.kunyomi,
    required this.radical,
    required this.radicalName,
    required this.radicalMeaning,
    required this.strokes,
    required this.themes,
    required this.vocabularyIds,
    required this.relatedIds,
  });

  final int id;
  final String character;
  final String level;
  final String meaning;
  final String onyomi;
  final String kunyomi;
  final String radical;
  final String radicalName;
  final String radicalMeaning;
  final int strokes;
  final List<String> themes;
  final List<int> vocabularyIds;
  final List<int> relatedIds;

  bool get hasCompleteMetadata =>
      meaning.isNotEmpty &&
      meaning != 'belum dipetakan' &&
      (onyomi.isNotEmpty || kunyomi.isNotEmpty);

  String get preferredReading {
    final raw = kunyomi.isNotEmpty && kunyomi != '—' ? kunyomi : onyomi;
    if (raw.isEmpty) return character;
    return raw
        .split(RegExp(r'[、,・/]'))
        .first
        .replaceAll(RegExp(r'[.\-]'), '')
        .trim();
  }

  factory Kanji.fromJson(Map<String, dynamic> json) => Kanji(
        id: (json['id'] as num).toInt(),
        character: json['char'] as String? ?? '',
        level: json['level'] as String? ?? 'N5',
        meaning: MeaningLocalizer.cleanId(json['meaning'] as String? ?? ''),
        onyomi: json['on'] as String? ?? '',
        kunyomi: json['kun'] as String? ?? '',
        radical: json['radical'] as String? ?? '',
        radicalName: json['radicalName'] as String? ?? '',
        radicalMeaning: MeaningLocalizer.cleanId(json['radicalMeaning'] as String? ?? ''),
        strokes: int.tryParse('${json['strokes'] ?? 0}') ?? 0,
        themes: (json['themes'] as List<dynamic>? ?? const [])
            .map((e) => '$e')
            .toList(growable: false),
        vocabularyIds: (json['vocabIds'] as List<dynamic>? ?? const [])
            .map((e) => (e as num).toInt())
            .toList(growable: false),
        relatedIds: (json['relatedIds'] as List<dynamic>? ?? const [])
            .map((e) => (e as num).toInt())
            .toList(growable: false),
      );
}
