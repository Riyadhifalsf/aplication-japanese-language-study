import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../state/app_controller.dart';
import '../../widgets/liquid_glass.dart';
import '../auth/login_screen.dart';
import '../kanji/kanji_review_screen.dart';
import '../profile/bug_report_screen.dart';
import 'change_password_screen.dart';
import '../donation/donation_screen.dart';
import 'privacy_policy_screen.dart';
import 'reminder_settings_screen.dart';

class ProfileSettingsScreen extends StatelessWidget {
  const ProfileSettingsScreen({super.key});

  Future<void> _logout(BuildContext context, AppController app) async {
    await app.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  Widget _surface(BuildContext context, AppController app, Widget child) {
    if (!app.glassTheme) return Card(child: child);
    return LiquidGlass(padding: EdgeInsets.zero, borderRadius: 22, child: child);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 34),
        children: [
          const Text('Profil', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          _surface(context, app, ListTile(leading: const Icon(Icons.edit_rounded), title: const Text('Sunting profil', style: TextStyle(fontWeight: FontWeight.w900)), subtitle: const Text('Foto, nama, bio, identitas, dan tautan sosial.'), trailing: const Icon(Icons.chevron_right_rounded), onTap: () => _editProfile(context, app))),
          const SizedBox(height: 20),
          const Text('Keamanan akun', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          _surface(context, app, ListTile(leading: const Icon(Icons.lock_reset_rounded), title: const Text('Password & verifikasi', style: TextStyle(fontWeight: FontWeight.w900)), subtitle: Text(app.isGoogleOnlyAccount ? 'Atur atau reset password lewat verifikasi email.' : 'Ubah password langsung atau minta link reset ke email.'), trailing: const Icon(Icons.chevron_right_rounded), onTap: () { if (!app.isAuthenticated) { Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())); return; } Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen())); })),
          const SizedBox(height: 20),
          const Text('Belajar', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          _surface(context, app, Column(children: [
            ListTile(leading: const Icon(Icons.school_rounded), title: const Text('Level materi', style: TextStyle(fontWeight: FontWeight.w900)), subtitle: Text('Materi aktif: ${app.selectedStudyLevel}'), trailing: const Icon(Icons.chevron_right_rounded), onTap: () => _selectLevel(context, app)),
            const Divider(height: 1),
            ListTile(leading: const Icon(Icons.today_rounded), title: const Text('Target belajar harian', style: TextStyle(fontWeight: FontWeight.w900)), subtitle: Text('${app.dailyStudyMinutes} menit per hari'), trailing: const Icon(Icons.chevron_right_rounded), onTap: () => _dailyStudyGoal(context, app)),
            const Divider(height: 1),
            ListTile(leading: const Icon(Icons.notifications_active_rounded), title: const Text('Pengingat ulangan Kanji', style: TextStyle(fontWeight: FontWeight.w900)), subtitle: Text('${app.reviewReminderDaysLabel} · ${app.reviewReminderTimeLabel}'), trailing: const Icon(Icons.chevron_right_rounded), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReminderSettingsScreen()))),
            const Divider(height: 1),
            ListTile(leading: const Icon(Icons.update_rounded), title: const Text('Interval review Kanji', style: TextStyle(fontWeight: FontWeight.w900)), subtitle: Text('${app.reviewIntervalDays} hari awal · otomatis diperpanjang'), trailing: const Icon(Icons.chevron_right_rounded), onTap: () => _reviewInterval(context, app)),
            const Divider(height: 1),
            SwitchListTile(value: app.furiganaVisible, onChanged: (_) => app.toggleFurigana(), secondary: const Icon(Icons.text_fields_rounded), title: const Text('Furigana', style: TextStyle(fontWeight: FontWeight.w900)), subtitle: const Text('Tampilkan bacaan kecil pada kanji.')),
            SwitchListTile(value: app.darkMode, onChanged: (_) => app.toggleTheme(), secondary: const Icon(Icons.dark_mode_rounded), title: const Text('Tema gelap', style: TextStyle(fontWeight: FontWeight.w900))),
            SwitchListTile(value: app.glassTheme, onChanged: (_) => app.toggleGlassTheme(), secondary: const Icon(Icons.blur_on_rounded), title: const Text('Liquid Glass', style: TextStyle(fontWeight: FontWeight.w900)), subtitle: const Text('Efek kaca blur dipakai langsung pada panel pengaturan dan kartu beranda.')),
            ListTile(leading: const Icon(Icons.auto_awesome_rounded), title: const Text('Kanji hari ini', style: TextStyle(fontWeight: FontWeight.w900)), subtitle: Text('Mode ${app.todayKanjiMode} · ${app.todayKanjiCharacter}'), trailing: const Icon(Icons.chevron_right_rounded), onTap: () => _todayKanjiMode(context, app)),
            const Divider(height: 1),
            ListTile(
                leading: const Icon(Icons.style_rounded),
                title: const Text('Jumlah Kanji hari ini',
                    style: TextStyle(fontWeight: FontWeight.w900)),
                subtitle:
                    Text('${app.todayKanjiCount} kartu di beranda'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _todayKanjiCount(context, app)),
          ])),
          const SizedBox(height: 20),
          const Text('Bahasa & suara', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          _surface(context, app, Column(children: [
            ListTile(leading: const Icon(Icons.language_rounded), title: const Text('Bahasa aplikasi', style: TextStyle(fontWeight: FontWeight.w900)), subtitle: Text(app.languageLabel), trailing: const Icon(Icons.chevron_right_rounded), onTap: () => _language(context, app)),
            const Divider(height: 1),
            ListTile(leading: const Icon(Icons.record_voice_over_rounded), title: const Text('Profil suara TTS', style: TextStyle(fontWeight: FontWeight.w900)), subtitle: Text(_voiceLabel(app.ttsGender)), trailing: const Icon(Icons.chevron_right_rounded), onTap: () => _ttsVoice(context, app)),
            const Divider(height: 1),
            ListTile(leading: const Icon(Icons.volume_up_rounded), title: const Text('Tes bahasa Jepang'), trailing: const Icon(Icons.play_arrow_rounded), onTap: () => app.tts.speak('今日も日本語を勉強しましょう。')),
          ])),
          const SizedBox(height: 20),
          const Text('Dukungan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          _surface(context, app, ListTile(
            leading: const Icon(Icons.volunteer_activism_rounded),
            title: const Text('Donasi', style: TextStyle(fontWeight: FontWeight.w900)),
            subtitle: const Text('Lihat kanal donasi, jumlah donatur, dan peringkat dukungan.'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DonationScreen())),
          )),
          const SizedBox(height: 20),
          const Text('Ulangan & data', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          _surface(context, app, Column(children: [
            ListTile(leading: const Icon(Icons.event_available_rounded), title: const Text('Ulangan jatuh tempo', style: TextStyle(fontWeight: FontWeight.w900)), subtitle: Text('${app.dueKanjiReviewCount} kanji perlu diulang.'), trailing: const Icon(Icons.chevron_right_rounded), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KanjiReviewScreen()))),
            const Divider(height: 1),
            ListTile(leading: const Icon(Icons.privacy_tip_outlined), title: const Text('Privacy Policy', style: TextStyle(fontWeight: FontWeight.w900)), trailing: const Icon(Icons.chevron_right_rounded), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()))),
            const Divider(height: 1),
            ListTile(leading: const Icon(Icons.bug_report_outlined), title: const Text('Laporkan bug', style: TextStyle(fontWeight: FontWeight.w900)), trailing: const Icon(Icons.chevron_right_rounded), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BugReportScreen()))),
          ])),
          const SizedBox(height: 34),
          Card(color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: .5), child: ListTile(leading: const Icon(Icons.logout_rounded), title: const Text('Keluar / Logout', style: TextStyle(fontWeight: FontWeight.w900)), onTap: () => _logout(context, app))),
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
    final picker = ImagePicker();

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20, 12, 20, MediaQuery.viewInsetsOf(sheetContext).bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Sunting profil', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text('Buat profilmu terasa lebih lengkap dan personal.', style: TextStyle(color: Theme.of(sheetContext).colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 18),
                  Center(
                    child: CircleAvatar(
                      radius: 46,
                      backgroundImage: app.profilePhotoData.isNotEmpty ? MemoryImage(base64Decode(app.profilePhotoData)) : null,
                      child: app.profilePhotoData.isEmpty ? Text(app.profileName.isEmpty ? '日' : app.profileName.substring(0, 1).toUpperCase(), style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w900)) : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 720, imageQuality: 78);
                        if (image == null) return;
                        app.updateProfilePhotoData(base64Encode(await image.readAsBytes()));
                      },
                      icon: const Icon(Icons.upload_rounded),
                      label: const Text('Ganti foto'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _field(name, 'Nama tampilan', Icons.person_outline_rounded),
                  _field(email, 'Surel', Icons.email_outlined, keyboard: TextInputType.emailAddress),
                  _field(handle, 'Username komunitas', Icons.alternate_email_rounded),
                  _field(
                    bio,
                    'Bio',
                    Icons.notes_rounded,
                    maxLines: 6,
                    hint: 'Tulis target JLPT, minat, atau alasanmu belajar bahasa Jepang.',
                  ),
                  _field(birth, 'Tanggal lahir', Icons.cake_outlined, keyboard: TextInputType.datetime),
                  _field(phone, 'Nomor telepon', Icons.phone_outlined, keyboard: TextInputType.phone),
                  _field(instagram, 'Instagram', Icons.camera_alt_outlined),
                  _field(youtube, 'YouTube', Icons.play_circle_outline_rounded),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: () {
                      app.updateProfile(
                        name: name.text,
                        email: email.text,
                        birthDate: birth.text,
                        phone: phone.text,
                        handle: handle.text,
                        bio: bio.text,
                        instagram: instagram.text,
                        youtube: youtube.text,
                      );
                      Navigator.pop(sheetContext);
                    },
                    icon: const Icon(Icons.save_rounded),
                    label: const Text('Simpan profil'),
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboard,
    int maxLines = 1,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
          alignLabelWithHint: maxLines > 1,
        ),
      ),
    );
  }

  void _selectLevel(BuildContext context, AppController app) {
    const levels = ['N5', 'N4', 'N3', 'N2', 'N1'];
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Level materi aktif', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              const Text('Learning hanya menampilkan materi level aktif. Library tetap menampilkan seluruh katalog.'),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final level in levels)
                    ChoiceChip(
                      label: Padding(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5), child: Text(level)),
                      selected: app.selectedStudyLevel == level,
                      onSelected: app.isLevelUnlocked(level)
                          ? (_) {
                              app.setSelectedStudyLevel(level);
                              Navigator.pop(context);
                            }
                          : null,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _dailyStudyGoal(BuildContext context, AppController app) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Target belajar harian', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              const Text('Pilih durasi belajar yang realistis untuk menjaga konsistensi setiap hari.'),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final minutes in AppController.allowedDailyStudyMinutes)
                    ChoiceChip(
                      label: Padding(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5), child: Text('$minutes menit')),
                      selected: app.dailyStudyMinutes == minutes,
                      onSelected: (_) {
                        app.setDailyStudyMinutes(minutes);
                        Navigator.pop(context);
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _language(BuildContext context, AppController app) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(value: 'id', groupValue: app.appLanguage, title: const Text('Bahasa Indonesia'), onChanged: (v) { if (v != null) app.setAppLanguage(v); Navigator.pop(context); }),
            RadioListTile<String>(value: 'en', groupValue: app.appLanguage, title: const Text('English'), onChanged: (v) { if (v != null) app.setAppLanguage(v); Navigator.pop(context); }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _ttsVoice(BuildContext context, AppController app) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final option in [('auto', 'Otomatis'), ('female', 'Perempuan'), ('male', 'Laki-laki')])
              RadioListTile<String>(value: option.$1, groupValue: app.ttsGender, title: Text(option.$2), onChanged: (v) { if (v != null) app.setTtsGender(v); Navigator.pop(context); }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _reviewInterval(BuildContext context, AppController app) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Interval review Kanji', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
                const SizedBox(height: 5),
                const Text('Tentukan jarak review pertama. Interval berikutnya bertambah bertahap.'),
                Slider(
                  min: 1,
                  max: 30,
                  divisions: 29,
                  value: app.reviewIntervalDays.toDouble(),
                  label: '${app.reviewIntervalDays} hari',
                  onChanged: (v) {
                    app.setReviewIntervalDays(v.round());
                    setState(() {});
                  },
                ),
                Center(child: Text('${app.reviewIntervalDays} hari', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _todayKanjiMode(BuildContext context, AppController app) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(padding: EdgeInsets.all(16), child: Align(alignment: Alignment.centerLeft, child: Text('Mode Kanji hari ini', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)))),
            for (final item in [('adaptive', 'Adaptif'), ('favorites', 'Favorit'), ('due', 'Jatuh tempo'), ('manual', 'Kanji pilihan')])
              RadioListTile<String>(
                value: item.$1,
                groupValue: app.todayKanjiMode,
                title: Text(item.$2),
                subtitle: item.$1 == 'manual' && app.todayKanjiPinnedId > 0
                    ? Text(
                        'Terpilih: ${app.repository.kanjiById(app.todayKanjiPinnedId)?.character ?? ''}')
                    : null,
                onChanged: (v) {
                  if (v == null) return;
                  Navigator.pop(context);
                  if (v == 'manual') {
                    _pickKanji(context, app);
                  } else {
                    app.setTodayKanjiMode(v);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  /// Pilih jumlah kartu Kanji hari ini di beranda (3/5/7/10).
  void _todayKanjiCount(BuildContext context, AppController app) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
                padding: EdgeInsets.all(16),
                child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Jumlah Kanji hari ini',
                        style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w900)))),
            for (final n in AppController.allowedTodayKanjiCounts)
              RadioListTile<int>(
                value: n,
                groupValue: app.todayKanjiCount,
                title: Text('$n kartu'),
                onChanged: (v) {
                  if (v == null) return;
                  app.setTodayKanjiCount(v);
                  Navigator.pop(sheetContext);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Pilih manual kanji hari ini (cari per huruf/arti/bacaan).
  void _pickKanji(BuildContext context, AppController app) {
    var query = '';
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          final q = query.trim().toLowerCase();
          final all = app.repository.kanji;
          final filtered = q.isEmpty
              ? all.take(200).toList()
              : all
                  .where((k) =>
                      k.character.contains(query.trim()) ||
                      k.meaning.toLowerCase().contains(q) ||
                      k.onyomi.toLowerCase().contains(q) ||
                      k.kunyomi.toLowerCase().contains(q))
                  .take(200)
                  .toList();
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 8,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pilih kanji hari ini',
                      style:
                          TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),
                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'Cari huruf, arti, atau bacaan…',
                      prefixIcon: Icon(Icons.search_rounded),
                      border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.all(Radius.circular(16))),
                    ),
                    onChanged: (v) =>
                        setSheetState(() => query = v),
                  ),
                  const SizedBox(height: 10),
                  Flexible(
                    child: filtered.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('Tidak ketemu. Coba kata lain.'),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (_, i) {
                              final k = filtered[i];
                              final selected =
                                  app.todayKanjiPinnedId == k.id;
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                    child: Text(k.character,
                                        style: const TextStyle(
                                            fontWeight:
                                                FontWeight.w900))),
                                title: Text(k.meaning,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800)),
                                subtitle: Text(
                                    '${k.level} · ${k.preferredReading}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                trailing: selected
                                    ? const Icon(
                                        Icons.check_circle_rounded,
                                        color: Colors.green)
                                    : null,
                                onTap: () {
                                  app.setTodayKanjiMode('manual',
                                      pinnedId: k.id);
                                  Navigator.pop(sheetContext);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
