class CultureItem {
  const CultureItem({
    required this.id,
    required this.category,
    required this.title,
    required this.summary,
    required this.detail,
    required this.example,
    required this.tips,
  });

  final String id;
  final String category;
  final String title;
  final String summary;
  final String detail;
  final String example;
  final List<String> tips;

  factory CultureItem.fromJson(Map<String, dynamic> json) => CultureItem(
        id: json['id'] as String? ?? '',
        category: json['category'] as String? ?? 'Budaya',
        title: json['title'] as String? ?? '',
        summary: json['summary'] as String? ?? '',
        detail: json['detail'] as String? ?? '',
        example: json['example'] as String? ?? '',
        tips: (json['tips'] as List<dynamic>? ?? const [])
            .map((item) => '$item')
            .toList(growable: false),
      );
}
