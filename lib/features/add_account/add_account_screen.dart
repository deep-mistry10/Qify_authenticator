import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/ids.dart';
import '../../models/totp_account.dart';
import '../../repositories/vault_repository.dart';
import '../../services/otpauth_parser.dart';
import '../../services/vault_sync_service.dart';
import '../qr_scanner/qr_scanner_screen.dart';

class AddAccountScreen extends StatefulWidget {
  const AddAccountScreen({super.key});

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  final _issuer = TextEditingController();
  final _secret = TextEditingController();

  String _accountName = '';
  String _algorithm = AppConstants.defaultTotpAlgorithm;
  int _digits = AppConstants.defaultTotpDigits;
  int _period = AppConstants.defaultTotpPeriod;
  bool _manualMode = false;
  bool _saving = false;
  bool _openingScanner = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scan());
  }

  @override
  void dispose() {
    _issuer.dispose();
    _secret.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    if (_openingScanner || _saving) return;
    setState(() => _openingScanner = true);

    try {
      final result = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (_) => const QrScannerScreen()),
      );

      if (!mounted) return;
      if (result == null || result.trim().isEmpty) {
        setState(() => _manualMode = true);
        return;
      }

      final parsed = OtpAuthParser.parse(result);
      setState(() {
        _issuer.text = parsed.issuer == 'Unknown' ? '' : parsed.issuer;
        _secret.text = parsed.secret;
        _accountName = parsed.accountName;
        _algorithm = parsed.algorithm;
        _digits = parsed.digits;
        _period = parsed.period;
        _manualMode = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _manualMode = true);
      _message(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _openingScanner = false);
    }
  }

  Future<void> _save() async {
    final issuer = _issuer.text.trim();
    final secret = _secret.text.replaceAll(RegExp(r'\s+'), '').toUpperCase();

    if (issuer.isEmpty || secret.isEmpty) {
      _message('App / service name and security key are required.');
      return;
    }

    setState(() => _saving = true);

    try {
      final current = await VaultRepository.instance.load();
      final now = DateTime.now().toUtc();
      final accountName = _accountName.trim().isEmpty ? issuer : _accountName.trim();

      final item = TotpAccount(
        id: createId(),
        issuer: issuer,
        accountName: accountName,
        secret: secret,
        algorithm: _algorithm,
        digits: _digits,
        period: _period,
        createdAt: now,
        updatedAt: now,
        sortOrder: current.accounts.length,
      );

      await VaultRepository.instance.addAccount(item);

      final backupEnabled = await VaultRepository.instance.isBackupEnabled();
      if (backupEnabled) {
        final result = await VaultSyncService.instance.syncIfEnabled();
        if (!result.success && mounted) _message(result.message);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        _message(e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
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
      appBar: AppBar(title: const Text('Add account')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (!_manualMode)
            Column(
              children: [
                const Icon(Icons.qr_code_scanner_rounded, size: 70),
                const SizedBox(height: 18),
                const Text(
                  'Scan the QR code from the service you want to add.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton.icon(
                    onPressed: _openingScanner ? null : _scan,
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                    label: const Text('Scan QR code'),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: _openingScanner ? null : () => setState(() => _manualMode = true),
                  child: const Text('Enter manually'),
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Account details',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _issuer,
                  enabled: !_saving,
                  decoration: const InputDecoration(
                    labelText: 'App / service name',
                    hintText: 'GitHub',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _secret,
                  enabled: !_saving,
                  obscureText: true,
                  textCapitalization: TextCapitalization.characters,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: const InputDecoration(
                    labelText: 'Security key',
                  ),
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: _saving ? null : _scan,
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: const Text('Scan a different QR code'),
                ),
                const SizedBox(height: 20),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.info_outline_rounded),
                    title: const Text('Account name'),
                    subtitle: Text(
                      _accountName.isNotEmpty
                          ? _accountName
                          : 'For QR imports, the username or email is read from the QR code automatically.',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _algorithm,
                  decoration: const InputDecoration(labelText: 'Algorithm'),
                  items: const [
                    DropdownMenuItem(value: 'SHA1', child: Text('SHA-1')),
                    DropdownMenuItem(value: 'SHA256', child: Text('SHA-256')),
                    DropdownMenuItem(value: 'SHA512', child: Text('SHA-512')),
                  ],
                  onChanged: _saving ? null : (value) => setState(() => _algorithm = value ?? 'SHA1'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: _digits,
                  decoration: const InputDecoration(labelText: 'Digits'),
                  items: const [
                    DropdownMenuItem(value: 6, child: Text('6')),
                    DropdownMenuItem(value: 8, child: Text('8')),
                  ],
                  onChanged: _saving ? null : (value) => setState(() => _digits = value ?? 6),
                ),
                const SizedBox(height: 12),
                InputDecorator(
                  decoration: const InputDecoration(labelText: 'Period'),
                  child: Text('$_period seconds'),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 54,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save account'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
