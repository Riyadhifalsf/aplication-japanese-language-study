import '../state/app_controller.dart';

class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.value,
    required this.target,
  });

  final String id;
  final String title;
  final String description;
  final String icon;
  final int value;
  final int target;

  double get progress => target <= 0 ? 1 : (value / target).clamp(0, 1).toDouble();
  bool get unlocked => value >= target;
}

class AchievementService {
  AchievementService._();

  static List<Achievement> getAll(AppController app) => [
        Achievement(
          id: 'first-step',
          title: 'Langkah Pertama',
          description: 'Selesaikan aktivitas belajar pertamamu.',
          icon: '歩',
          value: app.activityJournal.isEmpty ? 0 : 1,
          target: 1,
        ),
        Achievement(
          id: 'streak-7',
          title: 'Ritme 7 Hari',
          description: 'Pertahankan rentetan belajar selama 7 hari.',
          icon: '火',
          value: app.streak,
          target: 7,
        ),
        Achievement(
          id: 'kanji-50',
          title: 'Kanji Hunter',
          description: 'Pelajari setidaknya 50 kanji.',
          icon: '日',
          value: app.learnedKanjiCount,
          target: 50,
        ),
        Achievement(
          id: 'kanji-200',
          title: 'Kanji Explorer',
          description: 'Pelajari setidaknya 200 kanji.',
          icon: '字',
          value: app.learnedKanjiCount,
          target: 200,
        ),
        Achievement(
          id: 'mastery-25',
          title: 'Mastery Builder',
          description: 'Kuasai 25 kanji.',
          icon: '極',
          value: app.masteredKanjiCount,
          target: 25,
        ),
        Achievement(
          id: 'quiz-100',
          title: 'Seratus Jawaban',
          description: 'Jawab total 100 soal latihan.',
          icon: '答',
          value: app.quizAnswered,
          target: 100,
        ),
        Achievement(
          id: 'accuracy-80',
          title: 'Akurasi 80%',
          description: 'Capai akurasi quiz minimal 80% setelah 20 jawaban.',
          icon: '精',
          value: app.quizAnswered >= 20 && app.quizAccuracy >= .8 ? 1 : 0,
          target: 1,
        ),
        Achievement(
          id: 'xp-1000',
          title: 'Seribu XP',
          description: 'Kumpulkan 1.000 XP.',
          icon: '星',
          value: app.xp,
          target: 1000,
        ),
        Achievement(
          id: 'active-600',
          title: '10 Jam Fokus',
          description: 'Kumpulkan 10 jam waktu aktif belajar.',
          icon: '時',
          value: app.totalActiveMinutes,
          target: 600,
        ),
      ];
}
