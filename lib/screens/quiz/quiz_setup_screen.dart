import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../models/exam_question.dart';
import '../../state/app_controller.dart';
import '../../widgets/common_widgets.dart';
import '../exams/exam_hub_screen.dart';
import '../kana/kana_screen.dart';
import '../kanji/kanji_hiragana_quiz_screen.dart';
import '../kanji/kanji_mastery_quiz_screen.dart';
import '../kanji/kanji_review_screen.dart';
import '../kanji/kanji_similar_quiz_screen.dart';
import '../vocab/vocabulary_quiz_screen.dart';

class QuizSetupScreen extends StatefulWidget {
  const QuizSetupScreen({super.key});

  @override
  State<QuizSetupScreen> createState() => _QuizSetupScreenState();
}

class _QuizSetupScreenState extends State<QuizSetupScreen> {
  bool _kanjiMode = true;
  String _level = 'N5';
  int _questionCount = 10;
  int _secondsPerQuestion = 15;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return CustomScrollView(
      slivers: [
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 18, 20, 12),
          sliver: SliverToBoxAdapter(child: _QuizHeader()),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          sliver: SliverToBoxAdapter(
            child: _QuizHero(
              kanjiMode: _kanjiMode,
              level: _level,
              count: _questionCount,
              seconds: _secondsPerQuestion,
              accuracy: app.quizAccuracy,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          sliver: SliverToBoxAdapter(
            child: _ModeSwitch(
              kanjiMode: _kanjiMode,
              onChanged: (value) => setState(() => _kanjiMode = value),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          sliver: SliverToBoxAdapter(
            child: _SetupPanel(
              kanjiMode: _kanjiMode,
              level: _level,
              questionCount: _questionCount,
              secondsPerQuestion: _secondsPerQuestion,
              onLevelChanged: (value) => setState(() => _level = value),
              onCountChanged: (value) => setState(() => _questionCount = value),
              onSecondsChanged: (value) =>
                  setState(() => _secondsPerQuestion = value),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          sliver: SliverToBoxAdapter(
            child: FilledButton.icon(
              onPressed: app.contentReady ? () => _start(context) : null,
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(app.contentReady
                  ? (_kanjiMode
                      ? 'Mulai tantangan kanji'
                      : 'Mulai latihan kosakata')
                  : 'Menyiapkan soal…'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(58),
                textStyle:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
          sliver: SliverToBoxAdapter(
            child: _ExamSimulatorBanner(
              onJlpt: () => _open(context, const ExamHubScreen()),
              onJft: () => _open(
                  context, const ExamHubScreen(initialType: ExamType.jft)),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
          sliver: const SliverToBoxAdapter(
            child: SectionTitle(
              title: 'Pilih gaya latihan',
              subtitle:
                  'Terinspirasi dari aplikasi belajar, tapi tampilannya dibuat beda.',
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(
            child: _QuizModeGrid(
              modes: [
                _QuizModeData(
                  title: 'Simulasi JLPT',
                  subtitle: '50 paket per tingkat',
                  icon: Icons.school_rounded,
                  jp: '試',
                  color: const Color(0xFF635BFF),
                  onTap: () => _open(context, const ExamHubScreen()),
                ),
                _QuizModeData(
                  title: 'Simulasi JFT',
                  subtitle: 'A2 kerja dan choukai',
                  icon: Icons.badge_rounded,
                  jp: '職',
                  color: AppTheme.seed,
                  onTap: () => _open(
                      context, const ExamHubScreen(initialType: ExamType.jft)),
                ),
                _QuizModeData(
                  title: 'Pemanasan 10 Soal',
                  subtitle: 'Cepat untuk awal latihan',
                  icon: Icons.timer_rounded,
                  jp: '速',
                  color: AppTheme.seed,
                  onTap: () => _start(context, count: 10),
                ),
                _QuizModeData(
                  title: 'Ingat Lewat Suara',
                  subtitle: 'Dengar lalu pilih arti',
                  icon: Icons.hearing_rounded,
                  jp: '音',
                  color: AppTheme.seed,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Mode suara sementara dinonaktifkan. Gunakan latihan biasa.')),
                    );
                  },
                ),
                _QuizModeData(
                  title: 'Kanji ke Hiragana',
                  subtitle: 'Lihat kanji pilih bacaan',
                  icon: Icons.category_rounded,
                  jp: '家',
                  color: AppTheme.seed,
                  onTap: () => _open(context, const KanjiHiraganaQuizScreen()),
                ),
                _QuizModeData(
                  title: 'Kanji Mirip',
                  subtitle: 'Bedakan bentuk serupa',
                  icon: Icons.blur_on_rounded,
                  jp: '似',
                  color: AppTheme.seed,
                  onTap: () => _open(context, const KanjiSimilarQuizScreen()),
                ),
                _QuizModeData(
                  title: 'Ulangi yang Lemah',
                  subtitle: 'Kartu yang harus diulang',
                  icon: Icons.notifications_active_rounded,
                  jp: '復',
                  color: AppTheme.seed,
                  onTap: () => _open(context, const KanjiReviewScreen()),
                ),
                _QuizModeData(
                  title: 'Latihan Kana Cepat',
                  subtitle: 'Hiragana & katakana',
                  icon: Icons.grid_view_rounded,
                  jp: 'あ',
                  color: AppTheme.seed,
                  onTap: () => _open(context, const KanaScreen()),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
          sliver: SliverToBoxAdapter(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const CircleAvatar(child: Icon(Icons.insights_rounded)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Statistik latihan',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${app.quizAnswered} jawaban · akurasi ${(app.quizAccuracy * 100).round()}% · ulangan ${app.dueKanjiReviewCount}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _start(BuildContext context, {int? count}) {
    final app = AppScope.of(context);
    if (!app.contentReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Data quiz sedang disiapkan. Coba lagi sebentar.')),
      );
      return;
    }
    if (_kanjiMode) {
      _open(
        context,
        KanjiMasteryQuizScreen(
          level: _level,
          sessionSize: count ?? _questionCount,
        ),
      );
    } else {
      _open(
          context,
          VocabularyQuizScreen(
              level: _level, sessionSize: count ?? _questionCount));
    }
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}

class _QuizHeader extends StatelessWidget {
  const _QuizHeader();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: const LinearGradient(
            colors: [AppTheme.primaryDark, AppTheme.seed],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .15),
                borderRadius: BorderRadius.circular(22),
              ),
              alignment: Alignment.center,
              child: const Text(
                '問',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kuis',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Pilih jenis latihan. Tanpa tombol suara tambahan.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.white70, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _ExamSimulatorBanner extends StatelessWidget {
  const _ExamSimulatorBanner({required this.onJlpt, required this.onJft});

  final VoidCallback onJlpt;
  final VoidCallback onJft;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: .16),
              Theme.of(context).colorScheme.tertiary.withValues(alpha: .10),
            ],
          ),
          border:
              Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final buttons = [
              FilledButton.icon(
                onPressed: onJlpt,
                icon: const Icon(Icons.school_rounded),
                label: const Text('Simulasi JLPT'),
              ),
              FilledButton.tonalIcon(
                onPressed: onJft,
                icon: const Icon(Icons.badge_rounded),
                label: const Text('Simulasi JFT'),
              ),
            ];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Simulasi ujian lengkap',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                ),
                const SizedBox(height: 5),
                Text(
                  'Paket 30 soal dengan dokkai, choukai, bunpou, dan poin hasil simulasi.',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 14),
                if (constraints.maxWidth < 430)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      buttons[0],
                      const SizedBox(height: 8),
                      buttons[1]
                    ],
                  )
                else
                  Row(children: [
                    Expanded(child: buttons[0]),
                    const SizedBox(width: 10),
                    Expanded(child: buttons[1])
                  ]),
              ],
            );
          },
        ),
      );
}

class _QuizHero extends StatelessWidget {
  const _QuizHero({
    required this.kanjiMode,
    required this.level,
    required this.count,
    required this.seconds,
    required this.accuracy,
  });

  final bool kanjiMode;
  final String level;
  final int count;
  final int seconds;
  final double accuracy;

  @override
  Widget build(BuildContext context) {
    const color = AppTheme.seed;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: .92),
            AppTheme.primaryDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: .22),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .17),
                  borderRadius: BorderRadius.circular(24),
                ),
                alignment: Alignment.center,
                child: Text(
                  kanjiMode ? '問' : '語',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kanjiMode ? 'Tantangan kanji' : 'Latihan kosakata',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$level · $count soal · $seconds detik/soal',
                      style: const TextStyle(
                          color: Colors.white70, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _MiniQuizStat(
                  label: 'Jenis', value: kanjiMode ? 'Kanji' : 'Kosakata'),
              const SizedBox(width: 10),
              _MiniQuizStat(label: 'Tingkat', value: level),
              const SizedBox(width: 10),
              _MiniQuizStat(
                  label: 'Akurasi', value: '${(accuracy * 100).round()}%'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniQuizStat extends StatelessWidget {
  const _MiniQuizStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .14),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(color: Colors.white70, fontSize: 11)),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
      );
}

class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({required this.kanjiMode, required this.onChanged});

  final bool kanjiMode;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withValues(alpha: .55),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Expanded(
              child: _ModePill(
                label: 'Kanji',
                icon: Icons.translate_rounded,
                selected: kanjiMode,
                onTap: () => onChanged(true),
              ),
            ),
            Expanded(
              child: _ModePill(
                label: 'Kosakata',
                icon: Icons.menu_book_rounded,
                selected: !kanjiMode,
                onTap: () => onChanged(false),
              ),
            ),
          ],
        ),
      );
}

class _ModePill extends StatelessWidget {
  const _ModePill({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 19,
                color:
                    selected ? Theme.of(context).colorScheme.onPrimary : null,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color:
                      selected ? Theme.of(context).colorScheme.onPrimary : null,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      );
}

class _SetupPanel extends StatelessWidget {
  const _SetupPanel({
    required this.kanjiMode,
    required this.level,
    required this.questionCount,
    required this.secondsPerQuestion,
    required this.onLevelChanged,
    required this.onCountChanged,
    required this.onSecondsChanged,
  });

