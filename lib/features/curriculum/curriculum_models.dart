// Struktur data Learning Path / Curriculum System.
//
// Hierarki: Level -> Unit -> Lesson -> Activity.
// File ini murni Dart (tanpa Flutter) agar mudah diuji dan dipakai
// offline-first. UI hanya membaca model ini lewat CurriculumEngine.
//
// Desain:
// - curriculum data (katalog) terpisah dari user progress.
// - lesson content & quiz data tetap memakai repository yang sudah ada
//   (kanji/vocabulary/grammar/readings/dll) via contentRef.
// - JFT/SSW boleh memakai ulang lesson dari Japanese Path via
//   `reusedLessonId` agar tidak duplikasi data.

/// Status satu lesson dari sudut pandang pengguna.
enum CurriculumLessonStatus {
  locked,
  available,
  inProgress,
  completed,
  mastered;

  String get label => switch (this) {
        CurriculumLessonStatus.locked => 'Terkunci',
        CurriculumLessonStatus.available => 'Tersedia',
        CurriculumLessonStatus.inProgress => 'Dipelajari',
        CurriculumLessonStatus.completed => 'Selesai',
        CurriculumLessonStatus.mastered => 'Dikuasai',
      };

  static CurriculumLessonStatus fromName(Object? value) {
    for (final s in values) {
      if (s.name == value) return s;
    }
    return CurriculumLessonStatus.locked;
  }
}

/// Jenis aktivitas di dalam satu lesson. Kombinasi per lesson dibuat
/// bervariasi agar pengguna tidak bosan.
enum CurriculumActivityType {
  vocabulary,
  kanji,
  grammar,
  exampleSentences,
  reading,
  listening,
  speaking,
  shadowing,
  conversation,
  quiz,
  review,
  writing,
  unitTest,
  bossTest,
  finalTest,
  mockTest,
  placementTest;

  String get label => switch (this) {
        CurriculumActivityType.vocabulary => 'Kosakata',
        CurriculumActivityType.kanji => 'Kanji',
        CurriculumActivityType.grammar => 'Tata Bahasa',
        CurriculumActivityType.exampleSentences => 'Contoh Kalimat',
        CurriculumActivityType.reading => 'Reading',
        CurriculumActivityType.listening => 'Listening',
        CurriculumActivityType.speaking => 'Speaking',
        CurriculumActivityType.shadowing => 'Shadowing',
        CurriculumActivityType.conversation => 'Kaiwa',
        CurriculumActivityType.quiz => 'Quiz',
        CurriculumActivityType.review => 'Review',
        CurriculumActivityType.writing => 'Menulis',
        CurriculumActivityType.unitTest => 'Unit Test',
        CurriculumActivityType.bossTest => 'Boss Test',
        CurriculumActivityType.finalTest => 'Final Test',
        CurriculumActivityType.mockTest => 'Mock Test',
        CurriculumActivityType.placementTest => 'Placement Test',
      };

  /// XP reward default per aktivitas (bisa di-override per activity).
  int get defaultXp => switch (this) {
        CurriculumActivityType.vocabulary => 10,
        CurriculumActivityType.kanji => 15,
        CurriculumActivityType.grammar => 15,
        CurriculumActivityType.exampleSentences => 10,
        CurriculumActivityType.reading => 15,
        CurriculumActivityType.listening => 20,
        CurriculumActivityType.speaking => 15,
        CurriculumActivityType.shadowing => 15,
        CurriculumActivityType.conversation => 15,
        CurriculumActivityType.quiz => 20,
        CurriculumActivityType.review => 10,
        CurriculumActivityType.writing => 15,
        CurriculumActivityType.unitTest => 50,
        CurriculumActivityType.bossTest => 50,
        CurriculumActivityType.finalTest => 100,
        CurriculumActivityType.mockTest => 50,
        CurriculumActivityType.placementTest => 0,
      };

  /// Skill terkait untuk adaptive learning & review system.
  String get skillKey => switch (this) {
        CurriculumActivityType.vocabulary => 'vocabulary',
        CurriculumActivityType.kanji => 'kanji',
        CurriculumActivityType.grammar => 'grammar',
        CurriculumActivityType.exampleSentences => 'grammar',
        CurriculumActivityType.reading => 'reading',
        CurriculumActivityType.listening => 'listening',
        CurriculumActivityType.speaking => 'speaking',
        CurriculumActivityType.shadowing => 'speaking',
        CurriculumActivityType.conversation => 'speaking',
        CurriculumActivityType.quiz => 'mixed',
        CurriculumActivityType.review => 'mixed',
        CurriculumActivityType.writing => 'kanji',
        CurriculumActivityType.unitTest => 'mixed',
        CurriculumActivityType.bossTest => 'mixed',
        CurriculumActivityType.finalTest => 'mixed',
        CurriculumActivityType.mockTest => 'mixed',
        CurriculumActivityType.placementTest => 'mixed',
      };

