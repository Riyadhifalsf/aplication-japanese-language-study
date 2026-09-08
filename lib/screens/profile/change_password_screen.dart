import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../state/app_controller.dart';

/// Ganti password akun. Wajib memasukkan password saat ini dulu
/// (konfirmasi identitas) sebelum password baru diterima.
///
/// Backend menyimpan bcrypt cost 12 + salt; token lama otomatis mati dan
/// notifikasi dikirim ke Gmail. Akun login-Google murni tidak punya
/// password sehingga diarahkan kelola via akun Google.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _fresh = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  bool _obscureCurrent = true;
  bool _obscureFresh = true;
  bool _obscureConfirm = true;
  String _error = '';

  @override
  void dispose() {
    _current.dispose();
    _fresh.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final app = AppScope.of(context);
    if (_confirm.text != _fresh.text) {
      setState(() => _error = 'Konfirmasi password tidak sama.');
      return;
    }
    setState(() {
      _busy = true;
      _error = '';
    });
    final error = await app.changeAccountPassword(
      currentPassword: _current.text,
      newPassword: _fresh.text,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    await HapticFeedback.lightImpact();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Password berhasil diubah. Sesi lama dimatikan; masuk ulang di perangkat lain.',
        ),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    if (!app.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ganti password')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('Masuk dulu untuk ganti password.'),
          ),
        ),
      );
    }
    if (app.isGoogleOnlyAccount) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ganti password')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
          children: [
            const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Akun Google',
                      style: TextStyle(
                          fontSize: 19, fontWeight: FontWeight.w900),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Akun ini login dengan Google sehingga tidak punya password di aplikasi. Kelola password melalui akun Google-mu (myaccount.google.com > Keamanan).',
                      style: TextStyle(height: 1.45),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Ganti password')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
            children: [
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.shield_rounded),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Demi keamanan, masukkan password saat ini dulu. Password disimpan sebagai hash bcrypt — tidak ada yang bisa melihat password aslimu, termasuk admin.',
                          style: TextStyle(height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _current,
                obscureText: _obscureCurrent,
                enableSuggestions: false,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: 'Password saat ini',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    onPressed: () => setState(
                        () => _obscureCurrent = !_obscureCurrent),
                    icon: Icon(_obscureCurrent
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _fresh,
                obscureText: _obscureFresh,
                enableSuggestions: false,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: 'Password baru (min. 8 karakter)',
                  prefixIcon: const Icon(Icons.lock_reset_rounded),
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _obscureFresh = !_obscureFresh),
                    icon: Icon(_obscureFresh
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _confirm,
                obscureText: _obscureConfirm,
                enableSuggestions: false,
                autocorrect: false,
                onSubmitted: (_) => _busy ? null : _submit(),
                decoration: InputDecoration(
                  labelText: 'Ulangi password baru',
                  prefixIcon: const Icon(Icons.check_circle_outline_rounded),
                  suffixIcon: IconButton(
                    onPressed: () => setState(
                        () => _obscureConfirm = !_obscureConfirm),
                    icon: Icon(_obscureConfirm
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              if (_error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _error,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              FilledButton.icon(
                onPressed: _busy ? null : _submit,
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52)),
                icon: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded),
                label: const Text('Simpan password baru'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
