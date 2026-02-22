/// Models for the Watch Party Sync feature.
/// Covers watch_parties, watch_party_members, and watch_party_progress tables.

// ---------------------------------------------------------------------------
// WatchParty — maps watch_parties row
// ---------------------------------------------------------------------------
class WatchParty {
  final String id;
  final String name;
  final int tmdbId;
  final String mediaType; // 'tv' | 'movie'
  final String createdBy;
  final DateTime createdAt;

  /// Populated by fetchUserParties() after a secondary users query.
  /// Null when constructed directly from JSON (e.g. createParty).
  final String? creatorUsername;

  const WatchParty({
    required this.id,
    required this.name,
    required this.tmdbId,
    required this.mediaType,
    required this.createdBy,
    required this.createdAt,
    this.creatorUsername,
  });

  factory WatchParty.fromJson(Map<String, dynamic> json) {
    return WatchParty(
      id: json['id'] as String,
      name: json['name'] as String,
      tmdbId: json['tmdb_id'] as int,
      mediaType: json['media_type'] as String,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  WatchParty copyWith({String? creatorUsername}) {
    return WatchParty(
      id: id,
      name: name,
      tmdbId: tmdbId,
      mediaType: mediaType,
      createdBy: createdBy,
      createdAt: createdAt,
      creatorUsername: creatorUsername ?? this.creatorUsername,
    );
  }
}

// ---------------------------------------------------------------------------
// WatchPartyMemberStatus enum
// ---------------------------------------------------------------------------
enum WatchPartyMemberStatus { pending, active, left }

extension WatchPartyMemberStatusX on WatchPartyMemberStatus {
  String get value => name;

  static WatchPartyMemberStatus fromString(String v) =>
      WatchPartyMemberStatus.values.firstWhere(
        (s) => s.name == v,
        orElse: () => WatchPartyMemberStatus.pending,
      );
}

// ---------------------------------------------------------------------------
// WatchPartyMember — maps watch_party_members row
// ---------------------------------------------------------------------------
class WatchPartyMember {
  final String id;
  final String partyId;
  final String userId;
  final WatchPartyMemberStatus status;
  final DateTime? joinedAt;
  final DateTime createdAt;

  const WatchPartyMember({
    required this.id,
    required this.partyId,
    required this.userId,
    required this.status,
    this.joinedAt,
    required this.createdAt,
  });

  factory WatchPartyMember.fromJson(Map<String, dynamic> json) {
    return WatchPartyMember(
      id: json['id'] as String,
      partyId: json['party_id'] as String,
      userId: json['user_id'] as String,
      status: WatchPartyMemberStatusX.fromString(json['status'] as String),
      joinedAt: json['joined_at'] != null
          ? DateTime.parse(json['joined_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

// ---------------------------------------------------------------------------
// EpisodeProgress — one row from watch_party_progress
// ---------------------------------------------------------------------------
class EpisodeProgress {
  final int seasonNumber;  // 0 for movies
  final int episodeNumber; // 0 for movies
  final int progressPercent; // 0–100
  final bool watched;
  final DateTime updatedAt;

  const EpisodeProgress({
    required this.seasonNumber,
    required this.episodeNumber,
    required this.progressPercent,
    required this.watched,
    required this.updatedAt,
  });

  bool get isComplete => progressPercent == 100;
  bool get isPartial => progressPercent > 0 && progressPercent < 100;
  bool get isNotStarted => progressPercent == 0;

  factory EpisodeProgress.fromJson(Map<String, dynamic> json) {
    return EpisodeProgress(
      seasonNumber: json['season_number'] as int,
      episodeNumber: json['episode_number'] as int,
      progressPercent: json['progress_percent'] as int,
      watched: json['watched'] as bool,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  EpisodeProgress copyWith({int? progressPercent, bool? watched, DateTime? updatedAt}) {
    return EpisodeProgress(
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
      progressPercent: progressPercent ?? this.progressPercent,
      watched: watched ?? this.watched,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// ---------------------------------------------------------------------------
// WatchPartyMemberProgress — aggregated view: one member's full progress
// ---------------------------------------------------------------------------
class WatchPartyMemberProgress {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final List<EpisodeProgress> episodes;

  const WatchPartyMemberProgress({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.episodes,
  });

  bool get isAllWatched => episodes.isNotEmpty && episodes.every((e) => e.watched);
  bool get hasStarted => episodes.any((e) => !e.isNotStarted);

  /// Latest updatedAt across all episodes.
  DateTime? get lastUpdated => episodes.isEmpty
      ? null
      : episodes.map((e) => e.updatedAt).reduce((a, b) => a.isAfter(b) ? a : b);

  WatchPartyMemberProgress copyWith({List<EpisodeProgress>? episodes}) {
    return WatchPartyMemberProgress(
      userId: userId,
      displayName: displayName,
      avatarUrl: avatarUrl,
      episodes: episodes ?? this.episodes,
    );
  }
}
