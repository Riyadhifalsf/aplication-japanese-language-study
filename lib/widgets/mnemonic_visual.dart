import 'package:flutter/material.dart';

class MnemonicVisual extends StatelessWidget {
  const MnemonicVisual({
    required this.word,
    required this.meaning,
    this.character,
    super.key,
  });

  final String word;
  final String meaning;
  final String? character;

  IconData get _icon {
    final m = meaning.toLowerCase();
    if (RegExp(r'air|cuaca|hujan|salju|angin|langit').hasMatch(m)) return Icons.cloud_rounded;
    if (RegExp(r'makan|makanan|nasi|minum').hasMatch(m)) return Icons.restaurant_rounded;
    if (RegExp(r'orang|keluarga|ayah|ibu|anak|teman').hasMatch(m)) return Icons.people_alt_rounded;
    if (RegExp(r'sekolah|belajar|buku|bahasa').hasMatch(m)) return Icons.menu_book_rounded;
    if (RegExp(r'kerja|perusahaan|kantor').hasMatch(m)) return Icons.work_rounded;
    if (RegExp(r'rumah|bangunan|kamar').hasMatch(m)) return Icons.home_rounded;
    if (RegExp(r'jalan|pergi|transport|kereta|mobil|bus').hasMatch(m)) return Icons.directions_transit_rounded;
    if (RegExp(r'waktu|hari|jam|pagi|malam').hasMatch(m)) return Icons.schedule_rounded;
    if (RegExp(r'alam|gunung|laut|sungai|pohon|bunga').hasMatch(m)) return Icons.park_rounded;
    return Icons.lightbulb_rounded;
  }

  @override
  Widget build(BuildContext context) => Container(
        height: 190,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: .12),
              Theme.of(context).colorScheme.surfaceContainerHighest,
            ],
          ),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Stack(
          children: [
            Positioned(
              right: 8,
              bottom: 0,
              child: Icon(
                _icon,
                size: 96,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: .12),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 112,
                  height: 112,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: const [BoxShadow(blurRadius: 18, offset: Offset(0, 7))],
                  ),
                  child: Text(
                    character ?? word,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 46, fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Gambar pengingat',
                          style: TextStyle(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 6),
                      Text(
                        'Hubungkan bentuk/kata dengan ikon dan arti untuk membuat asosiasi visual.',
                        style: TextStyle(
                          height: 1.35,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        meaning,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}