  static CurriculumActivityType fromName(Object? value) {
    for (final t in values) {
      if (t.name == value) return t;
    }
    return CurriculumActivityType.quiz;
  }
}

/// Satu aktivitas di dalam lesson.
///
/// [contentRef] adalah kunci opsional ke repository yang sudah ada,
/// misalnya `level:N5`, `category:daily`, `kanjiTheme:angka`.
/// [contentIds] adalah referensi eksplisit ke item konten
/// (vocab id int / grammar id / kanji id / phrase id sebagai string)
/// yang di-resolve via ContentRepository dan disajikan INLINE di lesson.
/// REFERENCE ≠ NAVIGATE AWAY: UI wajib menampilkan kontennya di dalam
/// lesson, bukan membuka halaman library global sebagai alur utama.
/// [routeHint] memberi tahu UI layar library mana yang dibuka sebagai
/// secondary action (detail global opsional).
/// [reusedLessonId] dipakai jalur JFT/SSW untuk memakai ulang materi
/// dari Japanese Path tanpa duplikasi data.
class LessonActivity {
  const LessonActivity({
    required this.id,
    required this.type,
    required this.title,
    this.description = '',
    this.xpReward,
    this.estimatedMinutes = 5,
    this.contentRef = '',
    this.contentIds = const [],
    this.routeHint = '',
    this.reusedLessonId,
  });

  final String id;
  final CurriculumActivityType type;
  final String title;
  final String description;
  final int? xpReward;
  final int estimatedMinutes;
  final String contentRef;
  final List<String> contentIds;
  final String routeHint;
  final String? reusedLessonId;

  int get xp => xpReward ?? type.defaultXp;

  Map<String, Object?> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'description': description,
        'xpReward': xpReward,
        'estimatedMinutes': estimatedMinutes,
        'contentRef': contentRef,
        'contentIds': contentIds,
        'routeHint': routeHint,
        'reusedLessonId': reusedLessonId,
      };

  static LessonActivity fromJson(Map<dynamic, dynamic> raw) =>
      LessonActivity(
        id: '${raw['id'] ?? ''}',
        type: CurriculumActivityType.fromName(raw['type']),
        title: '${raw['title'] ?? ''}',
        description: '${raw['description'] ?? ''}',
        xpReward: (raw['xpReward'] as num?)?.toInt(),
        estimatedMinutes: ((raw['estimatedMinutes'] as num?) ?? 5).toInt(),
        contentRef: '${raw['contentRef'] ?? ''}',
        contentIds: ((raw['contentIds'] as List? ?? const [])
            .map((e) => '$e')
            .toList(growable: false)),
        routeHint: '${raw['routeHint'] ?? ''}',
        reusedLessonId: raw['reusedLessonId'] as String?,
      );
}

/// Satu lesson: kombinasi 1-4 aktivitas yang bervariasi.
///
/// CONTENT = sumber materi reusable (di ContentRepository).
/// CURRICULUM = urutan pedagogis (field referensi di sini).
/// [objectives]: tujuan belajar ("Setelah lesson ini kamu dapat...").
/// [vocabularyIds]: id int vocabulary (sebagai string) khusus lesson ini.
/// [grammarIds]: id grammar (mis. "n5-wa") yang diajarkan di lesson ini.
/// [kanjiIds]: id int kanji (sebagai string) yang relevan.
/// [phraseIds]: id phrase (mis. "ph-0001") untuk materi salam/dialog.
/// [questionIds]: id soal khusus assessment lesson ini (bukan random).
/// Semua default kosong (backward compatible). Hanya isi dengan ID yang
/// BENAR-BENAR ada di data + relevan pedagogis — jangan mengarang mapping.
class CurriculumLesson {
  const CurriculumLesson({
    required this.id,
    required this.unitId,
    required this.levelId,
    required this.sequence,
    required this.title,
    this.subtitle = '',
    this.activities = const [],
    this.objectives = const [],
    this.vocabularyIds = const [],
    this.grammarIds = const [],
    this.kanjiIds = const [],
    this.phraseIds = const [],
    this.questionIds = const [],
    this.isFinalTest = false,
    this.isBossTest = false,
    this.isPlacement = false,
    this.requiredScore = 0,
    this.estimatedMinutes = 10,
  });

  final String id;
  final String unitId;
  final String levelId;
  final int sequence;
  final String title;
  final String subtitle;
  final List<LessonActivity> activities;
  final List<String> objectives;
  final List<String> vocabularyIds;
  final List<String> grammarIds;
  final List<String> kanjiIds;
  final List<String> phraseIds;
  final List<String> questionIds;
  final bool isFinalTest;
  final bool isBossTest;
  final bool isPlacement;
  final int requiredScore;
  final int estimatedMinutes;

  int get totalXp =>
      activities.fold<int>(0, (sum, activity) => sum + activity.xp);

  /// True bila lesson punya kurikulum inline nyata (bukan sekadar
  /// kumpulan shortcut): ada objectives atau referensi konten terisi.
  bool get hasInlineContent =>
      objectives.isNotEmpty ||
      vocabularyIds.isNotEmpty ||
      grammarIds.isNotEmpty ||
      kanjiIds.isNotEmpty ||
      phraseIds.isNotEmpty;

