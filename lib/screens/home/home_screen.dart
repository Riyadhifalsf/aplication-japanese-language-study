import 'dart:convert';

import 'package:flutter/material.dart';

import '../../models/kanji.dart';
import '../../state/app_controller.dart';
import '../../widgets/admob_native_slot.dart';
import '../../widgets/continue_learning_card.dart';
import '../../widgets/entrance.dart';
import '../../widgets/learning_components.dart';
import '../../widgets/liquid_glass.dart';
import '../kanji/kanji_detail_screen.dart';
import '../kanji/kanji_study_screen.dart';
import '../notifications/notification_center_screen.dart';
import '../kana/kana_screen.dart';
import '../grammar/grammar_screen.dart';
import '../vocab/vocabulary_screen.dart';
import '../readings/reading_screen.dart';
import '../review/mistake_review_screen.dart';
import '../streak/streak_screen.dart';
import '../study/today_learning_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    required this.onOpenStudy,
    required this.onOpenQuiz,
    required this.onOpenProfile,
    super.key,
  });

  final VoidCallback onOpenStudy;
  final VoidCallback onOpenQuiz;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final today = DateTime.now();
    ImageProvider? headerPhoto;
    try {
      headerPhoto = app.profilePhotoData.isNotEmpty
          ? MemoryImage(base64Decode(app.profilePhotoData))
          : null;
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${app.homeGreeting}, ${app.homeDisplayName}',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _homeSubheading(today),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Badge(
                isLabelVisible:
                    app.hasUnreadNotifications || app.dueKanjiReviewCount > 0,
                label: Text(
                  app.dueKanjiReviewCount > 99
                      ? '99+'
                      : '${app.dueKanjiReviewCount}',
                ),
                child: IconButton.filledTonal(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationCenterScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.notifications_rounded),
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: 'Buka profil',
                child: GestureDetector(
                  onTap: onOpenProfile,
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    backgroundImage: headerPhoto,
                    child: headerPhoto == null
                        ? (app.isAuthenticated
                            ? Text(
                                app.homeDisplayName.isEmpty
                                    ? '日'
                                    : app.homeDisplayName
                                        .substring(0, 1)
                                        .toUpperCase(),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w900),
                              )
                            : const Icon(Icons.person_rounded))
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
        // HEADER meta: level + XP + streak (jawab: progress/streak/pencapaian).
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            LevelBadge(level: app.level),
            XPIndicator(xp: app.xp),
            StreakBadge(streak: app.streak),
          ],
        ),
        const SizedBox(height: 14),
        // CURRENT LEARNING (jawab: sedang belajar apa + harus apa sekarang).
        const Text('Saat ini belajar',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        const Entrance(
          keyName: 'home-continue',
          child: ContinueLearningCard(),
        ),
        const SizedBox(height: 16),
        // DAILY GOAL (jawab: pencapaian hari ini).
        _DailyGoalCard(app: app),
        const SizedBox(height: 16),
        Entrance(
          keyName: 'home-streak',
          delay: const Duration(milliseconds: 35),
          child: _StreakCard(app: app),
        ),
        const SizedBox(height: 16),
        Entrance(
          keyName: 'home-kanji',
          delay: const Duration(milliseconds: 60),
          child: _TodayKanjiCarousel(app: app),
        ),
        const SizedBox(height: 16),
        const Text('Akses cepat', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        _ShortcutSlider(
          items: [
            _HomeShortcut('Pusat Quiz', Icons.quiz_rounded, onOpenQuiz),
            _HomeShortcut('Misi hari ini', Icons.flag_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TodayLearningScreen()))),
            _HomeShortcut('Kana', Icons.translate_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KanaScreen()))),
            _HomeShortcut('Kanji', Icons.menu_book_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KanjiStudyScreen()))),
            _HomeShortcut('Grammar', Icons.rule_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GrammarScreen()))),
            _HomeShortcut('Kotoba', Icons.text_fields_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VocabularyScreen()))),
            _HomeShortcut('Reading', Icons.chrome_reader_mode_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReadingScreen()))),
          ],
        ),
        const SizedBox(height: 16),
        Entrance(keyName: 'home-mission', delay: const Duration(milliseconds: 80), child: _TodayMissionCard(app: app)),
        // Iklan tetap tampil (bukan paywall). Premium check dihapus Phase 1.
        const SizedBox(height: 16),
        AdmobNativeSlot(hidden: false),
      ],
    );
  }

  static String _homeSubheading(DateTime now) {
    if (now.hour < 12) return 'Hari baru untuk satu langkah kecil.';
    if (now.hour < 18) return 'Lanjutkan latihanmu saat ritmenya masih hangat.';
    return 'Tutup hari dengan sedikit review.';
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
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TodayLearningScreen()),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 27,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: const Icon(Icons.flag_rounded),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Yang perlu dipelajari sekarang',
                        style: TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(
                      lesson?.title ??
                          'Review dan pertahankan materi yang sudah dikuasai',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      lesson?.whyNow ??
                          'Tidak ada lesson baru yang boleh dibuka sebelum katalog berikutnya tersedia.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
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

    // Ketuk untuk membuka kalender streak (Rentetan Belajar).
    return InkWell(
      borderRadius: BorderRadius.circular(26),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const StreakScreen()),
      ),
      child: LiquidGlass(
        padding: const EdgeInsets.all(18),
        tint: cs.primaryContainer,
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${app.streak} hari rentetan',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          Text(
            'Kanji hari ini aktif setelah kamu belajar.',
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i == 6 ? 0 : 6),
                    child: _KanjiStreak(
                      item: _kanji[i],
                      active: app.hasStudyOnDate(monday.add(Duration(days: i))),
                      selected: i == today.weekday - 1,
                    ),
                  ),
                ),
            ],
          ),
        ],
        ),
      ),
    );
  }
}

