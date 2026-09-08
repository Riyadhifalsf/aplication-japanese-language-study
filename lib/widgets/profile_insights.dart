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
    final skillValues = <double>[
      app.levelOverallMastery(app.selectedStudyLevel),
      (quiz / 100).clamp(0, 1).toDouble(),
      mastered > 0 ? (mastered / math.max(1, learned)).clamp(0, 1).toDouble() : 0,
      vocab > 0 ? math.min(1, vocab / 2000).toDouble() : 0,
      math.min(1, app.totalActiveMinutes / 600).toDouble(),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Insight belajar', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text('Ringkasan visual supaya progres tidak cuma terlihat sebagai angka.', style: TextStyle(color: cs.onSurfaceVariant)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _Stat('Kanji dipelajari', '$learned', Icons.translate_rounded),
                _Stat('Kanji dikuasai', '$mastered', Icons.verified_rounded),
                _Stat('Kosakata dikuasai', '$vocab', Icons.abc_rounded),
                _Stat('Akurasi quiz', '$quiz%', Icons.track_changes_rounded),
                _Stat('Event belajar', '$events', Icons.insights_rounded),
              ],
            ),
            const SizedBox(height: 18),
            const Text('Ritme 14 aktivitas terakhir', style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            SizedBox(height: 92, child: CustomPaint(painter: _SparklinePainter(values: values, color: cs.primary), child: const SizedBox.expand())),
            const SizedBox(height: 18),
            const Text('Profil kemampuan', style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            Center(
              child: SizedBox(
                width: 190,
                height: 190,
                child: CustomPaint(
                  painter: _RadarPainter(values: skillValues, color: cs.primary),
                  child: const Center(child: Text('Skill\nProfile', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900))),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, this.icon);
  final String label;
  final String value;
  final IconData icon;
  @override Widget build(BuildContext c) => Container(width: 150, padding: const EdgeInsets.all(13), decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), color: Theme.of(c).colorScheme.surfaceContainerHighest.withValues(alpha: .45)), child: Row(children: [Icon(icon, size: 19), const SizedBox(width: 8), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)), Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10))]))]));
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({required this.values, required this.color});
  final List<double> values;
  final Color color;
  @override void paint(Canvas canvas, Size size) { if (values.isEmpty) return; final p = Paint()..color = color..strokeWidth = 3..style = PaintingStyle.stroke..strokeCap = StrokeCap.round; final fill = Paint()..color = color.withValues(alpha: .10)..style = PaintingStyle.fill; final path = Path(); final area = Path(); for (var i = 0; i < values.length; i++) { final x = values.length == 1 ? 0.0 : i / (values.length - 1) * size.width; final y = size.height - (values[i].clamp(0, 1) * size.height * .82) - 8; if (i == 0) { path.moveTo(x, y); area.moveTo(x, size.height); area.lineTo(x, y); } else { path.lineTo(x, y); area.lineTo(x, y); } } area.lineTo(size.width, size.height); area.close(); canvas.drawPath(area, fill); canvas.drawPath(path, p); }
  @override bool shouldRepaint(covariant _SparklinePainter oldDelegate) => oldDelegate.values != values || oldDelegate.color != color;
}

class _RadarPainter extends CustomPainter {
  const _RadarPainter({required this.values, required this.color});
  final List<double> values;
  final Color color;
  @override void paint(Canvas canvas, Size size) { final center = Offset(size.width / 2, size.height / 2); final radius = size.shortestSide * .36; final grid = Paint()..color = color.withValues(alpha: .14)..style = PaintingStyle.stroke; final shape = Paint()..color = color.withValues(alpha: .18)..style = PaintingStyle.fill; final outline = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2.4; for (var ring = 1; ring <= 4; ring++) { final path = Path(); for (var i = 0; i < 5; i++) { final a = -math.pi / 2 + i * 2 * math.pi / 5; final r = radius * ring / 4; final pt = center + Offset(math.cos(a) * r, math.sin(a) * r); if (i == 0) path.moveTo(pt.dx, pt.dy); else path.lineTo(pt.dx, pt.dy); } path.close(); canvas.drawPath(path, grid); } final path = Path(); for (var i = 0; i < 5; i++) { final a = -math.pi / 2 + i * 2 * math.pi / 5; final r = radius * values[i].clamp(0, 1); final pt = center + Offset(math.cos(a) * r, math.sin(a) * r); if (i == 0) path.moveTo(pt.dx, pt.dy); else path.lineTo(pt.dx, pt.dy); } path.close(); canvas.drawPath(path, shape); canvas.drawPath(path, outline); }
  @override bool shouldRepaint(covariant _RadarPainter oldDelegate) => oldDelegate.values != values || oldDelegate.color != color;
}
