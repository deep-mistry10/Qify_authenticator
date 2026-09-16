import 'package:flutter/material.dart';

import '../../services/firebase_auth_service.dart';
import '../../services/onboarding_service.dart';
import '../../services/vault_sync_service.dart';
import '../home/home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _loading = false;

  Future<void> _startLocal() async {
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

      final result =
          await VaultSyncService.instance.restoreForSignedInUser(user: user);

      if (!mounted) return;

      if (!result.success) {
        await FirebaseAuthService.instance.logout();
        if (mounted) _message(result.message);
        return;
      }

      await OnboardingService.instance.complete();

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      if (mounted) {
        _message(
          e.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _message(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.shield_outlined, size: 72),
                  const SizedBox(height: 24),
                  Text(
                    'Qify Authenticator',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Use your authenticator locally, or restore an encrypted cloud backup from your Google account.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(height: 1.45),
                  ),
                  const SizedBox(height: 34),
                  FilledButton(
                    onPressed: _loading ? null : _startLocal,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Text('I am a new user'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _loading ? null : _recover,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('I have a backup'),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Cloud backup is optional. TOTP generation works offline.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
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
