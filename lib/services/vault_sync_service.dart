import 'dart:convert';

import '../models/vault.dart';
import 'secure_storage_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptography/cryptography.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../repositories/vault_repository.dart';
import 'encryption_service.dart';
import 'firebase_auth_service.dart';

class VaultSyncResult {
  final bool success;
  final String message;

  const VaultSyncResult({
    required this.success,
    required this.message,
  });

  factory VaultSyncResult.success([
    String message = 'Backup completed successfully.',
  ]) {
    return VaultSyncResult(
      success: true,
      message: message,
    );
  }

  factory VaultSyncResult.failure(String message) {
    return VaultSyncResult(
      success: false,
      message: message,
    );
  }
}

class VaultSyncService {
  VaultSyncService._();

  static final VaultSyncService instance = VaultSyncService._();

  static const String _backupKeySeed =
      'QIFY_AUTHENTICATOR_BACKUP_V1_9f6a72d4';

  static const String _enabledStorageKeyPrefix =
      'qify.cloud.backup.enabled.v3.';

  static const String _collectionName = 'users';

  static const String _vaultSubcollectionName = 'vault';

  static const String _vaultDocumentId = 'main';

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final Hmac _hmac = Hmac.sha256();

  String _enabledStorageKey(String uid) {
    return '$_enabledStorageKeyPrefix$uid';
  }

  DocumentReference<Map<String, dynamic>> _vaultDocument(
      String uid,
      ) {
    return _firestore
        .collection(_collectionName)
        .doc(uid)
        .collection(_vaultSubcollectionName)
        .doc(_vaultDocumentId);
  }

  Future<List<int>> _deriveBackupKey(String uid) async {
    final secret = SecretKey(
      utf8.encode(_backupKeySeed),
    );

    final mac = await _hmac.calculateMac(
      utf8.encode(uid),
      secretKey: secret,
    );

    final bytes = mac.bytes;

    if (bytes.length < 32) {
      throw StateError(
        'Unable to derive the backup encryption key.',
      );
    }

    return bytes.sublist(0, 32);
  }

  User? get currentUser {
    return FirebaseAuthService.instance.currentUser;
  }

  bool get isSignedIn {
    final user = currentUser;
    return user != null;
  }

  Future<bool> isBackupEnabled([
    Object? account,
  ]) async {
    final user = await _resolveUser(account);

    if (user == null) {
      return false;
    }

    final value = await SecureStorageService.instance.read(
      _enabledStorageKey(user.uid),
    );

    return value == 'true';
  }

