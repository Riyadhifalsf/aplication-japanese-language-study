import 'package:flutter/material.dart';

/// Satu kanal donasi resmi. Hanya yang terisi yang tampil di layar Donasi.
class DonationMethod {
  const DonationMethod({
    required this.label,
    required this.value,
    required this.note,
    required this.icon,
  });

  final String label;
  final String value;
  final String note;
  final IconData icon;
}

/// CARA ISI: tambahkan entri dengan nomor/akun resmi, contoh:
/// ```dart
/// static const methods = <DonationMethod>[
///   DonationMethod(
///     label: 'QRIS',
///     value: '0812XXXXXXX',
///     note: 'a.n. Japanese Study',
///     icon: Icons.qr_code_rounded,
///   ),
/// ];
/// ```
/// Kosong = layar Donasi hanya menampilkan dukungan gratis (rating).
class DonationConfig {
  DonationConfig._();

  static const methods = <DonationMethod>[];

  /// ID paket Android untuk tautan Play Store (fakta dari konfigurasi rilis).
  static const playPackage = 'com.babeh.japanese_study';
}
