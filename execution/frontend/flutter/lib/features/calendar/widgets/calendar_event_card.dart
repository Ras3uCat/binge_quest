import 'package:flutter/material.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../shared/models/calendar_event.dart';

class CalendarEventCard extends StatelessWidget {
  const CalendarEventCard({required this.event, required this.onTap, super.key});

  final CalendarEvent event;
  final VoidCallback onTap;

  static const double _posterWidth = 60;
  static const double _posterHeight = 90;
  static const String _tmdbImageBase = 'https://image.tmdb.org/t/p/w200';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: ESizes.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Poster(posterPath: event.posterPath),
            const SizedBox(width: ESizes.md),
            Expanded(child: _Info(event: event)),
          ],
        ),
      ),
    );
  }
}

class _Poster extends StatelessWidget {
  const _Poster({required this.posterPath});

  final String? posterPath;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(ESizes.radiusSm),
      child: posterPath != null
          ? Image.network(
              '${CalendarEventCard._tmdbImageBase}$posterPath',
              width: CalendarEventCard._posterWidth,
              height: CalendarEventCard._posterHeight,
              fit: BoxFit.cover,
              errorBuilder: (_, error, stack) => _placeholder(),
            )
          : _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      width: CalendarEventCard._posterWidth,
      height: CalendarEventCard._posterHeight,
      color: EColors.backgroundSecondary,
      child: const Icon(Icons.movie_outlined, color: EColors.textSecondary),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.event});

  final CalendarEvent event;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: ESizes.xs),
        Text(
          event.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: EColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: ESizes.fontMd,
          ),
        ),
        const SizedBox(height: ESizes.xs),
        if (event.episodeCode != null)
          _Chip(text: event.episodeCode!, color: EColors.primary)
        else
          const _Chip(text: 'Theatrical Release', color: EColors.accent),
        const SizedBox(height: ESizes.xs),
        _Chip(text: event.watchlistName, color: EColors.textSecondary),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: ESizes.sm, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(ESizes.radiusXs),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: ESizes.fontXs, fontWeight: FontWeight.w500),
      ),
    );
  }
}
