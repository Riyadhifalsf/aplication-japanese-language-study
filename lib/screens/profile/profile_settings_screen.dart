import 'package:flutter/material.dart';
import '../../state/app_controller.dart';
import '../auth/login_screen.dart';
import 'change_password_screen.dart';
import 'faq_screen.dart';
import 'terms_of_service_screen.dart';
import 'voucher_screen.dart';
import 'privacy_policy_screen.dart';
import 'reminder_settings_screen.dart';

class ProfileSettingsScreen extends StatelessWidget {
  const ProfileSettingsScreen({super.key});

  Future<void> _logout(BuildContext context, AppController app) async {
    await app.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  Future<void> _confirmReset(BuildContext context, {required String title, required String message, required Future<void> Function() action}) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(title: Text(title), content: Text(message), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Lanjutkan'))]),
    );
    if (ok != true || !context.mounted) return;
    await action();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perubahan berhasil disimpan.')));
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 34),
        children: [
          _section('Profil', [
            _item(Icons.edit_rounded, 'Sunting profil', 'Foto, nama, bio, dan tautan sosial.', () => _showProfileEditor(context, app)),
            _item(Icons.public_rounded, 'Wilayah & negara', '${app.region} · ${app.country}', () => _regionCountry(context, app)),
          ]),
          _section('Belajar', [
            _item(Icons.school_rounded, 'Level materi', 'Materi aktif: ${app.selectedStudyLevel}', () => _selectLevel(context, app)),
            _item(Icons.event_available_rounded, 'Rencana belajar', app.studyPlan, () => _studyPlan(context, app)),
            _item(Icons.notifications_active_rounded, 'Pengingat ulangan Kanji', '${app.reviewReminderDaysLabel} · ${app.reviewReminderTimeLabel}', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReminderSettingsScreen()))),
            _item(Icons.tune_rounded, 'Interval review Kanji', '${app.reviewIntervalDays} hari awal', () => _reviewInterval(context, app)),
            SwitchListTile(value: app.repeatWeakMaterials, onChanged: app.setRepeatWeakMaterials, secondary: const Icon(Icons.replay_rounded), title: const Text('Ulangi materi lemah', style: TextStyle(fontWeight: FontWeight.w900)), subtitle: const Text('Prioritaskan materi dengan penguasaan rendah.')),
            SwitchListTile(value: app.furiganaVisible, onChanged: (_) => app.toggleFurigana(), secondary: const Icon(Icons.text_fields_rounded), title: const Text('Furigana', style: TextStyle(fontWeight: FontWeight.w900))),
            _item(Icons.restart_alt_rounded, 'Setel ulang pengaturan latihan', 'Kembalikan pengaturan latihan ke nilai awal.', () => _confirmReset(context, title: 'Setel ulang latihan?', message: 'Progress tidak dihapus; hanya pengaturan latihan yang dikembalikan.', action: app.resetPracticeSettings)),
            _item(Icons.delete_sweep_rounded, 'Bersihkan data belajar', 'Hapus progress, statistik latihan, dan jurnal belajar.', () => _confirmReset(context, title: 'Bersihkan data belajar?', message: 'Tindakan ini tidak dapat dibatalkan.', action: app.resetLearningData)),
          ]),
          _section('Tampilan & audio', [
            SwitchListTile(value: app.darkMode, onChanged: (_) => app.toggleTheme(), secondary: const Icon(Icons.dark_mode_rounded), title: const Text('Mode gelap', style: TextStyle(fontWeight: FontWeight.w900))),
            SwitchListTile(value: app.soundEffectsEnabled, onChanged: app.setSoundEffectsEnabled, secondary: const Icon(Icons.volume_up_rounded), title: const Text('Efek suara', style: TextStyle(fontWeight: FontWeight.w900))),
            _item(Icons.record_voice_over_rounded, 'Suara TTS', app.ttsGender, () => _tts(context, app)),
          ]),
          _section('Notifikasi', [
            SwitchListTile(value: app.studyNotificationsEnabled, onChanged: app.setStudyNotificationsEnabled, secondary: const Icon(Icons.school_rounded), title: const Text('Pengingat belajar', style: TextStyle(fontWeight: FontWeight.w900))),
            SwitchListTile(value: app.streakNotificationsEnabled, onChanged: app.setStreakNotificationsEnabled, secondary: const Icon(Icons.local_fire_department_rounded), title: const Text('Notifikasi streak', style: TextStyle(fontWeight: FontWeight.w900))),
          ]),
          _section('Data & privasi', [
            _item(Icons.language_rounded, 'Bahasa aplikasi', app.appLanguage == 'id' ? 'Bahasa Indonesia' : 'English', () => _language(context, app)),
            _item(Icons.storage_rounded, 'Data aplikasi & cache', 'Kelola data lokal dan lihat perkiraan ukuran.', () => _storage(context, app)),
            _item(Icons.policy_rounded, 'Kebijakan privasi', 'Cara data digunakan dan disimpan.', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()))),
            _item(Icons.description_rounded, 'Syarat & layanan', 'Ketentuan penggunaan Japanese Study.', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsOfServiceScreen()))),
            _item(Icons.redeem_rounded, 'Gunakan voucher', 'Masukkan kode voucher yang kamu miliki.', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VoucherScreen()))),
          ]),
          _section('Bantuan', [
            _item(Icons.help_outline_rounded, 'Bantuan & FAQ', 'Jawaban pertanyaan yang paling sering muncul.', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FaqScreen()))),
            _item(Icons.info_outline_rounded, 'Tentang Japanese Study', 'Versi, waktu bergabung, dan ID instalasi.', () => _about(context, app)),
          ]),
          _section('Akun', [
            _item(Icons.logout_rounded, 'Keluar', 'Keluar dari akun pada perangkat ini.', () => _confirmReset(context, title: 'Keluar?', message: 'Kamu perlu login lagi untuk sinkronisasi akun.', action: () => _logout(context, app))),
            _item(Icons.person_remove_rounded, 'Hapus akun & data lokal', 'Hapus data belajar lokal dan keluar dari akun. Penghapusan akun server memerlukan verifikasi layanan.', () => _confirmReset(context, title: 'Hapus data lokal?', message: 'Semua data lokal akan dihapus dan sesi akan keluar.', action: () async { await app.resetLearningData(); await app.logout(); })),
          ]),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) => Padding(padding: const EdgeInsets.only(bottom: 18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)), const SizedBox(height: 8), Card(child: Column(children: children))]));
  Widget _item(IconData icon, String title, String subtitle, VoidCallback onTap) => ListTile(leading: Icon(icon), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)), subtitle: Text(subtitle), trailing: const Icon(Icons.chevron_right_rounded), onTap: onTap);

  Future<void> _regionCountry(BuildContext context, AppController app) async {
    final region = TextEditingController(text: app.region);
    final country = TextEditingController(text: app.country);
    await showDialog<void>(context: context, builder: (_) => AlertDialog(title: const Text('Wilayah & negara'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: region, decoration: const InputDecoration(labelText: 'Wilayah')), TextField(controller: country, decoration: const InputDecoration(labelText: 'Negara'))]), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')), FilledButton(onPressed: () { app.setRegionCountry(region.text, country.text); Navigator.pop(context); }, child: const Text('Simpan'))]));
    region.dispose(); country.dispose();
  }
  Future<void> _studyPlan(BuildContext context, AppController app) async { await showModalBottomSheet<void>(context: context, builder: (_) => SafeArea(child: ListView(shrinkWrap: true, children: [for (final value in const ['10 menit per hari','20 menit per hari','30 menit per hari','45 menit per hari']) RadioListTile<String>(value: value, groupValue: app.studyPlan, title: Text(value), onChanged: (v) { if (v != null) { app.setStudyPlan(v); Navigator.pop(context); } })]))); }
  Future<void> _selectLevel(BuildContext context, AppController app) async { await showModalBottomSheet<void>(context: context, builder: (_) => SafeArea(child: ListView(shrinkWrap: true, children: [for (final level in const ['N5','N4','N3','N2','N1']) RadioListTile<String>(value: level, groupValue: app.selectedStudyLevel, title: Text(level), onChanged: (v) { if (v != null) { app.setSelectedStudyLevel(v); Navigator.pop(context); } })]))); }
  Future<void> _language(BuildContext context, AppController app) async { await showModalBottomSheet<void>(context: context, builder: (_) => SafeArea(child: ListView(shrinkWrap: true, children: [RadioListTile(value: 'id', groupValue: app.appLanguage, title: const Text('Bahasa Indonesia'), onChanged: (v) { app.setAppLanguage(v!); Navigator.pop(context); }), RadioListTile(value: 'en', groupValue: app.appLanguage, title: const Text('English'), onChanged: (v) { app.setAppLanguage(v!); Navigator.pop(context); })]))); }
  Future<void> _tts(BuildContext context, AppController app) async { await showModalBottomSheet<void>(context: context, builder: (_) => SafeArea(child: ListView(shrinkWrap: true, children: [for (final pair in const [('auto','Otomatis'),('female','Suara perempuan'),('male','Suara laki-laki')]) RadioListTile(value: pair.$1, groupValue: app.ttsGender, title: Text(pair.$2), onChanged: (v) { app.setTtsGender(v!); Navigator.pop(context); })]))); }
  Future<void> _reviewInterval(BuildContext context, AppController app) async { await showModalBottomSheet<void>(context: context, builder: (_) => SafeArea(child: ListView(shrinkWrap: true, children: [for (final d in const [1,2,3,5,7]) RadioListTile<int>(value: d, groupValue: app.reviewIntervalDays, title: Text('$d hari'), onChanged: (v) { if (v != null) { app.setReviewIntervalDays(v); Navigator.pop(context); } })]))); }
  Future<void> _storage(BuildContext context, AppController app) async { const note = 'Perkiraan ukuran berdasarkan data lokal yang dikelola aplikasi. Data sistem perangkat lain dapat memiliki ukuran berbeda.'; await showDialog<void>(context: context, builder: (_) => AlertDialog(title: const Text('Data aplikasi & cache'), content: const Text(note), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup')), FilledButton.tonal(onPressed: () async { await app.clearApplicationData(); if (context.mounted) Navigator.pop(context); }, child: const Text('Bersihkan data aplikasi'))])); }
  Future<void> _about(BuildContext context, AppController app) async { await showDialog<void>(context: context, builder: (_) => AlertDialog(title: const Text('Tentang Japanese Study'), content: SelectableText('Versi: 1.7.1+9\nBergabung: ${app.firstUsedAt?.toLocal() ?? '-'}\nID instalasi: ${app.installationId}'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup'))])); }
  Future<void> _showProfileEditor(BuildContext context, AppController app) async { final name = TextEditingController(text: app.profileName); final bio = TextEditingController(text: app.profileBio); await showDialog<void>(context: context, builder: (_) => AlertDialog(title: const Text('Sunting profil'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: name, decoration: const InputDecoration(labelText: 'Nama')), TextField(controller: bio, minLines: 2, maxLines: 4, decoration: const InputDecoration(labelText: 'Bio'))]), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')), FilledButton(onPressed: () { app.profileName = name.text.trim(); app.profileBio = bio.text.trim(); app.notifyListeners(); Navigator.pop(context); }, child: const Text('Simpan'))])); name.dispose(); bio.dispose(); }
}
