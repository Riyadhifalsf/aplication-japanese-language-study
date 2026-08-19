import 'package:flutter/material.dart';
import '../../services/web3_passport_service.dart';
import '../../state/app_controller.dart';
import '../../widgets/liquid_glass.dart';

class Web3PassportScreen extends StatelessWidget {
  const Web3PassportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final identity = app.web3Identity;
    return Scaffold(
      appBar: AppBar(title: const Text('Japanese Web3 Passport')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 32),
        children: [
          LiquidGlass(
            padding: const EdgeInsets.all(20),
            tint: Theme.of(context).colorScheme.primaryContainer,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Image.asset('assets/branding/japanese_study_logo.png', width: 54, height: 54, fit: BoxFit.contain),
                const SizedBox(width: 12),
                const Expanded(child: Text('Learning Identity', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900))),
              ]),
              const SizedBox(height: 16),
              Text(Web3PassportService.instance.shortIdentity(identity), style: const TextStyle(fontFamily: 'monospace', fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text('Identitas lokal yang deterministik untuk catatan pencapaian belajar. Siap dihubungkan ke wallet/backend ketika layer blockchain sudah aktif.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.4)),
            ]),
          ),
          const SizedBox(height: 14),
          Card(child: ListTile(leading: const Icon(Icons.verified_rounded), title: const Text('Achievement credentials', style: TextStyle(fontWeight: FontWeight.w900)), subtitle: Text('${app.web3CredentialCount} credential dibuat'))),
          const SizedBox(height: 10),
          Card(child: ListTile(leading: const Icon(Icons.lock_clock_rounded), title: const Text('Proof of learning', style: TextStyle(fontWeight: FontWeight.w900)), subtitle: Text('XP ${app.xp} · ${app.learnedKanjiCount} kanji · ${app.learnedVocabularyCount} kotoba · ${app.learnedGrammarCount} bunpou'))),
          const SizedBox(height: 10),
          Card(child: ListTile(leading: const Icon(Icons.link_rounded), title: const Text('Blockchain ready', style: TextStyle(fontWeight: FontWeight.w900)), subtitle: const Text('Data credential belum dikirim ke chain sehingga tidak ada biaya gas.'))),
          const SizedBox(height: 18),
          FilledButton.icon(onPressed: () => showDialog<void>(context: context, builder: (c) => AlertDialog(title: const Text('Credential lokal'), content: SelectableText(app.latestWeb3Credential.isEmpty ? 'Belum ada credential.' : app.latestWeb3Credential), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Tutup'))])), icon: const Icon(Icons.fingerprint_rounded), label: const Text('Lihat credential terakhir')),
        ],
      ),
    );
  }
}
