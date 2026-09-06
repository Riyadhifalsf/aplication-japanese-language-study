import 'package:flutter_test/flutter_test.dart';

import 'package:japanese_study/services/progress_sync_service.dart';

void main() {
  group('ProgressSyncService.merge', () {
    test('counter pakai nilai terbesar agar XP tidak hilang', () {
      final merged = ProgressSyncService.merge(
        {'xp': 100, 'streak': 3, 'quizCorrect': 5},
        {'xp': 250, 'streak': 1, 'quizCorrect': 9},
      );
      expect(merged['xp'], 250);
      expect(merged['streak'], 3);
      expect(merged['quizCorrect'], 9);
    });

    test('set ID di-union (HP lama + HP baru bergabung)', () {
      final merged = ProgressSyncService.merge(
        {
          'learnedKanji': [1, 2, 3]
        },
        {
          'learnedKanji': [3, 4, 5]
        },
      );
      expect((merged['learnedKanji'] as List).toSet(), {1, 2, 3, 4, 5});
    });

    test('lokal kosong + server berisi = server mengisi ulang (union)', () {
      final merged = ProgressSyncService.merge(
        {'learnedKanji': [], 'xp': 0, 'streak': 0},
        {
          'learnedKanji': [7, 8],
          'xp': 120,
          'streak': 4
        },
      );
      expect((merged['learnedKanji'] as List).toSet(), {7, 8});
      expect(merged['xp'], 120);
      expect(merged['streak'], 4);
    });

    test('best score pakai max per key', () {
      final merged = ProgressSyncService.merge(
        {
          'examBestScores': {'a': 70, 'b': 90}
        },
        {
          'examBestScores': {'a': 85, 'c': 60}
        },
      );
      final scores = Map<String, dynamic>.from(merged['examBestScores'] as Map);
      expect(scores['a'], 85);
      expect(scores['b'], 90);
      expect(scores['c'], 60);
    });

    test('config pakai last-write-wins berdasarkan timestamp', () {
      final merged = ProgressSyncService.merge(
        {'studyGoal': 'JLPT'},
        {'studyGoal': 'JFT'},
        localUpdatedAt: {'studyGoal': 100},
        remoteUpdatedAt: {'studyGoal': 200},
      );
      expect(merged['studyGoal'], 'JFT');

      final merged2 = ProgressSyncService.merge(
        {'studyGoal': 'JLPT'},
        {'studyGoal': 'JFT'},
        localUpdatedAt: {'studyGoal': 300},
        remoteUpdatedAt: {'studyGoal': 200},
      );
      expect(merged2['studyGoal'], 'JLPT');
    });

    test('journal digabung unik dan dibatasi 2000', () {
      final merged = ProgressSyncService.merge(
        {
          'activityJournal': [
            {'id': '1', 'at': '2026-01-01'},
          ]
        },
        {
          'activityJournal': [
            {'id': '1', 'at': '2026-01-01'},
            {'id': '2', 'at': '2026-01-02'},
          ]
        },
      );
      final journal = merged['activityJournal'] as List;
      expect(journal.length, 2);
    });

    test('learning engine digabung per-record tanpa menghapus mastery lokal',
        () {
      final merged = ProgressSyncService.merge(
        {
          'learningEngineState': {
            'currentLessonId': 'lesson_mnn_001',
            'mastery': {
              'grammar_n5_001_desu:grammar': {
                'score': 80,
                'attemptCount': 2,
                'correctCount': 2,
                'updatedAt': '2026-09-07T08:00:00.000',
              },
            },
            'reviews': {},
            'mistakes': {},
            'lessonProgress': {},
          },
        },
        {
          'learningEngineState': {
            'currentLessonId': 'lesson_mnn_001',
            'mastery': {
              'vocab_n5_001_watashi:vocabulary': {
                'score': 100,
                'attemptCount': 1,
                'correctCount': 1,
                'updatedAt': '2026-09-07T09:00:00.000',
              },
            },
            'reviews': {},
            'mistakes': {},
            'lessonProgress': {},
          },
        },
      );

      final state =
          Map<String, dynamic>.from(merged['learningEngineState'] as Map);
      final mastery = Map<String, dynamic>.from(state['mastery'] as Map);
      expect(
          mastery.keys,
          containsAll([
            'grammar_n5_001_desu:grammar',
            'vocab_n5_001_watashi:vocabulary',
          ]));
    });
  });
}
