/// Video (trailer, teaser, etc.) from TMDB.
class TmdbVideo {
  final String id;
  final String key;
  final String name;
  final String site;
  final String type;
  final bool official;
  final int size;
  final DateTime? publishedAt;

  TmdbVideo({
    required this.id,
    required this.key,
    required this.name,
    required this.site,
    required this.type,
    required this.official,
    required this.size,
    this.publishedAt,
  });

  bool get isYouTube => site.toLowerCase() == 'youtube';

  bool get isTrailer => type.toLowerCase() == 'trailer';

  bool get isTeaser => type.toLowerCase() == 'teaser';

  bool get isYouTubeTrailer => isYouTube && isTrailer;

  String get youtubeUrl => 'https://www.youtube.com/watch?v=$key';

  String get youtubeThumbnail => 'https://img.youtube.com/vi/$key/mqdefault.jpg';

  factory TmdbVideo.fromJson(Map<String, dynamic> json) {
    DateTime? publishedAt;
    if (json['published_at'] != null) {
      publishedAt = DateTime.tryParse(json['published_at'] as String);
    }

    return TmdbVideo(
      id: json['id'] as String,
      key: json['key'] as String? ?? '',
      name: json['name'] as String? ?? 'Video',
      site: json['site'] as String? ?? '',
      type: json['type'] as String? ?? '',
      official: json['official'] as bool? ?? false,
      size: json['size'] as int? ?? 0,
      publishedAt: publishedAt,
    );
  }
}

/// Helper class to parse and manage video lists.
class TmdbVideoList {
  final List<TmdbVideo> videos;

  TmdbVideoList({required this.videos});

  /// Get the best trailer (official YouTube trailer preferred).
  TmdbVideo? get bestTrailer {
    // First try official YouTube trailers
    final officialTrailers = videos
        .where((v) => v.isYouTubeTrailer && v.official)
        .toList();
    if (officialTrailers.isNotEmpty) {
      // Prefer higher resolution
      officialTrailers.sort((a, b) => b.size.compareTo(a.size));
      return officialTrailers.first;
    }

    // Then try any YouTube trailer
    final trailers = videos.where((v) => v.isYouTubeTrailer).toList();
    if (trailers.isNotEmpty) {
      trailers.sort((a, b) => b.size.compareTo(a.size));
      return trailers.first;
    }

    // Then try YouTube teasers
    final teasers = videos
        .where((v) => v.isYouTube && v.isTeaser)
        .toList();
    if (teasers.isNotEmpty) {
      teasers.sort((a, b) => b.size.compareTo(a.size));
      return teasers.first;
    }

    // Finally, any YouTube video
    final youtubeVideos = videos.where((v) => v.isYouTube).toList();
    if (youtubeVideos.isNotEmpty) {
      return youtubeVideos.first;
    }

    return null;
  }

  /// Get all YouTube trailers.
  List<TmdbVideo> get trailers =>
      videos.where((v) => v.isYouTubeTrailer).toList();

  /// Get all YouTube videos.
  List<TmdbVideo> get youtubeVideos =>
      videos.where((v) => v.isYouTube).toList();

  factory TmdbVideoList.fromJson(Map<String, dynamic> json) {
    final results = json['results'] as List? ?? [];
    return TmdbVideoList(
      videos: results.map((v) => TmdbVideo.fromJson(v)).toList(),
    );
  }
}
