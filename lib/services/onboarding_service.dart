import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class OnboardingService {
  OnboardingService._();

  static final OnboardingService instance =
  OnboardingService._();

  static const String _key =
      'qify.onboarding.completed.v2';

  final FlutterSecureStorage _storage =
  const FlutterSecureStorage();

  Future<bool> isComplete() async {
    final value = await _storage.read(
      key: _key,
    );

    return value == 'true';
  }

  Future<void> complete() async {
    await _storage.write(
      key: _key,
      value: 'true',
    );
  }
}