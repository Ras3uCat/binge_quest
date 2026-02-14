/// Watchlist model representing a user's content list.
class Watchlist {
  final String id;
  final String userId;
  final String name;
  final bool isDefault;
  final DateTime createdAt;

  const Watchlist({
    required this.id,
    required this.userId,
    required this.name,
    required this.isDefault,
    required this.createdAt,
  });

  factory Watchlist.fromJson(Map<String, dynamic> json) {
    return Watchlist(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      isDefault: json['is_default'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'is_default': isDefault,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Creates a new watchlist for insertion (without id, let DB generate it).
  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'name': name,
      'is_default': isDefault,
    };
  }

  Watchlist copyWith({
    String? id,
    String? userId,
    String? name,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return Watchlist(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Watchlist && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
