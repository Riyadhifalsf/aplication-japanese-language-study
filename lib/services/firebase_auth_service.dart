import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'firebase_bootstrap.dart';

/// Error auth Firebase dengan pesan Indonesia siap tampil.
class FirebaseAuthFailure implements Exception {
  FirebaseAuthFailure(this.message, {this.isNetworkError = false});

  final String message;
  final bool isNetworkError;

  @override
  String toString() => message;

  static FirebaseAuthFailure fromCode(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return FirebaseAuthFailure('Email sudah terdaftar. Masuk saja.');
      case 'invalid-email':
        return FirebaseAuthFailure('Format email tidak valid.');
      case 'weak-password':
        return FirebaseAuthFailure('Password terlalu lemah (minimal 6 karakter).');
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return FirebaseAuthFailure('Email atau password salah.');
      case 'user-disabled':
        return FirebaseAuthFailure('Akun dinonaktifkan. Hubungi admin.');
      case 'too-many-requests':
        return FirebaseAuthFailure(
            'Terlalu banyak percobaan. Coba lagi beberapa menit.');
      case 'network-request-failed':
        return FirebaseAuthFailure('Tidak ada koneksi internet.',
            isNetworkError: true);
      case 'operation-not-allowed':
        return FirebaseAuthFailure(
            'Login email belum diaktifkan di Firebase Console.');
      case 'internal-error':
        return FirebaseAuthFailure(
            'Server auth tidak merespons (kemungkinan reCAPTCHA / '
            'konfigurasi Firebase belum lengkap). Coba lagi.');
      default:
        return FirebaseAuthFailure('Auth gagal (${e.code}).');
    }
  }
}

/// Hasil auth email/password via Firebase.
class FirebaseEmailResult {
  const FirebaseEmailResult({
    required this.uid,
    required this.email,
    required this.displayName,
  });

  final String uid;
  final String email;
  final String displayName;
}

/// Hasil login Google via Firebase.
class FirebaseGoogleResult {
  const FirebaseGoogleResult({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    required this.idToken,
  });

  final String uid;
  final String email;
  final String displayName;
  final String photoUrl;
  final String idToken;
}

/// Auth Google yang benar via Firebase.
///
/// Alur: Google Sign-In -> dapat idToken/accessToken ->
/// Firebase `signInWithCredential` -> dapat Firebase `idToken`
/// untuk verifikasi ke backend (`POST /api/auth/google`) jadi JWT.
class FirebaseAuthService {
  FirebaseAuthService({FirebaseAuth? auth, GoogleSignIn? signIn})
      : _auth = auth ?? FirebaseAuth.instance,
        _signIn = signIn ??
            GoogleSignIn(scopes: const ['email', 'profile']);

  final FirebaseAuth _auth;
  final GoogleSignIn _signIn;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  void _ensureAvailable() {
    if (!FirebaseBootstrap.isAvailable) {
      throw Exception(
        'Firebase belum dikonfigurasi. Tambah google-services.json '
        'dan jalankan flutterfire configure.',
      );
    }
  }

  /// Pesan ramah untuk kegagalan Google Sign-In di Android.
  ///
  /// Kasus paling umum: PlatformException(sign_in_failed, ... ApiException:
  /// 10: ...) = SHA-1 belum didaftarkan di Firebase Console.
  static String _googleErrorMessage(Object e) {
    final text = e.toString();
    if (text.contains('ApiException: 10') ||
        text.contains('DEVELOPER_ERROR')) {
      return 'Login Google gagal (error 10): SHA-1 HP/keystore belum '
          'terdaftar di Firebase Console. Minta admin daftarkan SHA-1 lalu '
          'update google-services.json.';
    }
    if (text.contains('ApiException: 7') ||
        text.contains('NETWORK_ERROR')) {
      return 'Login Google gagal: tidak ada koneksi internet.';
    }
    if (text.contains('sign_in_canceled') ||
        text.contains('canceled')) {
      return 'Login Google dibatalkan.';
    }
    return 'Login Google gagal. Coba lagi.';
  }

  Future<FirebaseGoogleResult> signInWithGoogle() async {
    _ensureAvailable();
    late final dynamic account;
    try {
      account =
          await _signIn.signInSilently() ?? await _signIn.signIn();
    } catch (e) {
      throw Exception(_googleErrorMessage(e));
    }
    if (account == null) throw Exception('Login Google dibatalkan.');
    final googleAuth = await account.authentication;
    final idToken = googleAuth.idToken;
    final accessToken = googleAuth.accessToken;
    if (idToken == null && accessToken == null) {
      throw Exception('Gagal mendapat token Google.');
    }
    final credential = GoogleAuthProvider.credential(
      idToken: idToken,
      accessToken: accessToken,
    );
    final userCredential =
        await _auth.signInWithCredential(credential);
    final user = userCredential.user;
    if (user == null) throw Exception('Login Firebase gagal.');
    final firebaseIdToken = await user.getIdToken();
    return FirebaseGoogleResult(
      uid: user.uid,
      email: user.email ?? account.email,
      displayName:
          user.displayName ?? account.displayName ?? account.email,
      photoUrl: user.photoURL ?? account.photoUrl ?? '',
      idToken: firebaseIdToken ?? '',
    );
  }

  /// Daftar akun baru dengan email/password (Firebase backend utama).
  Future<FirebaseEmailResult> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    _ensureAvailable();
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) throw FirebaseAuthFailure('Pendaftaran gagal.');
      final displayName = name.trim();
      if (displayName.isNotEmpty) {
        try {
          await user.updateDisplayName(displayName);
          await user.reload();
        } catch (_) {}
      }
      final current = _auth.currentUser ?? user;
      return FirebaseEmailResult(
        uid: current.uid,
        email: current.email ?? email,
        displayName: current.displayName ?? displayName,
      );
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthFailure.fromCode(e);
    }
  }

  /// Masuk dengan email/password (Firebase backend utama).
  Future<FirebaseEmailResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _ensureAvailable();
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) throw FirebaseAuthFailure('Login gagal.');
      return FirebaseEmailResult(
        uid: user.uid,
        email: user.email ?? email,
        displayName: user.displayName ?? (user.email ?? email).split('@').first,
      );
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthFailure.fromCode(e);
    }
  }

  Future<void> signOut() async {
    try {
      await _signIn.signOut();
    } catch (_) {}
    try {
      await _auth.signOut();
    } catch (_) {}
  }

  Future<String?> getIdToken({bool forceRefresh = false}) async {
    final user = _auth.currentUser;
    if (user == null) return null;
    try {
      return await user.getIdToken(forceRefresh);
    } catch (_) {
      return null;
    }
  }
}
