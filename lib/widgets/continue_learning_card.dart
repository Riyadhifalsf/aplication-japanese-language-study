import 'package:flutter/material.dart';

import '../screens/curriculum/curriculum_lesson_detail_screen.dart';
import '../screens/curriculum/curriculum_path_screen.dart';
import '../state/app_controller.dart';

/// Dashboard "Continue Learning" untuk Home.
///
/// Menampilkan: Current Level / Unit / Lesson / Progress + [Continue],
/// di bawahnya: Daily Review, Kanji Today, Vocabulary Review, Streak, XP.
/// Terhubung langsung ke progress Learning (bukan mockup).
class ContinueLearningCard extends StatelessWidget {
  const ContinueLearningCard({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final cont = app.curriculumContinue();
    final scheme = Theme.of(context).colorScheme;
    if (cont == null) return const SizedBox.shrink();
    final level = cont.level;
    final unit = cont.unit;
    final lesson = cont.lesson;
    final progress = cont.progress;

    if (app.hideContinueBanner) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              colors: [scheme.primary, const Color(0xFF4A1110)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'CONTINUE LEARNING · ${level.id}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .18),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '${(progress.percent * 100).round()}%',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Current Level: JLPT ${level.id}',
                style:
                    const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                'Current Unit: ${unit == null ? '-' : 'Unit ${unit.sequence} — ${unit.title}'}',
                style:
                    const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                'Current Lesson: ${lesson?.title ?? 'Semua selesai — review'}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    height: 1.2),
              ),
              const SizedBox(height: 4),
              Text(
                'Progress: ${progress.completedLessons}/${progress.totalLessons} lesson',
                style:
                    const TextStyle(color: Colors.white70, height: 1.4),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: progress.percent.clamp(0.0, 1.0).toDouble(),
                  minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: .22),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: scheme.primary,
                      ),
                      onPressed: () {
                        if (lesson != null) {
                          app.setCurriculumActiveLesson(lesson.id);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CurriculumLessonDetailScreen(
                                  lessonId: lesson.id),
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CurriculumPathScreen(
                                  initialLevel: level.id),
                            ),
                          );
                        }
                      },
                      child: Text(lesson == null
                          ? 'Review ${level.id}'
                          : 'Continue'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54),
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CurriculumPathScreen(
                              initialLevel: level.id),
                        ),
                      ),
                      child: const Text('Open Learning'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          right: -10,
          top: -10,
          child: Tooltip(
            message: 'Sembunyikan',
            child: GestureDetector(
              onTap: () => app.setHideContinueBanner(true),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.error,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
          ),
        ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _MiniStat(
                    icon: Icons.local_fire_department_rounded,
                    label: 'Streak',
                    value: '${app.streak} hari')),
            const SizedBox(width: 8),
            Expanded(
                child: _MiniStat(
                    icon: Icons.star_rounded,
                    label: 'JLPT',
                    value: app.masteryTier.label)),
          ],
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(
      {required this.icon,
      required this.label,
      required this.value,
      this.onTap});

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 8),
                Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(fontWeight: FontWeight.w900)),
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 10.5,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant)),
              ],
            ),
          ),
        ),
      );
}
