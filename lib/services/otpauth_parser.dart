class ParsedOtpAuth {
  final String issuer;
  final String accountName;
  final String secret;
  final String algorithm;
  final int digits;
  final int period;

  const ParsedOtpAuth({
    required this.issuer,
    required this.accountName,
    required this.secret,
    required this.algorithm,
    required this.digits,
    required this.period,
  });
}

class OtpAuthParser {
  static ParsedOtpAuth parse(
      String raw,
      ) {
    final uri = Uri.tryParse(
      raw.trim(),
    );

    if (uri == null ||
        uri.scheme.toLowerCase() !=
            'otpauth') {
      throw const FormatException(
        'Invalid otpauth URI',
      );
    }

    if (uri.host.toLowerCase() !=
        'totp') {
      throw const FormatException(
        'Only TOTP QR codes are supported',
      );
    }

    final secret =
    uri.queryParameters['secret'];

    if (secret == null ||
        secret.trim().isEmpty) {
      throw const FormatException(
        'Missing TOTP secret',
      );
    }

    final label = uri.pathSegments.isEmpty
        ? ''
        : Uri.decodeComponent(
      uri.pathSegments.join('/'),
    ).trim();

    final issuerParam =
        uri.queryParameters['issuer']
            ?.trim() ??
            '';

    var issuer = issuerParam;
    var account = label;

    final colon = label.indexOf(':');

    if (colon >= 0) {
      final labelIssuer =
      label.substring(
        0,
        colon,
      ).trim();

      final labelAccount =
      label.substring(
        colon + 1,
      ).trim();

      if (issuer.isEmpty) {
        issuer = labelIssuer;
      }

      account = labelAccount;
    }

    final algorithm =
    (uri.queryParameters['algorithm'] ??
        'SHA1')
        .toUpperCase();

    final digits =
        int.tryParse(
          uri.queryParameters['digits'] ??
              '6',
        ) ??
            6;

    final period =
        int.tryParse(
          uri.queryParameters['period'] ??
              '30',
        ) ??
            30;

    if (digits != 6 &&
        digits != 8) {
      throw const FormatException(
        'Unsupported OTP digits',
      );
    }

    if (period <= 0) {
      throw const FormatException(
        'Invalid OTP period',
      );
    }

    const supportedAlgorithms = {
      'SHA1',
      'SHA-1',
      'SHA256',
      'SHA-256',
      'SHA512',
      'SHA-512',
    };

    if (!supportedAlgorithms.contains(
      algorithm,
    )) {
      throw const FormatException(
        'Unsupported OTP algorithm',
      );
    }

    return ParsedOtpAuth(
      issuer: issuer.isEmpty
          ? 'Unknown'
          : issuer,
      accountName: account.isEmpty
          ? 'Unknown account'
          : account,
      secret: secret
          .replaceAll(
        RegExp(r'\s+'),
        '',
      )
          .toUpperCase(),
      algorithm: algorithm
          .replaceAll(
        '-',
        '',
      ),
      digits: digits,
      period: period,
    );
  }

  static bool looksLikeOtpAuth(
      String value,
      ) {
    return value
        .trim()
        .toLowerCase()
        .startsWith(
      'otpauth://totp/',
    );
  }

  static Map<String, String>
  parseAdditionalParameters(
      String raw,
      ) {
    final uri = Uri.tryParse(
      raw.trim(),
    );

    if (uri == null) {
      return const {};
    }

    return Map.unmodifiable(
      uri.queryParameters,
    );
  }
}