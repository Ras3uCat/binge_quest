/// Model representing a streaming provider for filtering.
class StreamingProvider {
  final int id;
  final String name;
  final String logoPath;

  const StreamingProvider({
    required this.id,
    required this.name,
    required this.logoPath,
  });

  /// Get the full logo URL.
  String get logoUrl => 'https://image.tmdb.org/t/p/original$logoPath';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StreamingProvider &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Common US streaming providers with their TMDB IDs.
/// These are the most popular services in the US market.
class StreamingProviders {
  StreamingProviders._();

  static const netflix = StreamingProvider(
    id: 8,
    name: 'Netflix',
    logoPath: '/pbpMk2JmcoNnQwx5JGpXngfoWtp.jpg',
  );

  static const amazonPrime = StreamingProvider(
    id: 9,
    name: 'Prime Video',
    logoPath: '/emthp39XA2YScoYL1p0sdbAH2WA.jpg',
  );

  static const disneyPlus = StreamingProvider(
    id: 337,
    name: 'Disney+',
    logoPath: '/7rwgEs15tFwyR9NPQ5vpzxTj19Q.jpg',
  );

  static const hulu = StreamingProvider(
    id: 15,
    name: 'Hulu',
    logoPath: '/zxrVdFjIjLqkfnwyghnfywTn3Lh.jpg',
  );

  static const hboMax = StreamingProvider(
    id: 1899,
    name: 'Max',
    logoPath: '/6Q3ZYUNA9Hsgj6iWnVsw2gR5V6z.jpg',
  );

  static const appleTvPlus = StreamingProvider(
    id: 350,
    name: 'Apple TV+',
    logoPath: '/6uhKBfmtzFqOcLousHwZuzcrScK.jpg',
  );

  static const peacock = StreamingProvider(
    id: 386,
    name: 'Peacock',
    logoPath: '/8VCV78prwd9QzZnEm0ReO6bERDa.jpg',
  );

  static const paramount = StreamingProvider(
    id: 531,
    name: 'Paramount+',
    logoPath: '/xbhHHa1YgtpwhC8lb1NQ3ACVcLd.jpg',
  );

  /// List of all common providers for quick access.
  static const List<StreamingProvider> all = [
    netflix,
    amazonPrime,
    disneyPlus,
    hulu,
    hboMax,
    appleTvPlus,
    peacock,
    paramount,
  ];

  /// Get provider by ID.
  static StreamingProvider? getById(int id) {
    try {
      return all.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
