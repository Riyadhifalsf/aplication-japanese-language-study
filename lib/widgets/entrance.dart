import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Animasi masuk satu-kali: fade + naik halus, dengan jeda untuk efek stagger.
///
/// Hanya main SEKALI per [keyName] selama sesi aplikasi — rebuild karena
/// `notifyListeners` tidak mengulang animasi. Hormati aksesibilitas: bila
/// user mematikan animasi (atau reduce motion), tampil instan.
///
/// Contoh:
/// ```dart
/// Entrance(keyName: 'home-header', child: header),
/// Entrance(keyName: 'home-streak', delay: Duration(milliseconds: 70), child: card),
/// ```
class Entrance extends StatefulWidget {
  const Entrance({
    required this.child,
    this.delay = Duration.zero,
    this.keyName = '',
    super.key,
  });

  final Widget child;
  final Duration delay;
  final String keyName;

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance>
    with SingleTickerProviderStateMixin {
  static final Set<String> _played = {};

  AnimationController? _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    final reduceMotion = SchedulerBinding
        .instance.platformDispatcher.accessibilityFeatures.disableAnimations;
    final seen =
        widget.keyName.isNotEmpty && _played.contains(widget.keyName);
    if (reduceMotion || seen) return;
    if (widget.keyName.isNotEmpty) _played.add(widget.keyName);
    _controller = AnimationController(
      duration: const Duration(milliseconds: 380),
      vsync: this,
    );
    final curved =
        CurvedAnimation(parent: _controller!, curve: Curves.easeOutCubic);
    _fade = Tween<double>(begin: 0, end: 1).animate(curved);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(curved);
    if (widget.delay == Duration.zero) {
      _controller!.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller?.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) return widget.child;
    return AnimatedBuilder(
      animation: controller,
      builder: (_, child) => Opacity(
        opacity: _fade.value,
        child: FractionalTranslation(
          translation: _slide.value,
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}
