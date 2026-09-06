/// Catatan perubahan bawaan aplikasi.
///
/// Setiap ada update versi / tambahan konten, tambah satu entri di
/// [entries] dengan version yang lebih besar. Saat aplikasi dibuka dan
/// versi tersimpan lebih lama, tiap entri baru otomatis masuk ke kotak
/// masuk notifikasi pengguna (tanpa perlu server).
class AppChangelogEntry {
  const AppChangelogEntry({
    required this.version,
    required this.title,
    required this.body,
  });

  final String version;
  final String title;
  final String body;
}

class AppChangelog {
  AppChangelog._();

  static const String latestVersion = '3.3.0';

  static const List<AppChangelogEntry> entries = [
    AppChangelogEntry(
      version: '3.3.0',
      title: 'Tampilan merah + pratinjau tamu',
      body:
          'Tema merah Japanese Study, splash logo, mode pratinjau 5 soal '
          'untuk tamu, reset progres lokal+server, dan startup lebih cepat.',
    ),
  ];

  /// Entri yang lebih baru dari [seenVersion] (perbandingan angka per segmen).
  static List<AppChangelogEntry> newerThan(String seenVersion) {
    return entries
        .where((e) => _compare(e.version, seenVersion) > 0)
        .toList();
  }

  static int _compare(String a, String b) {
    final pa = a.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final pb = b.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    for (var i = 0; i < 3; i++) {
      final x = i < pa.length ? pa[i] : 0;
      final y = i < pb.length ? pb[i] : 0;
      if (x != y) return x.compareTo(y);
    }
    return 0;
  }
}
