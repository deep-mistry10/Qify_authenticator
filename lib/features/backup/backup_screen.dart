import 'package:flutter/material.dart';

import '../../services/firebase_auth_service.dart';
import '../../services/vault_sync_service.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({
    super.key,
  });

  @override
  State<BackupScreen> createState() =>
      _BackupScreenState();
}

class _BackupScreenState
    extends State<BackupScreen> {
  bool _loading = true;
  bool _working = false;
  bool _backupEnabled = false;

  String? _email;
  DateTime? _lastBackup;

  @override
  void initState() {
    super.initState();
    _loadBackupState();
  }

  Future<void> _loadBackupState() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final user =
          FirebaseAuthService.instance.currentUser;

      if (user == null) {
        if (!mounted) {
          return;
        }

        setState(() {
          _backupEnabled = false;
          _email = null;
          _lastBackup = null;
          _loading = false;
        });

        return;
      }

      final enabled =
      await VaultSyncService.instance
          .isBackupEnabled(user)
          .timeout(
        const Duration(seconds: 8),
      );

      final lastBackup =
      await VaultSyncService.instance
          .lastBackupTime(user)
          .timeout(
        const Duration(seconds: 8),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _backupEnabled = enabled;
        _email = user.email;
        _lastBackup = lastBackup;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
      });

      _showMessage(
        _cleanError(e),
      );
    }
  }

  Future<void> _enableBackup() async {
    if (_working) {
      return;
    }

    setState(() {
      _working = true;
    });

    try {
      final result =
      await VaultSyncService.instance
          .enableBackup()
          .timeout(
        const Duration(seconds: 30),
      );

      if (!mounted) {
        return;
      }

      if (result.success) {
        _showMessage(
          result.message,
        );

        await _loadBackupState();
      } else {
        _showMessage(
          result.message,
        );
      }
    } catch (e) {
      if (mounted) {
        _showMessage(
          _cleanError(e),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _working = false;
        });
      }
    }
  }

  Future<void> _backupNow() async {
    if (_working) {
      return;
    }

    setState(() {
      _working = true;
    });

    try {
      var user =
          FirebaseAuthService.instance.currentUser;

      if (user == null) {
        final credential =
        await FirebaseAuthService.instance
            .signInWithGoogle();

        user = credential.user;
      }

      if (user == null) {
        throw StateError(
          'Google sign-in did not return a user.',
        );
      }

      final enabled =
      await VaultSyncService.instance
          .isBackupEnabled(user)
          .timeout(
        const Duration(seconds: 8),
      );

      if (!enabled) {
        throw StateError(
          'Cloud backup is not enabled.',
        );
      }

      final result =
      await VaultSyncService.instance
          .syncNow(
        user: user,
      )
          .timeout(
        const Duration(seconds: 30),
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        result.message,
      );

      if (result.success) {
        await _loadBackupState();
      }
    } catch (e) {
      if (mounted) {
        _showMessage(
          _cleanError(e),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _working = false;
        });
      }
    }
  }

  Future<void> _restoreBackup() async {
    if (_working) {
      return;
    }

    setState(() {
      _working = true;
    });

    try {
      var user =
          FirebaseAuthService.instance.currentUser;

      if (user == null) {
        final credential =
        await FirebaseAuthService.instance
            .signInWithGoogle();

        user = credential.user;
      }

      if (user == null) {
        throw StateError(
          'Sign in with the Google account that contains your backup.',
        );
      }

      final hasBackup =
      await VaultSyncService.instance
          .hasCloudBackup(user)
          .timeout(
        const Duration(seconds: 15),
      );

      if (!hasBackup) {
        throw StateError(
          'No Qify Authenticator backup was found for this Google account.',
        );
      }

      if (!mounted) {
        return;
      }

      final confirmed =
      await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text(
              'Restore backup?',
            ),
            content: const Text(
              'This will replace the accounts currently stored on this device with the encrypted cloud backup.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(
                    dialogContext,
                  ).pop(false);
                },
                child: const Text(
                  'Cancel',
                ),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(
                    dialogContext,
                  ).pop(true);
                },
                child: const Text(
                  'Restore',
                ),
              ),
            ],
          );
        },
      );

      if (confirmed != true) {
        return;
      }

      final result =
      await VaultSyncService.instance
          .restoreForSignedInUser(
        user: user,
      )
          .timeout(
        const Duration(seconds: 30),
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        result.message,
      );

      if (result.success) {
        await _loadBackupState();
      }
    } catch (e) {
      if (mounted) {
        _showMessage(
          _cleanError(e),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _working = false;
        });
      }
    }
  }

  Future<void> _turnOffBackup() async {
    if (_working) {
      return;
    }

    final confirmed =
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Turn off cloud backup?',
          ),
          content: const Text(
            'Your local authenticator accounts will remain on this device. Automatic backup will stop until you enable it again.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },
              child: const Text(
                'Cancel',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              child: const Text(
                'Turn off',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _working = true;
    });

    try {
      await VaultSyncService.instance
          .disableBackup();

      if (!mounted) {
        return;
      }

      _showMessage(
        'Cloud backup is now turned off.',
      );

      await _loadBackupState();
    } catch (e) {
      if (mounted) {
        _showMessage(
          _cleanError(e),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _working = false;
        });
      }
    }
  }

  String _cleanError(Object error) {
    var message = error.toString();

    message = message.replaceFirst(
      'Exception: ',
      '',
    );

    message = message.replaceFirst(
      'StateError: ',
      '',
    );

    message = message.replaceFirst(
      'FormatException: ',
      '',
    );

    if (message.contains(
      'TimeoutException',
    )) {
      return 'The operation timed out. Check your internet connection and try again.';
    }

    if (message.trim().isEmpty) {
      return 'Backup operation failed.';
    }

    return message.trim();
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  String _formatDateTime(
      DateTime? value,
      ) {
    if (value == null) {
      return 'No backup yet';
    }

    final local =
    value.toLocal();

    final day =
    local.day.toString().padLeft(
      2,
      '0',
    );

    final month =
    local.month.toString().padLeft(
      2,
      '0',
    );

    final year =
    local.year.toString();

    final hour =
    local.hour.toString().padLeft(
      2,
      '0',
    );

    final minute =
    local.minute.toString().padLeft(
      2,
      '0',
    );

    return '$day/$month/$year at $hour:$minute';
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Backup',
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadBackupState,
        child: ListView(
          physics:
          const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            Icon(
              _backupEnabled
                  ? Icons.cloud_done_rounded
                  : Icons.cloud_off_rounded,
              size: 68,
            ),
            const SizedBox(height: 18),
            Text(
              _backupEnabled
                  ? 'Cloud backup is enabled'
                  : 'Cloud backup is disabled',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(
                fontWeight:
                FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _backupEnabled
                  ? 'Your encrypted authenticator vault can be restored using the same Google account.'
                  : 'Qify Authenticator works without a Google account. Backup is optional.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            if (_backupEnabled) ...[
              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.account_circle_outlined,
                  ),
                  title: const Text(
                    'Backup account',
                  ),
                  subtitle: Text(
                    _email ?? 'Google account',
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.schedule_outlined,
                  ),
                  title: const Text(
                    'Last backup',
                  ),
                  subtitle: Text(
                    _formatDateTime(
                      _lastBackup,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed:
                  _working
                      ? null
                      : _backupNow,
                  icon: const Icon(
                    Icons.cloud_upload_outlined,
                  ),
                  label: Text(
                    _working
                        ? 'Backing up...'
                        : 'Back up now',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child:
                OutlinedButton.icon(
                  onPressed:
                  _working
                      ? null
                      : _restoreBackup,
                  icon: const Icon(
                    Icons.cloud_download_outlined,
                  ),
                  label: const Text(
                    'Restore backup',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed:
                _working
                    ? null
                    : _turnOffBackup,
                child: const Text(
                  'Turn off cloud backup',
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed:
                  _working
                      ? null
                      : _enableBackup,
                  icon: const Icon(
                    Icons.cloud_upload_outlined,
                  ),
                  label: Text(
                    _working
                        ? 'Connecting...'
                        : 'Turn on cloud backup',
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'OTP codes are generated locally. Backup stores the encrypted vault, not live OTP values.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}