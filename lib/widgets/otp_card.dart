import 'package:flutter/material.dart';

import '../models/totp_account.dart';
import '../services/totp_service.dart';
import 'otp_countdown.dart';

class OtpCard extends StatelessWidget {
  final TotpAccount account;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const OtpCard({super.key, required this.account, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final code = TotpService().generate(
      secret: account.secret,
      digits: account.digits,
      period: account.period,
      algorithm: account.algorithm,
    );

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 10, 16),
          child: Row(
            children: [
              CircleAvatar(child: Text(account.issuer.isEmpty ? '?' : account.issuer.substring(0, 1).toUpperCase())),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(account.issuer, style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(account.accountName, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 10),
                    Text(code, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: 2.5)),
                    const SizedBox(height: 8),
                    OtpCountdown(period: account.period),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (_) => const [PopupMenuItem(value: 'delete', child: Text('Delete'))],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
