/// Archetype reference data (seeded, read-only for clients).
class Archetype {
  final String id;
  final String displayName;
  final String tagline;
  final String description;
  final String iconName;
  final String colorHex;
  final int sortOrder;

  const Archetype({
    required this.id,
    required this.displayName,
    required this.tagline,
    required this.description,
    required this.iconName,
    required this.colorHex,
    required this.sortOrder,
  });

  factory Archetype.fromJson(Map<String, dynamic> json) => Archetype(
        id: json['id'] as String,
        displayName: json['display_name'] as String,
        tagline: json['tagline'] as String,
        description: json['description'] as String,
        iconName: json['icon_name'] as String,
        colorHex: json['color_hex'] as String,
        sortOrder: json['sort_order'] as int,
      );
}

/// A single row from user_archetypes — one of 12 scores per compute run.
/// The joined [archetype] is present when fetched with `archetypes(*)`.
class UserArchetype {
  final String id;
  final String userId;
  final String archetypeId;
  final double score;
  final int rank;
  final DateTime computedAt;
  final Map<String, dynamic>? metadata;
  final Archetype? archetype;

  const UserArchetype({
    required this.id,
    required this.userId,
    required this.archetypeId,
    required this.score,
    required this.rank,
    required this.computedAt,
    this.metadata,
    this.archetype,
  });

  /// Lightweight instance for display-only contexts (e.g. friend list badge).
  /// No score/rank data is needed — only the reference [archetype] for rendering.
  factory UserArchetype.displayOnly({
    required String userId,
    required Archetype archetype,
  }) =>
      UserArchetype(
        id: '',
        userId: userId,
        archetypeId: archetype.id,
        score: 0,
        rank: 1,
        computedAt: DateTime.fromMillisecondsSinceEpoch(0),
        archetype: archetype,
      );

  factory UserArchetype.fromJson(Map<String, dynamic> json) => UserArchetype(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        archetypeId: json['archetype_id'] as String,
        score: (json['score'] as num).toDouble(),
        rank: json['rank'] as int,
        computedAt: DateTime.parse(json['computed_at'] as String),
        metadata: json['metadata'] as Map<String, dynamic>?,
        archetype: json['archetypes'] != null
            ? Archetype.fromJson(json['archetypes'] as Map<String, dynamic>)
            : null,
      );

  /// Display name, resolving Genre Loyalist's dominant genre from metadata.
  /// Genre label mapping is handled by the widget layer if a lookup is needed;
  /// this returns the base archetype name for non-genre archetypes.
  String get resolvedDisplayName => archetype?.displayName ?? archetypeId;

  /// Dominant genre ID stored for genre_loyalist archetype (may be null).
  int? get dominantGenreId {
    if (archetypeId != 'genre_loyalist') return null;
    final raw = metadata?['dominant_genre_id'];
    if (raw == null) return null;
    return raw is int ? raw : int.tryParse(raw.toString());
  }
}
