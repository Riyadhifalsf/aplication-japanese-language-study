import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../../state/app_controller.dart';

class Web3PassportScreen extends StatelessWidget {
  const Web3PassportScreen({super.key});

  String _identity(AppController app) {
    final seed =
        '${app.profileEmail}|${app.firstUsedAt?.toIso8601String()}|japanese-study';
    final digest = sha256.convert(utf8.encode(seed)).toString();
    return '0x${digest.substring(0, 40)}';
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final address = _identity(app);
    final progress = (app.learnedKanjiCount +
            app.learnedVocabularyCount +
            app.learnedGrammarCount)
        .clamp(0, 999999);
    return Scaffold(
      appBar: AppBar(title: const Text('Web3 Japanese Passport')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: LinearGradient(colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.tertiary
              ]),
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.verified_user_rounded,
                  color: Colors.white, size: 42),
              const SizedBox(height: 14),
              const Text('Japanese Learning Passport',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 5),
              Text(
                  'Identitas pencapaian belajar yang siap dihubungkan ke jaringan blockchain.',
                  style: const TextStyle(color: Colors.white70, height: 1.4)),
              const SizedBox(height: 18),
              Text(address,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13)),
            ]),
          ),
          const SizedBox(height: 14),
          Card(
              child: ListTile(
            leading: const CircleAvatar(
                child: Icon(Icons.account_balance_wallet_rounded)),
            title: const Text('Learning Identity',
                style: TextStyle(fontWeight: FontWeight.w900)),
            subtitle:
                Text('ID lokal deterministik • ${app.activeDays} hari aktif'),
            trailing: const Icon(Icons.verified_rounded),
          )),
          const SizedBox(height: 12),
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Verifiable achievements',
                            style: TextStyle(
                                fontSize: 19, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 12),
                        _Badge('🔥 Streak', '${app.streak} hari'),
                        _Badge('漢 Kanji', '${app.masteredKanjiCount} dikuasai'),
                        _Badge('📚 Materi', '$progress unit selesai'),
                        _Badge('⚡ XP', '${app.xp}'),
                      ]))),
          const SizedBox(height: 12),
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Status Web3',
                            style: TextStyle(
                                fontSize: 19, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 6),
                        const Text(
                            'Mode sekarang: local-first. Data belajar tetap milik pengguna; bukti pencapaian dapat diekspor sebagai credential dan nanti di-anchor ke blockchain tanpa mengubah sistem belajar.',
                            style: TextStyle(height: 1.45)),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () =>
                              _exportCredential(context, app, address),
                          icon: const Icon(Icons.verified_rounded),
                          label: const Text('Buat credential pencapaian'),
                        ),
                      ]))),
        ],
      ),
    );
  }

  void _exportCredential(
      BuildContext context, AppController app, String address) {
    final credential = {
      'type': 'JapaneseLearningAchievement',
      'identity': address,
      'issuedAt': DateTime.now().toIso8601String(),
      'streak': app.streak,
      'xp': app.xp,
      'kanjiMastered': app.masteredKanjiCount,
      'vocabularyMastered': app.learnedVocabularyCount,
      'grammarCompleted': app.learnedGrammarCount,
      'activeDays': app.activeDays,
      'totalActiveSeconds': app.totalActiveSeconds,
    };
    app.issueWeb3Credential('manual_export', meta: credential);
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Credential siap'),
        content: SingleChildScrollView(
            child: SelectableText(
                JsonEncoder.withIndent('  ').convert(credential))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'))
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.title, this.value);
  final String title, value;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: Row(children: [
          Expanded(
              child: Text(title,
                  style: const TextStyle(fontWeight: FontWeight.w700))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900))
        ]),
      );
}