  Future<DateTime?> lastBackupTime([
    Object? account,
  ]) async {
    final user = await _resolveUser(account);

    if (user == null) {
      return null;
    }

    try {
      final snapshot = await _vaultDocument(
        user.uid,
      ).get();

      if (!snapshot.exists) {
        return null;
      }

      final data = snapshot.data();

      if (data == null) {
        return null;
      }

      final timestamp = data['updatedAt'];

      if (timestamp is Timestamp) {
        return timestamp.toDate();
      }

      if (timestamp is String) {
        return DateTime.tryParse(timestamp);
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  Future<VaultSyncResult> enableBackup() async {
    try {
      User? user = currentUser;

      if (user == null) {
        final credentials =
        await FirebaseAuthService.instance
            .signInWithGoogle();

        user = credentials.user;
      }

      if (user == null) {
        return VaultSyncResult.failure(
          'Google sign-in did not return a user.',
        );
      }

      return await syncNow(
        user: user,
        markBackupEnabled: true,
      );
    } on FirebaseAuthException catch (e) {
      return VaultSyncResult.failure(
        _firebaseAuthError(e),
      );
    } catch (e) {
      return VaultSyncResult.failure(
        _cleanError(e),
      );
    }
  }

  Future<VaultSyncResult> syncNow({
    User? user,
    bool markBackupEnabled = false,
  }) async {
    try {
      final effectiveUser = user ?? currentUser;

      if (effectiveUser == null) {
        return VaultSyncResult.failure(
          'Sign in with Google before using cloud backup.',
        );
      }

      if (!markBackupEnabled) {
        final enabled = await isBackupEnabled(
          effectiveUser,
        );

        if (!enabled) {
          return VaultSyncResult.failure(
            'Cloud backup is not enabled.',
          );
        }
      }

      final vault = await VaultRepository.instance.load();

      final vaultJson = jsonEncode(
        vault.toJson(),
      );

      final keyBytes = await _deriveBackupKey(
        effectiveUser.uid,
      );

      final encrypted =
      await EncryptionService.instance.encryptWithRawKey(
        plaintext: vaultJson,
        keyBytes: keyBytes,
      );

      final existingSnapshot = await _vaultDocument(
        effectiveUser.uid,
      ).get();

      int previousVersion = 0;

      if (existingSnapshot.exists) {
        final existingData = existingSnapshot.data();

        if (existingData != null &&
            existingData['vaultVersion'] is int) {
          previousVersion =
          existingData['vaultVersion'] as int;
        }
      }

      final nextVersion = previousVersion + 1;

      await _vaultDocument(
        effectiveUser.uid,
      ).set(
        {
          'formatVersion': 3,
          'cryptoVersion': 1,
          'uid': effectiveUser.uid,
          'email': effectiveUser.email,
          'displayName': effectiveUser.displayName,
          'vaultVersion': nextVersion,
          'vaultCiphertext': encrypted,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (markBackupEnabled) {
        await SecureStorageService.instance.write(
          _enabledStorageKey(
            effectiveUser.uid,
          ),
          'true',
        );
      }

      return VaultSyncResult.success();
    } on FirebaseException catch (e) {
      return VaultSyncResult.failure(
        _firebaseError(e),
      );
    } catch (e) {
      return VaultSyncResult.failure(
        _cleanError(e),
      );
    }
  }

  Future<VaultSyncResult> syncIfEnabled({
    User? user,
  }) async {
    try {
      final effectiveUser = user ?? currentUser;

      if (effectiveUser == null) {
        return VaultSyncResult.failure(
          'No Google account is signed in.',
        );
      }

      final enabled = await isBackupEnabled(
        effectiveUser,
      );

      if (!enabled) {
        return VaultSyncResult.success(
          'Backup is not enabled.',
        );
      }

      return await syncNow(
        user: effectiveUser,
      );
    } catch (e) {
      return VaultSyncResult.failure(
        _cleanError(e),
      );
    }
  }

  Future<bool> hasCloudBackup([
    Object? account,
  ]) async {
    final user = await _resolveUser(account);

    if (user == null) {
      return false;
    }

    try {
      final snapshot = await _vaultDocument(
        user.uid,
      ).get();

      if (!snapshot.exists) {
        return false;
      }

      final data = snapshot.data();

      if (data == null) {
        return false;
      }

      final ciphertext = data['vaultCiphertext'];

      return ciphertext is String &&
          ciphertext.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<VaultSyncResult> restoreForSignedInUser({
    User? user,
  }) async {
    try {
      final effectiveUser = user ?? currentUser;

      if (effectiveUser == null) {
        return VaultSyncResult.failure(
          'Sign in with the Google account used for backup.',
        );
      }

      final snapshot = await _vaultDocument(
        effectiveUser.uid,
      ).get();

      if (!snapshot.exists) {
        return VaultSyncResult.failure(
          'No backup was found for this Google account.',
        );
      }

      final data = snapshot.data();

      if (data == null) {
        return VaultSyncResult.failure(
          'The backup is empty or invalid.',
        );
      }

      final formatVersion = data['formatVersion'];

      if (formatVersion != 3) {
        return VaultSyncResult.failure(
          'This backup uses an unsupported format.',
        );
      }

      final ciphertext = data['vaultCiphertext'];

      if (ciphertext is! String ||
          ciphertext.isEmpty) {
        return VaultSyncResult.failure(
          'The cloud backup does not contain a vault.',
        );
      }

      final keyBytes = await _deriveBackupKey(
        effectiveUser.uid,
      );

      final plaintext =
      await EncryptionService.instance.decryptWithRawKey(
        encoded: ciphertext,
        keyBytes: keyBytes,
      );

      final json = jsonDecode(plaintext);

      if (json is! Map<String, dynamic>) {
        return VaultSyncResult.failure(
          'The restored vault has an invalid format.',
        );
      }

      final vault = Vault.fromJson(json);

      await VaultRepository.instance.replace(vault);

      await SecureStorageService.instance.write(
        _enabledStorageKey(
          effectiveUser.uid,
        ),
        'true',
      );

      return VaultSyncResult.success(
        'Backup restored successfully.',
      );
    } on FirebaseException catch (e) {
      return VaultSyncResult.failure(
        _firebaseError(e),
      );
    } on FormatException {
      return VaultSyncResult.failure(
        'The cloud backup is corrupted or unreadable.',
      );
    } catch (e) {
      return VaultSyncResult.failure(
        _cleanError(e),
      );
    }
  }

  Future<VaultSyncResult> restoreForCurrentUser({
    User? user,
  }) {
    return restoreForSignedInUser(
      user: user,
    );
  }

  Future<int?> cloudVersion({
    User? user,
  }) async {
    final effectiveUser = user ?? currentUser;

    if (effectiveUser == null) {
      return null;
    }

    try {
      final snapshot = await _vaultDocument(
        effectiveUser.uid,
      ).get();

      if (!snapshot.exists) {
        return null;
      }

      final data = snapshot.data();

      if (data == null) {
        return null;
      }

      final version = data['vaultVersion'];

      return version is int ? version : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> disableBackup({
    User? user,
  }) async {
    final effectiveUser = user ?? currentUser;

    if (effectiveUser == null) {
      return;
    }

    await SecureStorageService.instance.delete(
      _enabledStorageKey(
        effectiveUser.uid,
      ),
    );
  }

  Future<User?> _resolveUser(
      Object? account,
      ) async {
    if (account is User) {
      return account;
    }

    if (account is String &&
        account.trim().isNotEmpty) {
      final requestedEmail = account.trim().toLowerCase();

      final user = currentUser;

      if (user?.email?.toLowerCase() ==
          requestedEmail) {
        return user;
      }

      return null;
    }

    return currentUser;
  }

  String _cleanError(Object error) {
    final text = error
        .toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('StateError: ', '')
        .replaceFirst('FormatException: ', '')
        .trim();

    if (text.isEmpty) {
      return 'An unknown backup error occurred.';
    }

    return text;
  }

  String _firebaseError(
      FirebaseException error,
      ) {
    switch (error.code) {
      case 'permission-denied':
        return 'Firebase denied access to the backup.';
      case 'unauthenticated':
        return 'Your Google session has expired. Sign in again.';
      case 'unavailable':
        return 'Firebase is temporarily unavailable. Check your internet connection.';
      case 'failed-precondition':
        return 'Firebase could not complete the backup operation.';
      default:
        return error.message?.trim().isNotEmpty == true
            ? error.message!
            : 'Firebase could not complete the backup operation.';
    }
  }

  String _firebaseAuthError(
      FirebaseAuthException error,
      ) {
    switch (error.code) {
      case 'popup-closed-by-user':
      case 'canceled':
      case 'cancelled':
        return 'Google sign-in was cancelled.';
      case 'network-request-failed':
        return 'Network connection failed during Google sign-in.';
      case 'account-exists-with-different-credential':
        return 'This email is already linked to another sign-in method.';
      default:
        return error.message?.trim().isNotEmpty == true
            ? error.message!
            : 'Google sign-in failed.';
    }
  }
}