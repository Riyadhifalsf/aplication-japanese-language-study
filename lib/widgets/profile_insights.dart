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
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Insight belajar', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text('Ringkasan kemampuan dan kebiasaan belajar.', style: TextStyle(color: cs.onSurfaceVariant)),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _Stat('Kanji', '$mastered', Icons.translate_rounded)),
            const SizedBox(width: 10),
            Expanded(child: _Stat('Kosakata', '$vocab', Icons.abc_rounded)),
            const SizedBox(width: 10),
            Expanded(child: _Stat('Akurasi', '$quiz%', Icons.track_changes_rounded)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _Stat('Hari aktif', '${app.activeDays}', Icons.calendar_month_rounded)),
            const SizedBox(width: 10),
            Expanded(child: _Stat('Waktu', '${app.totalActiveMinutes}m', Icons.timer_rounded)),
            const SizedBox(width: 10),
            Expanded(child: _Stat('Grammar', '${app.completedGrammarIds.length}', Icons.rule_rounded)),
          ]),
          const SizedBox(height: 18),
          Row(children: [
            const Expanded(child: Text('Ritme belajar', style: TextStyle(fontWeight: FontWeight.w900))),
            Text('14 aktivitas', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          ]),
          const SizedBox(height: 8),
          SizedBox(height: 64, child: CustomPaint(painter: _SparklinePainter(values: values, color: cs.primary), child: const SizedBox.expand())),
          const SizedBox(height: 14),
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Profil kemampuan', style: TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text('Mastery, akurasi, retensi, kosakata, dan waktu belajar.', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12, height: 1.35)),
            ])),
            const SizedBox(width: 12),
            SizedBox(width: 118, height: 118, child: CustomPaint(painter: _RadarPainter(values: skillValues, color: cs.primary))),
          ]),
        ]),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, this.icon);
  final String label;
  final String value;
  final IconData icon;
  @override
  Widget build(BuildContext c) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Theme.of(c).colorScheme.surfaceContainerHighest.withValues(alpha: .45)),
        child: Row(children: [
          Icon(icon, size: 17),
          const SizedBox(width: 7),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10)),
          ])),
        ]),
      );
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({required this.values, required this.color});
  final List<double> values;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final p = Paint()..color = color..strokeWidth = 3..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final fill = Paint()..color = color.withValues(alpha: .10)..style = PaintingStyle.fill;
    final path = Path();
    final area = Path();
    for (var i = 0; i < values.length; i++) {
      final x = values.length == 1 ? 0.0 : i / (values.length - 1) * size.width;
      final y = size.height - (values[i].clamp(0, 1) * size.height * .78) - 6;
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
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) => oldDelegate.values != values || oldDelegate.color != color;
}

class _RadarPainter extends CustomPainter {
  const _RadarPainter({required this.values, required this.color});
  final List<double> values;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * .35;
    final grid = Paint()..color = color.withValues(alpha: .14)..style = PaintingStyle.stroke;
    final shape = Paint()..color = color.withValues(alpha: .18)..style = PaintingStyle.fill;
    final outline = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2;
    for (var ring = 1; ring <= 4; ring++) {
      final path = Path();
      for (var i = 0; i < 5; i++) {
        final a = -math.pi / 2 + i * 2 * math.pi / 5;
        final r = radius * ring / 4;
        final pt = center + Offset(math.cos(a) * r, math.sin(a) * r);
        if (i == 0) path.moveTo(pt.dx, pt.dy); else path.lineTo(pt.dx, pt.dy);
      }
      path.close();
      canvas.drawPath(path, grid);
    }
    final path = Path();
    for (var i = 0; i < 5; i++) {
      final a = -math.pi / 2 + i * 2 * math.pi / 5;
      final r = radius * values[i].clamp(0, 1);
      final pt = center + Offset(math.cos(a) * r, math.sin(a) * r);
      if (i == 0) path.moveTo(pt.dx, pt.dy); else path.lineTo(pt.dx, pt.dy);
    }
    path.close();
    canvas.drawPath(path, shape);
    canvas.drawPath(path, outline);
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) => oldDelegate.values != values || oldDelegate.color != color;
}
