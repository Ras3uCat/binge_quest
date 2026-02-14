class UserStreamingPreference {
  final String id;
  final String userId;
  final int providerId;
  final String providerName;
  final String? providerLogoPath;
  final bool notifyEnabled;
  final bool includeRentBuy;
  final DateTime createdAt;

  const UserStreamingPreference({
    required this.id,
    required this.userId,
    required this.providerId,
    required this.providerName,
    this.providerLogoPath,
    this.notifyEnabled = true,
    this.includeRentBuy = false,
    required this.createdAt,
  });

  factory UserStreamingPreference.fromJson(Map<String, dynamic> json) {
    return UserStreamingPreference(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      providerId: json['provider_id'] as int,
      providerName: json['provider_name'] as String,
      providerLogoPath: json['provider_logo_path'] as String?,
      notifyEnabled: json['notify_enabled'] as bool? ?? true,
      includeRentBuy: json['include_rent_buy'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'provider_id': providerId,
        'provider_name': providerName,
        'provider_logo_path': providerLogoPath,
        'notify_enabled': notifyEnabled,
        'include_rent_buy': includeRentBuy,
        'created_at': createdAt.toIso8601String(),
      };
}
