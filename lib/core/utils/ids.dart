import 'dart:convert';
import 'dart:math';

String createId() {
  final random = Random.secure();

  final bytes = List<int>.generate(
    16,
        (_) => random.nextInt(256),
  );

  return base64UrlEncode(bytes)
      .replaceAll('=', '');
}