import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'firebase_bootstrap.dart';

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

  Future<FirebaseGoogleResult> signInWithGoogle() async {
    _ensureAvailable();
    final account =
        await _signIn.signInSilently() ?? await _signIn.signIn();
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
