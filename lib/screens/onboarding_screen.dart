import 'package:flutter/material.dart';

import '../state/app_controller.dart';
import 'app_shell.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _page = 0;
  String _goal = 'JLPT';
  String _level = 'Pemula';
  int _minutes = 20;
  String _target = 'N5';

  Future<void> _finish() async {
    await AppScope.of(context).completeOnboarding(
      goal: _goal,
      level: _level,
      minutes: _minutes,
      targetLevel: _target,
    );
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AppShell()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [_goalPage(), _levelPage(), _planPage()];
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
              child: Row(
                children: [
                  const Text('Japanese Study',
                      style:
                          TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                  const Spacer(),
                  Text('${_page + 1}/3',
                      style: TextStyle(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                            begin: const Offset(.04, 0), end: Offset.zero)
                        .animate(animation),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(key: ValueKey(_page), child: pages[_page]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Row(
                children: [
                  if (_page > 0)
                    TextButton(
                        onPressed: () => setState(() => _page--),
                        child: const Text('Kembali'))
                  else
                    const SizedBox(width: 90),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed:
                        _page == 2 ? _finish : () => setState(() => _page++),
                    icon: Icon(_page == 2
                        ? Icons.check_rounded
                        : Icons.arrow_forward_rounded),
                    label: Text(_page == 2 ? 'Mulai belajar' : 'Lanjut'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _goalPage() => _PageBody(
        icon: Icons.flag_rounded,
        title: 'Apa tujuan belajarmu?',
        subtitle:
            'Kami akan memakai jawaban ini untuk menyusun rekomendasi awal, bukan untuk mengunci pilihanmu.',
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final item in const [
              'JLPT',
              'JFT / kerja',
              'Percakapan',
              'Anime & budaya'
            ])
              ChoiceChip(
                  label: Text(item),
                  selected: _goal == item,
                  onSelected: (_) => setState(() => _goal = item)),
          ],
        ),
      );

  Widget _levelPage() => _PageBody(
        icon: Icons.school_rounded,
        title: 'Seberapa jauh kamu sudah belajar?',
        subtitle:
            'Tidak perlu takut salah. Kamu bisa mengubah target ini kapan saja dari Home.',
        child: RadioGroup<String>(
          groupValue: _level,
          onChanged: (value) => setState(() {
            _level = value!;
            _target = switch (value) {
              'Benar-benar baru' || 'Pemula' => 'N5',
              'Sudah bisa kana' || 'Pernah belajar N5' => 'N4',
              _ => 'N3',
            };
          }),
          child: Column(
            children: [
              for (final item in const [
                'Benar-benar baru',
                'Pemula',
                'Sudah bisa kana',
                'Pernah belajar N5',
                'Sudah N4 atau lebih'
              ])
                RadioListTile<String>(
                  value: item,
                  title: Text(item),
                  contentPadding: EdgeInsets.zero,
                ),
            ],
          ),
        ),
      );

  Widget _planPage() => _PageBody(
        icon: Icons.schedule_rounded,
        title: 'Atur ritme yang realistis',
        subtitle:
            'Aplikasi akan memprioritaskan sesi yang bisa kamu selesaikan secara konsisten.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Target level',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final level in const ['N5', 'N4', 'N3', 'N2', 'N1', 'JFT'])
                  ChoiceChip(
                      label: Text(level),
                      selected: _target == level,
                      onSelected: (_) => setState(() => _target = level))
              ],
            ),
            const SizedBox(height: 22),
            Text('Waktu per hari: $_minutes menit',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w900)),
            Slider(
                value: _minutes.toDouble(),
                min: 10,
                max: 60,
                divisions: 5,
                label: '$_minutes menit',
                onChanged: (value) => setState(() => _minutes = value.round())),
            Card(
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withValues(alpha: .55),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Row(children: [
                  Icon(Icons.auto_awesome_rounded),
                  SizedBox(width: 10),
                  Expanded(
                      child: Text(
                          'Setelah ini Home akan menampilkan satu jalur utama, streak, target harian, dan rekomendasi berikutnya.'))
                ]),
              ),
            ),
          ],
        ),
      );
}

class _PageBody extends StatelessWidget {
  const _PageBody(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.child});
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 10),
        children: [
          CircleAvatar(radius: 34, child: Icon(icon, size: 34)),
          const SizedBox(height: 20),
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(subtitle,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.45)),
          const SizedBox(height: 24),
          child,
        ],
      );
}
