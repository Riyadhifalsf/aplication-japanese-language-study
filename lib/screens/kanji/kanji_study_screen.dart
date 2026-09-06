import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../state/app_controller.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/guest_preview_banner.dart';
import 'kanji_hiragana_quiz_screen.dart';
import 'kanji_library_screen.dart';
import 'kanji_mastery_quiz_screen.dart';
import 'kanji_review_screen.dart';
import 'kanji_similar_quiz_screen.dart';
import 'kanji_theme_quiz_screen.dart';

/// Pusat belajar Kanji yang menggabungkan pola belajar dari Kanji Study
/// dengan repository, progress, XP, review schedule, dan fitur kanji
/// yang sudah dimiliki aplikasi utama.
class KanjiStudyScreen extends StatelessWidget {
  const KanjiStudyScreen({super.key});

  void _open(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final target = app.selectedStudyLevel;
    final targetLevel =
        const {'N5', 'N4', 'N3', 'N2', 'N1'}.contains(target) ? target : 'N5';
    final total = app.repository.levelCount(targetLevel);
    final mastered = app.repository
        .kanjiForLevel(targetLevel)
        .where((k) => app.isKanjiMastered(k.id))
        .length;
    final progress = total == 0 ? 0.0 : mastered / total;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
          children: [
            const GuestPreviewBanner(),
            if (app.isGuestPreview) const SizedBox(height: 12),
            _Header(app: app),
            const SizedBox(height: 16),
            _HeroCard(
              level: targetLevel,
              mastered: mastered,
              total: total,
              progress: progress,
              due: app.dueKanjiReviewCount,
              onTap: () => _open(
                context,
                KanjiLibraryScreen(initialLevel: targetLevel),
              ),
            ),
            const SizedBox(height: 18),
            _StatsRow(app: app),
            const SizedBox(height: 24),
            _SectionTitle(
              title: 'Belajar Kanji',
              subtitle: 'Mulai dari materi, review, lalu latihan arti kanji.',
            ),
            const SizedBox(height: 12),
            _ActionGrid(
              actions: [
                _ActionData(
                  'Kumpulan Kanji',
                  '5.000 kanji',
                  Icons.translate_rounded,
                  AppTheme.seed,
                  () => _open(
                      context, KanjiLibraryScreen(initialLevel: targetLevel)),
                ),
                _ActionData(
                  'Review Hari Ini',
                  '${app.dueKanjiReviewCount} kartu',
                  Icons.notifications_active_rounded,
                  AppTheme.seed,
                  () => _open(
                      context,
                      KanjiReviewScreen(
                          sessionSize: app.cappedSessionSize(20))),
                ),
                _ActionData(
                  'Latihan Kanji',
                  'Arti Indonesia + detail',
                  Icons.workspace_premium_rounded,
                  AppTheme.seed,
                  () => _open(
                      context,
                      KanjiMasteryQuizScreen(
                        level: targetLevel,
                        sessionSize: app.cappedSessionSize(10),
                      )),
                ),
                _ActionData(
                  'Cari & Jelajah',
                  'Kanji + arti + bacaan',
                  Icons.search_rounded,
                  AppTheme.seed,
                  () =>
                      _open(context, KanjiLibraryScreen(initialLevel: 'Semua')),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SectionTitle(
              title: 'Level JLPT',
              subtitle: 'Pilih level dan lanjutkan dari progress terakhir.',
            ),
            const SizedBox(height: 12),
            for (final level in const ['N5', 'N4', 'N3', 'N2', 'N1'])
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _LevelTile(
                  level: level,
                  total: app.repository.levelCount(level),
                  mastered: app.repository
                      .kanjiForLevel(level)
                      .where((k) => app.isKanjiMastered(k.id))
                      .length,
                  selected: level == targetLevel,
                  onTap: () => _open(
                    context,
                    KanjiLibraryScreen(initialLevel: level),
                  ),
                ),
              ),
            const SizedBox(height: 14),
            _SectionTitle(
              title: 'Mode Latihan',
              subtitle:
                  'Variasikan latihan supaya kanji tidak cuma hafal bentuk.',
            ),
            const SizedBox(height: 12),
            _ModeCard(
              title: 'Kanji → Hiragana',
              subtitle: 'Lihat karakter, pilih bacaan yang tepat.',
              icon: Icons.spellcheck_rounded,
              onTap: () => _open(context, const KanjiHiraganaQuizScreen()),
            ),
            _ModeCard(
              title: 'Kuis Tema',
              subtitle:
                  'Belajar berdasarkan tema seperti alam, waktu, dan kehidupan.',
              icon: Icons.category_rounded,
              onTap: () => _open(context, const KanjiThemeQuizScreen()),
            ),
            _ModeCard(
              title: 'Kanji Mirip',
              subtitle:
                  'Latihan membedakan karakter yang bentuknya hampir sama.',
              icon: Icons.blur_on_rounded,
              onTap: () => _open(context, const KanjiSimilarQuizScreen()),
            ),
            const SizedBox(height: 18),
            _ReviewBanner(
              due: app.dueKanjiReviewCount,
              onTap: () => _open(context, const KanjiReviewScreen()),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.app});
  final AppController app;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.seed, AppTheme.primaryDark],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: const Text(
              '学',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kanji Study',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                Text(
                  'こんにちは、${app.profileName}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Badge(
            isLabelVisible: app.dueKanjiReviewCount > 0,
            label: Text('${app.dueKanjiReviewCount}'),
            child: IconButton.filledTonal(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const KanjiReviewScreen(),
                ),
              ),
              icon: const Icon(Icons.notifications_none_rounded),
            ),
          ),
        ],
      );
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.level,
    required this.mastered,
    required this.total,
    required this.progress,
    required this.due,
    required this.onTap,
  });

  final String level;
  final int mastered;
  final int total;
  final double progress;
  final int due;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.seed, AppTheme.accent, AppTheme.primaryDark],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppTheme.seed.withValues(alpha: .22),
                blurRadius: 24,
                offset: const Offset(0, 13),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TARGET HARI INI',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .8,
                ),
              ),
              const SizedBox(height: 7),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Latihan Kanji',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .16),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      level,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '$mastered/$total dikuasai · $due perlu direview',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        minHeight: 10,
                        backgroundColor: Colors.white24,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${(progress * 100).round()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                ],
              ),
            ],
          ),
        ),
      );
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.app});
  final AppController app;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: _StatCard(
              value: '${app.learnedKanjiIds.length}',
              label: 'dipelajari',
              icon: Icons.menu_book_rounded,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              value: '${app.masteredKanjiIds.length}',
              label: 'dikuasai',
              icon: Icons.verified_rounded,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              value: '${app.dueKanjiReviewCount}',
              label: 'review',
              icon: Icons.replay_rounded,
            ),
          ),
        ],
      );
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
  });
  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        height: 94,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withValues(alpha: .45),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 21),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid({required this.actions});
  final List<_ActionData> actions;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 620 ? 4 : 2;
          final gap = 10.0;
          final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final action in actions)
                SizedBox(
                  width: width,
                  height: 138,
                  child: _ActionCard(data: action),
                ),
            ],
          );
        },
      );
}

