import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../state/app_controller.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _handle = TextEditingController();
  final _bio = TextEditingController();
  final _phone = TextEditingController();
  final _instagram = TextEditingController();
  final _youtube = TextEditingController();
  final _country = TextEditingController();
  final _region = TextEditingController();

  String _birthDate = '';
  String _goal = 'JLPT';
  String _level = 'Pemula';
  String _studyPlan = '20 menit per hari';
  String _photoData = '';
  bool _saving = false;

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final app = AppScope.of(context);
    _name.text = app.profileName == 'Tamu' ? '' : app.profileName;
    _handle.text = app.profileHandle;
    _bio.text = app.profileBio;
    _phone.text = app.profilePhone;
    _instagram.text = app.profileInstagram;
    _youtube.text = app.profileYoutube;
    _country.text = app.country;
    _region.text = app.region;
    _birthDate = app.profileBirthDate;
    _goal = app.studyGoal;
    _level = app.selfLevel;
    _studyPlan = app.studyPlan;
    _photoData = app.profilePhotoData;
  }

  @override
  void dispose() {
    _name.dispose();
    _handle.dispose();
    _bio.dispose();
    _phone.dispose();
    _instagram.dispose();
    _youtube.dispose();
    _country.dispose();
    _region.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text('Foto profil', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              subtitle: Text('Pilih foto yang ingin digunakan sebagai avatar.'),
            ),
            ListTile(leading: const Icon(Icons.photo_library_rounded), title: const Text('Galeri'), onTap: () => Navigator.pop(context, ImageSource.gallery)),
            ListTile(leading: const Icon(Icons.camera_alt_rounded), title: const Text('Kamera'), onTap: () => Navigator.pop(context, ImageSource.camera)),
            if (_photoData.isNotEmpty)
              ListTile(leading: const Icon(Icons.delete_outline_rounded), title: const Text('Hapus foto'), onTap: () => Navigator.pop(context, null)),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (!mounted) return;
    if (source == null) {
      if (_photoData.isNotEmpty) setState(() => _photoData = '');
      return;
    }

    final file = await _picker.pickImage(
      source: source,
      imageQuality: 82,
      maxWidth: 1000,
      maxHeight: 1000,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() => _photoData = base64Encode(bytes));
  }

  Future<void> _pickBirthDate() async {
    DateTime initial = DateTime.tryParse(_birthDate) ?? DateTime(2000, 1, 1);
    final now = DateTime.now();
    if (initial.isAfter(now)) initial = DateTime(now.year - 18, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1940),
      lastDate: now,
      helpText: 'Pilih tanggal lahir',
    );
    if (picked != null) {
      setState(() => _birthDate = picked.toIso8601String().split('T').first);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final app = AppScope.of(context);
    final prefs = await SharedPreferences.getInstance();

    final name = _name.text.trim();
    final handle = _handle.text.trim().replaceFirst(RegExp(r'^@+'), '');
    final bio = _bio.text.trim();
    final phone = _phone.text.trim();
    final instagram = _instagram.text.trim().replaceFirst(RegExp(r'^@+'), '');
    final youtube = _youtube.text.trim();
    final country = _country.text.trim().isEmpty ? 'Indonesia' : _country.text.trim();
    final region = _region.text.trim().isEmpty ? 'Asia Tenggara' : _region.text.trim();

    app.profileName = name.isEmpty ? 'Tamu' : name;
    app.profileHandle = handle;
    app.profileBio = bio;
    app.profilePhone = phone;
    app.profileInstagram = instagram;
    app.profileYoutube = youtube;
    app.profileBirthDate = _birthDate;
    app.studyGoal = _goal;
    app.selfLevel = _level;
    app.studyPlan = _studyPlan;
    app.country = country;
    app.region = region;
    app.profilePhotoData = _photoData;

    await Future.wait([
      prefs.setString('profileName', app.profileName),
      prefs.setString('profileHandle', handle),
      prefs.setString('profileBio', bio),
      prefs.setString('profilePhone', phone),
      prefs.setString('profileInstagram', instagram),
      prefs.setString('profileYoutube', youtube),
      prefs.setString('profileBirthDate', _birthDate),
      prefs.setString('studyGoal', _goal),
      prefs.setString('selfLevel', _level),
      prefs.setString('studyPlan', _studyPlan),
      prefs.setString('country', country),
      prefs.setString('region', region),
      prefs.setString('profilePhotoData', _photoData),
    ]);
    app.notifyListeners();

    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil berhasil diperbarui.')));
    Navigator.pop(context);
  }

  InputDecoration _decoration(String label, {String? hint, IconData? icon}) => InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon == null ? null : Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final photo = _photoData.isEmpty ? null : MemoryImage(base64Decode(_photoData));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sunting profil'),
        actions: [
          TextButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.check_rounded),
            label: const Text('Simpan'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 40),
          children: [
            Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 58,
                    backgroundColor: cs.primaryContainer,
                    backgroundImage: photo,
                    child: photo == null ? Icon(Icons.person_rounded, size: 58, color: cs.primary) : null,
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Material(
                      color: cs.primary,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _pickPhoto,
                        child: const Padding(padding: EdgeInsets.all(11), child: Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Center(child: TextButton.icon(onPressed: _pickPhoto, icon: const Icon(Icons.image_rounded), label: Text(_photoData.isEmpty ? 'Upload foto profil' : 'Ganti foto'))),
            const SizedBox(height: 18),
            _section('Informasi dasar', [
              TextFormField(controller: _name, textCapitalization: TextCapitalization.words, decoration: _decoration('Nama', hint: 'Nama yang akan ditampilkan', icon: Icons.person_outline_rounded), validator: (v) => (v?.trim().length ?? 0) > 40 ? 'Maksimal 40 karakter' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _handle, decoration: _decoration('Username', hint: 'contoh: riyadhifal', icon: Icons.alternate_email_rounded), validator: (v) => (v?.contains(' ') ?? false) ? 'Username tidak boleh mengandung spasi' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _bio, maxLines: 4, maxLength: 160, decoration: _decoration('Bio', hint: 'Ceritakan sedikit tentang dirimu...', icon: Icons.notes_rounded)),
              const SizedBox(height: 4),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.cake_outlined),
                title: const Text('Tanggal lahir', style: TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text(_birthDate.isEmpty ? 'Belum diisi' : _birthDate),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _pickBirthDate,
              ),
              TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: _decoration('Nomor telepon', hint: 'Opsional', icon: Icons.phone_outlined)),
            ]),
            _section('Lokasi', [
              TextField(controller: _country, decoration: _decoration('Negara', icon: Icons.public_rounded)),
              const SizedBox(height: 12),
              TextField(controller: _region, decoration: _decoration('Wilayah', hint: 'Contoh: Jawa Barat', icon: Icons.location_on_outlined)),
            ]),
            _section('Tujuan belajar', [
              const Text('Target utama', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [for (final value in const ['JLPT', 'Percakapan', 'Kerja di Jepang', 'Hobi']) ChoiceChip(label: Text(value), selected: _goal == value, onSelected: (_) => setState(() => _goal = value))]),
              const SizedBox(height: 16),
              const Text('Level saat ini', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(value: _level, decoration: _decoration('Level', icon: Icons.school_outlined), items: const [DropdownMenuItem(value: 'Pemula', child: Text('Pemula')), DropdownMenuItem(value: 'Dasar', child: Text('Dasar')), DropdownMenuItem(value: 'Menengah', child: Text('Menengah')), DropdownMenuItem(value: 'Lanjutan', child: Text('Lanjutan'))], onChanged: (v) { if (v != null) setState(() => _level = v); }),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(value: _studyPlan, decoration: _decoration('Rencana belajar', icon: Icons.schedule_rounded), items: const [DropdownMenuItem(value: '10 menit per hari', child: Text('10 menit per hari')), DropdownMenuItem(value: '20 menit per hari', child: Text('20 menit per hari')), DropdownMenuItem(value: '30 menit per hari', child: Text('30 menit per hari')), DropdownMenuItem(value: '45 menit per hari', child: Text('45 menit per hari'))], onChanged: (v) { if (v != null) setState(() => _studyPlan = v); }),
            ]),
            _section('Tautan sosial', [
              TextField(controller: _instagram, decoration: _decoration('Instagram', hint: '@username', icon: Icons.camera_alt_outlined)),
              const SizedBox(height: 12),
              TextField(controller: _youtube, decoration: _decoration('YouTube', hint: 'Nama channel / URL', icon: Icons.play_circle_outline_rounded)),
            ]),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(children: [Icon(Icons.lock_outline_rounded, color: cs.primary), const SizedBox(width: 12), const Expanded(child: Text('Profil disimpan secara lokal di perangkat. Data profil belum dipublikasikan ke pengguna lain.', style: TextStyle(fontSize: 13)))]),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(onPressed: _saving ? null : _save, icon: const Icon(Icons.save_rounded), label: const Padding(padding: EdgeInsets.symmetric(vertical: 13), child: Text('Simpan perubahan'))),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children))),
        ]),
      );
}
