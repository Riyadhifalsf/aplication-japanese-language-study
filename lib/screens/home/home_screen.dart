import 'dart:convert';

import 'package:flutter/material.dart';

import '../../models/kanji.dart';
import '../../services/study_intelligence_service.dart';
import '../../state/app_controller.dart';
import '../../widgets/admob_native_slot.dart';
import '../../widgets/liquid_glass.dart';
import '../kanji/kanji_detail_screen.dart';
import '../notifications/notification_center_screen.dart';
import '../profile/study_stats_screen.dart';
import '../study/learning_path_screen.dart';

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
    final recommendation = StudyIntelligenceService.recommend(app);
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
        Row(
          children: [
            Tooltip(
              message: 'Buka profil',
              child: GestureDetector(
                onTap: onOpenProfile,
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .primaryContainer,
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
            ),
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
          ],
        ),
        const SizedBox(height: 14),
        _StreakCard(app: app),
        const SizedBox(height: 16),
        _TodayKanjiCarousel(app: app),
        if (!app.isPremium) ...[
          const SizedBox(height: 16),
          AdmobNativeSlot(hidden: false),
        ],
        const SizedBox(height: 18),
        const Text(
          'Jalur JLPT',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final level in const ['N5', 'N4', 'N3', 'N2', 'N1'])
              ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(level),
                    if (!app.isLevelUnlocked(level))
                      const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Icon(Icons.lock_rounded, size: 13),
                      ),
                  ],
                ),
                selected: app.selectedStudyLevel == level,
                onSelected: (_) {
                  if (!app.isLevelUnlocked(level)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Login untuk membuka level yang terkunci.',
                        ),
                      ),
                    );
                    return;
                  }
                  app.setSelectedStudyLevel(level);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LearningPathScreen(initialLevel: level),
                    ),
                  );
                },
              ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.auto_stories_rounded,
                title: 'Mulai belajar',
                subtitle:
                    '${app.dailyXp}/${AppController.dailyGoal} XP hari ini',
                onTap: onOpenStudy,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionCard(
                icon: Icons.quiz_rounded,
                title: 'Pusat Quiz',
                subtitle: 'Akurasi ${(app.quizAccuracy * 100).round()}%',
                onTap: onOpenQuiz,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Icons.auto_awesome_rounded),
            title: const Text(
              'Rekomendasi cerdas',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            subtitle: Text(recommendation.reason),
            trailing: const Icon(Icons.chevron_right_rounded),
          ),
        ),
        const SizedBox(height: 14),
        _HomeProgressCard(app: app),
      ],
    );
  }

  static String _homeSubheading(DateTime now) {
    if (now.hour < 12) return 'Hari baru untuk satu langkah kecil.';
    if (now.hour < 18) return 'Lanjutkan latihanmu saat ritmenya masih hangat.';
    return 'Tutup hari dengan sedikit review.';
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

    return LiquidGlass(
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

class _HomeProgressCard extends StatelessWidget {
  const _HomeProgressCard({required this.app});

  final AppController app;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final photo = app.profilePhotoData.isNotEmpty
        ? MemoryImage(base64Decode(app.profilePhotoData))
        : null;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const StudyStatsScreen(),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 27,
                backgroundColor: cs.primaryContainer,
                backgroundImage: photo,
                child: photo == null
                    ? Text(
                        app.profileName.isEmpty
                            ? '日'
                            : app.profileName.substring(0, 1).toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Progress kamu',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _Mini('XP', '${app.xp}'),
                        _Mini('Streak', '${app.streak}'),
                        _Mini('Kanji', '${app.learnedKanjiCount}'),
                      ],
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

class _Mini extends StatelessWidget {
  const _Mini(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              CircleAvatar(child: Icon(icon)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
