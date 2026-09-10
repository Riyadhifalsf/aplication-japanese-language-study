import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../state/app_controller.dart';

/// Reusable component system (Phase 2 redesign).
/// Semua screen Learn/Home/Review memakai komponen ini agar konsisten.
/// Tidak ada logic bisnis di sini — murni presentasi.

class AppCard extends StatelessWidget {
  const AppCard({required this.child, super.key, this.onTap, this.padding});

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      );
}

class LearningProgressBar extends StatelessWidget {
  const LearningProgressBar({required this.value, super.key, this.height = 8});

  final double value;
  final double height;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0).toDouble(),
        minHeight: height,
        backgroundColor: cs.surfaceContainerHighest,
        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.progress),
      ),
    );
  }
}

class XPIndicator extends StatelessWidget {
  const XPIndicator({required this.xp, super.key});

  final int xp;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.xp.withValues(alpha: .16),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, size: 14, color: AppColors.xp),
            const SizedBox(width: 4),
            Text('$xp XP',
                style: const TextStyle(
                    fontWeight: FontWeight.w900, fontSize: 12)),
          ],
        ),
      );
}

class StreakBadge extends StatelessWidget {
  const StreakBadge({required this.streak, super.key});

  final int streak;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.streak.withValues(alpha: .14),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_fire_department_rounded,
                size: 14, color: AppColors.streak),
            const SizedBox(width: 4),
            Text('$streak hari',
                style: const TextStyle(
                    fontWeight: FontWeight.w900, fontSize: 12)),
          ],
        ),
      );
}

class LevelBadge extends StatelessWidget {
  const LevelBadge({required this.level, super.key});

  final int level;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text('Player Lv $level',
          style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 12,
              color: cs.onPrimaryContainer)),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton(
      {required this.label, required this.onPressed, super.key, this.icon});

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon ?? Icons.play_arrow_rounded),
        label: Text(label),
      );
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton(
      {required this.label, required this.onPressed, super.key});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) =>
      OutlinedButton(onPressed: onPressed, child: Text(label));
}

class LessonCard extends StatelessWidget {
  const LessonCard({
    required this.title,
    required this.subtitle,
    super.key,
    this.progress = 0,
    this.statusLabel = '',
    this.locked = false,
    this.completed = false,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final double progress;
  final String statusLabel;
  final bool locked;
  final bool completed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final icon = locked
        ? Icons.lock_rounded
        : completed
            ? Icons.check_circle_rounded
            : Icons.play_circle_rounded;
    final iconColor = locked
        ? AppColors.locked
        : completed
            ? AppColors.success
            : cs.primary;
    return AppCard(
      onTap: locked ? null : onTap,
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12, color: cs.onSurfaceVariant)),
                if (!locked) ...[
                  const SizedBox(height: 8),
                  LearningProgressBar(value: progress),
                ],
                if (statusLabel.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(statusLabel,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurfaceVariant)),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

class ChapterCard extends StatelessWidget {
  const ChapterCard({
    required this.title,
    required this.description,
    super.key,
    this.progress = 0,
    this.meta = '',
    this.locked = false,
    this.onTap,
  });

  final String title;
  final String description;
  final double progress;
  final String meta;
  final bool locked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AppCard(
      onTap: locked ? null : onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w900)),
              ),
              Icon(
                  locked
                      ? Icons.lock_rounded
                      : Icons.arrow_forward_rounded,
                  color: locked ? AppColors.locked : cs.primary),
            ],
          ),
          const SizedBox(height: 4),
          Text(description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style:
                  TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          const SizedBox(height: 10),
          LearningProgressBar(value: progress),
          if (meta.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(meta,
                style: TextStyle(
                    fontSize: 11, color: cs.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }
}

class AnswerFeedback extends StatelessWidget {
  const AnswerFeedback.correct(
      {super.key,
      this.reading = '',
      this.meaning = '',
      this.explanation = ''})
      : correct = true,
        answer = '';

  const AnswerFeedback.wrong(
      {required this.answer,
      super.key,
      this.reading = '',
      this.meaning = '',
      this.explanation = ''})
      : correct = false;

  final bool correct;
  final String answer;
  final String reading;
  final String meaning;
  final String explanation;

  @override
  Widget build(BuildContext context) {
    final color = correct ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: .4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                  correct
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  color: color),
              const SizedBox(width: 8),
              Text(correct ? 'Correct!' : 'Not quite.',
                  style: TextStyle(
                      fontWeight: FontWeight.w900, color: color)),
            ],
          ),
          if (answer.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Jawaban: $answer',
                style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
          if (reading.isNotEmpty)
            Text('Reading: $reading',
                style: const TextStyle(height: 1.4)),
          if (meaning.isNotEmpty)
            Text('Meaning: $meaning',
                style: const TextStyle(height: 1.4)),
          if (explanation.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(explanation,
                style: const TextStyle(height: 1.4)),
          ],
        ],
      ),
    );
  }
}

extension MasteryTierColorExtension on MasteryTier {
  Color get color => switch (this) {
        MasteryTier.warrior => const Color(0xFF9E9E9E),
        MasteryTier.elite => const Color(0xFF4FC3F7),
        MasteryTier.master => const Color(0xFFBA68C8),
        MasteryTier.grandmaster => const Color(0xFFFFB300),
        MasteryTier.epic => const Color(0xFFFF5722),
        MasteryTier.legend => const Color(0xFFFFD700),
        MasteryTier.mythic => const Color(0xFFE040FB),
      };
}
