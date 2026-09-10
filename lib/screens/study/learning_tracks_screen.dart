import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../models/exam_question.dart';
import '../exams/exam_hub_screen.dart';

class LearningTracksScreen extends StatelessWidget {
  const LearningTracksScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Jalur JLPT & JFT')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
          children: [
            const _TrackHero(),
            const SizedBox(height: 18),
            _TrackCard(
              title: 'JLPT · N5 → N1',
              subtitle: 'Untuk kemampuan bahasa Jepang umum dan target JLPT.',
              icon: Icons.school_rounded,
              color: AppTheme.seed,
              bullets: const [
                '文字・語彙',
                '文法',
                '読解',
                '聴解',
                'Simulasi N5, N4, N3, N2, N1',
              ],
              button: 'Buka simulasi JLPT',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ExamHubScreen()),
              ),
            ),
            const SizedBox(height: 14),
            _TrackCard(
              title: 'JFT A1 Prep → A2',
              subtitle: 'Jalur praktis untuk komunikasi sehari-hari dan persiapan kerja.',
              icon: Icons.badge_rounded,
              color: const Color(0xFF17A673),
              bullets: const [
                'A1 Prep: fondasi sebelum JFT-Basic',
                'A2: target JFT-Basic',
                'Konteks kehidupan sehari-hari',
                'Listening dan respons situasional',
                'Simulasi dan test bertahap',
              ],
              button: 'Buka simulasi JFT',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ExamHubScreen(initialType: ExamType.jft),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const _Comparison(),
          ],
        ),
      );
}

class _TrackHero extends StatelessWidget {
  const _TrackHero();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              const Color(0xFF4A1110),
            ],
          ),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pilih tujuanmu',
                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w800)),
            SizedBox(height: 5),
            Text(
              'JLPT untuk kemampuan bahasa umum.\nJFT untuk komunikasi praktis sehari-hari.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 23,
                fontWeight: FontWeight.w900,
                height: 1.2,
              ),
            ),
          ],
        ),
      );
}

class _TrackCard extends StatelessWidget {
  const _TrackCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.bullets,
    required this.button,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<String> bullets;
  final String button;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: color.withValues(alpha: .12),
                    foregroundColor: color,
                    child: Icon(icon),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(title,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(subtitle, style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.35,
              )),
              const SizedBox(height: 12),
              for (final item in bullets)
                Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded, size: 17, color: color),
                      const SizedBox(width: 8),
                      Expanded(child: Text(item)),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              FilledButton.tonalIcon(
                onPressed: onTap,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text(button),
              ),
            ],
          ),
        ),
      );
}

class _Comparison extends StatelessWidget {
  const _Comparison();

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Catatan penting', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(
                'JFT-Basic menggunakan kerangka CEFR dan target utamanya A2. Label A1 di aplikasi dipakai sebagai jalur persiapan/fondasi, bukan level resmi JFT-Basic.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      );
}
