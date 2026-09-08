import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../models/exam_question.dart';
import '../../state/app_controller.dart';
import '../../services/study_intelligence_service.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/announcement_strip.dart';
import '../../widgets/ad_slot.dart';
import '../culture/culture_screen.dart';
import '../counters/counter_catalog_screen.dart';
import '../dialogs/dialog_screen.dart';
import '../exams/exam_hub_screen.dart';
import '../grammar/grammar_screen.dart';
import '../kana/kana_screen.dart';
import '../kanji/kanji_library_screen.dart';
import '../kanji/kanji_study_screen.dart';
import '../kanji/kanji_review_screen.dart';
import '../phrases/phrase_screen.dart';
import '../readings/reading_screen.dart';
import '../sentences/sentence_screen.dart';
import '../vocab/vocabulary_screen.dart';
import '../curriculum/curriculum_path_screen.dart';
import '../../features/curriculum/curriculum_catalog.dart';
import 'today_learning_screen.dart';
import 'learning_tracks_screen.dart';
import '../profile/study_stats_screen.dart';
import '../games/game_hub_screen.dart';
import '../review/mistake_review_screen.dart';

class StudyHubScreen extends StatelessWidget {
  const StudyHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
      children: [
        const _StudyHeader(),
        const SizedBox(height: 14),
        _ContinuePath(app: app),
        const SizedBox(height: 16),
        _StudyOverview(app: app),
        const AnnouncementStrip(),
        AdSlot(key: const ValueKey('study-ad')),
        const SizedBox(height: 12),
        _RecommendationCard(app: app),
        const SizedBox(height: 22),
        _StudyShelf(
            title: 'Akses cepat',
            subtitle: 'Materi yang sering kamu gunakan.',
            cards: [
              _StudyCardData(
                  title: 'Kanji',
                  subtitle: 'Materi kanji, flashcard, dan review',
                  icon: Icons.translate_rounded,
                  color: const Color(0xFFFFA62B),
                  badge: '${app.masteredKanjiIds.length} dikuasai',
                  progress: app.masteredKanjiIds.length / 5000,
                  screen: const KanjiStudyScreen()),
            ]),
        const SizedBox(height: 22),
        _StudyShelf(
          title: 'Ruang latihan pintar',
          subtitle: 'Fitur yang menyesuaikan diri dengan progresmu.',
          cards: [
            _StudyCardData(
              title: 'Ulasan Kesalahan',
              subtitle: 'Kesalahan yang paling perlu kamu perbaiki',
              icon: Icons.rate_review_rounded,
              color: const Color(0xFFEF4444),
              badge: 'Smart review',
              screen: MistakeReviewScreen(),
            ),
            const _StudyCardData(
              title: 'Statistik Belajar',
              subtitle: 'Ringkasan XP, streak, waktu, dan mastery',
              icon: Icons.insights_rounded,
              color: Color(0xFF315C7E),
              badge: 'Insight',
              screen: StudyStatsScreen(),
            ),
          ],
        ),
        const SizedBox(height: 22),
        _StudyShelf(
          title: 'Jalur utama belajar',
          subtitle: 'Ikuti path bab demi bab seperti course modern.',
          cards: [
            const _StudyCardData(
              title: 'Misi hari ini',
              subtitle: 'Urutan lesson, review, dan remedial yang jelas',
              icon: Icons.flag_rounded,
              color: Color(0xFF6D4AFF),
              badge: 'Mulai di sini',
              screen: TodayLearningScreen(),
            ),
            _StudyCardData(
              title: 'Learning',
              subtitle: 'Beginner → N5 → N1 + Work Path',
              icon: Icons.route_rounded,
              color: const Color(0xFFD92D20),
              badge: 'Recommended',
              progress: app
                  .curriculumLevelProgress(app.curriculumActiveLevelId)
                  .percent,
              screen: CurriculumPathScreen(
                  initialLevel: app.curriculumActiveLevelId),
            ),
            _StudyCardData(
              title: 'Kanji Study',
              subtitle: 'Pendalaman kanji sebagai tambahan materi',
              icon: Icons.auto_awesome_rounded,
              color: const Color(0xFFFFA62B),
              badge: '${app.masteredKanjiIds.length} dikuasai',
              progress: app.masteredKanjiIds.length / 5000,
              screen: const KanjiStudyScreen(),
            ),
            const _StudyCardData(
              title: 'Jalur JLPT & JFT',
              subtitle: 'N5–N1 · A1 Prep → A2',
              icon: Icons.alt_route_rounded,
              color: Color(0xFF17A673),
              badge: 'Target',
              screen: LearningTracksScreen(),
            ),
            const _StudyCardData(
              title: 'Latihan Kana',
              subtitle: 'A I U E O dan yōon',
              icon: Icons.grid_view_rounded,
              color: Color(0xFF17A673),
              badge: 'あ ア',
              screen: KanaScreen(),
            ),
            _StudyCardData(
              title: 'Frasa Cepat',
              subtitle: 'Sopan, santai, gaul',
              icon: Icons.forum_rounded,
              color: const Color(0xFFE64E64),
              badge: '${app.repository.phrases.length}',
              screen: const PhraseScreen(),
            ),
            const _StudyCardData(
              title: 'Dialog',
              subtitle: 'Percakapan dan alat terjemah',
              icon: Icons.chat_bubble_rounded,
              color: Color(0xFF315C7E),
              badge: '会話',
              screen: DialogScreen(),
            ),
            _StudyCardData(
              title: 'Cerita Buku',
              subtitle: 'Cerita utuh dan alat terjemah',
              icon: Icons.auto_stories_rounded,
              color: const Color(0xFF20A4F3),
              badge: 'Panjang',
              screen: const ReadingScreen(),
            ),
            const _StudyCardData(
                title: 'Games',
                subtitle: 'Typing Kana, Kotoba, Kanji',
                icon: Icons.sports_esports_rounded,
                color: Color(0xFFB42318),
                badge: 'Play',
                screen: GameHubScreen()),
          ],
        ),
        const SizedBox(height: 16),
        _StudyShelf(
            title: 'Pilih materi',
            subtitle:
                'Level aktif menentukan materi Learning; Library tetap lengkap.',
            cards: [
              _StudyCardData(
                  title: 'Learning aktif',
                  subtitle: 'Buka semua bab dan sub-bab pada levelmu',
                  icon: Icons.assignment_turned_in_rounded,
                  color: const Color(0xFFD92D20),
                  badge: 'BEBAS',
                  screen: const CurriculumPathScreen()),
            ]),
        const SizedBox(height: 24),
        _StudyShelf(
          title: 'Materi inti',
          subtitle: 'Bank materi utama aplikasi.',
          cards: [
            _StudyCardData(
              title: 'Kumpulan Kanji',
              subtitle: '5.000 kanji bertema',
              icon: Icons.translate_rounded,
              color: AppTheme.seed,
              progress: app.masteredKanjiIds.length / 5000,
              badge: '${app.masteredKanjiIds.length}/5000',
              screen: const KanjiLibraryScreen(),
            ),
            _StudyCardData(
              title: 'Gudang Kosakata',
              subtitle: '10.000 kosakata ID',
              icon: Icons.menu_book_rounded,
              color: const Color(0xFF3687FF),
              progress: app.masteredVocabularyIds.length / 10000,
              badge: '${app.masteredVocabularyIds.length}/10000',
              screen: const VocabularyScreen(),
            ),
            const _StudyCardData(
              title: 'Penghitung Jepang',
              subtitle: 'Josuushi 1–100 N5–N1',
              icon: Icons.format_list_numbered_rounded,
              color: Color(0xFFB91C1C),
              badge: '助数詞',
              screen: CounterCatalogScreen(),
            ),
            _StudyCardData(
              title: 'Peta Bunpou',
              subtitle: '${app.repository.grammar.length} pola tata bahasa',
              icon: Icons.account_tree_rounded,
              color: const Color(0xFFFF8A4C),
              badge: '${app.repository.grammar.length}',
              screen: const GrammarScreen(),
            ),
            _StudyCardData(
              title: 'Pola Kalimat',
              subtitle: '${app.repository.sentences.length} contoh',
              icon: Icons.subject_rounded,
              color: const Color(0xFF00A6A6),
              badge: '${app.repository.sentences.length}',
              screen: const SentenceScreen(),
            ),
            _StudyCardData(
              title: 'Budaya Jepang',
              subtitle: 'Etika, kerja, musim',
              icon: Icons.temple_buddhist_rounded,
              color: const Color(0xFFEF6C00),
              badge: '${app.repository.culture.length}',
              screen: const CultureScreen(),
            ),
          ],
        ),

      ],
    );
  }

  static void _open(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}

