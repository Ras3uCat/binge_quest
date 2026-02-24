import 'package:flutter/material.dart';
import '../../../shared/models/archetype.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';

/// Displays the user's archetype identity label.
///
/// - Pass [primary] only for the compact friend-list variant.
/// - Pass both [primary] and [secondary] on own profile for dual display.
/// - Omit both (or pass null) to render the "Still Exploring..." placeholder.
/// - Set [showTagline] to true on own-profile to show the tagline below.
class ArchetypeBadge extends StatelessWidget {
  final UserArchetype? primary;
  final UserArchetype? secondary;
  final bool showTagline;
  final VoidCallback? onTap;

  const ArchetypeBadge({
    super.key,
    this.primary,
    this.secondary,
    this.showTagline = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (primary == null) return _buildPlaceholder();

    final primaryColor = _hexColor(primary!.archetype?.colorHex);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPill(primaryColor),
          if (showTagline && primary!.archetype != null) ...[
            SizedBox(height: ESizes.xs),
            Text(
              primary!.archetype!.tagline,
              style: TextStyle(
                color: EColors.textSecondary,
                fontSize: ESizes.fontSm,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPill(Color color) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ESizes.sm + ESizes.xs,
        vertical: ESizes.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(ESizes.radiusRound),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLabel(primary!, color),
          if (secondary != null) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: ESizes.xs),
              child: Text(
                '+',
                style: TextStyle(
                  color: EColors.textSecondary,
                  fontSize: ESizes.fontSm,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            _buildLabel(
              secondary!,
              _hexColor(secondary!.archetype?.colorHex),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLabel(UserArchetype ua, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          _iconForName(ua.archetype?.iconName),
          size: ESizes.iconXs,
          color: color,
        ),
        SizedBox(width: ESizes.xs),
        Text(
          ua.resolvedDisplayName,
          style: TextStyle(
            color: color,
            fontSize: ESizes.fontSm,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ESizes.sm + ESizes.xs,
        vertical: ESizes.xs,
      ),
      decoration: BoxDecoration(
        color: EColors.border.withOpacity(0.3),
        border: Border.all(color: EColors.border),
        borderRadius: BorderRadius.circular(ESizes.radiusRound),
      ),
      child: Text(
        'Still Exploring...',
        style: TextStyle(
          color: EColors.textSecondary,
          fontSize: ESizes.fontSm,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  static Color _hexColor(String? hex) {
    if (hex == null) return Colors.grey;
    return Color(int.parse(hex.replaceAll('#', '0xFF')));
  }

  static IconData _iconForName(String? name) {
    switch (name) {
      case 'weekend_warrior':
        return Icons.weekend;
      case 'local_movies':
        return Icons.local_movies;
      case 'shuffle':
        return Icons.shuffle;
      case 'military_tech':
        return Icons.military_tech;
      case 'archive':
        return Icons.archive;
      case 'nights_stay':
        return Icons.nights_stay;
      case 'recommend':
        return Icons.recommend;
      case 'bolt':
        return Icons.bolt;
      case 'waves':
        return Icons.waves;
      case 'checklist':
        return Icons.checklist;
      case 'trending_up':
        return Icons.trending_up;
      case 'explore':
        return Icons.explore;
      default:
        return Icons.star;
    }
  }
}
