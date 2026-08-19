import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../state/app_controller.dart';

class BugReportScreen extends StatefulWidget {
  const BugReportScreen({super.key});
  @override
  State<BugReportScreen> createState() => _BugReportScreenState();
}

class _BugReportScreenState extends State<BugReportScreen> {
  final _controller = TextEditingController();
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _copy() {
    final app = AppScope.of(context);
    final text =
        'Japanese Study bug report\nLevel: ${app.selectedStudyLevel}\nMode: ${app.learningMode}\nDetail: ${_controller.text.trim()}';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content:
            Text('Laporan disalin. Kamu bisa kirim ke email/issue tracker.')));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Laporkan Bug')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        children: [
          const Text('Ada yang bermasalah?',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text('Tulis apa yang terjadi dan langkah untuk mengulanginya.',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 18),
          TextField(
              onChanged: (_) => setState(() {}),
              controller: _controller,
              minLines: 8,
              maxLines: 14,
              decoration: const InputDecoration(
                  hintText:
                      'Contoh: saat membuka kuis N5, aplikasi kembali ke Home...',
                  border: OutlineInputBorder())),
          const SizedBox(height: 14),
          FilledButton.icon(
              onPressed: _controller.text.trim().isEmpty ? null : _copy,
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Salin laporan')),
          const SizedBox(height: 10),
          const Text(
              'Struktur ini sengaja dibuat sederhana dulu. Nanti bisa diarahkan langsung ke backend ticket/issue tracker tanpa mengubah UI.',
              style: TextStyle(height: 1.45)),
        ],
      ));
}