/// Kartu "Lanjutkan belajar": alur sejelas mungkin — user selalu tahu
/// persis bab berapa yang dikerjakan berikutnya (ala path Duolingo/Busuu).
///
/// Deep-link langsung ke bab berikutnya; bila level selesai, tawarkan review.
class _ContinuePath extends StatelessWidget {
  const _ContinuePath({required this.app});
  final AppController app;

  @override
  Widget build(BuildContext context) {
    final levelId = {'N5', 'N4', 'N3', 'N2', 'N1'}.contains(app.selectedStudyLevel)
        ? app.selectedStudyLevel
        : 'N5';
    final level = CurriculumCatalogData.levelById(levelId);
    if (level == null) return const SizedBox.shrink();
    final progress = app.curriculumLevelProgress(level.id);
    final next = app.curriculumContinue()?.lesson;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [scheme.primary, const Color(0xFF4A1110)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('CONTINUE · ', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
            Text(level.id, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
            const Spacer(),
            Text('${(progress.percent * 100).round()}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          ]),
          const SizedBox(height: 10),
          Text(
            next == null ? 'Jelajahi materi ${level.id}' : next.title,
            style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 5),
          Text(
            next?.subtitle ?? 'Semua bab dan sub-bab pada level ini tersedia untuk dipelajari kapan saja.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress.percent.clamp(0.0, 1.0).toDouble(),
              minHeight: 7,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: scheme.primary),
              onPressed: () {
                if (next != null) app.setCurriculumActiveLesson(next.id);
                Navigator.push(context, MaterialPageRoute(builder: (_) => CurriculumPathScreen(initialLevel: level.id)));
              },
              child: Text(next == null ? 'Buka Learning' : 'Lanjut di Learning'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.app});
  final AppController app;
  @override
  Widget build(BuildContext context) {
    final recommendation = StudyIntelligenceService.recommend(app);
    final icon = switch (recommendation.action) {
      'review' => Icons.refresh_rounded,
      'practice_weak_topics' => Icons.track_changes_rounded,
      'advance' => Icons.arrow_forward_rounded,
      _ => Icons.flag_rounded,
    };
    return Card(
        child: ListTile(
            leading: CircleAvatar(child: Icon(icon)),
            title: const Text('Rekomendasi langkah berikutnya',
                style: TextStyle(fontWeight: FontWeight.w900)),
            subtitle: Text(recommendation.reason),
            trailing: const Icon(Icons.chevron_right_rounded)));
  }
}

class _StudyHeader extends StatelessWidget {
  const _StudyHeader();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: .92),
              const Color(0xFF4A1110)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Row(children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('学ぶ · manabu',
                    style: TextStyle(
                        color: Colors.white70, fontWeight: FontWeight.w800)),
                SizedBox(height: 10),
                Text('Belajar',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w900)),
                SizedBox(height: 6),
                Text(
                    'Jalur utama, materi inti, Kanji, dan review dalam satu ruang.',
                    style: TextStyle(
                        color: Colors.white70, fontWeight: FontWeight.w700)),
              ])),
          SizedBox(width: 12),
          CircleAvatar(
              backgroundColor: Colors.white24,
              child: Text('学',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 20))),
        ]),
      );
}

