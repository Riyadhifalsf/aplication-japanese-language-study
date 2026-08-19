import 'package:shared_preferences/shared_preferences.dart';

class FeatureFlagDefinition {
  const FeatureFlagDefinition({required this.key, required this.name, required this.description, this.beta = true, this.defaultEnabled = false});
  final String key;
  final String name;
  final String description;
  final bool beta;
  final bool defaultEnabled;
}

class FeatureFlagsService {
  static const payment = 'payment';
  static const community = 'community';
  static const followers = 'followers';
  static const comments = 'comments';
  static const web3Passport = 'web3_passport';
  static const aiCoach = 'ai_coach';
  static const speaking = 'speaking';

  static const definitions = <FeatureFlagDefinition>[
    FeatureFlagDefinition(key: community, name: 'Komunitas & posting', description: 'Feed komunitas dan upload posting pengguna.'),
    FeatureFlagDefinition(key: followers, name: 'Pengikut / mengikuti', description: 'Relasi follower dan following antar pengguna.'),
    FeatureFlagDefinition(key: comments, name: 'Komentar', description: 'Komentar pada posting komunitas.'),
    FeatureFlagDefinition(key: web3Passport, name: 'Japanese Web3 Passport', description: 'Identitas dan credential verifikasi pencapaian.'),
    FeatureFlagDefinition(key: aiCoach, name: 'AI Coach', description: 'Tutor AI personal.'),
    FeatureFlagDefinition(key: speaking, name: 'Speaking Practice', description: 'Latihan speaking dan shadowing.'),
    FeatureFlagDefinition(key: payment, name: 'Payment', description: 'Pembayaran Premium/Lifetime. Saat ini dinonaktifkan untuk pengujian.', beta: false, defaultEnabled: false),
  ];

  static const _prefix = 'feature_flag_v2_';

  static Future<Map<String, bool>> load() async {
    final p = await SharedPreferences.getInstance();
    return {for (final f in definitions) f.key: p.getBool('$_prefix${f.key}') ?? f.defaultEnabled};
  }

  static Future<void> set(String key, bool enabled) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('$_prefix$key', enabled);
  }
}
