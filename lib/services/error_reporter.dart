import 'package:flutter/foundation.dart';

/// Pelaporan error global tingkat enterprise (ringan, offline-first).
///
/// Menangkap error framework ([FlutterError.onError]) dan error async tak
/// tertangani ([PlatformDispatcher.onError]) agar tidak hilang diam-diam.
/// Disimpan di ring buffer memori (100 terakhir) + diteruskan ke handler
/// sebelumnya + `debugPrint`. TIDAK dikirim ke server otomatis dan TIDAK
/// ikut sync Firestore (hindari noise) — dibaca manual saat butuh diagnosis.
class AppErrorRecord {
  AppErrorRecord(this.message, this.stack, this.at);

  final String message;
  final StackTrace? stack;
  final DateTime at;
}

class ErrorReporter {
  ErrorReporter._();

  static final List<AppErrorRecord> recent = [];
  static bool _installed = false;

  static void install() {
    if (_installed) return;
    _installed = true;
    final prevFlutter = FlutterError.onError;
    FlutterError.onError = (details) {
      record(details.exceptionAsString(), details.stack);
      if (prevFlutter != null) {
        prevFlutter(details);
      } else {
        FlutterError.presentError(details);
      }
    };
    final prevPlatform =
        PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (error, stack) {
      record('$error', stack);
      if (prevPlatform != null) return prevPlatform(error, stack);
      return false;
    };
  }

  static void record(String message, [StackTrace? stack]) {
    recent.insert(0, AppErrorRecord(message, stack, DateTime.now()));
    if (recent.length > 100) recent.removeRange(100, recent.length);
    debugPrint('[APP-ERROR] $message');
  }
}
