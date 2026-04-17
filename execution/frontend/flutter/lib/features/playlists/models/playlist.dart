class PlaylistItem {
  final String id;
  final String playlistId;
  final int tmdbId;
  final String mediaType;
  final String title;
  final String? posterPath;
  final int position;
  final String? note;
  final DateTime addedAt;

  const PlaylistItem({
    required this.id,
    required this.playlistId,
    required this.tmdbId,
    required this.mediaType,
    required this.title,
    this.posterPath,
    required this.position,
    this.note,
    required this.addedAt,
  });

  factory PlaylistItem.fromJson(Map<String, dynamic> json) {
    return PlaylistItem(
      id: json['id'] as String,
      playlistId: json['playlist_id'] as String,
      tmdbId: json['tmdb_id'] as int,
      mediaType: json['media_type'] as String,
      title: json['title'] as String,
      posterPath: json['poster_path'] as String?,
      position: json['position'] as int? ?? 0,
      note: json['note'] as String?,
      addedAt: DateTime.parse(json['added_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'playlist_id': playlistId,
    'tmdb_id': tmdbId,
    'media_type': mediaType,
    'title': title,
    'poster_path': posterPath,
    'position': position,
    'note': note,
    'added_at': addedAt.toIso8601String(),
  };
}

class Playlist {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final bool isPublic;
  final bool isRanked;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<PlaylistItem> items;

  const Playlist({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.isPublic,
    this.isRanked = false,
    required this.createdAt,
    required this.updatedAt,
    this.items = const [],
  });

  String? get coverPosterPath => items.isNotEmpty ? items.first.posterPath : null;
  int get itemCount => items.length;

  factory Playlist.fromJson(Map<String, dynamic> json) {
    final rawItems = json['playlist_items'] as List<dynamic>?;
    final parsedItems = rawItems != null
        ? rawItems.map((e) => PlaylistItem.fromJson(e as Map<String, dynamic>)).toList()
        : <PlaylistItem>[];
    return Playlist(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      isPublic: json['is_public'] as bool? ?? true,
      isRanked: json['is_ranked'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      items: parsedItems,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'name': name,
    'description': description,
    'is_public': isPublic,
    'is_ranked': isRanked,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'playlist_items': items.map((i) => i.toJson()).toList(),
  };

  Playlist copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    bool? isPublic,
    bool? isRanked,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<PlaylistItem>? items,
  }) {
    return Playlist(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      isPublic: isPublic ?? this.isPublic,
      isRanked: isRanked ?? this.isRanked,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
    );
  }
}
