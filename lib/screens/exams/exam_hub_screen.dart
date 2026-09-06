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

class _ExamHubScreenState extends State<ExamHubScreen> {
  late ExamType _type = widget.initialType;
  String _jlptLevel = 'N5';
  String _jftTrack = 'A2.1';

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final repository = ExamSimulatorRepository(app.repository);
    final levels = _type == ExamType.jlpt
        ? ExamSimulatorRepository.jlptLevels
        : ExamSimulatorRepository.jftTracks;
    final activeLevel = _type == ExamType.jlpt ? _jlptLevel : _jftTrack;
    final format = ExamSimulatorRepository.formatSummary(_type, activeLevel);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            PageHeader(
              title: 'Simulasi ${examTypeLabel(_type)}',
              subtitle:
                  '$format. Ujian penuh: pewaktu aktif, skor dihitung di akhir, dan pembahasan muncul setelah selesai.',
              trailing: IconButton.filledTonal(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
            _ExamSwitch(
              type: _type,
              onChanged: (value) => setState(() => _type = value),
            ),
            const SizedBox(height: 16),
            _ExamSummary(app: app, type: _type, activeLevel: activeLevel),
            const SizedBox(height: 20),
            SectionTitle(
              title: _type == ExamType.jlpt ? 'Pilih tingkat JLPT' : 'Pilih jalur JFT-Basic',
              subtitle: _type == ExamType.jlpt
                  ? 'N5 sampai N1, 50 paket simulasi per tingkat. Level mengikuti progress atau placement quiz.'
                  : 'A1 sampai A2, 50 paket ujian komputer per jalur.',
            ),
            const SizedBox(height: 12),
            _LevelChips(
              levels: levels,
              selected: activeLevel,
              lockedLevels: _type == ExamType.jlpt ? levels.where((l) => !app.isLevelUnlocked(l)).toSet() : const <String>{},
              onSelected: (value) => setState(() {
                if (_type == ExamType.jlpt) {
                  _jlptLevel = value;
                } else {
                  _jftTrack = value;
                }
              }),
            ),
            const SizedBox(height: 22),
            _ExamBlueprint(type: _type, level: activeLevel),
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
                    final key = app.examKey(_type, activeLevel, stage);
                    final best = app.examBestScores[key] ?? 0;
                    return _StageCard(
                      type: _type,
                      level: activeLevel,
                      stage: stage,
                      bestScore: best,
                      locked: (!app.isPremium && stage > 3) || (_type == ExamType.jlpt && !app.isLevelUnlocked(activeLevel)),
                      onTap: () {
                        if (_type == ExamType.jlpt && !app.isLevelUnlocked(activeLevel)) {
                          _showLevelLockedHint(context, activeLevel);
                          return;
                        }
                        if (!app.isPremium && stage > 3) {
                          _showPremiumHint(context);
                          return;
                        }
                        final plan = repository.buildSession(
                          type: _type,
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
        ),
      ),
    );
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
}

class _ExamSwitch extends StatelessWidget {
  const _ExamSwitch({required this.type, required this.onChanged});

  final ExamType type;
  final ValueChanged<ExamType> onChanged;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: .65),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Expanded(
              child: _SwitchItem(
                label: 'JLPT',
                selected: type == ExamType.jlpt,
                icon: Icons.school_rounded,
                onTap: () => onChanged(ExamType.jlpt),
              ),
            ),
            Expanded(
              child: _SwitchItem(
                label: 'JFT-Basic',
                selected: type == ExamType.jft,
                icon: Icons.work_history_rounded,
                onTap: () => onChanged(ExamType.jft),
              ),
            ),
          ],
        ),
      );
}

class _SwitchItem extends StatelessWidget {
  const _SwitchItem({
    required this.label,
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            color: selected ? Theme.of(context).colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: selected ? Theme.of(context).colorScheme.onPrimary : null),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: selected ? Theme.of(context).colorScheme.onPrimary : null,
                  ),
                ),
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
          _SummaryText(label: 'Format', value: ExamSimulatorRepository.formatSummary(type, activeLevel)),
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
    final format = ExamSimulatorRepository.formatSummary(type, level);
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
                      '$level · $format',
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
