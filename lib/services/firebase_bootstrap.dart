import 'package:firebase_core/firebase_core.dart';

/// Initializes Firebase when platform configuration has been added.
///
/// The learning app remains usable before Firebase is configured, so local
/// study progress is not blocked during development or self-hosted deployment.
///
/// Android: tambah `android/app/google-services.json`.
/// Web/semua platform: jalankan `flutterfire configure` untuk generate
/// `lib/firebase_options.dart`, lalu Firebase otomatis terpakai.
class FirebaseBootstrap {
  FirebaseBootstrap._();

  static bool isAvailable = false;
  static String? lastError;

  static Future<void> initialize() async {
    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp();
      isAvailable = true;
      lastError = null;
    } on FirebaseException catch (e) {
      isAvailable = false;
      lastError = e.message;
    } catch (e) {
      isAvailable = false;
      lastError = e.toString();
    }
  }
}
