import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleBackupAuthService {
  GoogleBackupAuthService._();
  static final instance = GoogleBackupAuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _initialized = false;

  User? get currentUser => _auth.currentUser;

  Future<void> initialize() async {
    if (_initialized) return;
    await _googleSignIn.initialize();
    _initialized = true;
  }

  Future<UserCredential> signIn() async {
    await initialize();

    final googleUser = await _googleSignIn.authenticate();
    final googleAuth = googleUser.authentication;
    final idToken = googleAuth.idToken;

    if (idToken == null || idToken.isEmpty) {
      throw FirebaseAuthException(
        code: 'missing-google-id-token',
        message: 'Google sign-in did not return an ID token.',
      );
    }

    final credential = GoogleAuthProvider.credential(
      idToken: idToken,
    );

    return _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } finally {
      await _auth.signOut();
    }
  }
}
