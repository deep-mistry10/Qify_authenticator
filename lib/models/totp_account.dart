class TotpAccount {
  final String id;
  final String issuer;
  final String accountName;
  final String secret;
  final String algorithm;
  final int digits;
  final int period;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int sortOrder;

  const TotpAccount({
    required this.id,
    required this.issuer,
    required this.accountName,
    required this.secret,
    this.algorithm = 'SHA1',
    this.digits = 6,
    this.period = 30,
    required this.createdAt,
    required this.updatedAt,
    required this.sortOrder,
  });

  TotpAccount copyWith({
    String? issuer,
    String? accountName,
    String? secret,
    String? algorithm,
    int? digits,
    int? period,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? sortOrder,
  }) {
    return TotpAccount(
      id: id,
      issuer: issuer ?? this.issuer,
      accountName: accountName ?? this.accountName,
      secret: secret ?? this.secret,
      algorithm: algorithm ?? this.algorithm,
      digits: digits ?? this.digits,
      period: period ?? this.period,
      createdAt: createdAt ?? this.createdAt,
      updatedAt:
      updatedAt ?? DateTime.now().toUtc(),
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'issuer': issuer,
      'accountName': accountName,
      'secret': secret,
      'algorithm': algorithm,
      'digits': digits,
      'period': period,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'sortOrder': sortOrder,
    };
  }

  factory TotpAccount.fromJson(
      Map<String, dynamic> json,
      ) {
    final createdAt =
        DateTime.tryParse(
          json['createdAt']?.toString() ?? '',
        ) ??
            DateTime.now().toUtc();

    final updatedAt =
        DateTime.tryParse(
          json['updatedAt']?.toString() ?? '',
        ) ??
            createdAt;

    return TotpAccount(
      id: json['id']?.toString() ?? '',
      issuer:
      json['issuer']?.toString().trim() ?? '',
      accountName:
      json['accountName']?.toString().trim() ??
          '',
      secret: json['secret']
          ?.toString()
          .replaceAll(
        RegExp(r'\s+'),
        '',
      )
          .toUpperCase() ??
          '',
      algorithm:
      json['algorithm']?.toString().toUpperCase() ??
          'SHA1',
      digits:
      (json['digits'] as num?)?.toInt() ??
          6,
      period:
      (json['period'] as num?)?.toInt() ??
          30,
      createdAt: createdAt.toUtc(),
      updatedAt: updatedAt.toUtc(),
      sortOrder:
      (json['sortOrder'] as num?)?.toInt() ??
          0,
    );
  }
}