// Logika Learning Path: status, progress, unlock, review, adaptive.
//
// Murni Dart agar bisa diuji tanpa Flutter. AppController hanya menyimpan
// state + meneruskan ke engine ini. Aturan unlock memakai KOMBINASI
// (lesson completion + unit completion + final test + mastery + XP),
// bukan XP saja — sesuai permintaan.

import 'curriculum_catalog.dart';
import 'curriculum_models.dart';

class CurriculumEngine {
  const CurriculumEngine._();

  /// Urutan lesson global dalam satu level (unit.sequence, lesson.sequence).
  static List<CurriculumLesson> orderedLessons(CurriculumLevel level) {
    final units = [...level.units]
      ..sort((a, b) => a.sequence.compareTo(b.sequence));
    final out = <CurriculumLesson>[];
    for (final unit in units) {
      final lessons = [...unit.lessons]
        ..sort((a, b) => a.sequence.compareTo(b.sequence));
      out.addAll(lessons);
    }
    return out;
  }

  /// Status satu lesson dengan aturan berurutan:
  /// lesson pertama selalu available; berikutnya terbuka bila sebelumnya
  /// completed/mastered. Final test terkunci sampai semua lesson non-final
  /// di unit/level-nya selesai (ditangani via previous).
  static CurriculumLessonStatus lessonStatus({
    required CurriculumLesson lesson,
    required List<CurriculumLesson> ordered,
    required Map<String, UserLessonProgress> progressById,
  }) {
    final saved = progressById[lesson.id];
    if (saved != null) {
      // Status tersimpan menang, kecuali lesson pertama yang belum pernah
      // disentuh tetap available.
      if (saved.status == CurriculumLessonStatus.completed && saved.mastered) {
        return CurriculumLessonStatus.mastered;
      }
      return saved.status;
    }
    final index = ordered.indexWhere((l) => l.id == lesson.id);
    if (index <= 0) return CurriculumLessonStatus.available;
    final prev = progressById[ordered[index - 1].id]?.status;
    if (prev == CurriculumLessonStatus.completed ||
        prev == CurriculumLessonStatus.mastered) {
      return CurriculumLessonStatus.available;
    }
    return CurriculumLessonStatus.locked;
  }

  static Map<String, CurriculumLessonStatus> statusesForLevel({
    required CurriculumLevel level,
    required Map<String, UserLessonProgress> progressById,
  }) {
    final ordered = orderedLessons(level);
    final out = <String, CurriculumLessonStatus>{};
    for (final lesson in ordered) {
      out[lesson.id] =
          lessonStatus(lesson: lesson, ordered: ordered, progressById: progressById);
    }
    return out;
  }

  /// Progress level: N5 — 43%, dst.
  static UserLevelProgress levelProgress({
    required CurriculumLevel level,
    required Map<String, UserLessonProgress> progressById,
    required bool unlocked,
  }) {
    final total = level.totalLessons;
    if (total == 0) {
      return UserLevelProgress(
          levelId: level.id,
          completedLessons: 0,
          totalLessons: 0,
          percent: 0,
          unlocked: unlocked,
          completed: false);
    }
    var done = 0;
    for (final lesson in level.allLessons) {
      final s = progressById[lesson.id]?.status;
      if (s == CurriculumLessonStatus.completed ||
          s == CurriculumLessonStatus.mastered) {
        done++;
      }
    }
    final completed = done >= total;
    return UserLevelProgress(
      levelId: level.id,
      completedLessons: done,
      totalLessons: total,
      percent: done / total,
      unlocked: unlocked,
      completed: completed,
    );
  }

  /// Progress unit: Unit 3 — 6/10 lesson selesai.
  static ({int done, int total, double percent}) unitProgress({
    required CurriculumUnit unit,
    required Map<String, UserLessonProgress> progressById,
  }) {
    final total = unit.lessons.length;
    if (total == 0) return (done: 0, total: 0, percent: 0);
    var done = 0;
    for (final lesson in unit.lessons) {
      final s = progressById[lesson.id]?.status;
      if (s == CurriculumLessonStatus.completed ||
          s == CurriculumLessonStatus.mastered) {
        done++;
      }
    }
    return (done: done, total: total, percent: done / total);
  }

