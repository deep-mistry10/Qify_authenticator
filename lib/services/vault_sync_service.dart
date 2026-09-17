import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptography/cryptography.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/vault.dart';
import '../repositories/vault_repository.dart';
import 'encryption_service.dart';

class SyncResult {
  final bool success;
  final String message;
  final bool hasBackup;

  const SyncResult(
      this.success,
      this.message, {
        this.hasBackup = false,
      });
}

class VaultSyncService {
  VaultSyncService._();
  static final instance = VaultSyncService._();

  static const _backupKeySeed = 'QIFY_AUTHENTICATOR_BACKUP_V1_9f6a72d4';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final VaultRepository _repo = VaultRepository.instance;
  final EncryptionService _crypto = EncryptionService.instance;
  final Hmac _hmac = Hmac.sha256();

  bool _syncing = false;

  DocumentReference<Map<String, dynamic>> _doc(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('vault')
        .doc('main');
  }

  Future<List<int>> _deriveBackupKey(String uid) async {
    final mac = await _hmac.calculateMac(
      utf8.encode(uid),
      secretKey: SecretKey(utf8.encode(_backupKeySeed)),
    );

    if (mac.bytes.length != 32) {
      throw StateError('Backup key derivation failed.');
    }

    return mac.bytes;
  }

  String? get currentUid => _auth.currentUser?.uid;

  Future<SyncResult> syncIfEnabled() async {
    final enabled = await _repo.isBackupEnabled();
    if (!enabled) {
      return const SyncResult(true, 'Cloud backup is disabled.');
    }

    final user = _auth.currentUser;
    if (user == null) {
      return const SyncResult(
        false,
        'Backup is enabled, but the backup account is not signed in.',
      );
    }

    return syncNow(user: user);
  }

