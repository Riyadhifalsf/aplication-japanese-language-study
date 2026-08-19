import 'dart:ui';
import 'package:flutter/material.dart';

class LiquidGlass extends StatelessWidget {
  const LiquidGlass({required this.child, this.padding, this.borderRadius = 26, this.tint, super.key});
  final Widget child;
  final EdgeInsets? padding;
  final double borderRadius;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final color = tint ?? Theme.of(context).colorScheme.surface;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: color.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? .40 : .62),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: Colors.white.withValues(alpha: .18)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .06), blurRadius: 30, offset: const Offset(0, 14))],
          ),
          child: child,
        ),
      ),
    );
  }
}
