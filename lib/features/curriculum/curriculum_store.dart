// Penyimpanan progress Learning Path: offline-first.
//
// - Lokal: SharedPreferences (JSON) via AppController.
// - Cloud: Firestore via ProgressSyncService merge (union per-lesson).
// Format versioned agar aman untuk migrasi.

import 'dart:convert';

import 'curriculum_models.dart';

class CurriculumStore {
  const CurriculumStore._();

  static const storageKey = 'curriculumProgressV1';
  static const finalScoresKey = 'curriculumFinalScoresV1';
  static const activeLessonKey = 'curriculumActiveLessonId';
  static const activeLevelKey = 'curriculumActiveLevelId';

  static Map<String, UserLessonProgress> decodeProgress(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      final out = <String, UserLessonProgress>{};
      for (final entry in decoded.entries) {
        final record = UserLessonProgress.fromJson(entry.value);
        if (record != null) out['${entry.key}'] = record;
      }
      return out;
    } catch (_) {
      return {};
    }
  }

  static String encodeProgress(Map<String, UserLessonProgress> progress) =>
      jsonEncode(progress.map((k, v) => MapEntry(k, v.toJson())));

  static Map<String, int> decodeScores(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      final out = <String, int>{};
      for (final entry in decoded.entries) {
        final value = (entry.value as num?)?.toInt() ?? int.tryParse('${entry.value}') ?? 0;
        out['${entry.key}'] = value.clamp(0, 100).toInt();
      }
      return out;
    } catch (_) {
      return {};
    }
  }

  static String encodeScores(Map<String, int> scores) => jsonEncode(scores);

  /// Format sync (tanpa DateTime object): aman untuk Firestore.
  static Map<String, dynamic> toSyncMap(
    Map<String, UserLessonProgress> progress,
    Map<String, int> finalScores,
  ) =>
      {
        'progress': progress.map((k, v) => MapEntry(k, v.toJson())),
        'finalScores': Map<String, dynamic>.from(finalScores),
      };

  /// Merge dua snapshot sync per-lesson (newer updatedAt menang per lesson,
  /// completedActivityIds di-union, bestScore max, mastered OR).
  static ({Map<String, UserLessonProgress> progress, Map<String, int> scores})
      mergeSync(
    Map<String, dynamic>? local,
    Map<String, dynamic>? remote,
  ) {
    final lProgress = <String, UserLessonProgress>{};
    final rProgress = <String, UserLessonProgress>{};
    if (local?['progress'] is Map) {
      for (final e in (local!['progress'] as Map).entries) {
        final r = UserLessonProgress.fromJson(e.value);
        if (r != null) lProgress['${e.key}'] = r;
      }
    }
    if (remote?['progress'] is Map) {
      for (final e in (remote!['progress'] as Map).entries) {
        final r = UserLessonProgress.fromJson(e.value);
        if (r != null) rProgress['${e.key}'] = r;
      }
    }
    final merged = <String, UserLessonProgress>{};
    for (final id in {...lProgress.keys, ...rProgress.keys}) {
      final a = lProgress[id];
      final b = rProgress[id];
      if (a == null) {
        merged[id] = b!;
        continue;
      }
      if (b == null) {
        merged[id] = a;
        continue;
      }
      final newer = b.updatedAt.isAfter(a.updatedAt) ? b : a;
      final older = identical(newer, a) ? b : a;
      merged[id] = UserLessonProgress(
        lessonId: id,
        status: newer.status,
        completedActivityIds: {...a.completedActivityIds, ...b.completedActivityIds},
        bestScore: a.bestScore >= b.bestScore ? a.bestScore : b.bestScore,
        attempts: a.attempts >= b.attempts ? a.attempts : b.attempts,
        mastered: a.mastered || b.mastered,
        updatedAt: newer.updatedAt.isAfter(older.updatedAt) ? newer.updatedAt : older.updatedAt,
      );
    }
    final lScores = local?['finalScores'] is Map
        ? Map<String, dynamic>.from(local!['finalScores'] as Map)
        : <String, dynamic>{};
    final rScores = remote?['finalScores'] is Map
        ? Map<String, dynamic>.from(remote!['finalScores'] as Map)
        : <String, dynamic>{};
    final scores = <String, int>{};
    for (final k in {...lScores.keys, ...rScores.keys}) {
      final a = (lScores[k] as num?)?.toInt() ?? 0;
      final b = (rScores[k] as num?)?.toInt() ?? 0;
      scores[k.toString()] = a >= b ? a : b;
    }
    return (progress: merged, scores: scores);
  }
}
