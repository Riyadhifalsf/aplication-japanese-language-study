import 'dart:convert';

import 'package:flutter/material.dart';

import '../../state/app_controller.dart';
import '../kanji/kanji_review_screen.dart';
import '../kanji/kanji_study_screen.dart';
import '../notifications/notification_center_screen.dart';
import '../kana/kana_screen.dart';
import '../grammar/grammar_screen.dart';
import '../vocab/vocabulary_screen.dart';
import '../readings/reading_screen.dart';
import '../profile/profile_screen.dart';
import '../streak/streak_screen.dart';
import '../study/today_learning_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({required this.onOpenStudy, required this.onOpenQuiz, required this.onOpenProfile, super.key});

  final VoidCallback onOpenStudy;
  final VoidCallback onOpenQuiz;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    ImageProvider? photo;
    try {
      photo = app.profilePhotoData.isNotEmpty ? MemoryImage(base64Decode(app.profilePhotoData)) : null;
    } catch (_) {}

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
      children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${app.homeGreeting}, ${app.homeDisplayName}', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 3),
            Text(_subheading(), style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ])),
          Badge(
            isLabelVisible: app.hasUnreadNotifications || app.dueKanjiReviewCount > 0,
            label: Text(app.dueKanjiReviewCount > 99 ? '99+' : '${app.dueKanjiReviewCount}'),
            child: IconButton.filledTonal(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationCenterScreen())),
              icon: const Icon(Icons.notifications_rounded),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onOpenProfile,
            child: CircleAvatar(
              radius: 22,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              backgroundImage: photo,
              child: photo == null ? const Icon(Icons.person_rounded) : null,
            ),
          ),
        ]),
        const SizedBox(height: 18),
        _TodayKanji(app: app),
        const SizedBox(height: 14),
        _StreakSummary(app: app),
        const SizedBox(height: 14),
        _DailyGoal(app: app),
        const SizedBox(height: 20),
        const Text('Akses cepat', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        _QuickActions(onOpenStudy: onOpenStudy, onOpenQuiz: onOpenQuiz),
        const SizedBox(height: 16),
        _TodayMission(app: app),
      ],
    );
  }

  String _subheading() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Mulai hari dengan satu materi penting.';
    if (hour < 18) return 'Sedikit latihan hari ini tetap berarti.';
    return 'Tutup hari dengan review singkat.';
  }
}

class _TodayKanji extends StatelessWidget {
  const _TodayKanji({required this.app});
  final AppController app;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final kanji = app.repository.kanjiById(app.todayKanjiId ?? -1);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KanjiReviewScreen())),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(children: [
            Container(width: 78, height: 78, alignment: Alignment.center, decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(22)), child: Text(kanji?.character ?? app.todayKanjiCharacter, style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: cs.primary))),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Kanji hari ini', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(kanji?.preferredReading.isNotEmpty == true ? kanji!.preferredReading : 'Pelajari dan ulangi kanji hari ini', style: TextStyle(color: cs.onSurfaceVariant)),
              const SizedBox(height: 8),
              Text('Ketuk untuk mulai review', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: cs.primary)),
            ])),
            const Icon(Icons.chevron_right_rounded),
          ]),
        ),
      ),
    );
  }
}

class _StreakSummary extends StatelessWidget {
  const _StreakSummary({required this.app});
  final AppController app;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StreakScreen())),
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            CircleAvatar(backgroundColor: cs.primaryContainer, child: Icon(Icons.local_fire_department_rounded, color: cs.primary)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${app.streak} hari', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              Text('Rentetan belajar', style: TextStyle(color: cs.onSurfaceVariant)),
            ])),
            Text('Lihat semua', style: TextStyle(fontWeight: FontWeight.w800, color: cs.primary)),
          ]),
        ),
      ),
    );
  }
}

class _DailyGoal extends StatelessWidget {
  const _DailyGoal({required this.app});
  final AppController app;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Expanded(child: Text('Today Goal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
            Text('${app.dailyStudyMinutes} menit', style: TextStyle(fontWeight: FontWeight.w900, color: cs.primary)),
          ]),
          const SizedBox(height: 4),
          Text('Target hari ini diatur dari Pengaturan.', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          const SizedBox(height: 10),
          ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: app.dailyProgress, minHeight: 7)),
          const SizedBox(height: 6),
          Text('${app.dailyActiveMinutes} / ${app.dailyStudyMinutes} menit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cs.onSurfaceVariant)),
        ]),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onOpenStudy, required this.onOpenQuiz});
  final VoidCallback onOpenStudy;
  final VoidCallback onOpenQuiz;

  @override
  Widget build(BuildContext context) => Wrap(spacing: 10, runSpacing: 10, children: [
    _Quick('Learning aktif', Icons.play_lesson_rounded, onOpenStudy),
    _Quick('Quiz', Icons.quiz_rounded, onOpenQuiz),
    _Quick('Kana', Icons.translate_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KanaScreen()))),
    _Quick('Kanji', Icons.menu_book_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KanjiStudyScreen()))),
    _Quick('Grammar', Icons.rule_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GrammarScreen()))),
    _Quick('Kotoba', Icons.text_fields_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VocabularyScreen()))),
    _Quick('Reading', Icons.chrome_reader_mode_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReadingScreen()))),
  ]);
}

class _Quick extends StatelessWidget {
  const _Quick(this.title, this.icon, this.onTap);
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => SizedBox(width: 150, child: Card(child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(22), child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [Icon(icon, color: Theme.of(context).colorScheme.primary), const SizedBox(width: 8), Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)))])))));
}

class _TodayMission extends StatelessWidget {
  const _TodayMission({required this.app});
  final AppController app;
  @override
  Widget build(BuildContext context) {
    final lesson = app.dailyLearningPlan().currentLesson;
    return Card(child: InkWell(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TodayLearningScreen())), borderRadius: BorderRadius.circular(22), child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
      CircleAvatar(backgroundColor: Theme.of(context).colorScheme.primaryContainer, child: const Icon(Icons.flag_rounded)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Misi hari ini', style: TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 3),
        Text(lesson?.title ?? 'Review materi yang sudah dipelajari', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      ])),
      const Icon(Icons.chevron_right_rounded),
    ]))));
  }
}