  /// Lesson berikutnya yang harus dikerjakan (pertama available/inProgress).
  static CurriculumLesson? nextLesson({
    required CurriculumLevel level,
    required Map<String, UserLessonProgress> progressById,
  }) {
    final ordered = orderedLessons(level);
    final statuses =
        statusesForLevel(level: level, progressById: progressById);
    for (final lesson in ordered) {
      final s = statuses[lesson.id];
      if (s == CurriculumLessonStatus.available ||
          s == CurriculumLessonStatus.inProgress) {
        return lesson;
      }
    }
    return null;
  }

  /// Lesson yang sedang berjalan (inProgress) atau berikutnya.
  static CurriculumLesson? currentLesson({
    required CurriculumLevel level,
    required Map<String, UserLessonProgress> progressById,
    String? activeLessonId,
  }) {
    if (activeLessonId != null) {
      for (final lesson in level.allLessons) {
        if (lesson.id == activeLessonId) {
          final s = progressById[lesson.id]?.status;
          if (s != CurriculumLessonStatus.completed &&
              s != CurriculumLessonStatus.mastered) {
            return lesson;
          }
        }
      }
    }
    return nextLesson(level: level, progressById: progressById);
  }

  /// Cek unlock level berikutnya: butuh semua lesson selesai + final test
  /// dengan skor ≥ requiredScore. XP TIDAK membuka level (hanya bonus).
  static LevelUnlockState unlockStateFor({
    required CurriculumLevel level,
    required Map<String, UserLessonProgress> progressById,
    required Map<String, int> finalScores,
  }) {
    final prevId = level.requiredPreviousLevelId;
    if (prevId == null) {
      return const LevelUnlockState(
        unlocked: true,
        allLessonsDone: true,
        finalPassed: true,
        finalScore: 100,
        requiredScore: 0,
        reason: 'Level pertama selalu terbuka.',
      );
    }
    final prev = CurriculumCatalogData.levelById(prevId);
    if (prev == null) {
      return LevelUnlockState(
        unlocked: false,
        allLessonsDone: false,
        finalPassed: false,
        finalScore: 0,
        requiredScore: level.unlockMinScore,
        reason: 'Level sebelumnya tidak ditemukan.',
      );
    }
    var done = 0;
    for (final lesson in prev.allLessons) {
      final s = progressById[lesson.id]?.status;
      if (s == CurriculumLessonStatus.completed ||
          s == CurriculumLessonStatus.mastered) {
        done++;
      }
    }
    final allDone = done >= prev.totalLessons && prev.totalLessons > 0;
    // Skor final = nilai terbaik dari lesson finalTest di level sebelumnya.
    var best = 0;
    for (final lesson in prev.allLessons) {
      if (lesson.isFinalTest) {
        final fromProgress = progressById[lesson.id]?.bestScore ?? 0;
        final fromScores = finalScores[lesson.id] ?? 0;
        if (fromProgress > best) best = fromProgress;
        if (fromScores > best) best = fromScores;
      }
    }
    // Fallback: skor di peta finalScores dengan key levelId.
    final levelKeyScore = finalScores[prev.id] ?? 0;
    if (levelKeyScore > best) best = levelKeyScore;
    final required = level.unlockMinScore;
    final passed = best >= required;
    final unlocked = allDone && passed;
    final reason = !allDone
        ? 'Selesaikan ${prev.totalLessons - done} lesson lagi di ${prev.id}.'
        : (!passed
            ? 'Butuh final test ${prev.id} ≥ $required% (sekarang $best%).'
            : '${prev.id} lulus. ${level.id} terbuka.');
    return LevelUnlockState(
      unlocked: unlocked,
      allLessonsDone: allDone,
      finalPassed: passed,
      finalScore: best,
      requiredScore: required,
      reason: reason,
    );
  }

