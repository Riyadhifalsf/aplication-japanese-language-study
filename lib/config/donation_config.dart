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

class DonationRecord {
  const DonationRecord({required this.displayName, required this.amount});

  final String displayName;
  final int amount;
}

class DonationConfig {
  DonationConfig._();

  /// Halaman pembayaran resmi aplikasi.
  static const saweriaUrl = 'https://saweria.co/Riyadhifalsf';

  static const methods = <DonationMethod>[
    DonationMethod(
      label: 'Saweria',
      value: saweriaUrl,
      note: 'Donasi melalui halaman resmi Japanese Language Study.',
      icon: Icons.favorite_rounded,
    ),
  ];

  /// Feed leaderboard. Untuk data dinamis, isi dari backend/database yang
  /// menerima data donasi Saweria. Jangan menyimpan data pembayaran sensitif di aplikasi.
  static const donors = <DonationRecord>[];

  static int get donorCount => donors.length;
  static int get totalAmount => donors.fold(0, (sum, donor) => sum + donor.amount);

  /// ID paket Android untuk tautan Play Store.
  static const playPackage = 'com.babeh.japanese_study';
}
