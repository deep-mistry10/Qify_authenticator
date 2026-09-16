import 'dart:math' as math;
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;

class TotpService {
  String generate({
    required String secret,
    int digits = 6,
    int period = 30,
    String algorithm = 'SHA1',
    DateTime? now,
  }) {
    if (digits != 6 && digits != 8) {
      throw ArgumentError(
        'Digits must be 6 or 8',
      );
    }

    if (period <= 0) {
      throw ArgumentError(
        'Period must be positive',
      );
    }

    final key = _decodeBase32(secret);

    final timestamp =
        (now ?? DateTime.now())
            .millisecondsSinceEpoch ~/
            1000;

    final counter = timestamp ~/ period;

    final counterBytes = Uint8List(8);

    var value = counter;

    for (var i = 7; i >= 0; i--) {
      counterBytes[i] = value & 0xff;
      value >>= 8;
    }

    final normalizedAlgorithm =
    algorithm
        .toUpperCase()
        .replaceAll('-', '');

    final List<int> digest;

    switch (normalizedAlgorithm) {
      case 'SHA256':
        digest = crypto.Hmac(
          crypto.sha256,
          key,
        ).convert(counterBytes).bytes;
        break;

      case 'SHA512':
        digest = crypto.Hmac(
          crypto.sha512,
          key,
        ).convert(counterBytes).bytes;
        break;

      case 'SHA1':
      default:
        digest = crypto.Hmac(
          crypto.sha1,
          key,
        ).convert(counterBytes).bytes;
        break;
    }

    final offset =
    digest[digest.length - 1] & 0x0f;

    final binary =
    ((digest[offset] & 0x7f) << 24) |
    ((digest[offset + 1] & 0xff) << 16) |
    ((digest[offset + 2] & 0xff) << 8) |
    (digest[offset + 3] & 0xff);

    final modulo =
    math.pow(10, digits).toInt();

    return (binary % modulo)
        .toString()
        .padLeft(
      digits,
      '0',
    );
  }

  int remainingSeconds({
    int period = 30,
    DateTime? now,
  }) {
    if (period <= 0) {
      throw ArgumentError(
        'Period must be positive',
      );
    }

    final timestamp =
        (now ?? DateTime.now())
            .millisecondsSinceEpoch ~/
            1000;

    return period - (timestamp % period);
  }

  List<int> _decodeBase32(
      String input,
      ) {
    final cleaned = input
        .replaceAll(
      RegExp(r'\s+'),
      '',
    )
        .replaceAll(
      '=',
      '',
    )
        .toUpperCase();

    if (cleaned.isEmpty) {
      throw const FormatException(
        'Empty TOTP secret',
      );
    }

    const alphabet =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

    var buffer = 0;
    var bitsLeft = 0;

    final output = <int>[];

    for (final char in cleaned.split('')) {
      final index = alphabet.indexOf(char);

      if (index < 0) {
        throw const FormatException(
          'Invalid Base32 secret',
        );
      }

      buffer =
      (buffer << 5) | index;

      bitsLeft += 5;

      if (bitsLeft >= 8) {
        bitsLeft -= 8;

        output.add(
          (buffer >> bitsLeft) & 0xff,
        );
      }
    }

    if (output.isEmpty) {
      throw const FormatException(
        'Empty TOTP secret',
      );
    }

    return output;
  }
}