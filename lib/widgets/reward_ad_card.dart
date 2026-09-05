import 'package:flutter/material.dart';

import '../services/ads_service.dart';
import '../state/app_controller.dart';

class RewardAdCard extends StatelessWidget {
  const RewardAdCard({super.key, this.xpReward = 10});

  final int xpReward;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      color: cs.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.play_circle_fill_rounded, color: cs.onTertiaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bonus XP',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Text(
                    'Tonton iklan singkat dan dapatkan +$xpReward XP gratis.',
                    style: TextStyle(color: cs.onTertiaryContainer.withValues(alpha: .8)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () async {
                final app = AppScope.of(context);
                final messenger = ScaffoldMessenger.of(context);
                final earned = await AdsService.instance.showRewarded();
                if (!context.mounted) return;
                if (earned) {
                  await app.addBonusXp(xpReward);
                  messenger.showSnackBar(
                    SnackBar(content: Text('+$xpReward XP! Terima kasih sudah menonton.')),
                  );
                } else {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Iklan belum tersedia saat ini, coba lagi.')),
                  );
                }
              },
              child: const Text('Tonton'),
            ),
          ],
        ),
      ),
    );
  }
}