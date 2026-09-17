import 'totp_account.dart';

class Vault {
  final int version;
  final List<TotpAccount> accounts;

  const Vault({this.version = 1, this.accounts = const []});

  Vault copyWith({int? version, List<TotpAccount>? accounts}) {
    return Vault(
      version: version ?? this.version,
      accounts: List.unmodifiable(accounts ?? this.accounts),
    );
  }

  Map<String, dynamic> toJson() => {
        'version': version,
        'accounts': accounts.map((a) => a.toJson()).toList(),
      };

  factory Vault.fromJson(Map<String, dynamic> json) {
    final raw = (json['accounts'] as List? ?? const []);
    return Vault(
      version: (json['version'] as num? ?? 1).toInt(),
      accounts: raw
          .whereType<Map>()
          .map((e) => TotpAccount.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}
