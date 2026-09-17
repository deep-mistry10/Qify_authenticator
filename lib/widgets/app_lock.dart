import 'package:flutter/material.dart';

import '../services/biometric_service.dart';
import '../services/onboarding_service.dart';

class AppLockGate extends StatefulWidget {
  const AppLockGate({
    super.key,
    required this.child,
  });

  final Widget child;

  static final ValueNotifier<int> lockRequest = ValueNotifier<int>(0);

  static void lockNow() {
    lockRequest.value++;
  }

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate>
    with WidgetsBindingObserver {
  bool _locked = false;
  bool _authenticating = false;
  bool _shouldLockOnResume = false;
  bool _initialCheckCompleted = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    AppLockGate.lockRequest.addListener(_handleLockRequest);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialCheck();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AppLockGate.lockRequest.removeListener(_handleLockRequest);
    super.dispose();
  }

  Future<bool> _canUseAppLock() async {
    try {
      final onboardingComplete =
      await OnboardingService.instance.isComplete();

      if (!onboardingComplete) {
        return false;
      }

      return await BiometricService.instance.isSupported();
    } catch (_) {
      return false;
    }
  }

  Future<void> _initialCheck() async {
    if (!mounted || _initialCheckCompleted) {
      return;
    }

    _initialCheckCompleted = true;

    final shouldLock = await _canUseAppLock();

    if (!mounted || !shouldLock) {
      return;
    }

    await _lockAndAuthenticate();
  }

  void _handleLockRequest() {
    if (!mounted || _authenticating) {
      return;
    }

    _shouldLockOnResume = false;

    _lockAndAuthenticate();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      if (!_authenticating) {
        _shouldLockOnResume = true;
      }

      return;
    }

    if (state == AppLifecycleState.resumed) {
      if (_authenticating) {
        return;
      }

      if (_shouldLockOnResume) {
        _shouldLockOnResume = false;
        _lockAndAuthenticate();
      }
    }
  }

  Future<bool> _runBiometricWithTimeout() async {
    try {
      return await BiometricService.instance
          .authenticate()
          .timeout(
        const Duration(seconds: 20),
        onTimeout: () => false,
      );
    } catch (_) {
      return false;
    }
  }

  Future<void> _lockAndAuthenticate() async {
    if (!mounted || _authenticating) {
      return;
    }

    final canUseLock = await _canUseAppLock();

    if (!mounted) {
      return;
    }

    if (!canUseLock) {
      setState(() {
        _locked = false;
        _authenticating = false;
      });
      return;
    }

    setState(() {
      _locked = true;
      _authenticating = true;
    });

    try {
      final authenticated = await _runBiometricWithTimeout();

      if (!mounted) {
        return;
      }

      if (authenticated) {
        setState(() {
          _locked = false;
        });
      } else {
        // Authentication was cancelled, failed, or timed out.
        // Keep the app locked, but allow the user to press Unlock again.
        setState(() {
          _locked = true;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _authenticating = false;
        });
      }
    }
  }

  Future<void> _unlockManually() async {
    await _lockAndAuthenticate();
  }

  @override
  Widget build(BuildContext context) {
    if (!_locked) {
      return widget.child;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F2),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 28,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 420,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B6B57).withValues(
                        alpha: 0.08,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.fingerprint,
                      size: 38,
                      color: Color(0xFF0B6B57),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Qify Authenticator',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF101512),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Verify your identity to continue',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF61706A),
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: _authenticating
                          ? null
                          : _unlockManually,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0B6B57),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _authenticating
                          ? const SizedBox(
                        width: 21,
                        height: 21,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Text(
                        'Unlock',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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