/// Watch provider result from TMDB (streaming services).
class TmdbWatchProviderResult {
  final String? link;
  final List<TmdbWatchProvider> flatrate;
  final List<TmdbWatchProvider> rent;
  final List<TmdbWatchProvider> buy;

  TmdbWatchProviderResult({
    this.link,
    this.flatrate = const [],
    this.rent = const [],
    this.buy = const [],
  });

  bool get hasAnyProvider =>
      flatrate.isNotEmpty || rent.isNotEmpty || buy.isNotEmpty;

  bool get hasStreaming => flatrate.isNotEmpty;

  bool get hasRent => rent.isNotEmpty;

  bool get hasBuy => buy.isNotEmpty;

  /// Get all unique providers across all categories.
  List<TmdbWatchProvider> get allProviders {
    final seen = <int>{};
    final providers = <TmdbWatchProvider>[];
    for (final p in [...flatrate, ...rent, ...buy]) {
      if (!seen.contains(p.providerId)) {
        seen.add(p.providerId);
        providers.add(p);
      }
    }
    return providers;
  }

  factory TmdbWatchProviderResult.fromJson(Map<String, dynamic> json) {
    return TmdbWatchProviderResult(
      link: json['link'] as String?,
      flatrate: (json['flatrate'] as List?)
              ?.map((p) => TmdbWatchProvider.fromJson(p))
              .toList() ??
          [],
      rent: (json['rent'] as List?)
              ?.map((p) => TmdbWatchProvider.fromJson(p))
              .toList() ??
          [],
      buy: (json['buy'] as List?)
              ?.map((p) => TmdbWatchProvider.fromJson(p))
              .toList() ??
          [],
    );
  }

  /// Empty result for when no providers are available.
  factory TmdbWatchProviderResult.empty() {
    return TmdbWatchProviderResult();
  }
}

/// Individual watch provider (e.g., Netflix, Hulu).
class TmdbWatchProvider {
  final int providerId;
  final String providerName;
  final String? logoPath;
  final int displayPriority;

  TmdbWatchProvider({
    required this.providerId,
    required this.providerName,
    this.logoPath,
    required this.displayPriority,
  });

  String get logoUrl {
    if (logoPath == null || logoPath!.isEmpty) return '';
    return 'https://image.tmdb.org/t/p/w92$logoPath';
  }

  factory TmdbWatchProvider.fromJson(Map<String, dynamic> json) {
    return TmdbWatchProvider(
      providerId: json['provider_id'] as int,
      providerName: json['provider_name'] as String? ?? 'Unknown',
      logoPath: json['logo_path'] as String?,
      displayPriority: json['display_priority'] as int? ?? 999,
    );
  }
}

/// Helper to parse watch providers response.
class TmdbWatchProviders {
  final Map<String, TmdbWatchProviderResult> results;

  TmdbWatchProviders({required this.results});

  /// Get providers for a specific country code (e.g., "US").
  TmdbWatchProviderResult? forCountry(String countryCode) {
    return results[countryCode.toUpperCase()];
  }

  /// Get providers for US (most common).
  TmdbWatchProviderResult? get us => results['US'];

  factory TmdbWatchProviders.fromJson(Map<String, dynamic> json) {
    final resultsJson = json['results'] as Map<String, dynamic>? ?? {};
    final results = <String, TmdbWatchProviderResult>{};

    for (final entry in resultsJson.entries) {
      results[entry.key] = TmdbWatchProviderResult.fromJson(
        entry.value as Map<String, dynamic>,
      );
    }

    return TmdbWatchProviders(results: results);
  }
}
