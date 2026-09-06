/// Notifikasi dalam aplikasi (kotak masuk di pusat notifikasi).
///
/// Disimpan lokal per perangkat dan TIDAK bisa dihapus manual:
/// entri kedaluwarsa otomatis [retentionDays] hari setelah dibuat.
class AppNotification {
  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    this.kind = 'info',
    DateTime? createdAt,
    this.read = false,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Berapa lama notifikasi disimpan sebelum terhapus otomatis.
  static const int retentionDays = 90;

  final String id;
  final String title;
  final String body;

  /// Jenis: 'update' (versi aplikasi), 'konten' (materi baru),
  /// 'pengumuman' (dari admin), 'pengingat', 'info'.
  final String kind;
  final DateTime createdAt;
  bool read;

  bool get expired =>
      DateTime.now().difference(createdAt).inDays >= retentionDays;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'kind': kind,
        'createdAt': createdAt.toIso8601String(),
        'read': read,
      };

  factory AppNotification.fromJson(Map<String, dynamic> j) {
    return AppNotification(
      id: j['id'] as String? ?? '',
      title: j['title'] as String? ?? '',
      body: j['body'] as String? ?? '',
      kind: j['kind'] as String? ?? 'info',
      createdAt: DateTime.tryParse(j['createdAt'] as String? ?? ''),
      read: j['read'] == true,
    );
  }

  /// Buang entri yang sudah kedaluwarsa. Murni (pure) agar mudah dites.
  static List<AppNotification> pruneExpired(
    List<AppNotification> items, {
    DateTime? now,
  }) {
    final ref = now ?? DateTime.now();
    return items
        .where((e) =>
            e.id.isNotEmpty &&
            ref.difference(e.createdAt).inDays < retentionDays)
        .toList();
  }
}
