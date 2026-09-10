import 'package:flutter/material.dart';

class ChoukaiScreen extends StatefulWidget {
  const ChoukaiScreen({super.key});

  @override
  State<ChoukaiScreen> createState() => _ChoukaiScreenState();
}

class _ChoukaiScreenState extends State<ChoukaiScreen> {
  String _level = 'N5';

  @override
  Widget build(BuildContext context) {
    final levels = ['N5', 'N4', 'N3', 'N2', 'N1'];
    return Scaffold(
      appBar: AppBar(title: const Text('Choukai')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
        children: [
          Text(
            'Latihan Menyimak',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            'Persiapkan penguasaan JLPT melalui latihan mendengarkan sesuai tingkat kemampuan.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.4),
          ),
          const SizedBox(height: 20),
          const Text('Pilih tingkat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final level in levels)
                ChoiceChip(
                  label: Text(level),
                  selected: _level == level,
                  onSelected: (_) => setState(() => _level = level),
                ),
            ],
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.headphones_rounded, size: 42, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 12),
                Text('Choukai $_level', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text(
                  'Materi dan soal menyimak JLPT akan ditempatkan di sini. Struktur tingkat sudah disiapkan agar dapat dikembangkan dengan audio, transkrip, soal, dan pembahasan.',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
