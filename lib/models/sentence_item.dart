class SentenceItem {
  const SentenceItem({
    required this.id,
    required this.level,
    required this.category,
    required this.japanese,
    required this.reading,
    required this.meaning,
    required this.pattern,
    required this.note,
  });

  final String id;
  final String level;
  final String category;
  final String japanese;
  final String reading;
  final String meaning;
  final String pattern;
  final String note;

  factory SentenceItem.fromJson(Map<String, dynamic> json) => SentenceItem(
        id: json['id'] as String? ?? '',
        level: json['level'] as String? ?? 'N5',
        category: json['category'] as String? ?? 'Umum',
        japanese: json['japanese'] as String? ?? '',
        reading: json['reading'] as String? ?? '',
        meaning: json['meaning'] as String? ?? '',
        pattern: json['pattern'] as String? ?? '',
        note: json['note'] as String? ?? '',
      );
}
