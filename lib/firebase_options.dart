// File generated from google-services.json for project
// "aplication-japanese-study". Re-generasi dengan `flutterfire configure`
// bila menambah platform (iOS/Web) atau rotasi kunci.
//
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCx9uwUizDKyY4pyjeqg4s_Y_ImDw_voA0',
    appId: '1:418436084166:android:4546a716ac2330e7d602c7',
    messagingSenderId: '418436084166',
    projectId: 'aplication-japanese-study',
    databaseURL:
        'https://aplication-japanese-study-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'aplication-japanese-study.firebasestorage.app',
  );
}
