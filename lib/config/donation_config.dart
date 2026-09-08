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
class DonationRecord {
  const DonationRecord({required this.displayName, required this.amount});

  final String displayName;
  final int amount;
}

class DonationConfig {
  DonationConfig._();

  static const methods = <DonationMethod>[];

  /// Feed leaderboard donasi. Ganti dengan hasil API/backend ketika sistem
  /// pembayaran sudah terhubung. Jangan menyimpan data pembayaran sensitif di aplikasi.
  static const donors = <DonationRecord>[];

  static int get donorCount => donors.length;
  static int get totalAmount => donors.fold(0, (sum, donor) => sum + donor.amount);


  /// ID paket Android untuk tautan Play Store (fakta dari konfigurasi rilis).
  static const playPackage = 'com.babeh.japanese_study';
}