class _ActionData {
  const _ActionData(
    this.title,
    this.subtitle,
    this.icon,
    this.color,
    this.onTap,
  );
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.data});
  final _ActionData data;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: data.onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: data.color.withValues(alpha: .13),
                  foregroundColor: data.color,
                  child: Icon(data.icon),
                ),
                const Spacer(),
                Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  data.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.level,
    required this.total,
    required this.mastered,
    required this.selected,
    required this.onTap,
  });

  final String level;
  final int total;
  final int mastered;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : mastered / total;
    return Card(
      color: selected
          ? Theme.of(context)
              .colorScheme
              .primaryContainer
              .withValues(alpha: .55)
          : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Text(
                  level,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$mastered/$total dikuasai',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        minHeight: 7,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(width: 5),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Card(
          child: ListTile(
            onTap: onTap,
            leading: CircleAvatar(child: Icon(icon)),
            title: Text(title,
                style: const TextStyle(fontWeight: FontWeight.w900)),
            subtitle: Text(subtitle),
            trailing: const Icon(Icons.chevron_right_rounded),
          ),
        ),
      );
}

class _ReviewBanner extends StatelessWidget {
  const _ReviewBanner({required this.due, required this.onTap});
  final int due;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        color: Theme.of(context)
            .colorScheme
            .primaryContainer
            .withValues(alpha: .55),
        child: ListTile(
          onTap: onTap,
          leading: const CircleAvatar(child: Icon(Icons.replay_rounded)),
          title: Text(
            due > 0 ? 'Review $due kanji sekarang' : 'Review selesai',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          subtitle: Text(
            due > 0
                ? 'Spaced repetition akan menentukan kapan kartu muncul lagi.'
                : 'Belum ada kartu yang jatuh tempo. Bagus, lanjutkan materi baru.',
          ),
          trailing: const Icon(Icons.arrow_forward_rounded),
        ),
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
        ],
      );
}