  /// Tandai aktivitas selesai. Mengembalikan XP yang didapat.
  /// Lesson menjadi completed bila semua aktivitas selesai; mastered bila
  /// skor test memenuhi requiredScore atau semua aktivitas + quiz lulus.
  static ({UserLessonProgress progress, int xpGained, bool lessonJustCompleted})
      completeActivity({
    required CurriculumLesson lesson,
    required Map<String, UserLessonProgress> progressById,
    required String activityId,
    int score = 0,
    required DateTime now,
  }) {
    final existing = progressById[lesson.id] ??
        UserLessonProgress(
            lessonId: lesson.id, status: CurriculumLessonStatus.inProgress);
    final completed = {...existing.completedActivityIds, activityId};
    existing.completedActivityIds = completed;
    existing.attempts++;
    if (score > existing.bestScore) existing.bestScore = score.clamp(0, 100);
    existing.updatedAt = now;
    if (existing.status == CurriculumLessonStatus.locked ||
        existing.status == CurriculumLessonStatus.available) {
      existing.status = CurriculumLessonStatus.inProgress;
    }
    var xp = 0;
    for (final activity in lesson.activities) {
      if (activity.id == activityId) {
        xp = activity.xp;
        break;
      }
    }
    var justCompleted = false;
    final allIds = lesson.activities.map((a) => a.id).toSet();
    final allDone = allIds.every(completed.contains);
    if (allDone) {
      final needsScore = lesson.isFinalTest || lesson.isBossTest || lesson.isTest;
      final passedScore =
          !needsScore || existing.bestScore >= (lesson.requiredScore == 0 ? 70 : lesson.requiredScore);
      if (passedScore) {
        if (existing.status != CurriculumLessonStatus.completed &&
            existing.status != CurriculumLessonStatus.mastered) {
          justCompleted = true;
        }
        existing.status = existing.mastered
            ? CurriculumLessonStatus.mastered
            : CurriculumLessonStatus.completed;
        // Bonus XP lesson test sudah termasuk di aktivitas; tambah bonus
        // kecil agar final terasa rewarding tanpa merusak ekonomi XP.
        if (lesson.isFinalTest) xp += 20;
      }
    }
    progressById[lesson.id] = existing;
    return (progress: existing, xpGained: xp, lessonJustCompleted: justCompleted);
  }

  /// Tandai mastered (mis. skor ≥90% dua kali atau review sempurna).
  static void markMastered(
    Map<String, UserLessonProgress> progressById,
    String lessonId, {
    required DateTime now,
  }) {
    final existing = progressById[lessonId] ??
        UserLessonProgress(lessonId: lessonId);
    existing.mastered = true;
    existing.status = CurriculumLessonStatus.mastered;
    existing.updatedAt = now;
    progressById[lessonId] = existing;
  }

  // -------------------------------------------------------------------------
  // Review system: materi yang sering salah muncul lebih sering.
  // Input: mistakeCount per skillKey + progress. Output: antrean review.
  // -------------------------------------------------------------------------

  /// Lesson review yang disarankan (weak kanji/vocab/grammar → review lesson).
  static List<CurriculumLesson> reviewQueue({
    required CurriculumLevel level,
    required Map<String, UserLessonProgress> progressById,
    required Map<String, int> mistakeBySkill,
    int limit = 5,
  }) {
    // Cari lesson bertipe review yang sudah terbuka & belum mastered.
    final statuses =
        statusesForLevel(level: level, progressById: progressById);
    final candidates = level.allLessons.where((lesson) {
      final isReview = lesson.activities.any((a) =>
          a.type == CurriculumActivityType.review ||
          a.type.skillKey == 'mixed' &&
              lesson.subtitle.toLowerCase().contains('review'));
      if (!isReview) return false;
      final s = statuses[lesson.id];
      return s == CurriculumLessonStatus.available ||
          s == CurriculumLessonStatus.inProgress;
    }).toList();
    // Urutkan berdasarkan skill yang paling lemah.
    int weight(CurriculumLesson lesson) {
      var w = 0;
      for (final a in lesson.activities) {
        w += mistakeBySkill[a.type.skillKey] ?? 0;
      }
      return w;
    }

    candidates.sort((a, b) => weight(b).compareTo(weight(a)));
    if (candidates.isNotEmpty) return candidates.take(limit).toList();
    // Fallback: lesson yang inProgress (belum selesai) sebagai review.
    final ordered = orderedLessons(level);
    return ordered
        .where((l) =>
            statuses[l.id] == CurriculumLessonStatus.inProgress)
        .take(limit)
        .toList();
  }

