import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/offline_packs.dart';
import '../../state/app_controller.dart';
import '../auth/login_screen.dart';
import '../kanji/kanji_review_screen.dart';
import '../profile/bug_report_screen.dart';
import 'privacy_policy_screen.dart';
import 'reminder_settings_screen.dart';

class ProfileSettingsScreen extends StatelessWidget {
  const ProfileSettingsScreen({super.key});

  Future<void> _logout(BuildContext context, AppController app) async {
    await app.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 34),
        children: [
          const Text('Profil', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Card(child: ListTile(leading: const Icon(Icons.edit_rounded), title: const Text('Sunting profil', style: TextStyle(fontWeight: FontWeight.w900)), subtitle: const Text('Data pribadi, identitas komunitas, dan sosial media.'), trailing: const Icon(Icons.chevron_right_rounded), onTap: () => _editProfile(context, app))),
          const SizedBox(height: 20),
          const Text('Belajar', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                ListTile(leading: const Icon(Icons.school_rounded), title: const Text('Level materi', style: TextStyle(fontWeight: FontWeight.w900)), subtitle: Text('Saat ini ${app.selectedStudyLevel}'), trailing: const Icon(Icons.chevron_right_rounded), onTap: () => _selectLevel(context, app)),
                const Divider(height: 1),
                ListTile(leading: const Icon(Icons.notifications_active_rounded), title: const Text('Pengingat ulangan Kanji', style: TextStyle(fontWeight: FontWeight.w900)), subtitle: Text('${app.reviewReminderDaysLabel} · ${app.reviewReminderTimeLabel}'), trailing: const Icon(Icons.chevron_right_rounded), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReminderSettingsScreen()))),
                const Divider(height: 1),
                ListTile(leading: const Icon(Icons.update_rounded), title: const Text('Interval review Kanji', style: TextStyle(fontWeight: FontWeight.w900)), subtitle: Text('${app.reviewIntervalDays} hari awal · otomatis diperpanjang'), trailing: const Icon(Icons.chevron_right_rounded), onTap: () => _reviewInterval(context, app)),
                const Divider(height: 1),
                SwitchListTile(value: app.furiganaVisible, onChanged: (_) => app.toggleFurigana(), secondary: const Icon(Icons.text_fields_rounded), title: const Text('Furigana', style: TextStyle(fontWeight: FontWeight.w900)), subtitle: const Text('Tampilkan bacaan kecil pada kanji.')),
                SwitchListTile(value: app.darkMode, onChanged: (_) => app.toggleTheme(), secondary: const Icon(Icons.dark_mode_rounded), title: const Text('Tema gelap', style: TextStyle(fontWeight: FontWeight.w900))),
                SwitchListTile(value: app.glassTheme, onChanged: (_) => app.toggleGlassTheme(), secondary: const Icon(Icons.blur_on_rounded), title: const Text('Liquid Glass', style: TextStyle(fontWeight: FontWeight.w900)), subtitle: const Text('Kartu dengan efek kaca dan blur.')),
                ListTile(leading: const Icon(Icons.auto_awesome_rounded), title: const Text('Kanji hari ini', style: TextStyle(fontWeight: FontWeight.w900)), subtitle: Text('Mode ${app.todayKanjiMode} · ${app.todayKanjiCharacter}'), trailing: const Icon(Icons.chevron_right_rounded), onTap: () => _todayKanjiMode(context, app)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Bahasa & suara', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                ListTile(leading: const Icon(Icons.language_rounded), title: const Text('Bahasa aplikasi', style: TextStyle(fontWeight: FontWeight.w900)), subtitle: Text(app.languageLabel), trailing: const Icon(Icons.chevron_right_rounded), onTap: () => _language(context, app)),
                const Divider(height: 1),
                ListTile(leading: const Icon(Icons.record_voice_over_rounded), title: const Text('Profil suara TTS', style: TextStyle(fontWeight: FontWeight.w900)), subtitle: Text(_voiceLabel(app.ttsGender)), trailing: const Icon(Icons.chevron_right_rounded), onTap: () => _ttsVoice(context, app)),
                const Divider(height: 1),
                ListTile(leading: const Icon(Icons.volume_up_rounded), title: const Text('Tes bahasa Jepang'), trailing: const Icon(Icons.play_arrow_rounded), onTap: () => app.tts.speak('今日も日本語を勉強しましょう。')),
                ListTile(leading: const Icon(Icons.volume_up_rounded), title: const Text('Test English TTS'), trailing: const Icon(Icons.play_arrow_rounded), onTap: () => app.tts.speakEnglish('Let us study Japanese together today.')),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Langganan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Card(child: ListTile(leading: const Icon(Icons.lock_clock_rounded), title: const Text('Pembayaran'), subtitle: const Text('Nonaktif sementara selama tahap pengujian.'), trailing: const Text('OFF', style: TextStyle(fontWeight: FontWeight.w900)))),
          const SizedBox(height: 20),
          const Text('Ulangan & data', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                ListTile(leading: const Icon(Icons.event_available_rounded), title: const Text('Ulangan jatuh tempo', style: TextStyle(fontWeight: FontWeight.w900)), subtitle: Text('${app.dueKanjiReviewCount} kanji perlu diulang.'), trailing: const Icon(Icons.chevron_right_rounded), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KanjiReviewScreen()))),
                const Divider(height: 1),
                ListTile(leading: const Icon(Icons.copy_rounded), title: const Text('Cadangan manual', style: TextStyle(fontWeight: FontWeight.w900)), subtitle: const Text('Salin atau pulihkan JSON progres.'), trailing: const Icon(Icons.chevron_right_rounded), onTap: () => _manualBackup(context, app)),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.cloud_download_outlined),
                  title: const Text('Paket offline', style: TextStyle(fontWeight: FontWeight.w900)),
                  subtitle: Text('${app.downloadedPacks.length}/${OfflinePacks.all.length} paket siap offline.'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _offlinePacks(context, app),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.restart_alt_rounded),
                  title: const Text('Mulai dari nol', style: TextStyle(fontWeight: FontWeight.w900)),
                  subtitle: const Text('Hapus progres lokal DAN server (kanji kembali 0).'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _confirmReset(context, app),
                ),
                const Divider(height: 1),
                ListTile(leading: const Icon(Icons.privacy_tip_outlined), title: const Text('Privacy Policy', style: TextStyle(fontWeight: FontWeight.w900)), trailing: const Icon(Icons.chevron_right_rounded), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()))),
                const Divider(height: 1),
                ListTile(leading: const Icon(Icons.bug_report_outlined), title: const Text('Laporkan bug', style: TextStyle(fontWeight: FontWeight.w900)), trailing: const Icon(Icons.chevron_right_rounded), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BugReportScreen()))),
              ],
            ),
          ),
          const SizedBox(height: 34),
          Card(
            color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: .5),
            child: ListTile(leading: const Icon(Icons.logout_rounded), title: const Text('Keluar / Logout', style: TextStyle(fontWeight: FontWeight.w900)), subtitle: const Text('Terletak paling bawah agar tidak tersentuh tidak sengaja.'), onTap: () => _logout(context, app)),
          ),
        ],
      ),
    );
  }

  static String _voiceLabel(String value) => value == 'female' ? 'Suara perempuan' : value == 'male' ? 'Suara laki-laki' : 'Otomatis dari perangkat';

  Future<void> _editProfile(BuildContext context, AppController app) async {
    final name = TextEditingController(text: app.profileName);
    final email = TextEditingController(text: app.profileEmail);
    final birth = TextEditingController(text: app.profileBirthDate);
    final phone = TextEditingController(text: app.profilePhone);
    final handle = TextEditingController(text: app.profileHandle);
    final bio = TextEditingController(text: app.profileBio);
    final instagram = TextEditingController(text: app.profileInstagram);
    final youtube = TextEditingController(text: app.profileYoutube);
    final followers = TextEditingController(text: '${app.profileFollowers}');
    final following = TextEditingController(text: '${app.profileFollowing}');
    final picker = ImagePicker();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(20, 18, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Sunting profil', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          CircleAvatar(radius: 40, backgroundImage: app.profilePhotoData.isNotEmpty ? MemoryImage(base64Decode(app.profilePhotoData)) : null, child: app.profilePhotoData.isEmpty ? Text(app.profileName.isEmpty ? '日' : app.profileName.substring(0, 1).toUpperCase()) : null),
          const SizedBox(height: 8),
          OutlinedButton.icon(onPressed: () async { final image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 720, imageQuality: 78); if (image == null) return; final bytes = await image.readAsBytes(); app.updateProfilePhotoData(base64Encode(bytes)); }, icon: const Icon(Icons.upload_rounded), label: const Text('Upload foto')),
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Nama')),
          TextField(controller: email, decoration: const InputDecoration(labelText: 'Surel')),
          TextField(controller: birth, decoration: const InputDecoration(labelText: 'Tanggal lahir', hintText: 'DD/MM/YYYY'), keyboardType: TextInputType.datetime),
          TextField(controller: phone, decoration: const InputDecoration(labelText: 'Nomor telepon'), keyboardType: TextInputType.phone),
          TextField(controller: handle, decoration: const InputDecoration(labelText: 'Username komunitas', prefixText: '@')),
          TextField(controller: bio, decoration: const InputDecoration(labelText: 'Bio', hintText: 'Ceritakan sedikit tentang kamu'), maxLines: 2),
          TextField(controller: instagram, decoration: const InputDecoration(labelText: 'Instagram')),
          TextField(controller: youtube, decoration: const InputDecoration(labelText: 'YouTube')),
          Row(children: [Expanded(child: TextField(controller: followers, decoration: const InputDecoration(labelText: 'Pengikut'), keyboardType: TextInputType.number)), const SizedBox(width:10), Expanded(child: TextField(controller: following, decoration: const InputDecoration(labelText: 'Mengikuti'), keyboardType: TextInputType.number))]),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: () { app.updateProfile(name: name.text, email: email.text, birthDate: birth.text, phone: phone.text, handle: handle.text, bio: bio.text, instagram: instagram.text, youtube: youtube.text, followers: int.tryParse(followers.text) ?? 0, following: int.tryParse(following.text) ?? 0); Navigator.pop(context); }, child: const Text('Simpan'))),
        ]),
      ),
    );
  }

  void _selectLevel(BuildContext context, AppController app) {
    showModalBottomSheet<void>(context: context, showDragHandle: true, builder: (_) => SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 24), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Pilih level materi', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)), const SizedBox(height: 12), for (final level in const ['N5','N4','N3','N2','N1']) ListTile(title: Text(level), subtitle: Text(app.isLevelUnlocked(level) ? 'Tersedia' : 'Terkunci — gunakan placement quiz atau selesaikan level sebelumnya'), trailing: app.selectedStudyLevel == level ? const Icon(Icons.check_rounded) : null, onTap: app.isLevelUnlocked(level) ? () { app.setSelectedStudyLevel(level); Navigator.pop(context); } : null)]))));
  }

  void _language(BuildContext context, AppController app) {
    showModalBottomSheet<void>(context: context, showDragHandle: true, builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [RadioListTile<String>(value: 'id', groupValue: app.appLanguage, title: const Text('Bahasa Indonesia'), onChanged: (v) { if (v != null) app.setAppLanguage(v); Navigator.pop(context); }), RadioListTile<String>(value: 'en', groupValue: app.appLanguage, title: const Text('English'), onChanged: (v) { if (v != null) app.setAppLanguage(v); Navigator.pop(context); }), const SizedBox(height: 10)])));
  }

  void _ttsVoice(BuildContext context, AppController app) {
    showModalBottomSheet<void>(context: context, showDragHandle: true, builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [for (final option in [('auto','Otomatis'),('female','Perempuan'),('male','Laki-laki')]) RadioListTile<String>(value: option.$1, groupValue: app.ttsGender, title: Text(option.$2), subtitle: option.$1 == 'auto' ? const Text('Mengikuti voice yang dipilih perangkat.') : const Text('Menggunakan pitch/gaya suara yang mendekati profil ini.'), onChanged: (v) { if (v != null) app.setTtsGender(v); Navigator.pop(context); }), const SizedBox(height: 10)])));
  }

  void _reviewInterval(BuildContext context, AppController app) {
    showModalBottomSheet<void>(context: context, showDragHandle: true, builder: (_) => StatefulBuilder(builder: (context, setState) => SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 24), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Interval review Kanji', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)), const SizedBox(height: 4), const Text('Tentukan jarak review pertama. Interval berikutnya akan bertambah bertahap. 1–30 hari.'), Slider(min: 1, max: 30, divisions: 29, value: app.reviewIntervalDays.toDouble(), label: '${app.reviewIntervalDays} hari', onChanged: (v) { app.setReviewIntervalDays(v.round()); setState(() {}); }), Center(child: Text('${app.reviewIntervalDays} hari', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900))), ])))));
  }

  void _todayKanjiMode(BuildContext context, AppController app) {
    showModalBottomSheet<void>(context: context, showDragHandle: true, builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Padding(padding: EdgeInsets.fromLTRB(20, 8, 20, 6), child: Align(alignment: Alignment.centerLeft, child: Text('Mode Kanji hari ini', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)))),
      for (final item in [('adaptive','Adaptif: kanji yang sudah dipelajari'),('favorites','Favorit'),('due','Yang jatuh tempo'),('manual','Tetap pada kanji pilihan')])
        RadioListTile<String>(value: item.$1, groupValue: app.todayKanjiMode, title: Text(item.$2), onChanged: (v){ if(v!=null) { app.setTodayKanjiMode(v); Navigator.pop(context); } }),
      const SizedBox(height: 12),
    ])));
  }

  Future<void> _confirmReset(BuildContext context, AppController app) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Mulai dari nol?'),
        content: const Text(
          'Semua progres (XP, streak, kanji, kosakata, kuis) di HP ini DAN '
          'di server akan dihapus permanen dan kembali ke 0. Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, hapus semua'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final ok = await app.resetProgress();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Progres dihapus. Mulai lagi dari 0.'
              : 'Gagal menghapus data server (${app.lastSyncError ?? 'offline'}). Coba lagi saat online.',
        ),
      ),
    );
  }

  Future<void> _offlinePacks(BuildContext context, AppController app) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Paket offline',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              const Text('Unduh agar materi level tetap segar tanpa internet.'),
              const SizedBox(height: 12),
              for (final pack in OfflinePacks.all)
                Builder(builder: (_) {
                  final done = app.downloadedPacks.contains(pack.id);
                  final when = app.packSyncedAt[pack.id];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(child: Icon(pack.icon)),
                    title: Text(pack.title,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text(done
                        ? 'Siap offline${when == null ? '' : ' · $when'}'
                        : pack.subtitle),
                    trailing: done
                        ? const Icon(Icons.check_circle_rounded,
                            color: Colors.green)
                        : const Icon(Icons.cloud_download_outlined),
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      final fresh =
                          await app.downloadOfflinePack(pack.id);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(fresh
                              ? '${pack.title} disinkron & siap offline.'
                              : '${pack.title} siap offline dari bundel.'),
                        ),
                      );
                    },
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  void _manualBackup(BuildContext context, AppController app) {
    showModalBottomSheet<void>(context: context, builder: (context) => SafeArea(child: Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [const Text('Cadangan manual', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)), const SizedBox(height: 12), FilledButton.tonalIcon(onPressed: () async { await Clipboard.setData(ClipboardData(text: app.exportProgress())); if (context.mounted) Navigator.pop(context); }, icon: const Icon(Icons.copy_rounded), label: const Text('Salin data')), const SizedBox(height: 10), FilledButton.icon(onPressed: () async { final data = await Clipboard.getData(Clipboard.kTextPlain); final ok = data?.text != null && await app.importProgress(data!.text!); if (!context.mounted) return; Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Kemajuan dipulihkan.' : 'Data cadangan tidak valid.'))); }, icon: const Icon(Icons.restore_rounded), label: const Text('Pulihkan'))]))));
  }
}
