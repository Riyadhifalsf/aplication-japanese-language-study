import 'dart:convert';

import 'package:flutter/material.dart';

import '../../models/kanji.dart';
import '../../state/app_controller.dart';
import '../../widgets/continue_learning_card.dart';
import '../../widgets/entrance.dart';
import '../../widgets/learning_components.dart';
import '../kanji/kanji_detail_screen.dart';
import '../kanji/kanji_study_screen.dart';
import '../notifications/notification_center_screen.dart';
import '../streak/streak_screen.dart';
import '../study/today_learning_screen.dart';
import '../vocab/vocabulary_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({required this.onOpenStudy, required this.onOpenQuiz, required this.onOpenProfile, super.key});
  final VoidCallback onOpenStudy;
  final VoidCallback onOpenQuiz;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final today = DateTime.now();
    ImageProvider? headerPhoto;
    try {
      headerPhoto = app.profilePhotoData.isNotEmpty ? MemoryImage(base64Decode(app.profilePhotoData)) : null;
    } catch (_) {
      headerPhoto = null;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 34),
      children: [
        Entrance(
          keyName: 'home-header',
          child: Row(
            children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${app.homeGreeting}, ${app.homeDisplayName}', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 3),
                  Text(_homeSubheading(today), style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ]),
              ),
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
                  backgroundImage: headerPhoto,
                  child: headerPhoto == null
                      ? (app.isAuthenticated
                          ? Text(app.homeDisplayName.isEmpty ? '日' : app.homeDisplayName.substring(0, 1).toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900))
                          : const Icon(Icons.person_rounded))
                      : null,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Streak dan Kanji hari ini sengaja dinaikkan agar menjadi fokus utama Home.
        Entrance(keyName: 'home-streak', child: _StreakCard(app: app)),
        const SizedBox(height: 14),
        Entrance(keyName: 'home-kanji', delay: const Duration(milliseconds: 40), child: _TodayKanjiCarousel(app: app)),
        const SizedBox(height: 18),

        const Text('Saat ini belajar', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        const Entrance(keyName: 'home-continue', child: ContinueLearningCard()),
        const SizedBox(height: 18),

        const Text('Akses utama', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _HomeShortcutCard(label: 'Kanji Today', icon: Icons.wb_sunny_rounded, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KanjiStudyScreen())))),
            const SizedBox(width: 10),
            Expanded(child: _HomeShortcutCard(label: 'Vocab Review', icon: Icons.menu_book_rounded, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VocabularyScreen())))),
            const SizedBox(width: 10),
            Expanded(child: _HomeShortcutCard(label: 'Streak', icon: Icons.local_fire_department_rounded, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StreakScreen())))),
          ],
        ),
        const SizedBox(height: 18),
        Entrance(keyName: 'home-mission', delay: const Duration(milliseconds: 80), child: _TodayMissionCard(app: app)),
        const SizedBox(height: 18),
        const _HomeFooter(),
      ],
    );
  }

  static String _homeSubheading(DateTime now) {
    if (now.hour < 12) return 'Hari baru untuk satu langkah kecil.';
    if (now.hour < 18) return 'Lanjutkan latihanmu saat ritmenya masih hangat.';
    return 'Tutup hari dengan sedikit review.';
  }
}

class _HomeShortcutCard extends StatelessWidget {
  const _HomeShortcutCard({required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 6),
              Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
            ]),
          ),
        ),
      );
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.app});
  final AppController app;
  static const _kanji = ['月', '火', '水', '木', '金', '土', '日'];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final today = DateTime.now();
    final monday = today.subtract(Duration(days: today.weekday - 1));
    return InkWell(
      borderRadius: BorderRadius.circular(26),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StreakScreen())),
      child: Card(
        color: cs.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${app.streak} hari rentetan', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                Text('Konsistensi belajar minggu ini.', style: TextStyle(color: cs.onSurfaceVariant)),
              ])),
              StreakBadge(streak: app.streak),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i == 6 ? 0 : 6),
                    child: _KanjiStreak(item: _kanji[i], active: app.hasStudyOnDate(monday.add(Duration(days: i))), selected: i == today.weekday - 1),
                  ),
                ),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _KanjiStreak extends StatelessWidget {
  const _KanjiStreak({required this.item, required this.active, required this.selected});
  final String item;
  final bool active;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minHeight: 58),
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 3),
      decoration: BoxDecoration(
        color: active ? cs.primary : cs.surface.withValues(alpha: .48),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: selected ? cs.onPrimaryContainer : cs.outlineVariant, width: selected ? 2 : 1),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        FittedBox(fit: BoxFit.scaleDown, child: Text(item, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: active ? cs.onPrimary : cs.onSurface))),
        const SizedBox(height: 2),
        Icon(active ? Icons.check_circle_rounded : Icons.remove_rounded, size: 15, color: active ? cs.onPrimary : cs.onSurfaceVariant),
      ]),
    );
  }
}

