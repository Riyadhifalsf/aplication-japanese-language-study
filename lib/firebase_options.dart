// Firebase configuration for project "aplication-japanese-study".
//
// The Firebase Android API key is intentionally NOT committed to Git.
// Build/run with:
//   flutter run --dart-define=FIREBASE_ANDROID_API_KEY=<RESTRICTED_KEY>
//
// Keep the key restricted to the Android app and Firebase-related APIs in
// Google Cloud Console. This file can be safely committed because it contains
// only non-secret Firebase identifiers and reads the API key at build time.
//
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions belum dikonfigurasi untuk web - '
        'jalankan `flutterfire configure` untuk menambahkannya.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions belum dikonfigurasi untuk iOS - '
          'jalankan `flutterfire configure` untuk menambahkannya.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions belum dikonfigurasi untuk macOS - '
          'jalankan `flutterfire configure` untuk menambahkannya.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions belum dikonfigurasi untuk Windows - '
          'jalankan `flutterfire configure` untuk menambahkannya.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions belum dikonfigurasi untuk Linux - '
          'jalankan `flutterfire configure` untuk menambahkannya.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions tidak didukung untuk platform ini.',
        );
    }
  }

  static String get _androidApiKey {
    const key = String.fromEnvironment('FIREBASE_ANDROID_API_KEY');
    if (key.isEmpty) {
      throw UnsupportedError(
        'FIREBASE_ANDROID_API_KEY belum diberikan. Jalankan aplikasi dengan '
        '--dart-define=FIREBASE_ANDROID_API_KEY=<RESTRICTED_KEY>.',
      );
    }
    return key;
  }

  static FirebaseOptions get android => FirebaseOptions(
        apiKey: _androidApiKey,
        appId: '1:418436084166:android:4546a716ac2330e7d602c7',
        messagingSenderId: '418436084166',
        projectId: 'aplication-japanese-study',
        databaseURL:
            'https://aplication-japanese-study-default-rtdb.asia-southeast1.firebasedatabase.app',
        storageBucket: 'aplication-japanese-study.firebasestorage.app',
      );
}
