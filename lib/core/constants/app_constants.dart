import 'package:flutter/material.dart';

class AppConstants {
  static const appName = 'Qify Authenticator';
  static const defaultTotpPeriod = 30;
  static const defaultTotpDigits = 6;
  static const defaultTotpAlgorithm = 'SHA1';

  // Reference design palette sampled from the supplied Qify UI reference.
  static const primary = Color(0xFF0B6B57);
  static const background = Color(0xFFF3F5F2);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSoft = Color(0xFFF8FAF8);
  static const border = Color(0xFFD9E1DD);
  static const textPrimary = Color(0xFF101713);
  static const textSecondary = Color(0xFF61706A);
  static const textMuted = Color(0xFF7A8781);
}
