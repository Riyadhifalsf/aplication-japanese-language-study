class GrammarPoint {
  const GrammarPoint({
    required this.id,
    required this.pattern,
    required this.level,
    required this.title,
    required this.explanation,
    required this.formation,
    required this.examples,
  });

  final String id;
  final String pattern;
  final String level;
  final String title;
  final String explanation;
  final String formation;
  final List<GrammarExample> examples;

  factory GrammarPoint.fromJson(Map<String, dynamic> json) => GrammarPoint(
        id: json['id'] as String? ?? '',
        pattern: json['pattern'] as String? ?? '',
        level: json['level'] as String? ?? 'N5',
        title: json['title'] as String? ?? '',
        explanation: json['explanation'] as String? ?? '',
        formation: json['formation'] as String? ?? '',
        examples: (json['examples'] as List<dynamic>? ?? const [])
            .map((e) => GrammarExample.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
      );
}

class GrammarExample {
  const GrammarExample({
    required this.japanese,
    required this.reading,
    required this.meaning,
  });

  final String japanese;
  final String reading;
  final String meaning;

  factory GrammarExample.fromJson(Map<String, dynamic> json) => GrammarExample(
        japanese: json['japanese'] as String? ?? '',
        reading: json['reading'] as String? ?? '',
        meaning: json['meaning'] as String? ?? '',
      );
}
