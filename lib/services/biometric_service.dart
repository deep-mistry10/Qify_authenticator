import 'package:local_auth/local_auth.dart';

class BiometricService {
  BiometricService._();
  static final instance = BiometricService._();

  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> isSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Unlock Qify Authenticator',
        biometricOnly: false,
      );
    } catch (_) {
      return false;
    }
  }
}
