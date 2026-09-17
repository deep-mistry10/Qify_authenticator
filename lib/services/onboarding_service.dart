import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class OnboardingService {
  OnboardingService._();
  static final instance = OnboardingService._();

  static const _key = 'qify.onboarding.completed.v2';

  final FlutterSecureStorage _storage =
  const FlutterSecureStorage();

  Future<bool> isComplete() async {
    return (await _storage.read(key: _key)) == 'true';
  }

  Future<void> complete() async {
    await _storage.write(key: _key, value: 'true');
  }

  /// Resets the app to the first-launch welcome screen.
  ///
  /// This does not touch the cloud backup. It only means the next launch
  /// starts at the local/restore choice screen again.
  Future<void> reset() async {
    await _storage.delete(key: _key);
  }
}
