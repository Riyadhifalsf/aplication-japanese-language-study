import 'package:flutter/material.dart';

/// Misi Tersembunyi: pencapaian rahasia dengan syarat khusus.
///
/// Ide: user TIDAK diberi tahu syarat pastinya — hanya hint samar.
/// Yang terbuka tampil; yang terkunci tampil sebagai "???". Setiap misi
/// memberi bonus XP + notifikasi saat terbuka.
///
/// Syarat dirancang dari perilaku belajar nyata (waktu, konsistensi,
// * ketepatan, eksplorasi), bukan sekadar grind XP.
class QuestStats {
  const QuestStats({
    required this.hour,
    required this.streak,
    required this.dailyMasteredKanji,
    required this.dailyActiveSeconds,
    required this.perfectQuiz,
    required this.quizAnswered,
  });

  final int hour;
  final int streak;
  final int dailyMasteredKanji;
  final int dailyActiveSeconds;
  final bool perfectQuiz;
  final int quizAnswered;
}

class HiddenQuestDef {
  const HiddenQuestDef({
    required this.id,
    required this.title,
    required this.hint,
    required this.rewardXp,
    required this.icon,
    required this.check,
  });

  final String id;
  final String title;

  /// Petunjuk samar untuk misi yang belum terbuka.
  final String hint;
  final int rewardXp;
  final IconData icon;
  final bool Function(QuestStats s) check;
}

class HiddenQuests {
  HiddenQuests._();

  static const List<HiddenQuestDef> defs = [
    HiddenQuestDef(
      id: 'bangau-pagi',
      title: 'Bangau Pagi',
      hint: 'Ada yang rajin sebelum matahari terbit...',
      rewardXp: 50,
      icon: Icons.wb_twilight_rounded,
      check: _before6,
    ),
    HiddenQuestDef(
      id: 'burung-hantu',
      title: 'Burung Hantu',
      hint: 'Belajar paling nikmat saat semua orang tidur?',
      rewardXp: 50,
      icon: Icons.nights_stay_rounded,
      check: _after23,
    ),
    HiddenQuestDef(
      id: 'sempurna',
      title: 'Tanpa Cela',
      hint: 'Jawaban sempurna dalam satu sesi penuh...',
      rewardXp: 100,
      icon: Icons.verified_rounded,
      check: _perfect,
    ),
    HiddenQuestDef(
      id: 'pelahap-kanji',
      title: 'Pelahap Kanji',
      hint: 'Kuasai banyak kanji dalam sehari.',
      rewardXp: 100,
      icon: Icons.menu_book_rounded,
      check: _kanji5,
    ),
    HiddenQuestDef(
      id: 'maraton',
      title: 'Maraton 45',
      hint: 'Duduk lama demi satu tujuan.',
      rewardXp: 150,
      icon: Icons.directions_run_rounded,
      check: _marathon,
    ),
    HiddenQuestDef(
      id: 'seminggu-penuh',
      title: 'Seminggu Penuh',
      hint: 'Datang setiap hari tanpa putus.',
      rewardXp: 200,
      icon: Icons.calendar_month_rounded,
      check: _streak7,
    ),
  ];

  static bool _before6(QuestStats s) => s.hour < 6;
  static bool _after23(QuestStats s) => s.hour >= 23;
  static bool _perfect(QuestStats s) =>
      s.perfectQuiz && s.quizAnswered >= 5;
  static bool _kanji5(QuestStats s) => s.dailyMasteredKanji >= 5;
  static bool _marathon(QuestStats s) => s.dailyActiveSeconds >= 45 * 60;
  static bool _streak7(QuestStats s) => s.streak >= 7;

  static HiddenQuestDef? byId(String id) {
    for (final d in defs) {
      if (d.id == id) return d;
    }
    return null;
  }

  /// Kembalikan misi yang BARU terbuka (belum ada di [unlocked]).
  static List<HiddenQuestDef> checkUnlocked(
      QuestStats stats, Set<String> unlocked) {
    return defs
        .where((d) => !unlocked.contains(d.id) && d.check(stats))
        .toList();
  }
}
