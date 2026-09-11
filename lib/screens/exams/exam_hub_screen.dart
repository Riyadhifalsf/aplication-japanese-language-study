import 'package:flutter/material.dart';

import '../../models/exam_question.dart';
import '../../services/exam_simulator_repository.dart';
import '../../state/app_controller.dart';
import '../../widgets/common_widgets.dart';
import 'exam_session_screen.dart';

class ExamHubScreen extends StatefulWidget {
  const ExamHubScreen({super.key, this.initialType = ExamType.jlpt});

  final ExamType initialType;

  @override
  State<ExamHubScreen> createState() => _ExamHubScreenState();
}

class _ExamHubScreenState extends State<ExamHubScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  String _jlptLevel = 'N5';
  String _jftTrack = 'A2.1';

  @override
  void initState() {
    super.initState();
    _tab = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialType == ExamType.jft ? 1 : 0,
    );
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: .65),
                        borderRadius: BorderRadius.circular(22),
                      ),
                child: TabBar(
                  controller: _tab,
                  indicator: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  // Warna label dikelola _TabStyle bawaan (termasuk saat
                  // drag via _DragAnimation), sama seperti tab Kana.
                  labelColor: Theme.of(context).colorScheme.onPrimary,
                  unselectedLabelColor:
                      Theme.of(context).colorScheme.onSurface,
                  // Nol-kan padding label bawaan supaya konten pas
                  // selebar tab.
                  labelPadding: EdgeInsets.zero,
                  tabs: const [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.school_rounded, size: 18),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'JLPT',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.work_history_rounded, size: 18),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'JFT-Basic',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _buildPage(ExamType.jlpt),
                  _buildPage(ExamType.jft),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Satu halaman penuh untuk satu tipe ujian (dipakai TabBarView).
  /// Fisika geser + indikator bawaan Flutter sehingga halus seperti tab Kana.
  Widget _buildPage(ExamType type) {
    final app = AppScope.of(context);
    final repository = ExamSimulatorRepository(app.repository);
    final levels = type == ExamType.jlpt
        ? ExamSimulatorRepository.jlptLevels
        : ExamSimulatorRepository.jftTracks;
    final activeLevel = type == ExamType.jlpt ? _jlptLevel : _jftTrack;
    return ListView(
      key: PageStorageKey('exam-hub-${type.name}'),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
            _ExamSummary(app: app, type: type, activeLevel: activeLevel),
            const SizedBox(height: 20),
            SectionTitle(
              title: type == ExamType.jlpt ? 'Pilih tingkat JLPT' : 'Pilih jalur JFT-Basic',
              subtitle: type == ExamType.jlpt
                  ? 'N5 sampai N1, 50 paket simulasi per tingkat. Level mengikuti progress atau placement quiz.'
                  : 'A1 sampai A2, 50 paket ujian komputer per jalur.',
            ),
            const SizedBox(height: 12),
            _LevelChips(
              levels: levels,
              selected: activeLevel,
              lockedLevels: type == ExamType.jlpt ? levels.where((l) => !app.isLevelUnlocked(l)).toSet() : const <String>{},
              onSelected: (value) => setState(() {
                if (type == ExamType.jlpt) {
                  _jlptLevel = value;
                } else {
                  _jftTrack = value;
                }
              }),
            ),
            const SizedBox(height: 22),
            _ExamBlueprint(type: type, level: activeLevel),
            const SizedBox(height: 22),
            SectionTitle(
              title: 'Paket simulasi penuh',
              subtitle:
                  'Paket 1–50. Paket 1–3 gratis, sisanya terbuka setelah langganan aktif.',
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = responsiveColumns(
                  constraints.maxWidth,
                  compact: 1,
                  medium: 2,
                  large: 3,
                  extraLarge: 4,
                );
                return GridView.builder(
                  itemCount: ExamSimulatorRepository.stageCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: columns == 1 ? 3.7 : 1.55,
                  ),
                  itemBuilder: (context, index) {
                    final stage = index + 1;
                    final key = app.examKey(type, activeLevel, stage);
                    final best = app.examBestScores[key] ?? 0;
                    return _StageCard(
                      type: type,
                      level: activeLevel,
                      stage: stage,
                      bestScore: best,
                      // Phase 1: semua stage gratis. Lock hanya progression level.
                      locked: (type == ExamType.jlpt && !app.isLevelUnlocked(activeLevel)),
                      onTap: () {
                        if (type == ExamType.jlpt && !app.isLevelUnlocked(activeLevel)) {
                          _showLevelLockedHint(context, activeLevel);
                          return;
                        }
                        final plan = repository.buildSession(
                          type: type,
                          level: activeLevel,
                          stage: stage,
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ExamSessionScreen(plan: plan),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        );
  }
  }

  void _showLevelLockedHint(BuildContext context, String level) {
    final app = AppScope.of(context);
    final previous = app.requiredPreviousLevel(level);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$level masih terkunci', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(
              'Selesaikan ${previous ?? 'level sebelumnya'} atau ambil placement quiz sebelum mengerjakan simulasi level ini.',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.lock_rounded),
              label: const Text('Mengerti'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPremiumHint(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paket lanjutan untuk anggota langganan',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              'Pengguna gratis dapat mencoba 3 paket pertama. Setelah langganan aktif, semua paket simulasi penuh JLPT dan JFT-Basic terbuka.',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.workspace_premium_rounded),
              label: const Text('Mengerti'),
            ),
          ],
        ),
      ),
    );
  }

