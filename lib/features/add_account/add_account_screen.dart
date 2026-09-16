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
  final TextEditingController _issuerController = TextEditingController();
  final TextEditingController _secretController = TextEditingController();

  String _accountName = '';
  String _algorithm = AppConstants.defaultTotpAlgorithm;
  int _digits = AppConstants.defaultTotpDigits;
  int _period = AppConstants.defaultTotpPeriod;

  bool _manualMode = false;
  bool _openingScanner = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openScannerAutomatically();
    });
  }

  @override
  void dispose() {
    _issuerController.dispose();
    _secretController.dispose();
    super.dispose();
  }

  Future<void> _openScannerAutomatically() async {
    await _scanQrCode();
  }

  Future<void> _scanQrCode() async {
    if (_openingScanner || _saving || !mounted) {
      return;
    }

    setState(() {
      _openingScanner = true;
    });

    try {
      final result = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (_) => const QrScannerScreen(),
        ),
      );

      if (!mounted) {
        return;
      }

      if (result == null || result.trim().isEmpty) {
        setState(() {
          _manualMode = true;
        });
        return;
      }

      final parsed = OtpAuthParser.parse(result);

      setState(() {
        _issuerController.text =
        parsed.issuer == 'Unknown' ? '' : parsed.issuer;

        _secretController.text = parsed.secret;

        _accountName =
        parsed.accountName == 'Unknown account'
            ? ''
            : parsed.accountName;

        _algorithm = parsed.algorithm;
        _digits = parsed.digits;
        _period = parsed.period;

        _manualMode = true;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _manualMode = true;
      });

      _showMessage(
        _cleanError(e),
      );
    } finally {
      if (mounted) {
        setState(() {
          _openingScanner = false;
        });
      }
    }
  }

  Future<void> _saveAccount() async {
    if (_saving) {
      return;
    }

    final issuer = _issuerController.text.trim();
    final secret = _secretController.text
        .replaceAll(RegExp(r'\s+'), '')
        .trim()
        .toUpperCase();

    if (issuer.isEmpty) {
      _showMessage('Enter the app or service name.');
      return;
    }

    if (secret.isEmpty) {
      _showMessage('Enter the security key.');
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final vault = await VaultRepository.instance.load();
      final now = DateTime.now().toUtc();

      final normalizedAccountName = _accountName.trim();

      final account = TotpAccount(
        id: createId(),
        issuer: issuer,
        accountName: normalizedAccountName,
        secret: secret,
        algorithm: _algorithm,
        digits: _digits,
        period: _period,
        createdAt: now,
        updatedAt: now,
        sortOrder: vault.accounts.length,
      );

      await VaultRepository.instance.addAccount(account);

      final backupEnabled =
      await VaultRepository.instance.isBackupEnabled();

      if (backupEnabled) {
        final result =
        await VaultSyncService.instance.syncIfEnabled();

        if (!result.success && mounted) {
          _showMessage(result.message);
        }
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        _showMessage(
          _cleanError(e),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  String _cleanError(Object error) {
    return error
        .toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('FormatException: ', '')
        .trim();
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add account'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (!_manualMode)
              _buildInitialScannerView()
            else
              _buildAccountForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialScannerView() {
    return Column(
      children: [
        const SizedBox(height: 40),
        const Icon(
          Icons.qr_code_scanner_rounded,
          size: 76,
        ),
        const SizedBox(height: 20),
        Text(
          'Add a TOTP account',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          'Scan the QR code provided by the service.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context)
                .colorScheme
                .onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton.icon(
            onPressed: _openingScanner ? null : _scanQrCode,
            icon: const Icon(
              Icons.qr_code_scanner_rounded,
            ),
            label: Text(
              _openingScanner
                  ? 'Opening scanner...'
                  : 'Scan QR code',
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: _openingScanner
                ? null
                : () {
              setState(() {
                _manualMode = true;
              });
            },
            child: const Text('Enter manually'),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Account details',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter the service name and security key.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context)
                .colorScheme
                .onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),

        TextField(
          controller: _issuerController,
          enabled: !_saving,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'App / service name',
            hintText: 'GitHub',
            border: OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 14),

        TextField(
          controller: _secretController,
          enabled: !_saving,
          obscureText: true,
          autocorrect: false,
          enableSuggestions: false,
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Security key',
            hintText: 'JBSWY3DPEHPK3PXP',
            border: OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 18),

        if (_accountName.trim().isNotEmpty)
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(
                Icons.person_outline_rounded,
              ),
              title: const Text('Account'),
              subtitle: Text(
                _accountName.trim(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

        const SizedBox(height: 14),

        OutlinedButton.icon(
          onPressed: _saving ? null : _scanQrCode,
          icon: const Icon(
            Icons.qr_code_scanner_rounded,
          ),
          label: const Text('Scan a different QR code'),
        ),

        const SizedBox(height: 22),

        DropdownButtonFormField<String>(
          initialValue: _algorithm,
          decoration: const InputDecoration(
            labelText: 'Algorithm',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(
              value: 'SHA1',
              child: Text('SHA-1'),
            ),
            DropdownMenuItem(
              value: 'SHA256',
              child: Text('SHA-256'),
            ),
            DropdownMenuItem(
              value: 'SHA512',
              child: Text('SHA-512'),
            ),
          ],
          onChanged: _saving
              ? null
              : (value) {
            if (value == null) {
              return;
            }

            setState(() {
              _algorithm = value;
            });
          },
        ),

        const SizedBox(height: 14),

        DropdownButtonFormField<int>(
          initialValue: _digits,
          decoration: const InputDecoration(
            labelText: 'Digits',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(
              value: 6,
              child: Text('6 digits'),
            ),
            DropdownMenuItem(
              value: 8,
              child: Text('8 digits'),
            ),
          ],
          onChanged: _saving
              ? null
              : (value) {
            if (value == null) {
              return;
            }

            setState(() {
              _digits = value;
            });
          },
        ),

        const SizedBox(height: 14),

        InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Period',
            border: OutlineInputBorder(),
          ),
          child: Text(
            '$_period seconds',
          ),
        ),

        const SizedBox(height: 28),

        SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton(
            onPressed: _saving ? null : _saveAccount,
            child: _saving
                ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
                : const Text('Save account'),
          ),
        ),
      ],
    );
  }
}