class _StudyOverview extends StatelessWidget {
  const _StudyOverview({required this.app});

  final AppController app;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withValues(alpha: .45),
          borderRadius: BorderRadius.circular(26),
          border:
              Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: .12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.local_fire_department_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 30,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${app.streak} hari rentetan · ${app.xp} XP',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                        value: app.dailyProgress, minHeight: 7),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Akurasi kuis ${(app.quizAccuracy * 100).round()}% · ulangan ${app.dueKanjiReviewCount}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _StudyShelf extends StatelessWidget {
  const _StudyShelf(
      {required this.title, required this.subtitle, required this.cards});

  final String title;
  final String subtitle;
  final List<_StudyCardData> cards;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(title: title, subtitle: subtitle),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = responsiveColumns(
                constraints.maxWidth,
                compact: 2,
                medium: 2,
                large: 3,
                extraLarge: 4,
              );
              final spacing = 12.0;
              final width =
                  (constraints.maxWidth - (columns - 1) * spacing) / columns;
              final height = constraints.maxWidth < 390 ? 156.0 : 168.0;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final card in cards)
                    SizedBox(
                      width: width,
                      height: height,
                      child: FeatureCard(
                        title: card.title,
                        subtitle: card.subtitle,
                        icon: card.icon,
                        color: card.color,
                        badge: card.badge,
                        progress: card.progress,
                        onTap: () => StudyHubScreen._open(context, card.screen),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      );
}

class _StudyCardData {
  const _StudyCardData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.screen,
    this.badge,
    this.progress,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget screen;
  final String? badge;
  final double? progress;
}
