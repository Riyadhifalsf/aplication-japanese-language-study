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

  /// Data contoh untuk preview UI leaderboard.
  /// Ganti dengan data dari backend/database saat leaderboard sudah dinamis.
  /// Nama dan nominal di bawah ini bukan donasi nyata.
  static const donors = <DonationRecord>[
    DonationRecord(displayName: 'Sakura', amount: 250000),
    DonationRecord(displayName: 'Ryu', amount: 150000),
    DonationRecord(displayName: 'Aki', amount: 100000),
    DonationRecord(displayName: 'Hana', amount: 75000),
    DonationRecord(displayName: 'Kenji', amount: 50000),
    DonationRecord(displayName: 'Mika', amount: 50000),
    DonationRecord(displayName: 'Yuki', amount: 25000),
    DonationRecord(displayName: 'Ren', amount: 20000),
    DonationRecord(displayName: 'Nana', amount: 10000),
    DonationRecord(displayName: 'Taro', amount: 5000),
  ];

  static int get donorCount => donors.length;
  static int get totalAmount => donors.fold(0, (sum, donor) => sum + donor.amount);

  /// ID paket Android untuk tautan Play Store.
  static const playPackage = 'com.babeh.japanese_study';
}
