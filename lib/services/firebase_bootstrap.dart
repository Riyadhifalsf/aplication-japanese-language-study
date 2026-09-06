import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';

/// Initializes Firebase for project "aplication-japanese-study".
///
/// Android memakai `android/app/google-services.json` + plugin google-services.
/// Platform lain memakai [DefaultFirebaseOptions] (tambah via
/// `flutterfire configure`). Bila init gagal, app tetap jalan offline penuh.
class FirebaseBootstrap {
  FirebaseBootstrap._();

  static bool isAvailable = false;
  static String? lastError;

  static Future<void> initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
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
