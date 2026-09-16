class VaultMetadata {
  final int vaultVersion;
  final String updatedAt;
  final String deviceId;

  const VaultMetadata({
    required this.vaultVersion,
    required this.updatedAt,
    required this.deviceId,
  });

  Map<String, dynamic> toJson() => {
        'vaultVersion': vaultVersion,
        'updatedAt': updatedAt,
        'deviceId': deviceId,
      };
}
