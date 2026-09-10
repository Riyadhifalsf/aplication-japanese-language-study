import 'package:flutter/material.dart';
import '../../models/app_notification.dart';
import '../../state/app_controller.dart';
import '../../services/admin_data_service.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});
  @override State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  final service = AdminDataService();
  bool loading = true;
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    await service.load();
    if (!mounted) return;
    final app = AppScope.of(context);
    app.syncAnnouncementInbox(service.activeAnnouncements);
    app.markNotificationsRead();
    setState(() => loading = false);
  }

  String _dateLabel(DateTime at) {
    final now = DateTime.now();
    final days = DateUtils.dateOnly(now).difference(DateUtils.dateOnly(at)).inDays;
    if (days <= 0) return 'Hari ini';
    if (days == 1) return 'Kemarin';
    if (days < 30) return '$days hari lalu';
    final months = days ~/ 30;
    if (months < 12) return '$months bulan lalu';
    return '${at.day}/${at.month}/${at.year}';
  }

  IconData _kindIcon(String kind) => switch (kind) {
    'update' => Icons.system_update_rounded,
    'konten' => Icons.auto_stories_rounded,
    'pengumuman' => Icons.campaign_rounded,
    'pengingat' => Icons.schedule_rounded,
    'misi' => Icons.auto_awesome_rounded,
    _ => Icons.notifications_rounded,
  };

  String _kindLabel(String kind) => switch (kind) {
    'update' => 'Update aplikasi',
    'konten' => 'Konten baru',
    'pengumuman' => 'Pengumuman',
    'pengingat' => 'Pengingat',
    'misi' => 'Misi tersembunyi',
    _ => 'Info',
  };

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final items = service.activeBannersFor(app.isPremium);
    final inbox = app.inbox.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return Scaffold(appBar: AppBar(title: const Text('Notifikasi')), body: loading ? const Center(child: CircularProgressIndicator()) : ListView(padding: const EdgeInsets.fromLTRB(18, 8, 18, 30), children: [
      if (inbox.isEmpty && items.isEmpty && app.dueKanjiReviewCount <= 0)
        const Card(child: ListTile(leading: Icon(Icons.notifications_none_rounded), title: Text('Belum ada notifikasi'), subtitle: Text('Update aplikasi, konten baru, dan pengumuman akan muncul di sini.'))),
      if (inbox.isNotEmpty) ...[
        const Padding(
          padding: EdgeInsets.fromLTRB(4, 4, 4, 8),
          child: Text('Terbaru', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
        ),
        for (final n in inbox)
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: CircleAvatar(child: Icon(_kindIcon(n.kind), size: 20)),
              title: Text(n.title, style: const TextStyle(fontWeight: FontWeight.w900)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (n.body.isNotEmpty) Text(n.body),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(_kindLabel(n.kind), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        Text(_dateLabel(n.createdAt), style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        const Padding(
          padding: EdgeInsets.fromLTRB(4, 12, 4, 4),
          child: Text('Notifikasi tersimpan otomatis selama ${AppNotification.retentionDays} hari.', style: TextStyle(fontSize: 12)),
        ),
      ],
      for (final item in items) Card(margin: const EdgeInsets.only(bottom: 10), child: ListTile(leading: CircleAvatar(child: Icon(item.type == 'announcement' ? Icons.campaign_rounded : Icons.image_rounded)), title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w900)), subtitle: Padding(padding: const EdgeInsets.only(top: 5), child: Text(item.body)), trailing: item.ctaLabel.trim().isEmpty ? null : TextButton(onPressed: () {}, child: Text(item.ctaLabel)))),
      if (app.dueKanjiReviewCount > 0) Card(child: ListTile(leading: const Icon(Icons.schedule_rounded), title: const Text('Ulangan Kanji jatuh tempo', style: TextStyle(fontWeight: FontWeight.w900)), subtitle: Text('${app.dueKanjiReviewCount} kanji perlu diulang.'))),
    ]));
  }
}
