import 'package:flutter/material.dart';
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
  Future<void> _load() async { await service.load(); if (!mounted) return; final app = AppScope.of(context); app.markNotificationsRead(); setState(() => loading = false); }
  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final items = service.activeBannersFor(app.isPremium);
    return Scaffold(appBar: AppBar(title: const Text('Notifikasi')), body: loading ? const Center(child: CircularProgressIndicator()) : ListView(padding: const EdgeInsets.fromLTRB(18, 8, 18, 30), children: [
      if (items.isEmpty) const Card(child: ListTile(leading: Icon(Icons.notifications_none_rounded), title: Text('Belum ada notifikasi'), subtitle: Text('Pengumuman dari admin akan muncul di sini.'))),
      for (final item in items) Card(margin: const EdgeInsets.only(bottom: 10), child: ListTile(leading: CircleAvatar(child: Icon(item.type == 'announcement' ? Icons.campaign_rounded : Icons.image_rounded)), title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w900)), subtitle: Padding(padding: const EdgeInsets.only(top: 5), child: Text(item.body)), trailing: item.ctaLabel.trim().isEmpty ? null : TextButton(onPressed: () {}, child: Text(item.ctaLabel)))),
      if (app.dueKanjiReviewCount > 0) Card(child: ListTile(leading: const Icon(Icons.schedule_rounded), title: const Text('Ulangan Kanji jatuh tempo', style: TextStyle(fontWeight: FontWeight.w900)), subtitle: Text('${app.dueKanjiReviewCount} kanji perlu diulang.'))),
    ]));
  }
}
