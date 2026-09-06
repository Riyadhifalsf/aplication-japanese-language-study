import 'package:japanese_study/models/app_notification.dart';
import 'package:japanese_study/services/app_changelog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppNotification.pruneExpired', () {
    test('membuang yang berumur >= 90 hari, menyimpan yang baru', () {
      final now = DateTime(2026, 9, 6);
      final items = [
        AppNotification(
            id: 'baru', title: 'Baru', body: '', createdAt: now),
        AppNotification(
            id: 'lama-89',
            title: 'Hampir',
            body: '',
            createdAt: now.subtract(const Duration(days: 89))),
        AppNotification(
            id: 'kedaluwarsa',
            title: 'Tua',
            body: '',
            createdAt: now.subtract(const Duration(days: 90))),
        AppNotification(
            id: 'sangat-lama',
            title: 'Sangat tua',
            body: '',
            createdAt: now.subtract(const Duration(days: 200))),
        AppNotification(id: '', title: 'Tanpa id', body: ''),
      ];
      final kept = AppNotification.pruneExpired(items, now: now);
      expect(kept.map((e) => e.id), containsAll(['baru', 'lama-89']));
      expect(kept.map((e) => e.id), isNot(contains('kedaluwarsa')));
      expect(kept.map((e) => e.id), isNot(contains('sangat-lama')));
      expect(kept.map((e) => e.id), isNot(contains('')));
    });
  });

  group('AppChangelog.newerThan', () {
    test('hanya entri versi lebih baru yang keluar', () {
      expect(AppChangelog.newerThan(''), isNotEmpty);
      expect(AppChangelog.newerThan(AppChangelog.latestVersion), isEmpty);
      expect(AppChangelog.newerThan('0.0.1').length,
          AppChangelog.entries.length);
    });
  });
}
