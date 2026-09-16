class QrScannerService {
  bool isTotpPayload(String? value) {
    return value != null && value.trim().toLowerCase().startsWith('otpauth://totp/');
  }
}
