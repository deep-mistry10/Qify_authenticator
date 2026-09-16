import 'dart:convert';
import 'dart:math';

import '../models/totp_account.dart';
import '../models/vault.dart';
import '../services/encryption_service.dart';
import '../services/secure_storage_service.dart';

class VaultRepository {
  VaultRepository._();

  static final VaultRepository instance =
  VaultRepository._();

  static const String _vaultKey =
      'qify.local.vault.v3';

  static const String _localEncryptionKey =
      'qify.local.key.v3';

  static const String _deviceKey =
      'qify.device.id.v3';

  static const String _backupEnabledKey =
      'qify.cloud.backup.enabled.local.v3';

  final SecureStorageService _storage =
      SecureStorageService.instance;

  final EncryptionService _crypto =
      EncryptionService.instance;

  Vault? _cache;

  Future<String> deviceId() async {
    final existing =
    await _storage.read(_deviceKey);

    if (existing != null &&
        existing.isNotEmpty) {
      return existing;
    }

    final random = Random.secure();

    final bytes = List<int>.generate(
      16,
          (_) => random.nextInt(256),
    );

    final id = base64UrlEncode(
      bytes,
    );

    await _storage.write(
      _deviceKey,
      id,
    );

    return id;
  }

  Future<List<int>> _localKey() async {
    final existing =
    await _storage.read(
      _localEncryptionKey,
    );

    if (existing != null &&
        existing.isNotEmpty) {
      final decoded =
      base64Url.decode(existing);

      if (decoded.length != 32) {
        throw StateError(
          'Local encryption key is invalid.',
        );
      }

      return decoded;
    }

    final key =
    _crypto.randomBytes(32);

    await _storage.write(
      _localEncryptionKey,
      base64UrlEncode(key),
    );

    return key;
  }

  Future<Vault> load() async {
    if (_cache != null) {
      return _cache!;
    }

    final encrypted =
    await _storage.read(
      _vaultKey,
    );

    if (encrypted == null ||
        encrypted.isEmpty) {
      _cache = const Vault();
      return _cache!;
    }

    final plaintext =
    await _crypto.decryptWithRawKey(
      encoded: encrypted,
      keyBytes: await _localKey(),
    );

    final decoded =
    jsonDecode(plaintext);

    if (decoded is! Map) {
      throw const FormatException(
        'Local vault is invalid.',
      );
    }

    _cache = Vault.fromJson(
      Map<String, dynamic>.from(decoded),
    );

    return _cache!;
  }

  Future<Vault> save(
      Vault vault,
      ) async {
    final plaintext =
    jsonEncode(
      vault.toJson(),
    );

    final encrypted =
    await _crypto.encryptWithRawKey(
      plaintext: plaintext,
      keyBytes: await _localKey(),
    );

    await _storage.write(
      _vaultKey,
      encrypted,
    );

    _cache = vault;

    return vault;
  }

  Future<Vault> addAccount(
      TotpAccount account,
      ) async {
    final current =
    await load();

    final duplicate =
    current.accounts.any(
          (existing) =>
      existing.secret == account.secret &&
          existing.issuer == account.issuer &&
          existing.accountName ==
              account.accountName,
    );

    if (duplicate) {
      throw StateError(
        'This account already exists.',
      );
    }

    return save(
      current.copyWith(
        version: current.version + 1,
        accounts: [
          ...current.accounts,
          account,
        ],
      ),
    );
  }

  Future<Vault> updateAccount(
      TotpAccount account,
      ) async {
    final current =
    await load();

    return save(
      current.copyWith(
        version: current.version + 1,
        accounts: current.accounts
            .map(
              (existing) =>
          existing.id == account.id
              ? account
              : existing,
        )
            .toList(),
      ),
    );
  }

  Future<Vault> deleteAccount(
      String accountId,
      ) async {
    final current =
    await load();

    return save(
      current.copyWith(
        version: current.version + 1,
        accounts: current.accounts
            .where(
              (account) =>
          account.id != accountId,
        )
            .toList(),
      ),
    );
  }

  Future<void> replace(
      Vault vault,
      ) async {
    await save(vault);
  }

  Future<bool> isBackupEnabled() async {
    final value =
    await _storage.read(
      _backupEnabledKey,
    );

    return value == 'true';
  }

  Future<void> setBackupEnabled(
      bool enabled,
      ) async {
    await _storage.write(
      _backupEnabledKey,
      enabled ? 'true' : 'false',
    );
  }

  Future<void> clearMemoryCache() async {
    _cache = null;
  }
}