import 'package:flutter/material.dart';

import '../core/app_theme.dart';

class JlptBadge extends StatelessWidget {
  const JlptBadge(this.level, {super.key, this.compact = false});

  final String level;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .13),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        level,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textScaler: TextScaler.noScaling,
        style: TextStyle(
          color: color,
          fontSize: compact ? 10.5 : 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class AdaptiveContent extends StatelessWidget {
  const AdaptiveContent({required this.child, super.key, this.maxWidth = 980});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      );
}

int responsiveColumns(
  double width, {
  int compact = 1,
  int medium = 2,
  int large = 3,
  int extraLarge = 4,
}) {
  if (width >= 1040) return extraLarge;
  if (width >= 760) return large;
  if (width >= 520) return medium;
  return compact;
}

class PageHeader extends StatelessWidget {
  const PageHeader({
    required this.title,
    required this.subtitle,
    super.key,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final titleBlock = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            );
            if (trailing == null) return titleBlock;
            if (constraints.maxWidth < 380) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  titleBlock,
                  const SizedBox(height: 10),
                  Align(alignment: Alignment.centerRight, child: trailing!),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: titleBlock),
                const SizedBox(width: 10),
                trailing!,
              ],
            );
          },
        ),
      );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({
    required this.title,
    super.key,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final titleBlock = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          );
          if (trailing == null) return titleBlock;
          if (constraints.maxWidth < 380) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [titleBlock, const SizedBox(height: 8), trailing!],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: titleBlock),
              const SizedBox(width: 8),
              trailing!,
            ],
          );
        },
      );
}

class FeatureCard extends StatelessWidget {
  const FeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    super.key,
    this.progress,
    this.badge,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final double? progress;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact =
                constraints.maxHeight < 176 || constraints.maxWidth < 190;
            return Padding(
              padding: EdgeInsets.all(compact ? 13 : 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Row(
                    children: [
                      Container(
                        width: compact ? 40 : 44,
                        height: compact ? 40 : 44,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: .13),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child:
                            Icon(icon, color: color, size: compact ? 21 : 24),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: badge == null
                              ? Icon(Icons.arrow_forward_rounded,
                                  color: color, size: 20)
                              : Container(
                                  constraints:
                                      const BoxConstraints(maxWidth: 118),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: .1),
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: Text(
                                    badge!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    textScaler: TextScaler.noScaling,
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: compact ? 9 : 12),
                  Text(
                    title,
                    maxLines: compact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Flexible(
                    child: Text(
                      subtitle,
                      maxLines: compact ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                        height: 1.2,
                      ),
                    ),
                  ),
                  if (progress != null) ...[
                    SizedBox(height: compact ? 7 : 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: progress!.clamp(0.0, 1.0).toDouble(),
                        minHeight: 6,
                        color: color,
                        backgroundColor: color.withValues(alpha: .12),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  const StatTile({
    required this.value,
    required this.label,
    required this.icon,
    super.key,
    this.color = AppTheme.seed,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final stack = constraints.maxWidth < 155;
              final iconWidget = CircleAvatar(
                backgroundColor: color.withValues(alpha: .13),
                foregroundColor: color,
                child: Icon(icon, size: 20),
              );
              final textWidget = Column(
                crossAxisAlignment:
                    stack ? CrossAxisAlignment.start : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              );
              if (stack) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    iconWidget,
                    const SizedBox(height: 10),
                    textWidget
                  ],
                );
              }
              return Row(
                children: [
                  iconWidget,
                  const SizedBox(width: 12),
                  Expanded(child: textWidget),
                ],
              );
            },
          ),
        ),
      );
}

class FuriganaText extends StatelessWidget {
  const FuriganaText({
    required this.word,
    required this.reading,
    super.key,
    this.showReading = true,
    this.wordStyle,
    this.readingStyle,
    this.alignment = CrossAxisAlignment.center,
  });

  final String word;
  final String reading;
  final bool showReading;
  final TextStyle? wordStyle;
  final TextStyle? readingStyle;
  final CrossAxisAlignment alignment;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: alignment,
        children: [
          if (showReading)
            Text(
              reading,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: readingStyle ??
                  TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          Text(
            word,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: wordStyle ??
                const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
        ],
      );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.title,
    required this.message,
    super.key,
    this.icon = Icons.search_off_rounded,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 52,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
}
