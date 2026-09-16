import 'package:flutter/material.dart';

import '../models/totp_account.dart';

class AccountTile
    extends StatelessWidget {
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
  Widget build(
      BuildContext context,
      ) {
    final issuer =
    account.issuer.trim();

    final accountName =
    account.accountName.trim();

    final initial = issuer.isEmpty
        ? '?'
        : issuer
        .characters
        .first
        .toUpperCase();

    return Card(
      margin:
      const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 5,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius:
        BorderRadius.circular(16),
        child: Padding(
          padding:
          const EdgeInsets.fromLTRB(
            14,
            14,
            8,
            14,
          ),
          child: Row(
            crossAxisAlignment:
            CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 24,
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      issuer.isEmpty
                          ? 'Unknown service'
                          : issuer,
                      maxLines: 1,
                      overflow:
                      TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight:
                        FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    Text(
                      accountName.isEmpty
                          ? 'No account name'
                          : accountName,
                      maxLines: 2,
                      overflow:
                      TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Text(
                      'Delete account',
                    ),
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