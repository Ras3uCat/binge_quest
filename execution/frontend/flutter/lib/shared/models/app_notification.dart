enum NotificationType {
  streamingAlerts,
  talentReleases,
  newEpisodes,
  social,
  marketing,
  system;

  static const _dbMap = {
    'streaming_alerts': NotificationType.streamingAlerts,
    'talent_releases': NotificationType.talentReleases,
    'new_episodes': NotificationType.newEpisodes,
    'social': NotificationType.social,
    'marketing': NotificationType.marketing,
  };

  static const _toDbMap = {
    NotificationType.streamingAlerts: 'streaming_alerts',
    NotificationType.talentReleases: 'talent_releases',
    NotificationType.newEpisodes: 'new_episodes',
    NotificationType.social: 'social',
    NotificationType.marketing: 'marketing',
    NotificationType.system: 'system',
  };

  String toJson() => _toDbMap[this] ?? 'system';
  static NotificationType fromJson(String json) =>
      _dbMap[json] ?? NotificationType.system;
}

class AppNotification {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final String? imageUrl;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.imageUrl,
    this.data,
    this.isRead = false,
    required this.createdAt,
    this.readAt,
  });

  bool get hasDeepLink => data != null && data!.isNotEmpty;

  AppNotification copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? body,
    String? imageUrl,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      imageUrl: imageUrl ?? this.imageUrl,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: NotificationType.fromJson(json['category'] as String),
      title: json['title'] as String,
      body: json['body'] as String,
      imageUrl: json['image_url'] as String?,
      data: json['data'] as Map<String, dynamic>?,
      isRead: json['read_at'] != null,
      createdAt: DateTime.parse(json['created_at'] as String),
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'category': type.toJson(),
      'title': title,
      'body': body,
      'image_url': imageUrl,
      'data': data,
      'created_at': createdAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
    };
  }
}
