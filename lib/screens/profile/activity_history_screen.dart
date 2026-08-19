import 'package:flutter/material.dart';

import '../../state/app_controller.dart';

class ActivityHistoryScreen extends StatelessWidget {
  const ActivityHistoryScreen({super.key});

  String _label(String type) => switch (type) {
        'session_started' => 'Sesi dimulai',
        'session_ended' => 'Sesi selesai',
        'study' => 'Aktivitas belajar',
        'quiz' => 'Kuis selesai',
        'kanji_mastery' => 'Kanji dikuasai',
        'web3_credential' => 'Credential Web3 dibuat',
        _ => type,
      };

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final items = app.activityJournal.reversed.toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat aktivitas')),
      body: items.isEmpty
          ? const Center(child: Text('Belum ada aktivitas yang tercatat.'))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
              itemCount: items.length,
              itemBuilder: (_, index) {
                final item = items[index];
                final at = DateTime.tryParse('${item['at']}')?.toLocal();
                final dateLabel =
                    at == null ? '-' : at.toString().substring(0, 16);
                final detail = '${item['label'] ?? ''}'.trim();

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.history_rounded),
                    ),
                    title: Text(
                      _label('${item['type']}'),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    subtitle: Text(
                      detail.isEmpty ? dateLabel : '$dateLabel - $detail',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              },
            ),
    );
  }
}
