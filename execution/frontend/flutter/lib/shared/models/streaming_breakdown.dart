import 'content_cache.dart';

/// Aggregated streaming provider stats for profile display.
class StreamingBreakdownItem {
  final int providerId;
  final String providerName;
  final String? logoPath;
  final int itemCount;

  const StreamingBreakdownItem({
    required this.providerId,
    required this.providerName,
    this.logoPath,
    required this.itemCount,
  });

  /// Construct from StreamingProviderInfo with count.
  factory StreamingBreakdownItem.fromProvider(
    StreamingProviderInfo provider,
    int count,
  ) {
    return StreamingBreakdownItem(
      providerId: provider.id,
      providerName: provider.name,
      logoPath: provider.logoPath,
      itemCount: count,
    );
  }

  /// Full URL for provider logo.
  String get logoUrl =>
      logoPath != null ? 'https://image.tmdb.org/t/p/w92$logoPath' : '';

  /// Create a copy with updated count.
  StreamingBreakdownItem withCount(int newCount) {
    return StreamingBreakdownItem(
      providerId: providerId,
      providerName: providerName,
      logoPath: logoPath,
      itemCount: newCount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StreamingBreakdownItem &&
          runtimeType == other.runtimeType &&
          providerId == other.providerId;

  @override
  int get hashCode => providerId.hashCode;
}