  /// Tipe dominan untuk ikon node di UI (aktivitas pertama non-review).
  CurriculumActivityType get primaryType {
    for (final activity in activities) {
      if (activity.type != CurriculumActivityType.review) {
        return activity.type;
      }
    }
    return activities.isEmpty
        ? CurriculumActivityType.quiz
        : activities.first.type;
  }

  bool get isTest =>
      isFinalTest ||
      isBossTest ||
      activities.any((a) =>
          a.type == CurriculumActivityType.unitTest ||
          a.type == CurriculumActivityType.finalTest ||
          a.type == CurriculumActivityType.bossTest ||
          a.type == CurriculumActivityType.mockTest);
}

/// Satu unit / chapter / stage berisi beberapa lesson berurutan.
class CurriculumUnit {
  const CurriculumUnit({
    required this.id,
    required this.levelId,
    required this.sequence,
    required this.title,
    this.subtitle = '',
    this.description = '',
    this.icon = 'book',
    this.lessons = const [],
  });

  final String id;
  final String levelId;
  final int sequence;
  final String title;
  final String subtitle;
  final String description;
  final String icon;
  final List<CurriculumLesson> lessons;
}

/// Satu level JLPT / JFT / SSW.
class CurriculumLevel {
  const CurriculumLevel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.sequence,
    required this.track,
    this.description = '',
    this.requiredPreviousLevelId,
    this.unlockMinScore = 70,
    this.units = const [],
  });

  final String id;
  final String title;
  final String subtitle;
  final int sequence;
  /// 'jlpt' atau 'work' (JFT/SSW).
  final String track;
  final String description;
  final String? requiredPreviousLevelId;
  final int unlockMinScore;
  final List<CurriculumUnit> units;

  List<CurriculumLesson> get allLessons =>
      [for (final unit in units) ...unit.lessons];

  int get totalLessons => allLessons.length;

  int get totalXp =>
      allLessons.fold<int>(0, (sum, lesson) => sum + lesson.totalXp);
}

/// Progress satu lesson milik pengguna. Disimpan offline-first di
/// SharedPreferences lalu disinkronkan ke Firestore via merge.
class UserLessonProgress {
  UserLessonProgress({
    required this.lessonId,
    this.status = CurriculumLessonStatus.available,
    this.completedActivityIds = const {},
    this.bestScore = 0,
    this.attempts = 0,
    this.mastered = false,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  final String lessonId;
  CurriculumLessonStatus status;
  Set<String> completedActivityIds;
  int bestScore;
  int attempts;
  bool mastered;
  DateTime updatedAt;

  Map<String, Object?> toJson() => {
        'lessonId': lessonId,
        'status': status.name,
        'completedActivityIds': completedActivityIds.toList()..sort(),
        'bestScore': bestScore,
        'attempts': attempts,
        'mastered': mastered,
        'updatedAt': updatedAt.toIso8601String(),
      };

  static UserLessonProgress? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final lessonId = '${raw['lessonId'] ?? ''}'.trim();
    if (lessonId.isEmpty) return null;
    return UserLessonProgress(
      lessonId: lessonId,
      status: CurriculumLessonStatus.fromName(raw['status']),
      completedActivityIds: ((raw['completedActivityIds'] as List? ?? const [])
          .map((e) => '$e')
          .toSet()),
      bestScore: ((raw['bestScore'] as num?) ?? 0).toInt().clamp(0, 100).toInt(),
      attempts: ((raw['attempts'] as num?) ?? 0).toInt().clamp(0, 1000000).toInt(),
      mastered: raw['mastered'] == true,
      updatedAt: DateTime.tryParse('${raw['updatedAt'] ?? ''}') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

/// Ringkasan progress satu level.
class UserLevelProgress {
  const UserLevelProgress({
    required this.levelId,
    required this.completedLessons,
    required this.totalLessons,
    required this.percent,
    required this.unlocked,
    required this.completed,
  });

  final String levelId;
  final int completedLessons;
  final int totalLessons;
  final double percent;
  final bool unlocked;
  final bool completed;
}

/// Syarat membuka level berikutnya (kombinasi, bukan XP saja).
class LevelUnlockState {
  const LevelUnlockState({
    required this.unlocked,
    required this.allLessonsDone,
    required this.finalPassed,
    required this.finalScore,
    required this.requiredScore,
    required this.reason,
  });

  final bool unlocked;
  final bool allLessonsDone;
  final bool finalPassed;
  final int finalScore;
  final int requiredScore;
  final String reason;
}

/// Rekomendasi adaptif: jalur utama tetap, tapi ada saran personal.
class AdaptiveRecommendation {
  const AdaptiveRecommendation({
    required this.title,
    required this.reason,
    required this.targetLessonId,
    required this.skillKey,
  });

  final String title;
  final String reason;
  final String? targetLessonId;
  final String skillKey;
}