class _ExamSummary extends StatelessWidget {
  const _ExamSummary({required this.app, required this.type, required this.activeLevel});

  final AppController app;
  final ExamType type;
  final String activeLevel;

  @override
  Widget build(BuildContext context) {
    final color = type == ExamType.jlpt ? const Color(0xFFD92D20) : const Color(0xFF17A673);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: color.withValues(alpha: .22)),
      ),
      child: Wrap(
        spacing: 14,
        runSpacing: 14,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          CircleAvatar(
            backgroundColor: color,
            foregroundColor: Colors.white,
            child: Icon(type == ExamType.jlpt ? Icons.school_rounded : Icons.badge_rounded),
          ),
          _SummaryText(label: 'Poin simulasi', value: '${app.examPoints}'),
          _SummaryText(label: 'Paket terbaik', value: '${app.examBestScores.length}'),
        ],
      ),
    );
  }
}

class _SummaryText extends StatelessWidget {
  const _SummaryText({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 104),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          ],
        ),
      );
}

class _LevelChips extends StatelessWidget {
  const _LevelChips({required this.levels, required this.selected, required this.onSelected, this.lockedLevels = const <String>{}});

  final List<String> levels;
  final String selected;
  final ValueChanged<String> onSelected;
  final Set<String> lockedLevels;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final level in levels)
            ChoiceChip(
              label: Row(mainAxisSize: MainAxisSize.min, children: [Text(level), if (lockedLevels.contains(level)) const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.lock_rounded, size: 14))]),
              selected: selected == level,
              onSelected: (_) => onSelected(level),
            ),
        ],
      );
}

class _ExamBlueprint extends StatelessWidget {
  const _ExamBlueprint({required this.type, required this.level});

  final ExamType type;
  final String level;

  @override
  Widget build(BuildContext context) {
    final color = type == ExamType.jlpt ? const Color(0xFFD92D20) : const Color(0xFF17A673);
    final rows = type == ExamType.jlpt
        ? const [
            _BlueprintRow('文字・語彙', 'Kanji, bacaan, arti, penggunaan kosakata'),
            _BlueprintRow('文法', 'Pilih pola, susun kalimat, dan tata bahasa dalam teks'),
            _BlueprintRow('読解', 'Bacaan pendek, menengah, informasi penting'),
            _BlueprintRow('聴解', 'Tugas menyimak, poin utama, dan tanggapan cepat'),
          ]
        : const [
            _BlueprintRow('Huruf & Kosakata', 'Sekitar 12 soal huruf dan kosakata'),
            _BlueprintRow('Percakapan', 'Ungkapan dan tata bahasa untuk situasi sehari-hari'),
            _BlueprintRow('Menyimak', 'Suara ujian komputer, situasi toko, kerja, dan umum'),
            _BlueprintRow('Membaca', 'Pesan, pengumuman, informasi praktis'),
          ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: .20)),
        color: color.withValues(alpha: .07),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rancangan $level',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          for (final row in rows) ...[
            row,
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _BlueprintRow extends StatelessWidget {
  const _BlueprintRow(this.title, this.subtitle);

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF17A673)),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface, height: 1.35),
                children: [
                  TextSpan(text: '$title: ', style: const TextStyle(fontWeight: FontWeight.w900)),
                  TextSpan(text: subtitle),
                ],
              ),
            ),
          ),
        ],
      );
}

class _StageCard extends StatelessWidget {
  const _StageCard({
    required this.type,
    required this.level,
    required this.stage,
    required this.bestScore,
    required this.locked,
    required this.onTap,
  });

  final ExamType type;
  final String level;
  final int stage;
  final int bestScore;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = type == ExamType.jlpt ? const Color(0xFFD92D20) : const Color(0xFF17A673);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: locked ? Colors.grey.withValues(alpha: .16) : color.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(17),
                ),
                alignment: Alignment.center,
                child: Icon(
                  locked ? Icons.lock_rounded : Icons.fact_check_rounded,
                  color: locked ? Theme.of(context).colorScheme.onSurfaceVariant : color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Paket $stage',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      level,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
                    ),
                    if (bestScore > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Skor terbaik $bestScore%',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
