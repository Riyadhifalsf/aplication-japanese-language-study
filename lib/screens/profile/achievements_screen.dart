import 'package:flutter/material.dart';
import '../../services/achievement_service.dart';
import '../../state/app_controller.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final items = AchievementService.getAll(app);
    return Scaffold(
      appBar: AppBar(title: const Text('Semua pencapaian')),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, index) {
          final a = items[index];
          return Card(child: ListTile(
            leading: CircleAvatar(child: Text(a.icon)),
            title: Text(a.title, style: const TextStyle(fontWeight: FontWeight.w900)),
            subtitle: Text(a.description),
            trailing: a.unlocked ? const Icon(Icons.check_circle_rounded) : Text('${a.value}/${a.target}'),
          ));
        },
      ),
    );
  }
}
