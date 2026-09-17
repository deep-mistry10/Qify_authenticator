import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/service_logo.dart';
import '../models/totp_account.dart';

class AccountTile extends StatelessWidget {
  final TotpAccount account;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const AccountTile({
    super.key,
    required this.account,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final issuer = account.issuer.trim();
    final accountName = account.accountName.trim();

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          child: Row(
            children: [
              ServiceLogo.avatar(issuer),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      issuer.isEmpty ? 'Unknown service' : issuer,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppConstants.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      accountName.isEmpty ? 'Account' : accountName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppConstants.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete account'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