class _KanjiStreak extends StatelessWidget {
  const _KanjiStreak({
    required this.item,
    required this.active,
    required this.selected,
  });

  final String item;
  final bool active;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(17),
        color: active
            ? scheme.primaryContainer
            : scheme.surfaceContainerHighest.withValues(alpha: .55),
        border: Border.all(
          color: selected
              ? scheme.primary
              : (active ? scheme.primaryContainer : scheme.outlineVariant),
          width: selected ? 1.8 : 1,
        ),
      ),
      child: Text(
        item,
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w900,
          color: active ? scheme.primary : scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _TodayKanjiCarousel extends StatelessWidget {
  const _TodayKanjiCarousel({required this.app});

  final AppController app;

  @override
  Widget build(BuildContext context) {
    final learned = app.learnedKanjiIds
        .map((id) => app.repository.kanjiById(id))
        .whereType()
        .toList();
    final fallback = app.repository.kanji
        .where((k) => app.isLevelUnlocked(k.level))
        .toList();
    final source = (learned.isNotEmpty ? learned : fallback).toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    if (source.isEmpty) return const SizedBox.shrink();

    final seed =
        DateTime.now().difference(DateTime(2020, 1, 1)).inDays % source.length;
    final cards = List.generate(5, (i) => source[(seed + i) % source.length]);
    final sourceIds = cards.map<int>((k) => k.id).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Kanji hari ini',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
            ),
            Text(
              '5 kartu · geser',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 164,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: cards.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              return _KanjiTodayCard(
                app: app,
                kanji: cards[index],
                sourceIds: sourceIds,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _KanjiTodayCard extends StatelessWidget {
  const _KanjiTodayCard({
    required this.app,
    required this.kanji,
    required this.sourceIds,
  });

  final AppController app;
  final Kanji kanji;
  final List<int> sourceIds;

  @override
  Widget build(BuildContext context) {
    final reading = app.adaptiveReading(
      reading: kanji.preferredReading,
      level: kanji.level,
    );
    final learned = app.learnedKanjiIds.contains(kanji.id);

    return SizedBox(
      width: 166,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => KanjiDetailScreen(
                  initialId: kanji.id as int,
                  sourceIds: sourceIds,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kanji.character,
                  style: const TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  kanji.meaning,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                if (reading.isNotEmpty)
                  Text(
                    reading,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                const Spacer(),
                Row(
                  children: [
                    Icon(
                      learned
                          ? Icons.check_circle_rounded
                          : Icons.arrow_forward_rounded,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        learned ? 'Sudah dipelajari' : 'Buka detail',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DailyGoalCard extends StatelessWidget {
  const _DailyGoalCard({required this.app});

  final AppController app;

  @override
  Widget build(BuildContext context) {
    final goal = app.dailyGoalXp;
    final done = app.dailyXp.clamp(0, goal);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text("Today's Goal",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              ),
              Text('$done / $goal XP',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 10),
          LearningProgressBar(value: app.dailyProgress),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: [
              for (final g in AppController.allowedDailyGoals)
                ChoiceChip(
                  label: Text('$g'),
                  selected: goal == g,
                  onSelected: (_) => app.setDailyGoal(g),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            done >= goal
                ? 'Target harian tercapai. Pertahankan streak!'
                : 'Selesaikan 1 lesson untuk mendekati target.',
            style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions(
      {required this.onOpenStudy, required this.onOpenQuiz, required this.app});

  final VoidCallback onOpenStudy;
  final VoidCallback onOpenQuiz;
  final AppController app;

  @override
  Widget build(BuildContext context) => GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: .78,
        children: [
          _QuickTile(
              icon: Icons.auto_stories_rounded,
              label: 'Learn',
              onTap: onOpenStudy),
          _QuickTile(
              icon: Icons.refresh_rounded,
              label: 'Review',
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const MistakeReviewScreen()))),
          _QuickTile(
              icon: Icons.translate_rounded,
              label: 'Kanji',
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const KanjiStudyScreen()))),
          _QuickTile(
              icon: Icons.quiz_rounded, label: 'Practice', onTap: onOpenQuiz),
        ],
      );
}

class _QuickTile extends StatelessWidget {
  const _QuickTile(
      {required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 6),
              Text(label,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      );
}

class _HomeShortcut {
  const _HomeShortcut(this.title, this.icon, this.onTap);
  final String title;
  final IconData icon;
  final VoidCallback onTap;
}

class _ShortcutSlider extends StatelessWidget {
  const _ShortcutSlider({required this.items});
  final List<_HomeShortcut> items;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 116,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = items[index];
          return SizedBox(
            width: 148,
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: item.onTap,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(child: Icon(item.icon)),
                      const Spacer(),
                      Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 3),
                      const Text('Buka', style: TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
