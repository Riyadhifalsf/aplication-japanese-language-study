import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../models/kanji.dart';
import '../../services/stroke_service.dart';
import '../../state/app_controller.dart';
import '../../widgets/common_widgets.dart';

class StrokeOrderScreen extends StatefulWidget {
  const StrokeOrderScreen({required this.item, super.key});

  final Kanji item;

  @override
  State<StrokeOrderScreen> createState() => _StrokeOrderScreenState();
}

class _StrokeOrderScreenState extends State<StrokeOrderScreen>
    with SingleTickerProviderStateMixin {
  final _service = StrokeService();
  late final AnimationController _controller;
  StrokeData? _data;
  Object? _error;
  double _speed = 1;
  bool _practiceMode = false;
  int _practiceIndex = 0;
  String _practiceMessage = 'Ikuti goresan dari titik nomor 1.';
  bool _lastStrokeCorrect = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    _service.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _data = null;
      _error = null;
    });
    try {
      final data = await _service.load(widget.item.character);
      if (!mounted) return;
      setState(() {
        _data = data;
        _practiceIndex = 0;
        _practiceMessage = 'Ikuti goresan dari titik nomor 1.';
        _lastStrokeCorrect = false;
      });
      _configureDuration();
      _controller.forward(from: 0);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  void _configureDuration() {
    final count = _data?.paths.length ?? math.max(widget.item.strokes, 1);
    _controller.duration = Duration(
      milliseconds: ((count * 650 + 350) / _speed).round(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.item.character} · Urutan Goresan'),
        actions: [
          IconButton(
            tooltip: 'Dengarkan',
            onPressed: () => app.tts.speak(widget.item.preferredReading),
            icon: const Icon(Icons.volume_up_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
        children: [
          Row(
            children: [
              JlptBadge(widget.item.level),
              const SizedBox(width: 10),
              Text(
                '${widget.item.strokes > 0 ? widget.item.strokes : '?'} goresan',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Text(
                widget.item.meaning,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          AspectRatio(
            aspectRatio: 1,
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: _practiceMode && _data != null
                    ? _practicePlayer()
                    : _player(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _data == null
                              ? null
                              : () => _controller.forward(from: 0),
                          icon: const Icon(Icons.replay_rounded),
                          label: const Text('Putar ulang'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton.filledTonal(
                        tooltip: _controller.isAnimating ? 'Jeda' : 'Putar',
                        onPressed: _data == null
                            ? null
                            : () => setState(() {
                                  if (_controller.isAnimating) {
                                    _controller.stop();
                                  } else {
                                    _controller.forward();
                                  }
                                }),
                        icon: Icon(
                          _controller.isAnimating
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(Icons.speed_rounded),
                      const SizedBox(width: 10),
                      const Text(
                        'Kecepatan',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const Spacer(),
                      DropdownButton<double>(
                        value: _speed,
                        underline: const SizedBox.shrink(),
                        items: const [
                          DropdownMenuItem(value: .65, child: Text('Lambat')),
                          DropdownMenuItem(value: 1, child: Text('Normal')),
                          DropdownMenuItem(value: 1.45, child: Text('Cepat')),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _speed = value;
                            _configureDuration();
                            _controller.forward(from: 0);
                          });
                        },
                      ),
                    ],
                  ),
                  const Divider(height: 22),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _practiceMode,
                    onChanged: _data == null
                        ? null
                        : (value) => setState(() {
                              _practiceMode = value;
                              _controller.stop();
                              _practiceIndex = 0;
                              _practiceMessage = value
                                  ? 'Mode verifikasi aktif. Tulis goresan sesuai urutan.'
                                  : 'Ikuti goresan dari titik nomor 1.';
                            }),
                    secondary: const Icon(Icons.draw_rounded),
                    title: const Text('Mode latihan menulis'),
                    subtitle: const Text('Verifikasi benar/salah berdasarkan arah awal dan akhir goresan.'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Data KanjiVG dimuat saat pertama kali dibuka, lalu disimpan di perangkat. Garis samar menunjukkan bentuk lengkap; garis ungu menunjukkan urutan penulisan. Latihan menulis memberi pemeriksaan sederhana benar atau salah berdasarkan arah goresan.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }


  Widget _practicePlayer() => Column(
        children: [
          Expanded(
            child: _StrokePracticeCanvas(
              paths: _data!.paths,
              metrics: _data!.metrics,
              completedCount: _practiceIndex,
              messageColor: _lastStrokeCorrect ? AppTheme.success : Theme.of(context).colorScheme.error,
              onStrokeFinished: _verifyPracticeStroke,
            ),
          ),
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              _practiceMessage,
              key: ValueKey(_practiceMessage),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _lastStrokeCorrect ? AppTheme.success : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _data!.paths.isEmpty ? 0 : _practiceIndex / _data!.paths.length,
            minHeight: 7,
          ),
        ],
      );

  void _verifyPracticeStroke(List<Offset> points) {
    final data = _data;
    if (data == null || points.length < 2 || _practiceIndex >= data.metrics.length) {
      setState(() {
        _lastStrokeCorrect = false;
        _practiceMessage = 'Goresan terlalu pendek. Coba lagi.';
      });
      return;
    }
    final targetMetrics = data.metrics[_practiceIndex];
    if (targetMetrics.isEmpty) return;
    final metric = targetMetrics.first;
    final start = metric.getTangentForOffset(0)?.position;
    final end = metric.getTangentForOffset(metric.length)?.position;
    if (start == null || end == null) return;
    final actualStart = points.first;
    final actualEnd = points.last;
    final startDistance = (actualStart - start).distance;
    final endDistance = (actualEnd - end).distance;
    final reversedDistance = (actualStart - end).distance + (actualEnd - start).distance;
    final forwardDistance = startDistance + endDistance;
    final correct = startDistance < 26 && endDistance < 32 && forwardDistance < reversedDistance;
    setState(() {
      _lastStrokeCorrect = correct;
      if (correct) {
        _practiceIndex++;
        if (_practiceIndex >= data.paths.length) {
          _practiceMessage = 'Bagus! Semua goresan benar.';
          AppScope.of(context).recordStudy(xpGained: 8);
        } else {
          _practiceMessage = 'Benar. Lanjut goresan ${_practiceIndex + 1}.';
        }
      } else {
        _practiceMessage = 'Masih salah. Mulai dekat titik nomor ${_practiceIndex + 1} dan ikuti arahnya.';
      }
    });
  }

  Widget _player() {
    if (_error != null) {
      return EmptyState(
        title: widget.item.character,
        message: '$_error',
        icon: Icons.cloud_off_rounded,
      );
    }
    if (_data == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 14),
            Text('Memuat data goresan…'),
          ],
        ),
      );
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => RepaintBoundary(
        child: CustomPaint(
          painter: _StrokePainter(
            paths: _data!.paths,
            metrics: _data!.metrics,
            progress: _controller.value,
            lineColor: Theme.of(context).colorScheme.outlineVariant,
            strokeColor: AppTheme.seed,
            ghostColor: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: .1),
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}


class _StrokePracticeCanvas extends StatefulWidget {
  const _StrokePracticeCanvas({
    required this.paths,
    required this.metrics,
    required this.completedCount,
    required this.messageColor,
    required this.onStrokeFinished,
  });

  final List<Path> paths;
  final List<List<PathMetric>> metrics;
  final int completedCount;
  final Color messageColor;
  final ValueChanged<List<Offset>> onStrokeFinished;

  @override
  State<_StrokePracticeCanvas> createState() => _StrokePracticeCanvasState();
}

class _StrokePracticeCanvasState extends State<_StrokePracticeCanvas> {
  final List<Offset> _points = [];

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          Offset normalize(Offset local) {
            final scale = math.min(size.width, size.height) / 109;
            final dx = (size.width - 109 * scale) / 2;
            final dy = (size.height - 109 * scale) / 2;
            return Offset((local.dx - dx) / scale, (local.dy - dy) / scale);
          }

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (details) => setState(() {
              _points
                ..clear()
                ..add(normalize(details.localPosition));
            }),
            onPanUpdate: (details) => setState(() {
              _points.add(normalize(details.localPosition));
            }),
            onPanEnd: (_) {
              widget.onStrokeFinished(List<Offset>.from(_points));
              setState(_points.clear);
            },
            child: CustomPaint(
              painter: _StrokePracticePainter(
                paths: widget.paths,
                metrics: widget.metrics,
                completedCount: widget.completedCount,
                userPoints: _points,
                lineColor: Theme.of(context).colorScheme.outlineVariant,
                ghostColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: .1),
                completedColor: AppTheme.success,
                activeColor: AppTheme.seed,
                userColor: widget.messageColor,
              ),
              child: const SizedBox.expand(),
            ),
          );
        },
      );
}

class _StrokePracticePainter extends CustomPainter {
  const _StrokePracticePainter({
    required this.paths,
    required this.metrics,
    required this.completedCount,
    required this.userPoints,
    required this.lineColor,
    required this.ghostColor,
    required this.completedColor,
    required this.activeColor,
    required this.userColor,
  });

  final List<Path> paths;
  final List<List<PathMetric>> metrics;
  final int completedCount;
  final List<Offset> userPoints;
  final Color lineColor;
  final Color ghostColor;
  final Color completedColor;
  final Color activeColor;
  final Color userColor;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width, size.height) / 109;
    final dx = (size.width - 109 * scale) / 2;
    final dy = (size.height - 109 * scale) / 2;
    canvas
      ..save()
      ..translate(dx, dy)
      ..scale(scale);

    final grid = Paint()
      ..color = lineColor
      ..strokeWidth = .65
      ..style = PaintingStyle.stroke;
    canvas
      ..drawRect(const Rect.fromLTWH(1, 1, 107, 107), grid)
      ..drawLine(const Offset(54.5, 1), const Offset(54.5, 108), grid)
      ..drawLine(const Offset(1, 54.5), const Offset(108, 54.5), grid);

    final ghost = Paint()
      ..color = ghostColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 3.3;
    final done = Paint()
      ..color = completedColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 3.8;
    final active = Paint()
      ..color = activeColor.withValues(alpha: .62)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 4.0;
    for (var index = 0; index < paths.length; index++) {
      canvas.drawPath(paths[index], index < completedCount ? done : ghost);
    }
    if (completedCount < paths.length) {
      canvas.drawPath(paths[completedCount], active);
      final metric = metrics[completedCount].isEmpty ? null : metrics[completedCount].first;
      final start = metric?.getTangentForOffset(0)?.position;
      if (start != null) {
        canvas.drawCircle(start, 5.8, Paint()..color = activeColor);
        _number(canvas, '${completedCount + 1}', start, Colors.white);
      }
    }
    if (userPoints.length > 1) {
      final path = Path()..moveTo(userPoints.first.dx, userPoints.first.dy);
      for (final point in userPoints.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = userColor
          ..strokeWidth = 4.4
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke,
      );
    }
    canvas.restore();
  }

  void _number(Canvas canvas, String text, Offset position, Color color) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: 7, fontWeight: FontWeight.w900),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, position - Offset(painter.width / 2, painter.height / 2));
  }

  @override
  bool shouldRepaint(covariant _StrokePracticePainter oldDelegate) =>
      oldDelegate.completedCount != completedCount ||
      oldDelegate.userPoints != userPoints ||
      oldDelegate.userColor != userColor;
}

class _StrokePainter extends CustomPainter {
  const _StrokePainter({
    required this.paths,
    required this.metrics,
    required this.progress,
    required this.lineColor,
    required this.strokeColor,
    required this.ghostColor,
  });

  final List<Path> paths;
  final List<List<PathMetric>> metrics;
  final double progress;
  final Color lineColor;
  final Color strokeColor;
  final Color ghostColor;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width, size.height) / 109;
    final dx = (size.width - 109 * scale) / 2;
    final dy = (size.height - 109 * scale) / 2;
    canvas
      ..save()
      ..translate(dx, dy)
      ..scale(scale);

    final grid = Paint()
      ..color = lineColor
      ..strokeWidth = .65
      ..style = PaintingStyle.stroke;
    canvas
      ..drawRect(const Rect.fromLTWH(1, 1, 107, 107), grid)
      ..drawLine(const Offset(54.5, 1), const Offset(54.5, 108), grid)
      ..drawLine(const Offset(1, 54.5), const Offset(108, 54.5), grid)
      ..drawLine(const Offset(1, 1), const Offset(108, 108), grid)
      ..drawLine(const Offset(108, 1), const Offset(1, 108), grid);

    final ghost = Paint()
      ..color = ghostColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 3.4;
    for (final path in paths) {
      canvas.drawPath(path, ghost);
    }

    final live = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 3.7;
    final total = progress * paths.length;
    for (var index = 0; index < paths.length; index++) {
      final part = (total - index).clamp(0.0, 1.0).toDouble();
      if (part <= 0) continue;
      for (final metric in metrics[index]) {
        canvas.drawPath(metric.extractPath(0, metric.length * part), live);
        if (part > .06) {
          final start = metric.getTangentForOffset(0)?.position;
          if (start != null) _number(canvas, '${index + 1}', start);
        }
      }
    }
    canvas.restore();
  }

  void _number(Canvas canvas, String text, Offset position) {
    canvas.drawCircle(
      position,
      5.2,
      Paint()..color = strokeColor,
    );
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 6.5,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      position - Offset(painter.width / 2, painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _StrokePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.paths != paths ||
      oldDelegate.metrics != metrics ||
      oldDelegate.strokeColor != strokeColor;
}
