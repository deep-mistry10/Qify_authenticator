import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../repositories/vault_repository.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/vault_sync_service.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _loading = true;
  bool _working = false;
  bool _enabled = false;
  String? _email;
  DateTime? _lastBackup;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final enabled = await VaultRepository.instance
          .isBackupEnabled()
          .timeout(const Duration(seconds: 5));
      final email = await VaultRepository.instance
          .backupEmail()
          .timeout(const Duration(seconds: 5));
      final last = await VaultRepository.instance
          .lastBackupAt()
          .timeout(const Duration(seconds: 5));

      if (!mounted) return;
      setState(() {
        _enabled = enabled;
        _email = email;
        _lastBackup = last;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _message('Could not load backup settings. ${e.toString()}');
    }
  }

  Future<void> _enableBackup() async {
    if (_working) return;
    setState(() => _working = true);

    try {
      var user = FirebaseAuthService.instance.currentUser;
      if (user == null) {
        final credential = await FirebaseAuthService.instance.signInWithGoogle();
        user = credential.user;
      }

      if (user == null) {
        throw StateError('Google sign-in did not return a user.');
      }

      final existing = await VaultSyncService.instance
          .hasCloudBackup(user.uid)
          .timeout(const Duration(seconds: 15));

      if (existing && mounted) {
        final choice = await showDialog<String>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Backup already exists'),
            content: const Text(
              'This Google account already has a Qify backup. Restore that backup or replace it with the accounts currently on this device.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, 'cancel'),
                child: const Text('Cancel'),
              ),
              OutlinedButton(
                onPressed: () => Navigator.pop(context, 'restore'),
                child: const Text('Restore backup'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, 'replace'),
                child: const Text('Replace backup'),
              ),
            ],
          ),
        );

        if (!mounted) return;

        if (choice == 'restore') {
          final result = await VaultSyncService.instance
              .restoreForSignedInUser(user: user)
              .timeout(const Duration(seconds: 20));
          _message(result.message);
          await _load();
          return;
        }

        if (choice != 'replace') return;
      }

      final result = await VaultSyncService.instance
          .syncNow(user: user)
          .timeout(const Duration(seconds: 20));
      if (!mounted) return;
      _message(result.message);
      await _load();
    } catch (e) {
      if (mounted) {
        _message(_cleanError(e));
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _backupNow() async {
    if (_working) return;
    setState(() => _working = true);

    try {
      var user = FirebaseAuthService.instance.currentUser;
      if (user == null) {
        final credential = await FirebaseAuthService.instance.signInWithGoogle();
        user = credential.user;
      }

      if (user == null) {
        throw StateError('Please sign in to the backup Google account.');
      }

      final configuredUid = await VaultRepository.instance.backupUid();
      if (configuredUid != null && configuredUid != user.uid) {
        throw StateError(
          'Please sign in with the exact Google account used for backup.',
        );
      }

      final result = await VaultSyncService.instance
          .syncNow(user: user)
          .timeout(const Duration(seconds: 20));

      if (!mounted) return;
      _message(result.message);
      await _load();
    } catch (e) {
      if (mounted) _message(_cleanError(e));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _turnOff() async {
    if (_working) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Turn off cloud backup?'),
        content: const Text(
          'Your local authenticator accounts will stay on this device. Future changes will stop syncing until backup is enabled again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Turn off'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await VaultRepository.instance.clearBackupAccount();
    await FirebaseAuthService.instance.logout();
    await _load();
  }

  String _cleanError(Object error) {
    final text = error.toString().replaceFirst('Exception: ', '').trim();
    if (text.contains('TimeoutException')) {
      return 'Backup timed out. Check your internet connection and try again.';
    }
    return text.isEmpty ? 'Backup failed.' : text;
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _formatLastBackup() {
    if (_lastBackup == null) return 'Not backed up yet';
    return _lastBackup!.toLocal().toString().substring(0, 16);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Cloud backup')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          Center(
            child: Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: AppConstants.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Icon(
                _enabled ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
                size: 42,
                color: AppConstants.primary,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            _enabled ? 'Cloud backup is on' : 'Cloud backup is off',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            _enabled
                ? 'Your encrypted vault is backed up after local changes.'
                : 'Qify works fully offline. Backup is optional.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.45,
                ),
          ),
          const SizedBox(height: 24),
          if (_enabled) ...[
            Card(
              child: ListTile(
                leading: const Icon(Icons.account_circle_outlined),
                title: const Text('Backup account'),
                subtitle: Text(
                  _email?.isNotEmpty == true ? _email! : 'Google account',
                ),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.schedule_outlined),
                title: const Text('Last backup'),
                subtitle: Text(_formatLastBackup()),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _working ? null : _backupNow,
                icon: const Icon(Icons.cloud_upload_outlined),
                label: Text(_working ? 'Backing up...' : 'Back up now'),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: _working ? null : _turnOff,
              child: const Text('Turn off cloud backup'),
            ),
          ] else ...[
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _working ? null : _enableBackup,
                icon: const Icon(Icons.cloud_upload_outlined),
                label: Text(_working ? 'Connecting...' : 'Turn on cloud backup'),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppConstants.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppConstants.border),
            ),
            child: Text(
              'Only the encrypted vault is uploaded. Live OTP codes are generated locally.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    height: 1.4,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
