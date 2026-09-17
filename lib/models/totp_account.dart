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
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now().toUtc(),
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toJson() => {
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

  factory TotpAccount.fromJson(Map<String, dynamic> json) {
    return TotpAccount(
      id: json['id'] as String,
      issuer: (json['issuer'] as String? ?? '').trim(),
      accountName: (json['accountName'] as String? ?? '').trim(),
      secret: (json['secret'] as String).replaceAll(' ', '').toUpperCase(),
      algorithm: (json['algorithm'] as String? ?? 'SHA1').toUpperCase(),
      digits: (json['digits'] as num? ?? 6).toInt(),
      period: (json['period'] as num? ?? 30).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String).toUtc(),
      updatedAt: DateTime.parse(json['updatedAt'] as String).toUtc(),
      sortOrder: (json['sortOrder'] as num? ?? 0).toInt(),
    );
  }
}
