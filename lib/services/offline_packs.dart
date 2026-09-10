import 'package:flutter/material.dart';

/// Paket offline per level (ala ikon unduh Busuu).
///
/// Mekanisme jujur: konten bundel aplikasi SUDAH offline penuh. "Unduh"
/// berarti: pastikan bundel termuat + coba sinkron terbaru dari server,
/// lalu tandai paket siap offline beserta waktunya. Tanpa internet pun
/// paket tetap bisa dibuka dari bundel.
class OfflinePack {
  const OfflinePack({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String id; // 'n5'..'n1'
  final String title;
  final String subtitle;
  final IconData icon;
}

class OfflinePacks {
  OfflinePacks._();

  static const List<OfflinePack> all = [
    OfflinePack(
      id: 'n5',
      title: 'Paket N5',
      subtitle: 'Fondasi + 25 bab',
      icon: Icons.looks_one_rounded,
    ),
    OfflinePack(
      id: 'n4',
      title: 'Paket N4',
      subtitle: 'Kalimat praktis',
      icon: Icons.looks_two_rounded,
    ),
    OfflinePack(
      id: 'n3',
      title: 'Paket N3',
      subtitle: 'Komunikasi mandiri',
      icon: Icons.looks_3_rounded,
    ),
    OfflinePack(
      id: 'n2',
      title: 'Paket N2',
      subtitle: 'Formal & berita',
      icon: Icons.looks_4_rounded,
    ),
    OfflinePack(
      id: 'n1',
      title: 'Paket N1',
      subtitle: 'Tingkat lanjut',
      icon: Icons.looks_5_rounded,
    ),
  ];

  static OfflinePack? byId(String id) {
    for (final p in all) {
      if (p.id == id) return p;
    }
    return null;
  }
}
