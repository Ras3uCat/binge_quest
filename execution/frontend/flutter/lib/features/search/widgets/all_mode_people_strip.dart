import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_images.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../shared/models/tmdb_person.dart';
import '../controllers/search_controller.dart';
import '../screens/person_detail_screen.dart';

/// Horizontal people strip shown above content results in 'All' filter mode.
class AllModePeopleStrip extends StatelessWidget {
  const AllModePeopleStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final people = ContentSearchController.to.personResults;
      if (people.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(ESizes.lg, ESizes.sm, ESizes.lg, ESizes.xs),
            child: Text(
              'People',
              style: TextStyle(
                color: EColors.textSecondary,
                fontSize: ESizes.fontSm,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: ESizes.lg),
              itemCount: people.length,
              separatorBuilder: (_, __) => const SizedBox(width: ESizes.md),
              itemBuilder: (context, index) => _PersonChip(person: people[index]),
            ),
          ),
          const SizedBox(height: ESizes.sm),
          const Divider(color: EColors.border, height: 1),
        ],
      );
    });
  }
}

class _PersonChip extends StatelessWidget {
  final TmdbPersonSearchResult person;

  const _PersonChip({required this.person});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.to(() => PersonDetailScreen(personId: person.id)),
      child: SizedBox(
        width: 64,
        child: Column(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: EColors.surface,
              backgroundImage: person.profilePath != null
                  ? CachedNetworkImageProvider(EImages.tmdbProfile(person.profilePath!))
                  : null,
              child: person.profilePath == null
                  ? const Icon(Icons.person, color: EColors.textTertiary, size: 24)
                  : null,
            ),
            const SizedBox(height: 4),
            Text(
              person.name,
              style: const TextStyle(fontSize: ESizes.fontXs, color: EColors.textSecondary),
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
