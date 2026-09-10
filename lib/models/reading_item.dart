import '../services/meaning_localizer.dart';
import '../services/romaji.dart';

class ReadingItem {
  const ReadingItem({
    required this.id,
    required this.level,
    required this.category,
    required this.title,
    required this.japanese,
    required this.reading,
    required this.meaning,
    required this.questions,
  });

  final String id;
  final String level;
  final String category;
  final String title;
  final String japanese;
  final String reading;
  final String meaning;

  String get romaji => level == 'N5' ? Romaji.toRomaji(reading) : '';
  final List<ReadingQuestion> questions;

  factory ReadingItem.fromJson(Map<String, dynamic> json) => ReadingItem(
        id: json['id'] as String? ?? '',
        level: json['level'] as String? ?? 'N5',
        category: json['category'] as String? ?? 'Umum',
        title: MeaningLocalizer.cleanId(json['title'] as String? ?? ''),
        japanese: json['japanese'] as String? ?? '',
        reading: json['reading'] as String? ?? '',
        meaning: MeaningLocalizer.cleanId(json['meaning'] as String? ?? ''),
        questions: (json['questions'] as List<dynamic>? ?? const [])
            .map((item) => ReadingQuestion.fromJson(item as Map<String, dynamic>))
            .toList(growable: false),
      );
}

class ReadingQuestion {
  const ReadingQuestion({required this.question, required this.answer});

  final String question;
  final String answer;

  factory ReadingQuestion.fromJson(Map<String, dynamic> json) => ReadingQuestion(
        question: MeaningLocalizer.cleanId(json['question'] as String? ?? ''),
        answer: MeaningLocalizer.cleanId(json['answer'] as String? ?? ''),
      );
}
