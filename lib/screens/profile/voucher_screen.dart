import 'package:flutter/material.dart';

class VoucherScreen extends StatefulWidget {
  const VoucherScreen({super.key});
  @override State<VoucherScreen> createState() => _VoucherScreenState();
}

class _VoucherScreenState extends State<VoucherScreen> {
  final controller = TextEditingController();
  bool checking = false;

  @override
  void dispose() { controller.dispose(); super.dispose(); }

  Future<void> _apply() async {
    FocusScope.of(context).unfocus();
    final code = controller.text.trim();
    if (code.isEmpty) return;
    setState(() => checking = true);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() => checking = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Voucher akan diverifikasi melalui layanan resmi saat tersedia.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gunakan voucher')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text('Kode voucher', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          TextField(controller: controller, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Masukkan kode voucher')),
          const SizedBox(height: 12),
          FilledButton.icon(onPressed: checking ? null : _apply, icon: const Icon(Icons.redeem_rounded), label: Text(checking ? 'Memeriksa…' : 'Gunakan voucher')),
        ],
      ),
    );
  }
}
