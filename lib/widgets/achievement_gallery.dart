import 'package:flutter/material.dart';

import '../services/achievement_service.dart';
import '../state/app_controller.dart';
import '../screens/profile/achievements_screen.dart';

class AchievementGallery extends StatelessWidget {
  const AchievementGallery({required this.app, super.key});

  final AppController app;

  @override
  Widget build(BuildContext context) {
    final achievements = AchievementService.getAll(app);
    final unlocked = achievements.where((item) => item.unlocked).length;
    final cs = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Pencapaian',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AchievementsScreen())),
                  child: Text('$unlocked/${achievements.length} · Semua'),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              'Milestone kecil yang bikin progres panjang terasa nyata.',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 164,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: achievements.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final achievement = achievements[index];
                  return SizedBox(
                    width: 176,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: achievement.unlocked
                            ? cs.primaryContainer
                            : cs.surfaceContainerHighest.withValues(alpha: .5),
                        border: Border.all(
                          color: achievement.unlocked
                              ? cs.primary.withValues(alpha: .35)
                              : cs.outlineVariant,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: achievement.unlocked
                                    ? cs.primary
                                    : cs.outlineVariant,
                                child: Text(
                                  achievement.icon,
                                  style: TextStyle(
                                    color: achievement.unlocked
                                        ? cs.onPrimary
                                        : cs.onSurfaceVariant,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              if (achievement.unlocked)
                                Icon(Icons.check_circle_rounded,
                                    color: cs.primary, size: 20)
                              else
                                Text(
                                  '${achievement.value}/${achievement.target}',
                                  style: TextStyle(
                                    color: cs.onSurfaceVariant,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            achievement.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            achievement.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurfaceVariant,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: achievement.progress,
                              minHeight: 5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