class _TodayKanjiCarousel extends StatelessWidget {
  const _TodayKanjiCarousel({required this.app});
  final AppController app;

  @override
  Widget build(BuildContext context) {
    final learned = app.learnedKanjiIds.map((id) => app.repository.kanjiById(id)).whereType<Kanji>().toList();
    final fallback = app.repository.kanji.where((k) => app.isLevelUnlocked(k.level)).toList();
    final source = (learned.isNotEmpty ? learned : fallback).toList()..sort((a, b) => a.id.compareTo(b.id));
    if (source.isEmpty) return const SizedBox.shrink();
    final seed = DateTime.now().difference(DateTime(2020, 1, 1)).inDays % source.length;
    final cards = List.generate(5, (i) => source[(seed + i) % source.length]);
    final sourceIds = cards.map((k) => k.id).toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Expanded(child: Text('Kanji hari ini', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900))),
        Text('5 kartu · geser', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ]),
      const SizedBox(height: 10),
      SizedBox(
        height: 164,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: cards.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, index) => _KanjiTodayCard(app: app, kanji: cards[index], sourceIds: sourceIds),
        ),
      ),
    ]);
  }
}

class _KanjiTodayCard extends StatelessWidget {
  const _KanjiTodayCard({required this.app, required this.kanji, required this.sourceIds});
  final AppController app;
  final Kanji kanji;
  final List<int> sourceIds;

  @override
  Widget build(BuildContext context) {
    final reading = app.adaptiveReading(reading: kanji.preferredReading, level: kanji.level);
    final learned = app.learnedKanjiIds.contains(kanji.id);
    return SizedBox(
      width: 166,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => KanjiDetailScreen(initialId: kanji.id, sourceIds: sourceIds))),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(kanji.character, style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(kanji.meaning, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
              if (reading.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(reading, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
              const Spacer(),
              Row(children: [
                Icon(learned ? Icons.check_circle_rounded : Icons.arrow_forward_rounded, size: 16, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 5),
                Expanded(child: Text(learned ? 'Sudah dipelajari' : 'Buka detail', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.primary))),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}

class _TodayMissionCard extends StatelessWidget {
  const _TodayMissionCard({required this.app});
  final AppController app;

  @override
  Widget build(BuildContext context) {
    final plan = app.dailyLearningPlan();
    final lesson = plan.currentLesson;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TodayLearningScreen())),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            CircleAvatar(radius: 27, backgroundColor: Theme.of(context).colorScheme.primaryContainer, child: const Icon(Icons.flag_rounded)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Yang perlu dipelajari sekarang', style: TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(lesson?.title ?? 'Review dan pertahankan materi yang sudah dikuasai', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text(lesson?.whyNow ?? 'Review, latihan, dan lesson berikutnya dipilih dari progresmu sekarang.', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ])),
            const Icon(Icons.chevron_right_rounded),
          ]),
        ),
      ),
    );
  }
}

class _HomeFooter extends StatelessWidget {
  const _HomeFooter();
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
          child: Row(children: [
            Container(width: 42, height: 42, alignment: Alignment.center, decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: Theme.of(context).colorScheme.primaryContainer), child: const Icon(Icons.auto_awesome_rounded)),
            const SizedBox(width: 12),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Pelan-pelan, yang penting berlanjut.', style: TextStyle(fontWeight: FontWeight.w900)),
              SizedBox(height: 3),
              Text('Satu sesi yang selesai lebih berguna daripada banyak target yang tidak sempat disentuh.', style: TextStyle(fontSize: 12, height: 1.35)),
            ])),
          ]),
        ),
      );
}
