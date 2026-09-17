import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/onboarding_service.dart';
import '../../services/vault_sync_service.dart';
import '../../repositories/vault_repository.dart';
import '../home/home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _loading = false;

  Future<void> _startLocal() async {
    if (_loading) return;

    await OnboardingService.instance.complete();
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  Future<void> _recover() async {
    if (_loading) return;
    setState(() => _loading = true);

    try {
      final credential =
      await FirebaseAuthService.instance.signInWithGoogle();
      final user = credential.user;

      if (user == null) {
        throw StateError('Google sign-in did not return a user.');
      }

      final result = await VaultSyncService.instance
          .restoreForSignedInUser(user: user)
          .timeout(const Duration(seconds: 25));

      if (!mounted) return;

      if (result.success) {
        final restoredVault = await VaultRepository.instance.load();

        if (restoredVault.accounts.isEmpty) {
          throw StateError(
            'The backup was restored, but it contains no authenticator accounts.',
          );
        }

        await OnboardingService.instance.complete();
        if (!mounted) return;

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
        return;
      }

      final noBackup = result.message.toLowerCase().contains('no qify backup') ||
          result.message.toLowerCase().contains('no backup');

      if (noBackup) {
        await _showNoBackupDialog();
      } else {
        _message(result.message);
      }
    } catch (e) {
      if (!mounted) return;
      _message(_cleanError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showNoBackupDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('No backup found'),
          content: const Text(
            'This Google account does not have a Qify Authenticator backup yet. Choose “I am a new user” on the welcome screen to continue with a local authenticator.',
          ),
          actions: [
            FilledButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _startLocal();
              },
              child: const Text('I am a new user'),
            ),
          ],
        );
      },
    );
  }

  String _cleanError(Object error) {
    final text = error.toString().replaceFirst('Exception: ', '').trim();
    if (text.isEmpty) return 'Could not restore the backup.';
    if (text.contains('TimeoutException')) {
      return 'Backup lookup timed out. Check your internet connection and try again.';
    }
    return text;
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: AppConstants.primary,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.shield_outlined,
                      color: Colors.white,
                      size: 42,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Qify',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.1,
                    ),
                  ),
                  Text(
                    'Authenticator',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontSize: 31,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.7,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Simple, private authentication that keeps your TOTP codes on this device.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: 16,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 34),
                  Text(
                    'GET STARTED',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppConstants.primary,
                      letterSpacing: 1.6,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _loading ? null : _startLocal,
                    child: const Text('I am a new user'),
                  ),
                  const SizedBox(height: 11),
                  OutlinedButton(
                    onPressed: _loading ? null : _recover,
                    child: _loading
                        ? const SizedBox(
                      width: 21,
                      height: 21,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Text('Already have an account / Restore backup'),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppConstants.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppConstants.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: AppConstants.primary.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lock_outline_rounded,
                            size: 17,
                            color: AppConstants.primary,
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Text(
                            'Cloud backup is optional. TOTP generation works offline.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 13,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Your authenticator stays usable even when you are offline.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
