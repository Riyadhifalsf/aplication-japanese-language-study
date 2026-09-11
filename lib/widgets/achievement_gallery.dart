import 'package:flutter/material.dart';

import '../services/achievement_service.dart';
import '../state/app_controller.dart';

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
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Pencapaian', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              SizedBox(height: 3),
              Text('Jejak kecil yang membuktikan konsistensimu.', style: TextStyle(fontSize: 12)),
            ])),
            Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(99)), child: Text('$unlocked/${achievements.length}', style: TextStyle(fontWeight: FontWeight.w900, color: cs.primary))),
          ]),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: achievements.length < 3 ? achievements.length : 3,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: .72),
            itemBuilder: (context, index) => _AchievementTile(achievement: achievements[index], compact: true),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AchievementGalleryScreen(app: app))),
              icon: const Icon(Icons.grid_view_rounded, size: 19),
              label: const Text('Lihat semua pencapaian'),
            ),
          ),
        ]),
      ),
    );
  }
}

class AchievementGalleryScreen extends StatelessWidget {
  const AchievementGalleryScreen({required this.app, super.key});

  final AppController app;

  @override
  Widget build(BuildContext context) {
    final achievements = AchievementService.getAll(app);
    final unlocked = achievements.where((item) => item.unlocked).length;
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Semua pencapaian')),
      body: ListView(padding: const EdgeInsets.fromLTRB(18, 12, 18, 32), children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(22)),
          child: Row(children: [
            Container(width: 42, height: 42, alignment: Alignment.center, decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(14)), child: Icon(Icons.workspace_premium_rounded, color: cs.onPrimary)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Koleksi pencapaianmu', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
              const SizedBox(height: 3),
              Text('$unlocked dari ${achievements.length} pencapaian sudah terbuka', style: TextStyle(color: cs.onPrimaryContainer, fontSize: 12)),
            ])),
          ]),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: achievements.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 9, mainAxisSpacing: 9, childAspectRatio: .72),
          itemBuilder: (context, index) => _AchievementTile(achievement: achievements[index]),
        ),
      ]),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({required this.achievement, this.compact = false});

  final Achievement achievement;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final unlocked = achievement.unlocked;
    return Container(
      padding: EdgeInsets.all(compact ? 9 : 10),
      decoration: BoxDecoration(
        color: unlocked ? cs.primaryContainer : cs.surfaceContainerHighest.withValues(alpha: .52),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: unlocked ? cs.primary.withValues(alpha: .35) : cs.outlineVariant),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: compact ? 31 : 34, height: compact ? 31 : 34, alignment: Alignment.center, decoration: BoxDecoration(color: unlocked ? cs.primary : cs.outlineVariant, borderRadius: BorderRadius.circular(11)), child: Text(achievement.icon, style: TextStyle(color: unlocked ? cs.onPrimary : cs.onSurfaceVariant, fontWeight: FontWeight.w900, fontSize: compact ? 15 : 17))),
          const Spacer(),
          Icon(unlocked ? Icons.check_circle_rounded : Icons.lock_outline_rounded, color: unlocked ? cs.primary : cs.onSurfaceVariant, size: compact ? 16 : 18),
        ]),
        const Spacer(),
        Text(achievement.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w900, fontSize: compact ? 11 : 12, height: 1.12)),
        const SizedBox(height: 4),
        Text(unlocked ? 'Tercapai' : '${achievement.value}/${achievement.target}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: compact ? 10 : 11, color: cs.onSurfaceVariant, fontWeight: FontWeight.w700)),
        const SizedBox(height: 7),
        ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: achievement.progress, minHeight: 4, color: unlocked ? cs.primary : cs.outline)),
      ]),
    );
  }
}
