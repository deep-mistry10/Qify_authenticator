import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/firebase_auth_service.dart';
import '../../services/vault_sync_service.dart';

class CloudBackupScreen extends StatefulWidget {
  const CloudBackupScreen({super.key});

  @override
  State<CloudBackupScreen> createState() => _CloudBackupScreenState();
}

class _CloudBackupScreenState extends State<CloudBackupScreen> {
  bool _loading = true;
  bool _working = false;
  bool _backupEnabled = false;

  User? _user;
  DateTime? _lastBackup;
  String? _errorMessage;

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
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuthService.instance.currentUser;

      if (user == null) {
        if (!mounted) {
          return;
        }

        setState(() {
          _user = null;
          _backupEnabled = false;
          _lastBackup = null;
          _loading = false;
        });

        return;
      }

      final enabled =
      await VaultSyncService.instance.isBackupEnabled(user);

      final lastBackup =
      await VaultSyncService.instance.lastBackupTime(user);

      if (!mounted) {
        return;
      }

      setState(() {
        _user = user;
        _backupEnabled = enabled;
        _lastBackup = lastBackup;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _errorMessage = _cleanError(e);
      });
    }
  }

  Future<void> _enableBackup() async {
    if (_working) {
      return;
    }

    setState(() {
      _working = true;
      _errorMessage = null;
    });

    try {
      final result =
      await VaultSyncService.instance.enableBackup();

      if (!mounted) {
        return;
      }

      if (result.success) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(result.message),
            ),
          );

        await _loadBackupState();
      } else {
        setState(() {
          _errorMessage = result.message;
        });
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = _cleanError(e);
      });
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
      _errorMessage = null;
    });

    try {
      final result =
      await VaultSyncService.instance.syncNow();

      if (!mounted) {
        return;
      }

      if (result.success) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(result.message),
            ),
          );

        await _loadBackupState();
      } else {
        setState(() {
          _errorMessage = result.message;
        });
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = _cleanError(e);
      });
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

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Turn off cloud backup?'),
          content: const Text(
            'Your local authenticator accounts will remain on this device. '
                'Automatic cloud backup will stop until you enable it again.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Turn off'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _working = true;
      _errorMessage = null;
    });

    try {
      await VaultSyncService.instance.disableBackup();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Cloud backup is now turned off.'),
          ),
        );

      await _loadBackupState();
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = _cleanError(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _working = false;
        });
      }
    }
  }

  String _cleanError(Object error) {
    return error
        .toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('StateError: ', '')
        .replaceFirst('FormatException: ', '')
        .trim();
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) {
      return 'No backup yet';
    }

    final local = value.toLocal();

    final day =
    local.day.toString().padLeft(2, '0');

    final month =
    local.month.toString().padLeft(2, '0');

    final year = local.year.toString();

    final hour12 =
    local.hour == 0
        ? 12
        : local.hour > 12
        ? local.hour - 12
        : local.hour;

    final hour =
    hour12.toString().padLeft(2, '0');

    final minute =
    local.minute.toString().padLeft(2, '0');

    final period =
    local.hour >= 12 ? 'PM' : 'AM';

    return '$day/$month/$year at $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloud backup'),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
          child: CircularProgressIndicator(),
        )
            : RefreshIndicator(
          onRefresh: _loadBackupState,
          child: ListView(
            physics:
            const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              if (_errorMessage != null)
                _buildErrorCard(),
              if (_errorMessage != null)
                const SizedBox(height: 16),
              _user == null
                  ? _buildSignedOut()
                  : _backupEnabled
                  ? _buildBackupEnabled()
                  : _buildBackupDisabled(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cloud backup',
          style:
          Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Keep an encrypted copy of your local authenticator vault '
              'in your Google account.',
          style:
          Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context)
                .colorScheme
                .onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildSignedOut() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 40,
            ),
            const SizedBox(height: 16),
            Text(
              'Backup is not connected',
              style:
              Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your authenticator works normally without a Google '
                  'account. Sign in only when you want cloud backup.',
              style:
              Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: _working ? null : _enableBackup,
                icon: const Icon(
                  Icons.cloud_upload_outlined,
                ),
                label: _working
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
                    : const Text(
                  'Turn on cloud backup',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupDisabled() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.cloud_queue_rounded,
              size: 40,
            ),
            const SizedBox(height: 16),
            Text(
              'Cloud backup is off',
              style:
              Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your accounts are stored locally on this device. '
                  'Enable backup to save an encrypted copy to your Google account.',
              style:
              Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _working ? null : _enableBackup,
                child: _working
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
                    : const Text(
                  'Turn on cloud backup',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupEnabled() {
    return Column(
      children: [
        Card(
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(
                Icons.cloud_done_rounded,
              ),
            ),
            title: const Text(
              'Cloud backup enabled',
            ),
            subtitle: Text(
              _user?.email ?? 'Google account',
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(
              Icons.schedule_rounded,
            ),
            title: const Text(
              'Last backup',
            ),
            subtitle: Text(
              _formatDateTime(_lastBackup),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton.icon(
            onPressed: _working ? null : _backupNow,
            icon: const Icon(
              Icons.cloud_upload_rounded,
            ),
            label: _working
                ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
                : const Text(
              'Back up now',
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed:
            _working ? null : _turnOffBackup,
            child: const Text(
              'Turn off cloud backup',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color:
              Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _errorMessage!,
              ),
            ),
          ],
        ),
      ),
    );
  }
}