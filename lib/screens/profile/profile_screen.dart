import 'dart:convert';

import 'package:flutter/material.dart';

import '../../state/app_controller.dart';
import '../../widgets/brand_icons.dart';
import '../auth/login_screen.dart';
import 'profile_settings_screen.dart';
import 'study_stats_screen.dart';
import '../../widgets/profile_insights.dart';
import '../../widgets/achievement_gallery.dart';
import '../../widgets/weekly_learning_pulse.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int? _selectedActivityYear;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 34),
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(colors: [cs.primaryContainer, cs.surface]),
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
                              app.profileName.isEmpty ? '日' : app.profileName.substring(0, 1).toUpperCase(),
                              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: cs.primary),
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
                                        style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (app.isAccountVerified) ...[
                                      const SizedBox(width: 6),
                                      const VerifiedBadge(tooltip: 'Akun terverifikasi'),
                                    ],
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Pengaturan profil',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const ProfileSettingsScreen()),
                                  );
                                },
                                icon: const Icon(Icons.settings_rounded),
                              ),
                            ],
                          ),
                          if (app.profileHandle.isNotEmpty)
                            Text('@${app.profileHandle}', style: TextStyle(color: cs.primary, fontWeight: FontWeight.w800)),
                          if (app.profileBio.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 5),
                              child: Text(app.profileBio, maxLines: 2, overflow: TextOverflow.ellipsis),
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
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const StudyStatsScreen()));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    decoration: BoxDecoration(
                      color: cs.surface.withValues(alpha: .6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        _CompactMetric('Mastery', '${(app.overallMasteryScore * 100).round()}%'),
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
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                  ),
                ),
                if (!app.isAuthenticated) ...[
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                    },
                    icon: const Icon(Icons.login_rounded),
                    label: const Text('Login untuk sinkronisasi'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          ProfileInsights(app: app),
          const SizedBox(height: 14),
          WeeklyLearningPulse(app: app),
          const SizedBox(height: 14),
          AchievementGallery(app: app),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Penguasaan JLPT keseluruhan', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),
                  for (final level in const ['N5', 'N4', 'N3', 'N2', 'N1']) _LevelProgress(level, app),
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Expanded(child: Text('Aktivitas terakhir', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900))),
                      _ActivityYearDropdown(
                        year: _selectedActivityYear,
                        years: _activityYears(app.activityJournal),
                        onChanged: (value) => setState(() => _selectedActivityYear = value),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  for (final e in _filteredActivities(app.activityJournal).take(8))
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      leading: const Icon(Icons.timeline_rounded),
                      title: Text('${e['label'] ?? '-'}', maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text('${e['type'] ?? '-'} · ${_formatActivityDate(e['at'])}'),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<int> _activityYears(List<Map<String, Object?>> entries) {
    final years = <int>{DateTime.now().year};
    for (final e in entries) {
      final value = DateTime.tryParse('${e['at'] ?? ''}');
      if (value != null) years.add(value.year);
    }
    final sorted = years.toList()..sort((a, b) => b.compareTo(a));
    return sorted;
  }

  List<Map<String, Object?>> _filteredActivities(List<Map<String, Object?>> entries) {
    final year = _selectedActivityYear;
    if (year == null) return entries.reversed.toList(growable: false);
    return entries.where((e) => DateTime.tryParse('${e['at'] ?? ''}')?.year == year).toList(growable: false).reversed.toList(growable: false);
  }

  String _formatActivityDate(Object? raw) {
    final dt = DateTime.tryParse('$raw');
    if (dt == null) return '$raw';
    final local = dt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.day}/${two(local.month)}/${local.year} ${two(local.hour)}:${two(local.minute)}';
  }
}

class _ActivityYearDropdown extends StatelessWidget {
  const _ActivityYearDropdown({required this.year, required this.years, required this.onChanged});
  final int? year;
  final List<int> years;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<int?>(
        value: year,
        borderRadius: BorderRadius.circular(16),
        icon: const Icon(Icons.keyboard_arrow_down_rounded),
        isDense: true,
        hint: const Text('Semua tahun'),
        items: [
          const DropdownMenuItem<int?>(value: null, child: Text('Semua tahun')),
          ...years.map((y) => DropdownMenuItem<int?>(value: y, child: Text('$y'))),
        ],
        onChanged: onChanged,
      ),
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
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700)),
        ],
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
            child: LinearProgressIndicator(value: progress, minHeight: 8),
          ),
        ],
      ),
    );
  }
}
