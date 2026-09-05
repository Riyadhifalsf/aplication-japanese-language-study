import 'package:flutter/material.dart';

import '../../state/app_controller.dart';
import '../app_shell.dart';
import '../onboarding_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  bool _obscureConfirm = true;
  String _error = '';

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();
    if (_password.text != _confirmPassword.text) {
      setState(() => _error = 'Konfirmasi password tidak cocok.');
      return;
    }
    setState(() {
      _busy = true;
      _error = '';
    });
    final app = AppScope.of(context);
    final error = await app.registerUser(
      name: _name.text,
      email: _email.text,
      password: _password.text,
    );
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _busy = false;
        _error = error;
      });
      return;
    }
    if (!app.isAuthenticated) {
      final loginError = await app.loginWithEmail(_email.text, _password.text);
      if (!mounted) return;
      if (loginError != null) {
        setState(() {
          _busy = false;
          _error = loginError;
        });
        return;
      }
    }
    setState(() => _busy = false);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => app.onboardingComplete ? const AppShell() : const OnboardingScreen(),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Buat akun')),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                children: [
                  const Text('Mulai perjalanan bahasa Jepangmu', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  Text('Akunmu akan menyimpan progress belajar, streak, level, dan hasil quiz.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.45)),
                  const SizedBox(height: 24),
                  TextField(controller: _name, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Nama', prefixIcon: Icon(Icons.person_outline_rounded))),
                  const SizedBox(height: 12),
                  TextField(controller: _email, keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined))),
                  const SizedBox(height: 12),
                  TextField(controller: _password, obscureText: _obscure, textInputAction: TextInputAction.next, decoration: InputDecoration(labelText: 'Password', helperText: 'Minimal 8 karakter', prefixIcon: const Icon(Icons.lock_outline_rounded), suffixIcon: IconButton(onPressed: () => setState(() => _obscure = !_obscure), icon: Icon(_obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded)))),
                  const SizedBox(height: 12),
                  TextField(controller: _confirmPassword, obscureText: _obscureConfirm, textInputAction: TextInputAction.done, onSubmitted: (_) => _busy ? null : _register(), decoration: InputDecoration(labelText: 'Konfirmasi password', prefixIcon: const Icon(Icons.lock_person_outlined), suffixIcon: IconButton(onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm), icon: Icon(_obscureConfirm ? Icons.visibility_rounded : Icons.visibility_off_rounded)))),
                  const SizedBox(height: 14),
                  if (_error.isNotEmpty) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(_error, style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.w700))),
                  FilledButton(onPressed: _busy ? null : _register, style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)), child: _busy ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Daftar & mulai belajar')),
                  const SizedBox(height: 12),
                  OutlinedButton(onPressed: _busy ? null : () => Navigator.of(context).pop(), child: const Text('Sudah punya akun? Masuk')),
                ],
              ),
            ),
          ),
        ),
      );
}
