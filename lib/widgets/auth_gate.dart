import 'package:flutter/material.dart';

import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../state/app_controller.dart';

/// Palang guest: panggil sebelum membuka fitur khusus akun.
/// Mengembalikan true bila user sudah login, false bila masih tamu
/// (sambil menampilkan dialog ajakan masuk/daftar).
Future<bool> requireLogin(BuildContext context, {String feature = 'fitur ini'}) async {
  final app = AppScope.of(context);
  if (app.isAuthenticated) return true;
  if (!context.mounted) return false;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Login dulu yuk'),
      content: Text(
        '$feature khusus akun terdaftar. Masuk untuk simpan progress, '
        'atau daftar gratis.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Nanti'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(dialogContext);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RegisterScreen()),
            );
          },
          child: const Text('Daftar'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(dialogContext);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          },
          child: const Text('Masuk'),
        ),
      ],
    ),
  );
  return false;
}
