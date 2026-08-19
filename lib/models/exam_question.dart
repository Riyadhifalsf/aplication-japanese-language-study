enum ExamType { jlpt, jft }

enum ExamSection { mojiGoi, bunpou, dokkai, choukai, conversation }

class ExamQuestion {
  const ExamQuestion({
    required this.id,
    required this.examType,
    required this.level,
    required this.stage,
    required this.section,
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    this.passage,
    this.audioText,
    this.point = 10,
  });

  final String id;
  final ExamType examType;
  final String level;
  final int stage;
  final ExamSection section;
  final String prompt;
  final String? passage;
  final String? audioText;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final int point;

  bool get hasAudio => audioText != null && audioText!.trim().isNotEmpty;
}

class ExamSessionPlan {
  const ExamSessionPlan({
    required this.examType,
    required this.level,
    required this.stage,
    required this.questions,
    required this.minutes,
  });

  final ExamType examType;
  final String level;
  final int stage;
  final List<ExamQuestion> questions;
  final int minutes;

  String get title {
    final examName = examType == ExamType.jlpt ? 'JLPT' : 'JFT-Basic';
    return '$examName $level · Paket $stage';
  }

  int get totalPoints => questions.fold(0, (sum, item) => sum + item.point);

  String get questionCountLabel => '${questions.length} soal';

  String get durationLabel => '$minutes menit';
}

String examTypeLabel(ExamType type) => type == ExamType.jlpt ? 'JLPT' : 'JFT-Basic';

String examSectionLabel(ExamSection section) {
  switch (section) {
    case ExamSection.mojiGoi:
      return '文字・語彙';
    case ExamSection.bunpou:
      return '文法';
    case ExamSection.dokkai:
      return '読解';
    case ExamSection.choukai:
      return '聴解';
    case ExamSection.conversation:
      return '会話表現';
  }
}

String examSectionIndonesian(ExamSection section) {
  switch (section) {
    case ExamSection.mojiGoi:
      return 'Huruf & Kosakata';
    case ExamSection.bunpou:
      return 'Tata Bahasa';
    case ExamSection.dokkai:
      return 'Pemahaman Bacaan';
    case ExamSection.choukai:
      return 'Pemahaman Mendengar';
    case ExamSection.conversation:
      return 'Percakapan & Ungkapan';
  }
}
