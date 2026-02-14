class NotificationPreferences {
  final String userId;
  final bool streamingAlerts;
  final bool talentReleases;
  final bool newEpisodes;
  final bool social;
  final bool marketing;
  final bool quietHoursEnabled;
  final String quietHoursStart; // HH:mm (24h)
  final String quietHoursEnd; // HH:mm (24h)
  final String timezone;

  const NotificationPreferences({
    required this.userId,
    this.streamingAlerts = true,
    this.talentReleases = true,
    this.newEpisodes = true,
    this.social = true,
    this.marketing = false,
    this.quietHoursEnabled = false,
    this.quietHoursStart = '22:00',
    this.quietHoursEnd = '08:00',
    this.timezone = 'UTC',
  });

  static NotificationPreferences defaults(String userId) {
    return NotificationPreferences(userId: userId);
  }

  NotificationPreferences copyWith({
    String? userId,
    bool? streamingAlerts,
    bool? talentReleases,
    bool? newEpisodes,
    bool? social,
    bool? marketing,
    bool? quietHoursEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
    String? timezone,
  }) {
    return NotificationPreferences(
      userId: userId ?? this.userId,
      streamingAlerts: streamingAlerts ?? this.streamingAlerts,
      talentReleases: talentReleases ?? this.talentReleases,
      newEpisodes: newEpisodes ?? this.newEpisodes,
      social: social ?? this.social,
      marketing: marketing ?? this.marketing,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      timezone: timezone ?? this.timezone,
    );
  }

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      userId: json['user_id'] as String,
      streamingAlerts: json['streaming_alerts'] ?? true,
      talentReleases: json['talent_releases'] ?? true,
      newEpisodes: json['new_episodes'] ?? true,
      social: json['social'] ?? true,
      marketing: json['marketing'] ?? false,
      quietHoursEnabled: json['quiet_hours_enabled'] ?? false,
      quietHoursStart: json['quiet_hours_start'] ?? '22:00',
      quietHoursEnd: json['quiet_hours_end'] ?? '08:00',
      timezone: json['timezone'] ?? 'UTC',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'streaming_alerts': streamingAlerts,
      'talent_releases': talentReleases,
      'new_episodes': newEpisodes,
      'social': social,
      'marketing': marketing,
      'quiet_hours_enabled': quietHoursEnabled,
      'quiet_hours_start': quietHoursStart,
      'quiet_hours_end': quietHoursEnd,
      'timezone': timezone,
    };
  }
}