  final bool kanjiMode;
  final String level;
  final int questionCount;
  final int secondsPerQuestion;
  final ValueChanged<String> onLevelChanged;
  final ValueChanged<int> onCountChanged;
  final ValueChanged<int> onSecondsChanged;

  @override
  Widget build(BuildContext context) {
    const color = AppTheme.seed;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune_rounded, color: color),
                const SizedBox(width: 8),
                Text(
                  kanjiMode ? 'Racik soal kanji' : 'Racik soal kosakata',
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 9,
              runSpacing: 9,
              children: [
                for (final item in ['N5', 'N4', 'N3', 'N2', 'N1'])
                  ChoiceChip(
                    selected: level == item,
                    label: Text(item),
                    avatar: level == item
                        ? const Icon(Icons.check_rounded)
                        : const Icon(Icons.lock_open_rounded),
                    onSelected: (_) => onLevelChanged(item),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _SliderSetting(
              title: 'Jumlah pertanyaan',
              value: questionCount,
              min: 5,
              max: 30,
              divisions: 5,
              onChanged: onCountChanged,
            ),
            const SizedBox(height: 12),
            _SliderSetting(
              title: 'Pewaktu soal',
              value: secondsPerQuestion,
              min: 5,
              max: 30,
              divisions: 5,
              suffix: ' dtk',
              onChanged: onSecondsChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _SliderSetting extends StatelessWidget {
  const _SliderSetting({
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
    this.suffix = '',
  });

  final String title;
  final int value;
  final int min;
  final int max;
  final int divisions;
  final String suffix;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w900)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: .8),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '$value$suffix',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          Slider(
            value: value.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: divisions,
            onChanged: (next) => onChanged(next.round()),
          ),
        ],
      );
}

class _QuizModeData {
  const _QuizModeData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.jp,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String jp;
  final Color color;
  final VoidCallback onTap;
}

class _QuizModeGrid extends StatelessWidget {
  const _QuizModeGrid({required this.modes});

