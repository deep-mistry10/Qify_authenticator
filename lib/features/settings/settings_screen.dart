import 'package:flutter/material.dart';

import '../../services/firebase_auth_service.dart';
import '../backup/backup_screen.dart';
import '../../widgets/app_lock.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
  });

  @override
  State<SettingsScreen> createState() =>
      _SettingsScreenState();
}

class _SettingsScreenState
    extends State<SettingsScreen> {
  bool _signingOut = false;

  void _refresh() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  Future<void> _openBackup() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const BackupScreen(),
      ),
    );

    _refresh();
  }

  Future<void> _signOut() async {
    if (_signingOut) {
      return;
    }

    final user =
        FirebaseAuthService.instance.currentUser;

    if (user == null) {
      _refresh();
      return;
    }

    final confirmed =
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Sign out?',
          ),
          content: const Text(
            'You will be signed out of the Google backup account. '
                'Your local authenticator accounts will remain on this device.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext)
                    .pop(false);
              },
              child: const Text(
                'Cancel',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext)
                    .pop(true);
              },
              child: const Text(
                'Sign out',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _signingOut = true;
    });

    try {
      await FirebaseAuthService.instance
          .logout();

      if (!mounted) {
        return;
      }

      setState(() {
        _signingOut = false;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Signed out successfully.',
            ),
          ),
        );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _signingOut = false;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              _cleanError(e),
            ),
          ),
        );
    }
  }

  void _lockNow() {
    AppLockGate.lockNow();

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop();
  }

  String _cleanError(Object error) {
    return error
        .toString()
        .replaceFirst(
      'Exception: ',
      '',
    )
        .replaceFirst(
      'StateError: ',
      '',
    )
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    final user =
        FirebaseAuthService.instance.currentUser;

    final isSignedIn = user != null;

    final displayName =
    user?.displayName?.trim();

    final email =
    user?.email?.trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          16,
          8,
          16,
          32,
        ),
        children: [
          Text(
            'Account',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(
              fontWeight:
              FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: CircleAvatar(
                    child: Icon(
                      isSignedIn
                          ? Icons.account_circle_rounded
                          : Icons.person_outline_rounded,
                    ),
                  ),
                  title: Text(
                    isSignedIn
                        ? (displayName?.isNotEmpty == true
                        ? displayName!
                        : 'Google account')
                        : 'Not signed in',
                  ),
                  subtitle: Text(
                    isSignedIn
                        ? (email?.isNotEmpty == true
                        ? email!
                        : 'Google account')
                        : 'Google sign-in is optional.',
                  ),
                ),
                if (isSignedIn)
                  Padding(
                    padding:
                    const EdgeInsets.fromLTRB(
                      16,
                      0,
                      16,
                      16,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: _signingOut
                            ? null
                            : _signOut,
                        icon: _signingOut
                            ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                          CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                            : const Icon(
                          Icons.logout_rounded,
                        ),
                        label: Text(
                          _signingOut
                              ? 'Signing out...'
                              : 'Sign out',
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          Text(
            'Backup',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(
              fontWeight:
              FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.cloud_outlined,
              ),
              title: const Text(
                'Cloud backup',
              ),
              subtitle: const Text(
                'Encrypted backup and restore using your Google account.',
              ),
              trailing: const Icon(
                Icons.chevron_right_rounded,
              ),
              onTap: _openBackup,
            ),
          ),

          const SizedBox(height: 28),

          Text(
            'Security',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(
              fontWeight:
              FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(
                    Icons.phonelink_lock_rounded,
                  ),
                  title: Text(
                    'Device screen lock',
                  ),
                  subtitle: Text(
                    'Qify Authenticator uses your device security to protect the app.',
                  ),
                ),
                const Divider(
                  height: 1,
                ),
                ListTile(
                  leading: const Icon(
                    Icons.lock_outline_rounded,
                  ),
                  title: const Text(
                    'Lock now',
                  ),
                  subtitle: const Text(
                    'Lock the authenticator immediately.',
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                  ),
                  onTap: _lockNow,
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          Text(
            'Information',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(
              fontWeight:
              FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: const [
                ListTile(
                  leading: Icon(
                    Icons.security_rounded,
                  ),
                  title: Text(
                    'Local TOTP generation',
                  ),
                  subtitle: Text(
                    'OTP codes are generated locally on this device.',
                  ),
                ),
                Divider(
                  height: 1,
                ),
                ListTile(
                  leading: Icon(
                    Icons.cloud_outlined,
                  ),
                  title: Text(
                    'Optional cloud backup',
                  ),
                  subtitle: Text(
                    'The authenticator continues working without a Google account.',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}