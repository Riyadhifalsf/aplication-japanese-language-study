import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_theme.dart';
import '../../state/app_controller.dart';

class ReminderSettingsScreen extends StatelessWidget {
  const ReminderSettingsScreen({super.key});

  static const _days = [
    (1, '月', 'Senin', 'げつようび'),
    (2, '火', 'Selasa', 'かようび'),
    (3, '水', 'Rabu', 'すいようび'),
    (4, '木', 'Kamis', 'もくようび'),
    (5, '金', 'Jumat', 'きんようび'),
    (6, '土', 'Sabtu', 'どようび'),
    (7, '日', 'Minggu', 'にちようび'),
  ];

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Pengingat Kanji')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppTheme.seed.withValues(alpha: .13),
                        foregroundColor: AppTheme.seed,
                        child: const Icon(Icons.notifications_active_rounded),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Pengingat ulangan kanji', style: TextStyle(fontWeight: FontWeight.w900)),
                            Text(
                              '${app.reviewReminderDaysLabel} · ${app.reviewReminderTimeLabel}',
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: app.reviewReminderEnabled,
                        onChanged: app.setReviewReminderEnabled,
                      ),
                    ],
                  ),
                  const Divider(height: 28),
                  FilledButton.tonalIcon(
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(
                          hour: app.reviewReminderHour,
                          minute: app.reviewReminderMinute,
                        ),
                      );
                      if (picked != null) app.setReviewReminderTime(picked);
                    },
                    icon: const Icon(Icons.schedule_rounded),
                    label: Text('Ubah jam: ${app.reviewReminderTimeLabel}'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Pilih hari bebas',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final day in _days)
                    FilterChip(
                      selected: app.reviewReminderWeekdays.contains(day.$1),
                      label: Text('${day.$2} ${day.$3}'),
                      avatar: Text(day.$2, style: const TextStyle(fontWeight: FontWeight.w900)),
                      onSelected: (_) => app.toggleReviewReminderWeekday(day.$1),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: SwitchListTile(
              value: app.calendarReminderEnabled,
              onChanged: app.setCalendarReminderEnabled,
              secondary: const Icon(Icons.calendar_month_rounded),
              title: const Text('Pengingat kalender', style: TextStyle(fontWeight: FontWeight.w900)),
              subtitle: const Text('Simpan jadwal sebagai format kalender .ics untuk diimpor manual.'),
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: app.generateKanjiReminderIcs()));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Jadwal kalender .ics disalin. Simpan sebagai ulangan-kanji.ics lalu impor ke kalender.')),
              );
            },
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Salin jadwal kalender .ics'),
          ),
          const SizedBox(height: 14),
          Card(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Catatan: pengingat di dalam aplikasi dan berkas kalender sudah disiapkan. Untuk notifikasi Android otomatis, tambahkan paket notifikasi dan izin Android pada konfigurasi akhir.',
                style: TextStyle(height: 1.45),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