  final List<_QuizModeData> modes;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final columns = responsiveColumns(constraints.maxWidth,
              compact: 2, medium: 2, large: 3, extraLarge: 4);
          final spacing = 12.0;
          final width =
              (constraints.maxWidth - (columns - 1) * spacing) / columns;
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (final mode in modes)
                SizedBox(
                    width: width,
                    height: constraints.maxWidth < 390 ? 148 : 162,
                    child: _QuizModeCard(data: mode)),
            ],
          );
        },
      );
}

class _QuizModeCard extends StatelessWidget {
  const _QuizModeCard({required this.data});

  final _QuizModeData data;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: data.onTap,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact =
                  constraints.maxWidth < 180 || constraints.maxHeight < 155;
              return Stack(
                children: [
                  Positioned(
                    right: -20,
                    top: -20,
                    child: CircleAvatar(
                      radius: compact ? 44 : 54,
                      backgroundColor: data.color.withValues(alpha: .10),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(compact ? 12 : 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: compact ? 42 : 52,
                              height: compact ? 42 : 52,
                              decoration: BoxDecoration(
                                color: data.color,
                                borderRadius:
                                    BorderRadius.circular(compact ? 15 : 18),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                data.jp,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: compact ? 20 : 25,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Icon(data.icon,
                                color: data.color, size: compact ? 20 : 24),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          data.title,
                          maxLines: compact ? 1 : 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: compact ? 14 : 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          data.subtitle,
                          maxLines: compact ? 1 : 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 11.5,
                            height: 1.18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
}
