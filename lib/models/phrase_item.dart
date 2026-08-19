class PhraseItem {
  const PhraseItem({
    required this.id,
    required this.category,
    required this.japanese,
    required this.reading,
    required this.meaning,
    required this.politeness,
    required this.note,
    required this.tags,
  });

  final String id;
  final String category;
  final String japanese;
  final String reading;
  final String meaning;
  final String politeness;
  final String note;
  final List<String> tags;

  factory PhraseItem.fromJson(Map<String, dynamic> json) => PhraseItem(
        id: json['id'] as String? ?? '',
        category: json['category'] as String? ?? 'Umum',
        japanese: json['japanese'] as String? ?? '',
        reading: json['reading'] as String? ?? '',
        meaning: json['meaning'] as String? ?? '',
        politeness: json['politeness'] as String? ?? 'Sopan',
        note: json['note'] as String? ?? '',
        tags: (json['tags'] as List<dynamic>? ?? const [])
            .map((item) => '$item')
            .toList(growable: false),
      );
}
