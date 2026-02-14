/// Utility functions for formatting values.

/// Format large numbers with K/M notation.
/// Examples: 999 -> "999", 1234 -> "1.2K", 1500000 -> "1.5M"
String formatCompactNumber(int count) {
  if (count < 1000) return count.toString();
  if (count < 1000000) {
    final k = count / 1000;
    return '${k.toStringAsFixed(k < 10 ? 1 : 0)}K';
  }
  final m = count / 1000000;
  return '${m.toStringAsFixed(m < 10 ? 1 : 0)}M';
}
