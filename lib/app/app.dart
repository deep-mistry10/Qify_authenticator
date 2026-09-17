import 'package:flutter/material.dart';

import '../features/authentication/forgot_password_screen.dart';
import '../features/authentication/login_screen.dart';
import '../features/authentication/register_screen.dart';
import '../features/home/home_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../services/onboarding_service.dart';
import '../widgets/app_lock.dart';
import 'theme.dart';

class QifyAuthenticatorApp extends StatelessWidget {
  const QifyAuthenticatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Qify Authenticator',
      debugShowCheckedModeBanner: false,
      theme: buildQifyTheme(Brightness.light),
      darkTheme: buildQifyTheme(Brightness.dark),
      themeMode: ThemeMode.light,
      home: const StartupGate(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/forgot-password': (_) => const ForgotPasswordScreen(),
        '/home': (_) => const HomeScreen(),
      },
    );
  }
}

class StartupGate extends StatelessWidget {
  const StartupGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: OnboardingService.instance.isComplete(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data != true) {
          return const OnboardingScreen();
        }

        return const AppLockGate(
          child: HomeScreen(),
        );
      },
    );
  }
}