  Future<SyncResult> syncNow({User? user}) async {
    if (_syncing) {
      return const SyncResult(true, 'Backup already in progress.');
    }

    final backupUser = user ?? _auth.currentUser;
    if (backupUser == null) {
      return const SyncResult(
        false,
        'Sign in to the backup Google account first.',
      );
    }

    final configuredUid = await _repo.backupUid();
    if (configuredUid != null &&
        configuredUid.isNotEmpty &&
        configuredUid != backupUser.uid) {
      return const SyncResult(
        false,
        'The signed-in Google account is not the configured backup account.',
      );
    }

    _syncing = true;

    try {
      final vault = await _repo.load();
      final doc = _doc(backupUser.uid);

      debugPrint(
        '[Qify Backup] Uploading ${vault.accounts.length} account(s) '
            'to users/${backupUser.uid}/vault/main, version ${vault.version}.',
      );

      // Fetch the current server document so we never overwrite a newer cloud
      // vault with an older local vault.
      final snapshot = await doc.get(
        const GetOptions(source: Source.server),
      );

      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        final remoteVersion = (data['vaultVersion'] as num? ?? 0).toInt();

        if (remoteVersion > vault.version) {
          return const SyncResult(
            false,
            'A newer backup exists in the cloud. Restore it before making more changes on this device.',
            hasBackup: true,
          );
        }
      }

      final key = await _deriveBackupKey(backupUser.uid);
      final plaintext = jsonEncode(vault.toJson());
      final ciphertext = await _crypto.encryptWithRawKey(
        plaintext: plaintext,
        keyBytes: key,
      );

      await doc.set({
        'formatVersion': 3,
        'cryptoVersion': 1,
        'uid': backupUser.uid,
        'backupEmail': backupUser.email ?? '',
        'displayName': backupUser.displayName ?? '',
        'vaultVersion': vault.version,
        'accountCount': vault.accounts.length,
        'vaultCiphertext': ciphertext,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Read the document back from the server. This makes "Backup completed"
      // mean the server actually accepted the encrypted vault.
      final confirmation = await doc.get(
        const GetOptions(source: Source.server),
      );

      final confirmationData = confirmation.data();
      final storedCiphertext = confirmationData?['vaultCiphertext'];

      if (!confirmation.exists ||
          storedCiphertext is! String ||
          storedCiphertext.isEmpty) {
        throw StateError(
          'The backup upload was not confirmed by the Firestore server.',
        );
      }

      await _repo.setBackupAccount(
        uid: backupUser.uid,
        email: backupUser.email ?? '',
      );
      await _repo.setLastBackupAt(DateTime.now());

      debugPrint(
        '[Qify Backup] Server confirmed ${vault.accounts.length} account(s).',
      );

      return SyncResult(
        true,
        'Backup completed successfully (${vault.accounts.length} account${vault.accounts.length == 1 ? '' : 's'}).',
        hasBackup: true,
      );
    } on FirebaseException catch (e) {
      debugPrint('[Qify Backup] Upload Firebase error: ${e.code}: ${e.message}');
      return SyncResult(
        false,
        'Backup failed: ${e.message ?? e.code}.',
      );
    } catch (e) {
      debugPrint('[Qify Backup] Upload error: $e');
      return SyncResult(false, 'Backup failed: $e');
    } finally {
      _syncing = false;
    }
  }

  /// Reads the backup directly from the Firestore server.
  ///
  /// IMPORTANT: this method intentionally does not swallow exceptions.
  /// A permission/network/project error must not be mistaken for "no backup".
  Future<Map<String, dynamic>?> cloudMetadata(String uid) async {
    final snapshot = await _doc(uid).get(
      const GetOptions(source: Source.server),
    );

    if (!snapshot.exists) {
      debugPrint(
        '[Qify Backup] No Firestore document at users/$uid/vault/main.',
      );
      return null;
    }

    final data = snapshot.data();
    if (data == null) {
      throw StateError('The cloud backup document is empty.');
    }

    debugPrint(
      '[Qify Backup] Found cloud document for $uid with '
          '${(data['accountCount'] as num? ?? -1).toInt()} account(s).',
    );

    return data;
  }

  Future<bool> hasCloudBackup(String uid) async {
    final metadata = await cloudMetadata(uid);
    final ciphertext = metadata?['vaultCiphertext'];
    return ciphertext is String && ciphertext.isNotEmpty;
  }

  Future<Vault?> downloadAndDecrypt({required String uid}) async {
    final metadata = await cloudMetadata(uid);
    if (metadata == null) return null;

    final formatVersion = (metadata['formatVersion'] as num? ?? 0).toInt();
    if (formatVersion != 3) {
      throw const FormatException('Unsupported cloud backup format.');
    }

    final storedUid = metadata['uid'];
    if (storedUid is String && storedUid.isNotEmpty && storedUid != uid) {
      throw const FormatException('This backup belongs to a different Google account.');
    }

    final ciphertext = metadata['vaultCiphertext'];
    if (ciphertext is! String || ciphertext.isEmpty) {
      throw const FormatException('Cloud backup is incomplete.');
    }

    final expectedCount = (metadata['accountCount'] as num? ?? -1).toInt();

    debugPrint(
      '[Qify Backup] Decrypting cloud vault for $uid '
          '(expected account count: $expectedCount).',
    );

    final key = await _deriveBackupKey(uid);
    final clear = await _crypto.decryptWithRawKey(
      encoded: ciphertext,
      keyBytes: key,
    );

    final decoded = jsonDecode(clear);
    if (decoded is! Map) {
      throw const FormatException('Cloud vault JSON is invalid.');
    }

    final vault = Vault.fromJson(Map<String, dynamic>.from(decoded));

    if (expectedCount >= 0 && vault.accounts.length != expectedCount) {
      throw FormatException(
        'Cloud backup is inconsistent: expected $expectedCount account(s), '
            'but the encrypted vault contains ${vault.accounts.length}.',
      );
    }

    debugPrint(
      '[Qify Backup] Decryption succeeded. Restored ${vault.accounts.length} account(s).',
    );

    return vault;
  }

  Future<SyncResult> restoreForSignedInUser({required User user}) async {
    try {
      debugPrint(
        '[Qify Backup] Restore started for ${user.email ?? 'Google account'} '
            '(uid=${user.uid}).',
      );

      final cloudVault = await downloadAndDecrypt(uid: user.uid);
      if (cloudVault == null) {
        return const SyncResult(
          false,
          'No Qify backup was found for this Google account.',
        );
      }

      // Replace the encrypted local vault with the decrypted cloud vault.
      await _repo.replace(cloudVault);
      await _repo.clearMemoryCache();

      // Verify that the data written to local secure storage can be read back.
      final restored = await _repo.load();

      if (restored.accounts.length != cloudVault.accounts.length) {
        throw StateError(
          'Backup was decrypted, but the local vault verification failed.',
        );
      }

      await _repo.setBackupAccount(
        uid: user.uid,
        email: user.email ?? '',
      );
      await _repo.setLastBackupAt(DateTime.now());

      debugPrint(
        '[Qify Backup] Restore verified: ${restored.accounts.length} account(s) '
            'available locally.',
      );

      return SyncResult(
        true,
        'Backup restored successfully (${restored.accounts.length} account${restored.accounts.length == 1 ? '' : 's'}).',
        hasBackup: true,
      );
    } on FirebaseException catch (e) {
      debugPrint('[Qify Backup] Restore Firebase error: ${e.code}: ${e.message}');
      return SyncResult(
        false,
        'Restore failed: ${e.message ?? e.code}.',
      );
    } on FormatException catch (e) {
      debugPrint('[Qify Backup] Restore format error: $e');
      return SyncResult(false, e.message);
    } catch (e) {
      debugPrint('[Qify Backup] Restore error: $e');
      return SyncResult(false, 'The cloud backup could not be restored: $e');
    }
  }

  Future<int> cloudVersion(String uid) async {
    final metadata = await cloudMetadata(uid);
    return (metadata?['vaultVersion'] as num? ?? 0).toInt();
  }
}
