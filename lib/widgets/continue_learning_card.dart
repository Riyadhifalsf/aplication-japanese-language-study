import 'package:flutter/material.dart';

/// Continue Learning di beranda dinonaktifkan agar jalur belajar utama
/// hanya muncul di Library melalui bagian Learning aktif.
class ContinueLearningCard extends StatelessWidget {
  const ContinueLearningCard({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
