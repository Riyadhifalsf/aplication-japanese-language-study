import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../state/app_controller.dart';

/// Lupa password: 2 langkah.
///
/// 1. Masukkan email → server mengirim kode 6 digit ke Gmail
///    (atau link Firebase bila server tak terjangkau).
/// 2. Masukkan kode + password baru.
/// Pesan selalu generik agar tidak membocorkan akun terdaftar.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late final TextEditingController _email;
  final _code = TextEditingController();
  final _fresh = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  bool _codeSent = false;
  bool _linkMode = false;
  bool _obscureFresh = true;
  String _info = '';
  String _error = '';

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _fresh.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() {
      _busy = true;
      _error = '';
      _info = '';
    });
    final result =
        await AppScope.of(context).requestAccountPasswordReset(_email.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (result.method == 'none') {
      setState(() => _error = result.message);
      return;
    }
    setState(() {
      _codeSent = true;
      _linkMode = result.method == 'link';
      _info = result.message;
    });
    if (result.method == 'link') {
      // Link Firebase: tidak ada langkah kode; kembali ke login.
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  Future<void> _reset() async {
    if (_confirm.text != _fresh.text) {
      setState(() => _error = 'Konfirmasi password tidak sama.');
      return;
    }
    setState(() {
      _busy = true;
      _error = '';
    });
    final error = await AppScope.of(context).confirmAccountPasswordReset(
      email: _email.text,
      code: _code.text,
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
        content: Text('Password berhasil direset. Masuk dengan password baru.'),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Lupa password')),
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
                        Icon(Icons.mark_email_read_outlined),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Kode 6 digit dikirim ke Gmail, berlaku 15 menit dan sekali pakai. Jangan bagikan kode ke siapa pun.',
                            style: TextStyle(height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_busy && !_codeSent,
                  decoration: const InputDecoration(
                    labelText: 'Email akun',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: (_busy || _codeSent) ? null : _send,
                  style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50)),
                  icon: _busy && !_codeSent
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(_codeSent ? 'Kode terkirim' : 'Kirim kode ke Gmail'),
                ),
                if (_info.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(_info,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      )),
                ],
                if (_codeSent && !_linkMode) ...[
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _code,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Kode 6 digit dari Gmail',
                      prefixIcon: Icon(Icons.pin_outlined),
                      counterText: '',
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
                        onPressed: () => setState(
                            () => _obscureFresh = !_obscureFresh),
                        icon: Icon(_obscureFresh
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _confirm,
                    obscureText: true,
                    enableSuggestions: false,
                    autocorrect: false,
                    onSubmitted: (_) => _busy ? null : _reset(),
                    decoration: const InputDecoration(
                      labelText: 'Ulangi password baru',
                      prefixIcon:
                          Icon(Icons.check_circle_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: _busy ? null : _reset,
                    style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52)),
                    icon: _busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_rounded),
                    label: const Text('Reset password'),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                              _codeSent = false;
                              _info = '';
                              _error = '';
                            }),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Minta kode baru'),
                  ),
                ],
                if (_error.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    _error,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
}
