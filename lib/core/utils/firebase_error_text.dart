import 'package:firebase_auth/firebase_auth.dart';

String firebaseErrorText(Object error) {
  if (error is! FirebaseAuthException) return error.toString();
  return switch (error.code) {
    'email-already-in-use' => 'An account already exists for this email.',
    'invalid-email' => 'Please enter a valid email address.',
    'weak-password' => 'Use a stronger password.',
    'invalid-credential' => 'Email or password is incorrect.',
    'user-not-found' => 'No account was found for this email.',
    'wrong-password' => 'Email or password is incorrect.',
    'network-request-failed' => 'Network connection failed.',
    _ => error.message ?? 'Authentication failed.',
  };
}
