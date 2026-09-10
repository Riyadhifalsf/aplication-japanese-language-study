import 'package:flutter/material.dart';

/// Satu pola navigasi untuk halaman internal aplikasi.
/// Menggunakan Navigator dari context aktif agar konsisten di seluruh app.
class AppNavigation {
  const AppNavigation._();

  static Future<T?> push<T>(BuildContext context, Widget page) {
    return Navigator.of(context).push<T>(
      MaterialPageRoute<T>(builder: (_) => page),
    );
  }
}
