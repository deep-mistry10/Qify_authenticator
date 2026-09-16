import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

class EncryptionService {
  EncryptionService._();
  static final instance = EncryptionService._();

  final AesGcm _aes = AesGcm.with256bits();

  List<int> randomBytes(int length) {
    final random = Random.secure();
    return List<int>.generate(
      length,
      (_) => random.nextInt(256),
      growable: false,
    );
  }

  Future<String> encryptWithRawKey({
    required String plaintext,
    required List<int> keyBytes,
  }) async {
    if (keyBytes.length != 32) {
      throw ArgumentError('AES-256 key must contain 32 bytes.');
    }

    final box = await _aes.encryptString(
      plaintext,
      secretKey: SecretKey(keyBytes),
    );

    return base64UrlEncode(box.concatenation());
  }

  Future<String> decryptWithRawKey({
    required String encoded,
    required List<int> keyBytes,
  }) async {
    if (keyBytes.length != 32) {
      throw ArgumentError('AES-256 key must contain 32 bytes.');
    }

    final box = SecretBox.fromConcatenation(
      base64Url.decode(encoded),
      nonceLength: _aes.nonceLength,
      macLength: _aes.macAlgorithm.macLength,
    );

    return _aes.decryptString(
      box,
      secretKey: SecretKey(keyBytes),
    );
  }

  Future<String> _deriveCloudKey({
    required String uid,
    required List<int> salt,
  }) async {
    final argon2 = Argon2id(
      memory: 19000,
      parallelism: 1,
      iterations: 2,
      hashLength: 32,
    );

    final key = await argon2.deriveKeyFromPassword(
      password: uid,
      nonce: salt,
    );

    final bytes = await key.extractBytes();
    return base64UrlEncode(bytes);
  }

  Future<Map<String, dynamic>> encryptVaultForCloud({
    required String vaultJson,
    required String uid,
  }) async {
    final salt = randomBytes(16);
    final derivedKey = await _deriveCloudKey(
      uid: uid,
      salt: salt,
    );

    final box = await _aes.encryptString(
      vaultJson,
      secretKey: SecretKey(
        base64Url.decode(derivedKey),
      ),
    );

    return {
      'formatVersion': 2,
      'cryptoVersion': 2,
      'kdf': 'argon2id',
      'kdfMemory': 19000,
      'kdfParallelism': 1,
      'kdfIterations': 2,
      'kdfHashLength': 32,
      'salt': base64UrlEncode(salt),
      'vaultCiphertext': base64UrlEncode(
        box.concatenation(),
      ),
    };
  }

  Future<String> decryptCloudVault({
    required Map<String, dynamic> envelope,
    required String uid,
  }) async {
    final formatVersion =
        (envelope['formatVersion'] as num? ?? 0).toInt();

    if (formatVersion != 2) {
      throw const FormatException(
        'Unsupported cloud backup format.',
      );
    }

    final saltValue = envelope['salt'];
    final ciphertextValue = envelope['vaultCiphertext'];

    if (saltValue is! String || ciphertextValue is! String) {
      throw const FormatException(
        'Cloud backup is incomplete.',
      );
    }

    final salt = base64Url.decode(saltValue);

    final argon2 = Argon2id(
      memory: (envelope['kdfMemory'] as num? ?? 19000).toInt(),
      parallelism: (envelope['kdfParallelism'] as num? ?? 1).toInt(),
      iterations: (envelope['kdfIterations'] as num? ?? 2).toInt(),
      hashLength: (envelope['kdfHashLength'] as num? ?? 32).toInt(),
    );

    final key = await argon2.deriveKeyFromPassword(
      password: uid,
      nonce: salt,
    );

    final box = SecretBox.fromConcatenation(
      base64Url.decode(ciphertextValue),
      nonceLength: _aes.nonceLength,
      macLength: _aes.macAlgorithm.macLength,
    );

    return _aes.decryptString(
      box,
      secretKey: key,
    );
  }
}