  // -------------------------------------------------------------------------
  // Adaptive: kurikulum utama tetap, tapi beri rekomendasi personal.
  // -------------------------------------------------------------------------

  static AdaptiveRecommendation? adaptiveRecommendation({
    required CurriculumLevel level,
    required Map<String, UserLessonProgress> progressById,
    required Map<String, int> mistakeBySkill,
    required Map<String, double> masteryBySkill,
  }) {
    if (mistakeBySkill.isEmpty && masteryBySkill.isEmpty) return null;
    // Skill terlemah = mistake terbanyak / mastery terendah.
    String? weakest;
    var worst = 0;
    for (final entry in mistakeBySkill.entries) {
      if (entry.value > worst && entry.value >= 2) {
        worst = entry.value;
        weakest = entry.key;
      }
    }
    weakest ??= _lowestMastery(masteryBySkill);
    if (weakest == null) return null;
    final ordered = orderedLessons(level);
    final statuses =
        statusesForLevel(level: level, progressById: progressById);
    // Cari lesson terbuka yang melatih skill terlemah.
    for (final lesson in ordered) {
      final s = statuses[lesson.id];
      if (s != CurriculumLessonStatus.available &&
          s != CurriculumLessonStatus.inProgress) {
        continue;
      }
      final trainsWeak = lesson.activities
          .any((a) => a.type.skillKey == weakest || a.type.skillKey == 'mixed');
      if (trainsWeak) {
        return AdaptiveRecommendation(
          title: switch (weakest) {
            'kanji' => 'Kanji Review',
            'vocabulary' => 'Vocabulary Review',
            'grammar' => 'Grammar Review',
            'listening' => 'Listening Practice',
            'reading' => 'Reading Practice',
            'speaking' => 'Speaking Practice',
            _ => 'Personal Review',
          },
          reason: switch (weakest) {
            'kanji' => 'Kanji sering salah — perkuat sebelum lanjut.',
            'vocabulary' => 'Banyak kosakata terlupa — ulangi yang lemah.',
            'grammar' => 'Pola grammar sering keliru — latihan terarah.',
            'listening' => 'Listening lemah — tambah latihan dengar.',
            'reading' => 'Reading perlu diperkuat — baca cerita pendek.',
            'speaking' => 'Speaking jarang dilatih — coba shadowing.',
            _ => 'Ada materi yang perlu diperkuat.',
          },
          targetLessonId: lesson.id,
          skillKey: weakest,
        );
      }
    }
    return null;
  }

  static String? _lowestMastery(Map<String, double> mastery) {
    if (mastery.isEmpty) return null;
    var key = mastery.keys.first;
    var min = mastery[key]!;
    for (final entry in mastery.entries) {
      if (entry.value < min) {
        min = entry.value;
        key = entry.key;
      }
    }
    // Hanya rekomendasikan bila mastery di bawah 70.
    return min < 70 ? key : null;
  }

  /// Sisipkan Personal Review otomatis setelah tiap 4 lesson selesai.
  static bool shouldInsertPersonalReview({
    required CurriculumLevel level,
    required Map<String, UserLessonProgress> progressById,
  }) {
    final progress = levelProgress(
        level: level, progressById: progressById, unlocked: true);
    if (progress.completedLessons == 0) return false;
    if (progress.completed) return false;
    return progress.completedLessons % 4 == 0;
  }
}
