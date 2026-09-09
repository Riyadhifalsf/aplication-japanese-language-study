import 'package:flutter/material.dart';

/// Compatibility wrapper. The visual glass effect was removed from the app.
/// Existing callers now render as ordinary Material surfaces.
class LiquidGlass extends StatelessWidget {
  const LiquidGlass({required this.child, this.padding, this.borderRadius = 26, this.tint, super.key});
  final Widget child;
  final EdgeInsets? padding;
  final double borderRadius;
  final Color? tint;

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: tint ?? Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: child,
      );
}
