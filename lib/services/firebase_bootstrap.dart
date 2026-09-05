import 'package:firebase_core/firebase_core.dart';

/// Initializes Firebase when platform configuration has been added.
///
/// The learning app remains usable before Firebase is configured, so local
/// study progress is not blocked during development or self-hosted deployment.
class FirebaseBootstrap {
  FirebaseBootstrap._();

  static bool isAvailable = false;

  static Future<void> initialize() async {
    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp();
      isAvailable = true;
    } on FirebaseException {
      isAvailable = false;
    } catch (_) {
      isAvailable = false;
    }
  }
}
