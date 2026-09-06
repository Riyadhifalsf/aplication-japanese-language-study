import 'dart:convert';

import 'package:flutter/material.dart';

import '../../services/feature_flags_service.dart';
import '../../state/app_controller.dart';
import '../../widgets/reward_ad_card.dart';
import '../../services/hidden_quests.dart';
import '../../widgets/brand_icons.dart';
import '../auth/login_screen.dart';
import '../streak/streak_screen.dart';
import 'premium_screen.dart';
import 'profile_settings_screen.dart';
import 'study_stats_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final cs = Theme.of(context).colorScheme;

    // Halaman penuh (dibuka dari avatar beranda, ala Busuu): AppBar dengan
    // tombol kembali + judul. Pengaturan tetap via ikon gerigi di header.
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 34),
        children: [
          Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              colors: [cs.primaryContainer, cs.surface],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 42,
                    backgroundColor: cs.primary.withValues(alpha: .14),
                    backgroundImage: app.profilePhotoData.isNotEmpty
                        ? MemoryImage(base64Decode(app.profilePhotoData))
                        : null,
                    child: app.profilePhotoData.isEmpty
                        ? Text(
                            app.profileName.isEmpty
                                ? '日'
                                : app.profileName
                                    .substring(0, 1)
                                    .toUpperCase(),
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: cs.primary,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      app.profileName,
                                      style: const TextStyle(
                                        fontSize: 23,
                                        fontWeight: FontWeight.w900,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (app.isAccountVerified) ...[
                                    const SizedBox(width: 6),
                                    const VerifiedBadge(
                                      tooltip: 'Akun terverifikasi',
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Pengaturan profil',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const ProfileSettingsScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.settings_rounded),
                            ),
                          ],
                        ),
                        if (app.profileHandle.isNotEmpty)
                          Text(
                            '@${app.profileHandle}',
                            style: TextStyle(
                              color: cs.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        if (app.profileBio.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Text(
                              app.profileBio,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        const SizedBox(height: 9),
                        Row(
                          children: [
                            _SocialCount(
                              'Pengikut',
                              '${app.followersEnabled ? app.profileFollowers : 0}',
                              enabled: app.followersEnabled,
                            ),
                            const SizedBox(width: 18),
                            _SocialCount(
                              'Mengikuti',
                              '${app.followersEnabled ? app.profileFollowing : 0}',
                              enabled: app.followersEnabled,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const StudyStatsScreen(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surface.withValues(alpha: .6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      _CompactMetric('XP', '${app.xp}'),
                      _CompactMetric('Streak', '${app.streak}'),
                      _CompactMetric('Kanji', '${app.learnedKanjiCount}'),
                      _CompactMetric('Aktif', '${app.totalActiveMinutes}m'),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Ringkasan kemajuan · ketuk untuk statistik lengkap',
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
              if (!app.isAuthenticated) ...[
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LoginScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.login_rounded),
                  label: const Text('Login untuk sinkronisasi'),
                ),
              ],
              if (!app.isPremium) ...[
                const SizedBox(height: 12),
                Card(
                  color: cs.primaryContainer.withValues(alpha: .55),
                  child: ListTile(
                    leading: const Icon(Icons.workspace_premium_rounded),
                    title: const Text('Go Premium',
                        style: TextStyle(fontWeight: FontWeight.w900)),
                    subtitle: const Text(
                        'Mulai Rp15rb/bln — harga naik tiap fase.'),
                    trailing:
                        const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PremiumScreen()),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const RewardAdCard(),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        _HiddenQuestCard(app: app),
        const SizedBox(height: 14),
        Card(
          color: cs.surfaceContainerHighest,
          child: ListTile(
            leading: const Icon(Icons.groups_rounded),
            title: Row(
              children: [
                const Text(
                  'Komunitas',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(width: 7),
                const _BetaBadge(),
              ],
            ),
            subtitle: Text(
              app.communityEnabled
                  ? 'Feed komunitas aktif.'
                  : 'Upload, follow, dan komentar masih dalam tahap beta dan belum aktif.',
            ),
            trailing: const Icon(Icons.lock_clock_rounded),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.local_fire_department_rounded),
            title: const Text(
              'Rentetan',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            subtitle: Text('${app.streak} hari · ${app.streakTierName}'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StreakScreen(),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Penguasaan JLPT keseluruhan',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                for (final level in const ['N5', 'N4', 'N3', 'N2', 'N1'])
                  _LevelProgress(level, app),
              ],
            ),
          ),
        ),
        ],
      ),
    );
  }
}

class _SocialCount extends StatelessWidget {
  const _SocialCount(this.label, this.value, {required this.enabled});

  final String label;
  final String value;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: enabled ? Theme.of(context).colorScheme.onSurface : muted,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: muted)),
      ],
    );
  }
}

class _CompactMetric extends StatelessWidget {
  const _CompactMetric(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu misi tersembunyi: yang terbuka tampil, sisanya "???".
class _HiddenQuestCard extends StatelessWidget {
  const _HiddenQuestCard({required this.app});
  final AppController app;

  @override
  Widget build(BuildContext context) {
    final open = app.unlockedQuests.length;
    final total = HiddenQuests.defs.length;
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.auto_awesome_rounded)),
        title: const Text('Misi Tersembunyi',
            style: TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text('$open dari $total terbuka. Syaratnya rahasia...'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Misi Tersembunyi'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final q in HiddenQuests.defs)
                    Builder(builder: (_) {
                      final got = app.unlockedQuests.contains(q.id);
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 18,
                          child: Icon(got ? q.icon : Icons.question_mark_rounded,
                              size: 18),
                        ),
                        title: Text(got ? q.title : '???',
                            style:
                                const TextStyle(fontWeight: FontWeight.w800)),
                        subtitle: Text(got ? '+${q.rewardXp} XP' : q.hint,
                            style: const TextStyle(fontSize: 12)),
                      );
                    }),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BetaBadge extends StatelessWidget {
  const _BetaBadge();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        'BETA',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: scheme.onTertiaryContainer,
        ),
      ),
    );
  }
}


class _LevelProgress extends StatelessWidget {
  const _LevelProgress(this.level, this.app);

  final String level;
  final AppController app;

  @override
  Widget build(BuildContext context) {
    final progress = app.levelOverallMastery(level);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(level, style: const TextStyle(fontWeight: FontWeight.w900)),
              const Spacer(),
              Text('${(progress * 100).round()}%'),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}
