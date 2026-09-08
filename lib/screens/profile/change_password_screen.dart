import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../state/app_controller.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});
  @override State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
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

  @override void dispose() { _current.dispose(); _fresh.dispose(); _confirm.dispose(); super.dispose(); }

  Future<void> _submit() async {
    final app = AppScope.of(context);
    if (_confirm.text != _fresh.text) { setState(() => _error = 'Konfirmasi password tidak sama.'); return; }
    setState(() { _busy = true; _error = ''; });
    final error = await app.changeAccountPassword(currentPassword: _current.text, newPassword: _fresh.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) { setState(() => _error = error); return; }
    await HapticFeedback.lightImpact();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password berhasil diubah.')));
    Navigator.pop(context);
  }

  Future<void> _requestReset() async {
    final app = AppScope.of(context);
    if (app.profileEmail.trim().isEmpty) { setState(() => _error = 'Akun ini belum memiliki email pemulihan.'); return; }
    setState(() { _busy = true; _error = ''; });
    final result = await app.requestAccountPasswordReset(app.profileEmail);
    if (!mounted) return;
    setState(() => _busy = false);
    if (result.method == 'none') { setState(() => _error = result.message); return; }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    if (!app.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('Password & verifikasi')),
        body: const Center(child: Text('Masuk dulu untuk mengelola password.')),
      );
    }
    final googleOnly = app.isGoogleOnlyAccount;
    return Scaffold(
      appBar: AppBar(title: const Text('Password & verifikasi')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.verified_user_rounded),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              googleOnly ? 'Akun Google + password aplikasi' : 'Kelola password akun',
                              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      Text(
                        googleOnly
                            ? 'Password aplikasi dapat diatur melalui alur verifikasi email. Password Google tetap terpisah.'
                            : 'Gunakan password saat ini untuk mengganti password, atau kirim link reset ke email sebagai jalur verifikasi.',
                        style: TextStyle(height: 1.45, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              if (googleOnly)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Reset melalui email', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 6),
                        Text('Email verifikasi dikirim ke ${app.profileEmail}.'),
                        const SizedBox(height: 14),
                        FilledButton.icon(
                          onPressed: _busy ? null : _requestReset,
                          icon: _busy
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.mark_email_read_rounded),
                          label: const Text('Kirim email reset'),
                          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                TextField(
                  controller: _current,
                  obscureText: _obscureCurrent,
                  decoration: InputDecoration(
                    labelText: 'Password saat ini',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                      icon: Icon(_obscureCurrent ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _fresh,
                  obscureText: _obscureFresh,
                  decoration: InputDecoration(
                    labelText: 'Password baru (min. 8 karakter)',
                    prefixIcon: const Icon(Icons.lock_reset_rounded),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscureFresh = !_obscureFresh),
                      icon: Icon(_obscureFresh ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _confirm,
                  obscureText: _obscureConfirm,
                  onSubmitted: (_) => _busy ? null : _submit(),
                  decoration: InputDecoration(
                    labelText: 'Ulangi password baru',
                    prefixIcon: const Icon(Icons.check_circle_outline_rounded),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      icon: Icon(_obscureConfirm ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: _busy ? null : _submit,
                  icon: _busy
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.save_rounded),
                  label: const Text('Simpan password'),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _requestReset,
                  icon: const Icon(Icons.email_outlined),
                  label: const Text('Kirim link reset ke email'),
                ),
              ],
              if (_error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _error,
                    style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
