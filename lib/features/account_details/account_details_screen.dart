import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/totp_account.dart';
import '../../services/totp_service.dart';

class AccountDetailsScreen extends StatefulWidget {
  final TotpAccount account;

  const AccountDetailsScreen({
    super.key,
    required this.account,
  });

  @override
  State<AccountDetailsScreen> createState() => _AccountDetailsScreenState();
}

class _AccountDetailsScreenState extends State<AccountDetailsScreen> {
  final TotpService _totp = TotpService();
  Timer? _timer;
  String _code = '';
  int _remaining = 30;

  @override
  void initState() {
    super.initState();
    _update();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _update(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _update() {
    if (!mounted) return;
    final now = DateTime.now();
    setState(() {
      _code = _totp.generate(
        secret: widget.account.secret,
        digits: widget.account.digits,
        period: widget.account.period,
        algorithm: widget.account.algorithm,
        now: now,
      );
      _remaining = _totp.remainingSeconds(
        period: widget.account.period,
        now: now,
      );
    });
  }

  Future<void> _copy() async {
    await Clipboard.setData(
      ClipboardData(text: _code),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Code copied.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final period = widget.account.period;
    final progress =
        period == 0 ? 0.0 : _remaining / period;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            widget.account.issuer,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            widget.account.accountName,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 36),
          Center(
            child: Text(
              _code.replaceFirstMapped(
                RegExp(r'^(\d{3})(\d{3})$'),
                (m) => '${m[1]} ${m[2]}',
              ),
              style: const TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: SizedBox(
              width: 92,
              height: 92,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 7,
                  ),
                  Text(
                    '$_remaining s',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: _copy,
              icon: const Icon(Icons.copy_outlined),
              label: const Text('Copy code'),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Algorithm'),
                  trailing: Text(widget.account.algorithm),
                ),
                ListTile(
                  title: const Text('Digits'),
                  trailing: Text('${widget.account.digits}'),
                ),
                ListTile(
                  title: const Text('Period'),
                  trailing: Text('${widget.account.period} seconds'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
