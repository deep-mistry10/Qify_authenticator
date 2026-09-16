import 'package:flutter/material.dart';

import '../services/biometric_service.dart';
import '../services/onboarding_service.dart';

class AppLockGate extends StatefulWidget {
  final Widget child;

  /// External signal used by Settings > Lock now.
  static final ValueNotifier<int> lockRequest =
  ValueNotifier<int>(0);

  const AppLockGate({
    super.key,
    required this.child,
  });

  /// Immediately requests the application to lock.
  static void lockNow() {
    lockRequest.value++;
  }

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate>
    with WidgetsBindingObserver {
  bool _initialized = false;
  bool _locked = false;
  bool _authenticating = false;
  bool _lockOnResume = false;

  int _lastHandledRequest = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _lastHandledRequest =
        AppLockGate.lockRequest.value;

    AppLockGate.lockRequest.addListener(
      _handleExternalLockRequest,
    );

    _initialize();
  }

  @override
  void dispose() {
    AppLockGate.lockRequest.removeListener(
      _handleExternalLockRequest,
    );

    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      final onboardingComplete =
      await OnboardingService.instance.isComplete();

      if (!mounted) {
        return;
      }

      setState(() {
        _initialized = true;
        _locked = false;
      });

      if (onboardingComplete) {
        await _unlockIfRequired();
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _initialized = true;
        _locked = false;
      });
    }
  }

  void _handleExternalLockRequest() {
    if (!mounted) {
      return;
    }

    final request =
        AppLockGate.lockRequest.value;

    if (request == _lastHandledRequest) {
      return;
    }

    _lastHandledRequest = request;

    _lockImmediately();
  }

  void _lockImmediately() {
    if (!mounted) {
      return;
    }

    setState(() {
      _locked = true;
      _lockOnResume = false;
    });
  }

  Future<void> _unlockIfRequired() async {
    if (!mounted || _authenticating) {
      return;
    }

    _authenticating = true;

    try {
      final supported =
      await BiometricService.instance.isSupported();

      if (!mounted) {
        return;
      }

      if (!supported) {
        setState(() {
          _locked = false;
        });

        return;
      }

      setState(() {
        _locked = true;
      });

      final success =
      await BiometricService.instance.authenticate();

      if (!mounted) {
        return;
      }

      setState(() {
        _locked = !success;
        _lockOnResume = false;
      });
    } finally {
      _authenticating = false;
    }
  }

  @override
  void didChangeAppLifecycleState(
      AppLifecycleState state,
      ) {
    if (!_initialized || _authenticating) {
      return;
    }

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _lockOnResume = true;

      if (mounted) {
        setState(() {
          _locked = true;
        });
      }

      return;
    }

    if (state == AppLifecycleState.resumed &&
        _lockOnResume) {
      _lockOnResume = false;
      _unlockIfRequired();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_locked) {
      return widget.child;
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  size: 72,
                ),
                const SizedBox(height: 20),
                Text(
                  'Qify Authenticator is locked',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Use your device screen lock to continue.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed:
                    _authenticating
                        ? null
                        : _unlockIfRequired,
                    icon: const Icon(
                      Icons.lock_open_rounded,
                    ),
                    label: Text(
                      _authenticating
                          ? 'Waiting...'
                          : 'Unlock',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}