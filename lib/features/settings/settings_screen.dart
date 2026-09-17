import 'package:flutter/material.dart';

import '../../repositories/vault_repository.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/onboarding_service.dart';
import '../../widgets/app_lock.dart';
import '../backup/backup_screen.dart';
import '../onboarding/onboarding_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _signingOut = false;

  Future<void> _openBackup() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BackupScreen()),
    );
    if (mounted) setState(() {});
  }

  Future<void> _logout() async {
    if (_signingOut) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Sign out?'),
          content: const Text(
            'You will return to the Qify Authenticator start screen and the accounts stored locally on this device will be removed. Your cloud backup will not be deleted. You can restore it again by signing in with the same Google account.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Sign out'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || _signingOut) return;

    setState(() => _signingOut = true);

    try {
      // 1. End the Google/Firebase session.
      await FirebaseAuthService.instance.logout();

      // 2. Remove only local/device state associated with this session.
      //    The Firestore backup remains untouched.
      await VaultRepository.instance.clearAllLocalData();
      await VaultRepository.instance.clearBackupAccount();

      // 3. Make the app show the first-launch choice again.
      await OnboardingService.instance.reset();

      if (!mounted) return;

      // 4. Remove the current Home/Settings navigation stack so the user
      //    cannot press Back and return to the previous signed-out state.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const OnboardingScreen(),
        ),
            (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign out failed: $e'),
        ),
      );
      setState(() => _signingOut = false);
    }
  }

  Future<void> _lockNow() async {
    AppLockGate.lockNow();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuthService.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const ListTile(
            title: Text(
              'Account',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          if (user != null)
            ListTile(
              leading: CircleAvatar(
                backgroundImage:
                user.photoURL != null && user.photoURL!.isNotEmpty
                    ? NetworkImage(user.photoURL!)
                    : null,
                child: user.photoURL == null || user.photoURL!.isEmpty
                    ? const Icon(Icons.person_outline_rounded)
                    : null,
              ),
              title: Text(
                user.displayName?.isNotEmpty == true
                    ? user.displayName!
                    : 'Google account',
              ),
              subtitle: Text(user.email ?? ''),
            )
          else
            const ListTile(
              leading: Icon(Icons.person_off_outlined),
              title: Text('Not signed in'),
              subtitle: Text(
                'Google sign-in is only used for optional cloud backup.',
              ),
            ),
          if (user != null)
            ListTile(
              leading: const Icon(Icons.logout_rounded),
              title: Text(
                _signingOut ? 'Signing out...' : 'Sign out',
              ),
              subtitle: const Text(
                'Return to the start screen and clear local accounts from this device.',
              ),
              enabled: !_signingOut,
              onTap: _logout,
            ),
          const Divider(),
          const ListTile(
            title: Text(
              'Cloud backup',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          FutureBuilder<bool>(
            future: VaultRepository.instance.isBackupEnabled(),
            builder: (context, snapshot) {
              final enabled = snapshot.data ?? false;
              return ListTile(
                leading: Icon(
                  enabled
                      ? Icons.cloud_done_outlined
                      : Icons.cloud_off_outlined,
                ),
                title: const Text('Backup'),
                subtitle: Text(
                  enabled
                      ? 'Automatic encrypted backup is enabled.'
                      : 'Optional backup to your Google account.',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _openBackup,
              );
            },
          ),
          const Divider(),
          const ListTile(
            title: Text(
              'Security',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const ListTile(
            leading: Icon(Icons.security_rounded),
            title: Text('Device screen lock'),
            subtitle: Text(
              'The authenticator uses your device screen lock to protect the app.',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline_rounded),
            title: const Text('Lock now'),
            subtitle: const Text('Lock the authenticator immediately.'),
            onTap: _lockNow,
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Text(
              'Qify Authenticator works without a cloud account. TOTP codes are generated locally.',
            ),
          ),
        ],
      ),
    );
  }
}
