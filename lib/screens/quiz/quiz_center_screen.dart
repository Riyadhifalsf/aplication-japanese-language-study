import 'package:flutter/material.dart';

import '../../state/app_controller.dart';
import '../../widgets/entrance.dart';
import '../exams/exam_hub_screen.dart';
import '../kana/kana_screen.dart';
import '../kanji/kanji_hiragana_quiz_screen.dart';
import '../kanji/kanji_mastery_quiz_screen.dart';
import '../kanji/kanji_review_screen.dart';
import '../kanji/kanji_similar_quiz_screen.dart';
import '../review/mistake_review_screen.dart';
import '../games/game_hub_screen.dart';

class QuizCenterScreen extends StatelessWidget {
  const QuizCenterScreen({super.key});

  void _open(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    if (!app.contentReady) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.menu_book_rounded, size: 48),
              SizedBox(height: 12),
              Text('Menyiapkan Library…', style: TextStyle(fontWeight: FontWeight.w800)),
              SizedBox(height: 10),
              SizedBox(width: 120, child: LinearProgressIndicator()),
            ],
          ),
        ),
      );
    }

    final level = app.selectedStudyLevel == 'JFT' ? 'N5' : app.selectedStudyLevel;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
      children: [
        Entrance(
          keyName: 'library-header',
          child: _Section(
            title: 'Library latihan',
            subtitle: 'Pilih materi dan aktivitas yang ingin kamu latih.',
          ),
        ),
        const SizedBox(height: 10),
        _Grid(
          items: [
            _Item(
              'Latihan Kotoba',
              'Arti, bacaan, dan konteks',
              Icons.abc_rounded,
              () => _open(context, VocabularyQuizScreen(level: level, sessionSize: 15)),
            ),
            _Item(
              'Latihan Kanji',
              'Kanji → arti Bahasa Indonesia',
              Icons.translate_rounded,
              () => _open(context, KanjiMasteryQuizScreen(level: level, sessionSize: 15)),
            ),
            _Item(
              'Kanji → Hiragana',
              'Baca kanji dengan tepat',
              Icons.spellcheck_rounded,
              () => _open(context, const KanjiHiraganaQuizScreen()),
            ),
            _Item(
              'Kanji Mirip',
              'Bedakan karakter serupa',
              Icons.blur_on_rounded,
              () => _open(context, const KanjiSimilarQuizScreen()),
            ),
            _Item(
              'Review Jatuh Tempo',
              '${app.dueKanjiReviewCount} kanji siap direview',
              Icons.notifications_active_rounded,
              () => _open(context, const KanjiReviewScreen()),
            ),
            _Item(
              'Kana',
              'Hiragana & katakana',
              Icons.grid_view_rounded,
              () => _open(context, const KanaScreen()),
            ),
            _Item(
              'Ulasan Kesalahan',
              'Lihat dan ulangi jawaban yang salah',
              Icons.rate_review_rounded,
              () => _open(context, const MistakeReviewScreen()),
            ),
            _Item(
              'Games',
              'Typing Kana, Kotoba, dan Kanji',
              Icons.sports_esports_rounded,
              () => _open(context, const GameHubScreen()),
            ),
          ],
          enabled: true,
        ),
        const SizedBox(height: 22),
        _Section(
          title: 'Ujian & simulasi',
          subtitle: 'Simulasi ujian berada di sini, bukan di Library latihan.',
        ),
        const SizedBox(height: 10),
        _Grid(
          items: [
            _Item(
              'Simulasi JLPT',
              'N5 sampai N1',
              Icons.school_rounded,
              () => _open(context, const ExamHubScreen()),
            ),
            _Item(
              'Simulasi JFT-Basic',
              'Paket latihan A2',
              Icons.badge_rounded,
              () => _open(context, const ExamHubScreen(initialType: ExamType.jft)),
            ),
          ],
          enabled: true,
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      );
}

class _Grid extends StatelessWidget {
  const _Grid({required this.items, required this.enabled});

  final List<_Item> items;
  final bool enabled;

  @override
  Widget build(BuildContext context) => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 260,
          childAspectRatio: 1.18,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
        ),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final item = items[i];
          final on = item.enabledOverride ?? enabled;
          return Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: on ? item.onTap : null,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(child: Icon(on ? item.icon : Icons.lock_rounded)),
                        const Spacer(),
                        if (item.beta) const _BetaBadge(),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
}

class _BetaBadge extends StatelessWidget {
  const _BetaBadge();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          'BETA',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            color: Theme.of(context).colorScheme.onTertiaryContainer,
          ),
        ),
      );
}

class _Item {
  const _Item(
    this.title,
    this.subtitle,
    this.icon,
    this.onTap, {
    this.beta = false,
    this.enabledOverride,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool beta;
  final bool? enabledOverride;
}
