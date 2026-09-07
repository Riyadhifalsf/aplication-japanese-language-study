import 'dart:async';

import 'package:flutter/material.dart';

import '../../features/curriculum/curriculum_models.dart';
import '../../state/app_controller.dart';
import '../profile/premium_screen.dart';

/// View-model satu node unit di path melengkung ala LingoDeer.
class UnitPathNode {
  const UnitPathNode({
    required this.unit,
    required this.done,
    required this.total,
    required this.locked,
    required this.isCurrent,
    required this.nextLesson,
  });

  final CurriculumUnit unit;
  final int done;
  final int total;
  final bool locked;
  final bool isCurrent;
  final CurriculumLesson? nextLesson;

  bool get completed => total > 0 && done >= total;
}

/// Path melengkung ala LingoDeer: node lingkaran zig-zag kiri-kanan dengan
/// garis putus-putus di belakangnya. Satu node = satu unit.
class CurriculumWindingPath extends StatelessWidget {
  const CurriculumWindingPath({
    super.key,
    required this.nodes,
    required this.onOpen,
  });

  final List<UnitPathNode> nodes;
  final ValueChanged<UnitPathNode> onOpen;

  static const double rowHeight = 120;
  static const double _leftFrac = 0.24;
  static const double _rightFrac = 0.76;

  @override
  Widget build(BuildContext context) {
    if (nodes.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final centers = <Offset>[
          for (var i = 0; i < nodes.length; i++)
            Offset(
              width * (i.isEven ? _leftFrac : _rightFrac),
              rowHeight * i + rowHeight / 2,
            ),
        ];
        return CustomPaint(
          painter: _SnakePainter(
            points: centers,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          child: Column(
            children: [
              for (var i = 0; i < nodes.length; i++)
                SizedBox(
                  height: rowHeight,
                  child: _PathRow(
                    node: nodes[i],
                    center: centers[i],
                    width: width,
                    onOpen: onOpen,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _PathRow extends StatelessWidget {
  const _PathRow({
    required this.node,
    required this.center,
    required this.width,
    required this.onOpen,
  });

  final UnitPathNode node;
  final Offset center;
  final double width;
  final ValueChanged<UnitPathNode> onOpen;

  @override
  Widget build(BuildContext context) {
    final leftSide = center.dx < width / 2;
    // Jarak dari tengah node ke awal label (radius halo + spasi).
    const gap = 58.0;
    return Stack(
      children: [
        Align(
          alignment: Alignment((center.dx / width) * 2 - 1, 0),
          child: _NodeCircle(node: node, onTap: () => onOpen(node)),
        ),
        Positioned(
          top: 0,
          bottom: 0,
          left: leftSide ? center.dx + gap : 4,
          right: leftSide ? 4 : width - center.dx + gap,
          child: Align(
            alignment:
                leftSide ? Alignment.centerLeft : Alignment.centerRight,
            child: _NodeLabel(node: node, alignRight: !leftSide),
          ),
        ),
      ],
    );
  }
}

class _NodeLabel extends StatelessWidget {
  const _NodeLabel({required this.node, required this.alignRight});

  final UnitPathNode node;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          node.unit.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: alignRight ? TextAlign.right : TextAlign.left,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: node.locked ? scheme.onSurfaceVariant : scheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${node.done}/${node.total}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: node.isCurrent ? scheme.primary : scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _NodeCircle extends StatelessWidget {
  const _NodeCircle({required this.node, required this.onTap});

  final UnitPathNode node;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final completed = node.completed;

    final Color bg;
    final Widget icon;
    if (node.locked) {
      bg = scheme.surfaceContainerHighest;
      icon = Icon(
        _unitIcon(node.unit.icon),
        color: scheme.onSurfaceVariant,
        size: 38,
      );
    } else if (completed) {
      bg = Colors.green.shade600;
      icon = const Icon(Icons.check_rounded, color: Colors.white, size: 42);
    } else {
      bg = scheme.primary;
      icon = Icon(_unitIcon(node.unit.icon), color: Colors.white, size: 38);
    }

    return SizedBox(
      width: 104,
      height: 104,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (node.isCurrent)
            Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primary.withValues(alpha: .16),
              ),
            ),
          Material(
            type: MaterialType.transparency,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: Ink(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: bg,
                  boxShadow: !node.locked
                      ? [
                          BoxShadow(
                            color: bg.withValues(alpha: .45),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : null,
                ),
                child: Center(child: icon),
              ),
            ),
          ),
          if (node.isCurrent)
            Positioned(
              right: 2,
              top: 2,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5484D),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.star_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Garis ular putus-putus di belakang node.
class _SnakePainter extends CustomPainter {
  _SnakePainter({required this.points, required this.color});

  final List<Offset> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final path = Path()
      ..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final p0 = points[i - 1];
      final p1 = points[i];
      final midY = (p0.dy + p1.dy) / 2;
      path.cubicTo(p0.dx, midY, p1.dx, midY, p1.dx, p1.dy);
    }
    canvas.drawPath(
      _dash(path, 12, 9),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
  }

  static Path _dash(Path source, double dash, double gap) {
    final out = Path();
    for (final metric in source.computeMetrics()) {
      var dist = 0.0;
      while (dist < metric.length) {
        out.addPath(metric.extractPath(dist, dist + dash), Offset.zero);
        dist += dash + gap;
      }
    }
    return out;
  }

  @override
  bool shouldRepaint(covariant _SnakePainter old) =>
      old.color != color || old.points.length != points.length;
}

IconData _unitIcon(String icon) => switch (icon) {
      'waving' => Icons.waving_hand_rounded,
      'kana' => Icons.grid_view_rounded,
      'vocab' => Icons.menu_book_rounded,
      'kanji' => Icons.translate_rounded,
      'grammar' => Icons.account_tree_rounded,
      'chat' => Icons.forum_rounded,
      'reading' => Icons.auto_stories_rounded,
      'listening' => Icons.headphones_rounded,
      'trophy' => Icons.workspace_premium_rounded,
      'badge' => Icons.badge_rounded,
      'work' => Icons.work_rounded,
      'review' => Icons.refresh_rounded,
      _ => Icons.book_rounded,
    };

/// Banner promo premium ala LingoDeer: HEMAT + hitung mundur + tombol
/// upgrade. Sembunyi otomatis untuk pengguna premium.
class PromoBanner extends StatefulWidget {
  const PromoBanner({super.key});

  @override
  State<PromoBanner> createState() => _PromoBannerState();
}

class _PromoBannerState extends State<PromoBanner> {
  late Timer _timer;
  Duration _left = Duration.zero;

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    if (mounted) setState(() => _left = end.difference(now));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  static String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    if (app.isPremium) return const SizedBox.shrink();
    final h = _two(_left.inHours.clamp(0, 99).toInt());
    final m = _two(_left.inMinutes.remainder(60).clamp(0, 59).toInt());
    final s = _two(_left.inSeconds.remainder(60).clamp(0, 59).toInt());
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF1F2A44), Color(0xFF10182B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.workspace_premium_rounded,
            color: Color(0xFFFFD66B),
            size: 34,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'HEMAT\n40%',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                height: 1.0,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$h : $m : $s',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD66B),
                  foregroundColor: const Color(0xFF3A2B00),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PremiumScreen(),
                  ),
                ),
                child: const Text(
                  'Upgrade ke Premium >',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
