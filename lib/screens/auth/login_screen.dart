import 'package:flutter/material.dart';

import '../../state/app_controller.dart';
import '../admin/admin_dashboard_screen.dart';
import 'register_screen.dart';
import '../app_shell.dart';
import '../onboarding_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  String _error = '';

  @override
  void dispose() { _email.dispose(); _password.dispose(); super.dispose(); }

  Future<void> _emailLogin() async {
    setState(() { _busy = true; _error = ''; });
    final error = await AppScope.of(context).loginWithEmail(_email.text, _password.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    _goNext();
  }

  Future<void> _googleLogin() async {
    setState(() { _busy = true; _error = ''; });
    try {
      final ok = await AppScope.of(context).loginWithGoogle();
      if (!mounted) return;
      setState(() => _busy = false);
      if (!ok) { setState(() => _error = 'Login Google dibatalkan atau gagal.'); return; }
      _goNext();
    } catch (_) {
      if (!mounted) return;
      setState(() { _busy = false; _error = 'Google Login belum dikonfigurasi pada project ini.'; });
    }
  }

  void _goNext() {
    final app = AppScope.of(context);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => app.isAdmin ? const AdminDashboardScreen() : (app.onboardingComplete ? const AppShell() : const OnboardingScreen())),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520), child: ListView(padding: const EdgeInsets.fromLTRB(24, 42, 24, 28), children: [
      Container(width: 104, height: 104, padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .08), blurRadius: 26, offset: const Offset(0, 12))]), child: Image.asset('assets/branding/japanese_study_logo.png', fit: BoxFit.contain)),
      const SizedBox(height: 24),
      const Text('Masuk ke Japanese Study', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
      const SizedBox(height: 8),
      Text('Akses akunmu untuk sinkronisasi progress ke server secara aman.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.45)),
      const SizedBox(height: 24),
      FilledButton.icon(onPressed: _busy ? null : _googleLogin, icon: const Icon(Icons.account_circle_rounded), label: const Text('Lanjut dengan Google'), style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54))),
      const SizedBox(height: 20),
      Row(children: [Expanded(child: Divider(color: Theme.of(context).colorScheme.outlineVariant)), const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('atau')), Expanded(child: Divider(color: Theme.of(context).colorScheme.outlineVariant))]),
      const SizedBox(height: 18),
      TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined))),
      const SizedBox(height: 12),
      TextField(controller: _password, obscureText: _obscure, decoration: InputDecoration(labelText: 'Password', prefixIcon: const Icon(Icons.lock_outline_rounded), suffixIcon: IconButton(onPressed: () => setState(() => _obscure = !_obscure), icon: Icon(_obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded)))),
      const SizedBox(height: 14),
      if (_error.isNotEmpty) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(_error, style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.w700))),
      FilledButton(onPressed: _busy ? null : _emailLogin, style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)), child: _busy ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Masuk')),
      const SizedBox(height: 10),
      OutlinedButton.icon(
        onPressed: _busy ? null : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterScreen())),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Buat akun baru'),
        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
      ),
    ])))));
}
