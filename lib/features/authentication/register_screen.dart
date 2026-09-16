import 'package:flutter/material.dart';

import '../../core/utils/firebase_error_text.dart';
import '../../services/firebase_auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_password.text.length < 8) {
      _message('Use at least 8 characters for the password.');
      return;
    }
    if (_password.text != _confirm.text) {
      _message('Passwords do not match.');
      return;
    }
    setState(() => _loading = true);
    try {
      await FirebaseAuthService.instance.register(_email.text, _password.text);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) _message(firebaseErrorText(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _message(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')),
                const SizedBox(height: 14),
                TextField(controller: _password, obscureText: _obscure, decoration: InputDecoration(labelText: 'Password', suffixIcon: IconButton(onPressed: () => setState(() => _obscure = !_obscure), icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined)))) ,
                const SizedBox(height: 14),
                TextField(controller: _confirm, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm password')),
                const SizedBox(height: 22),
                FilledButton(
                  onPressed: _loading ? null : _register,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Create account'),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Your Firebase account is separate from your vault password. Do not reuse your Firebase password as your vault password.'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
