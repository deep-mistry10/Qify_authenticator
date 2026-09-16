extension StringValidation on String {
  bool get isValidEmail => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(trim());
  String get normalizedEmail => trim().toLowerCase();
}
