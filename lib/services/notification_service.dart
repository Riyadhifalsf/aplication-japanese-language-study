import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const settings = InitializationSettings(android: android);
      await _plugin.initialize(settings);
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      _initialized = true;
    } catch (_) {
      // Web/unsupported platforms can safely continue without notifications.
    }
  }

  Future<void> showFeatureRelease(String title, String details) async {
    await initialize();
    if (!_initialized) return;
    try {
      await _plugin.show(20001, 'Fitur baru: $title', details, const NotificationDetails(
        android: AndroidNotificationDetails(
          'feature_updates',
          'Pembaruan fitur',
          channelDescription: 'Notifikasi ketika Japanese Study mendapatkan fitur baru.',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ));
    } catch (_) {}
  }

  Future<void> syncReviewSchedule({
    required bool enabled,
    required int hour,
    required int minute,
    required Set<int> weekdays,
    required int dueCount,
  }) async {
    await initialize();
    if (!_initialized) return;
    try {
      for (var day = 1; day <= 7; day++) {
        await _plugin.cancel(1000 + day);
      }
      if (!enabled || dueCount <= 0 || weekdays.isEmpty) return;

      final now = tz.TZDateTime.now(tz.local);
      for (final weekday in weekdays) {
        var scheduled = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day,
          hour,
          minute,
        );
        final delta = (weekday - scheduled.weekday) % 7;
        scheduled = scheduled.add(Duration(days: delta));
        if (!scheduled.isAfter(now)) {
          scheduled = scheduled.add(const Duration(days: 7));
        }
        await _plugin.zonedSchedule(
          1000 + weekday,
          'Saatnya mengulang kanji 🇯🇵',
          '$dueCount kartu siap diulang. Jaga rentetan belajarmu!',
          scheduled,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'kanji_review',
              'Pengingat belajar',
              channelDescription: 'Pengingat ulangan kanji dan materi yang jatuh tempo.',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      }
    } catch (_) {
      // Keep the app usable if notification scheduling is unavailable.
    }
  }
}
