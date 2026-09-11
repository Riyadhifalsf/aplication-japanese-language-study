import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../state/app_controller.dart';

class ProfileInsights extends StatelessWidget {
  const ProfileInsights({required this.app, super.key});

  final AppController app;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final learned = app.learnedKanjiCount;
    final mastered = app.masteredKanjiIds.length;
    final vocab = app.masteredVocabularyIds.length;
    final quiz = (app.quizAccuracy * 100).round();
    final events = math.min(28, app.activityJournal.length);
    final values = List<double>.generate(14, (i) {
      final index = app.activityJournal.length - 14 + i;
      if (index < 0) return 0;
      final type = '${app.activityJournal[index]['type'] ?? ''}';
      return type.contains('study') || type.contains('session') ? 1.0 : .35;
    });

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(width: 42, height: 42, alignment: Alignment.center, decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(14)), child: Icon(Icons.insights_rounded, color: cs.primary)),
              const SizedBox(width: 11),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Insight belajar', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                SizedBox(height: 2),
                Text('Gambaran progres belajarmu', style: TextStyle(fontSize: 12)),
              ])),
              Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(99)), child: Text('$events aktivitas', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: cs.primary))),
            ]),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              decoration: BoxDecoration(color: cs.primaryContainer.withValues(alpha: .48), borderRadius: BorderRadius.circular(18)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Expanded(child: Text('Ritme 14 aktivitas terakhir', style: TextStyle(fontWeight: FontWeight.w900))),
                  Icon(Icons.show_chart_rounded, color: cs.primary, size: 20),
                ]),
                const SizedBox(height: 8),
                SizedBox(height: 72, child: CustomPaint(painter: _SparklinePainter(values: values, color: cs.primary), child: const SizedBox.expand())),
                const SizedBox(height: 3),
                Row(children: [Text('Lebih lama', style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)), const Spacer(), Text('Terbaru', style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant))]),
              ]),
            ),
            const SizedBox(height: 14),
            LayoutBuilder(builder: (context, constraints) {
              final width = (constraints.maxWidth - 10) / 2;
              return Wrap(spacing: 10, runSpacing: 10, children: [
                _Stat(width: width, label: 'Kanji dipelajari', value: '$learned', icon: Icons.brush_rounded, color: cs.primary),
                _Stat(width: width, label: 'Kanji dikuasai', value: '$mastered', icon: Icons.verified_rounded, color: cs.tertiary),
                _Stat(width: width, label: 'Kosakata dikuasai', value: '$vocab', icon: Icons.abc_rounded, color: cs.secondary),
                _Stat(width: width, label: 'Akurasi quiz', value: '$quiz%', icon: Icons.track_changes_rounded, color: cs.primary),
                _Stat(width: width, label: 'Hari aktif', value: '${app.activeDays}', icon: Icons.calendar_month_rounded, color: cs.tertiary),
                _Stat(width: width, label: 'Waktu aktif', value: '${app.totalActiveMinutes}m', icon: Icons.timer_rounded, color: cs.secondary),
                _Stat(width: width, label: 'Grammar selesai', value: '${app.completedGrammarIds.length}', icon: Icons.rule_rounded, color: cs.primary),
              ]);
            }),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.width, required this.label, required this.value, required this.icon, required this.color});
  final double width;
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: color.withValues(alpha: .085), borderRadius: BorderRadius.circular(17), border: Border.all(color: color.withValues(alpha: .13))),
          child: Row(children: [
            Container(width: 32, height: 32, alignment: Alignment.center, decoration: BoxDecoration(color: color.withValues(alpha: .14), borderRadius: BorderRadius.circular(11)), child: Icon(icon, size: 17, color: color)),
            const SizedBox(width: 9),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ])),
          ]),
        ),
      );
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({required this.values, required this.color});
  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final line = Paint()..color = color..strokeWidth = 3..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = color.withValues(alpha: .12)..style = PaintingStyle.fill;
    final path = Path();
    final area = Path();
    for (var i = 0; i < values.length; i++) {
      final x = values.length == 1 ? 0.0 : i / (values.length - 1) * size.width;
      final y = size.height - (values[i].clamp(0, 1) * size.height * .72) - 7;
      if (i == 0) {
        path.moveTo(x, y);
        area.moveTo(x, size.height);
        area.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        area.lineTo(x, y);
      }
    }
    area.lineTo(size.width, size.height);
    area.close();
    canvas.drawPath(area, fill);
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) => oldDelegate.values != values || oldDelegate.color != color;
}
