import 'package:flutter/material.dart';
import '../screens/kana/kana_screen.dart';

class KanaFoundationSection extends StatelessWidget {
  const KanaFoundationSection({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.translate_rounded, color: cs.primary),
              const SizedBox(width: 10),
              const Expanded(child: Text('Fondasi Kana', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900))),
              Text('Mulai di sini', style: TextStyle(color: cs.primary, fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 7),
            Text('Hiragana dan Katakana ditempatkan sebelum Bab 1 agar pengguna membangun fondasi membaca terlebih dahulu.', style: TextStyle(color: cs.onSurfaceVariant, height: 1.45)),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _KanaCard(title: 'Hiragana', subtitle: 'ひらがな · bunyi dasar', icon: Icons.text_fields_rounded, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KanaScreen())))),
              const SizedBox(width: 10),
              Expanded(child: _KanaCard(title: 'Katakana', subtitle: 'カタカナ · kata serapan', icon: Icons.language_rounded, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KanaScreen())))),
            ]),
          ],
        ),
      ),
    );
  }
}

class _KanaCard extends StatelessWidget {
  const _KanaCard({required this.title, required this.subtitle, required this.icon, required this.onTap});
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: cs.primaryContainer.withValues(alpha: .55), borderRadius: BorderRadius.circular(18)),
        child: Row(children: [
          Icon(icon, color: cs.primary),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 2), Text(subtitle, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant))])),
          const Icon(Icons.chevron_right_rounded, size: 19),
        ]),
      ),
    );
  }
}
