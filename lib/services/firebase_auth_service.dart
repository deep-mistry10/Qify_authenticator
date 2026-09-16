import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseAuthService {
  FirebaseAuthService._();

  static final FirebaseAuthService instance =
  FirebaseAuthService._();

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final GoogleSignIn _googleSignIn =
      GoogleSignIn.instance;

  bool _googleInitialized = false;

  User? get currentUser {
    return _auth.currentUser;
  }

  Stream<User?> get authStateChanges {
    return _auth.authStateChanges();
  }

  // ---------------------------------------------------------------------------
  // GOOGLE SIGN-IN
  // ---------------------------------------------------------------------------

  Future<void> initializeGoogleSignIn() async {
    if (_googleInitialized) {
      return;
    }

    await _googleSignIn.initialize();

    _googleInitialized = true;
  }

  Future<UserCredential> signInWithGoogle() async {
    await initializeGoogleSignIn();

    final GoogleSignInAccount googleUser =
    await _googleSignIn.authenticate();

    final GoogleSignInAuthentication googleAuth =
        googleUser.authentication;

    final String? idToken = googleAuth.idToken;

    if (idToken == null || idToken.isEmpty) {
      throw FirebaseAuthException(
        code: 'missing-google-id-token',
        message:
        'Google sign-in did not return an ID token.',
      );
    }

    final OAuthCredential credential =
    GoogleAuthProvider.credential(
      idToken: idToken,
    );

    return _auth.signInWithCredential(
      credential,
    );
  }

  // ---------------------------------------------------------------------------
  // EMAIL / PASSWORD LOGIN
  // ---------------------------------------------------------------------------

  // Positional arguments are intentionally used here
  // because the existing login screen calls:
  //
  // authService.login(email, password)
  Future<UserCredential> login(
      String email,
      String password,
      ) async {
    final cleanEmail =
    email.trim().toLowerCase();

    if (cleanEmail.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-email',
        message: 'Enter your email address.',
      );
    }

    if (password.isEmpty) {
      throw FirebaseAuthException(
        code: 'empty-password',
        message: 'Enter your password.',
      );
    }

    return _auth.signInWithEmailAndPassword(
      email: cleanEmail,
      password: password,
    );
  }

  // ---------------------------------------------------------------------------
  // REGISTER
  // ---------------------------------------------------------------------------

  // Positional arguments are intentionally used here
  // because the existing register screen calls:
  //
  // authService.register(email, password)
  Future<UserCredential> register(
      String email,
      String password,
      ) async {
    final cleanEmail =
    email.trim().toLowerCase();

    if (cleanEmail.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-email',
        message: 'Enter your email address.',
      );
    }

    if (password.isEmpty) {
      throw FirebaseAuthException(
        code: 'empty-password',
        message: 'Enter a password.',
      );
    }

    return _auth.createUserWithEmailAndPassword(
      email: cleanEmail,
      password: password,
    );
  }

  // ---------------------------------------------------------------------------
  // PASSWORD RESET
  // ---------------------------------------------------------------------------

  Future<void> resetPassword(
      String email,
      ) async {
    final cleanEmail =
    email.trim().toLowerCase();

    if (cleanEmail.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-email',
        message: 'Enter your email address.',
      );
    }

    await _auth.sendPasswordResetEmail(
      email: cleanEmail,
    );
  }

  // ---------------------------------------------------------------------------
  // LOGOUT
  // ---------------------------------------------------------------------------

  Future<void> logout() async {
    Object? firstError;

    try {
      if (!_googleInitialized) {
        await initializeGoogleSignIn();
      }

      await _googleSignIn.signOut();
    } catch (e) {
      firstError = e;
    }

    try {
      await _auth.signOut();
    } catch (e) {
      firstError ??= e;
    }

    if (firstError != null) {
      throw firstError;
    }
  }
}