import 'totp_account.dart';

class Vault {
  final int version;
  final List<TotpAccount> accounts;

  const Vault({
    this.version = 1,
    this.accounts = const [],
  });

  Vault copyWith({
    int? version,
    List<TotpAccount>? accounts,
  }) {
    return Vault(
      version: version ?? this.version,
      accounts: List.unmodifiable(
        accounts ?? this.accounts,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'accounts': accounts
          .map(
            (account) => account.toJson(),
      )
          .toList(),
    };
  }

  factory Vault.fromJson(
      Map<String, dynamic> json,
      ) {
    final rawAccounts =
    json['accounts'];

    final accounts = <TotpAccount>[];

    if (rawAccounts is List) {
      for (final item in rawAccounts) {
        if (item is Map) {
          accounts.add(
            TotpAccount.fromJson(
              Map<String, dynamic>.from(item),
            ),
          );
        }
      }
    }

    return Vault(
      version:
      (json['version'] as num?)?.toInt() ??
          1,
      accounts: List.unmodifiable(
        accounts,
      ),
    );
  }
}