import 'package:flutter/material.dart';

import '../screens/auth/login_screen.dart';
import '../state/app_controller.dart';

/// Spanduk mode pratinjau: hanya tampil untuk tamu (belum login).
///
/// Menjelaskan batas 5 soal per sesi + ajakan masuk/daftar. Progress
/// pratinjau tetap tersimpan lokal dan ikut ke akun saat mendaftar.
class GuestPreviewBanner extends StatelessWidget {
  const GuestPreviewBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    if (!app.isGuestPreview) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    return Card(
      color: cs.secondaryContainer.withValues(alpha: .55),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: cs.secondary,
              foregroundColor: cs.onSecondary,
              child: const Icon(Icons.visibility_rounded),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mode pratinjau',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Kamu bisa lihat & coba semua latihan, ${AppController.guestPreviewSessionSize} soal per sesi. Masuk untuk sesi penuh + simpan progress.',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              ),
              child: const Text('Masuk'),
            ),
          ],
        ),
      ),
    );
  }
}
