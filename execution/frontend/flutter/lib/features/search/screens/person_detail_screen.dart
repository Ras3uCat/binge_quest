import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../core/constants/e_text.dart';
import '../../../core/constants/e_images.dart';
import '../../../shared/models/tmdb_person.dart';
import '../../../shared/models/tmdb_content.dart';
import '../../../shared/models/watchlist_item.dart';
import '../../../shared/widgets/follow_talent_button.dart';
import '../controllers/search_controller.dart';
import '../widgets/content_detail_sheet.dart';

class PersonDetailScreen extends StatefulWidget {
  final int personId;

  const PersonDetailScreen({super.key, required this.personId});

  @override
  State<PersonDetailScreen> createState() => _PersonDetailScreenState();
}

class _PersonDetailScreenState extends State<PersonDetailScreen> {
  bool _bioExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadPerson();
  }

  void _loadPerson() {
    ContentSearchController.to.getPersonDetails(widget.personId);
  }

  /// Resolve person type from the known_for_department field.
  String _resolvePersonType(TmdbPerson person) {
    final dept = person.knownForDepartment?.toLowerCase() ?? '';
    if (dept.contains('direct')) return 'director';
    return 'actor';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              EColors.backgroundSecondary,
              EColors.background,
            ],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: Obx(() {
                final controller = ContentSearchController.to;
                final person = controller.selectedPerson;
                final isLoading = controller.isLoadingPerson;

                if (isLoading && person == null) {
                  return const SizedBox(
                    height: 300,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (person == null) {
                  return _buildErrorContent();
                }

                return _buildContent(person);
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorContent() {
    return const SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: EColors.textTertiary),
            SizedBox(height: ESizes.md),
            Text(
              'Failed to load person details',
              style: TextStyle(color: EColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: EColors.background,
      foregroundColor: EColors.textPrimary,
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back),
        color: EColors.textPrimary,
      ),
      actions: const [],
      flexibleSpace: FlexibleSpaceBar(
        background: Obx(() {
          final person = ContentSearchController.to.selectedPerson;
          return Stack(
            fit: StackFit.expand,
            children: [
              // Profile image
              if (person?.profilePath != null)
                CachedNetworkImage(
                  imageUrl:
                      EImages.tmdbProfile(person!.profilePath, size: 'h632'),
                  fit: BoxFit.cover,
                  placeholder: (context, url) => _buildProfilePlaceholder(),
                  errorWidget: (context, url, error) =>
                      _buildProfilePlaceholder(),
                )
              else
                _buildProfilePlaceholder(),
              // Top scrim for app bar button visibility
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.center,
                    colors: [
                      Colors.black54,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              // Bottom gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      EColors.background.withValues(alpha: 0.8),
                      EColors.background,
                    ],
                    stops: const [0.4, 0.8, 1.0],
                  ),
                ),
              ),
              // Name overlay with follow button
              if (person != null)
                Positioned(
                  bottom: ESizes.lg,
                  left: ESizes.lg,
                  right: ESizes.lg,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              person.name,
                              style: const TextStyle(
                                fontSize: ESizes.fontXxl,
                                fontWeight: FontWeight.bold,
                                color: EColors.textPrimary,
                              ),
                            ),
                          ),
                          FollowTalentButton(
                            tmdbPersonId: person.id,
                            personName: person.name,
                            personType: _resolvePersonType(person),
                            profilePath: person.profilePath,
                            iconSize: 28,
                          ),
                        ],
                      ),
                      if (person.knownForDepartment != null) ...[
                        const SizedBox(height: ESizes.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: ESizes.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: EColors.primary.withValues(alpha: 0.2),
                            borderRadius:
                                BorderRadius.circular(ESizes.radiusSm),
                          ),
                          child: Text(
                            person.knownForDepartment!,
                            style: const TextStyle(
                              fontSize: ESizes.fontSm,
                              color: EColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildProfilePlaceholder() {
    return Container(
      color: EColors.surfaceLight,
      child: const Center(
        child: Icon(
          Icons.person,
          size: 80,
          color: EColors.textTertiary,
        ),
      ),
    );
  }

  Widget _buildContent(TmdbPerson person) {
    return Padding(
      padding: const EdgeInsets.all(ESizes.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Personal info
          _buildPersonalInfo(person),
          const SizedBox(height: ESizes.lg),

          // Biography
          _buildBiography(person),
          const SizedBox(height: ESizes.xl),

          // Movie credits
          if (person.movieCredits.isNotEmpty) ...[
            _buildCreditsSection(
              title: EText.movieCredits,
              credits: person.movieCredits,
            ),
            const SizedBox(height: ESizes.xl),
          ],

          // TV credits
          if (person.tvCredits.isNotEmpty)
            _buildCreditsSection(
              title: EText.tvCredits,
              credits: person.tvCredits,
            ),

          const SizedBox(height: ESizes.xl),
        ],
      ),
    );
  }

  Widget _buildPersonalInfo(TmdbPerson person) {
    final infoItems = <Widget>[];

    if (person.formattedBirthday != null) {
      infoItems.add(_buildInfoRow(
        icon: Icons.cake,
        label: EText.born,
        value: person.formattedBirthday!,
        suffix: person.age != null ? ' (${person.age} years old)' : null,
      ));
    }

    if (person.isDeceased && person.formattedDeathday != null) {
      infoItems.add(_buildInfoRow(
        icon: Icons.favorite_border,
        label: EText.died,
        value: person.formattedDeathday!,
      ));
    }

    if (person.placeOfBirth != null) {
      infoItems.add(_buildInfoRow(
        icon: Icons.location_on,
        label: EText.placeOfBirth,
        value: person.placeOfBirth!,
      ));
    }

    if (infoItems.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: infoItems,
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    String? suffix,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ESizes.sm),
      child: Row(
        children: [
          Icon(icon, size: 18, color: EColors.textSecondary),
          const SizedBox(width: ESizes.sm),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: ESizes.fontSm,
              color: EColors.textSecondary,
            ),
          ),
          Expanded(
            child: Text(
              value + (suffix ?? ''),
              style: const TextStyle(
                fontSize: ESizes.fontSm,
                color: EColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBiography(TmdbPerson person) {
    final bio = person.biography;
    final hasBio = bio != null && bio.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          EText.biography,
          style: TextStyle(
            fontSize: ESizes.fontLg,
            fontWeight: FontWeight.bold,
            color: EColors.textPrimary,
          ),
        ),
        const SizedBox(height: ESizes.sm),
        if (!hasBio)
          const Text(
            EText.noBiography,
            style: TextStyle(
              fontSize: ESizes.fontMd,
              color: EColors.textTertiary,
              fontStyle: FontStyle.italic,
            ),
          )
        else
          GestureDetector(
            onTap: () => setState(() => _bioExpanded = !_bioExpanded),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bio,
                  style: const TextStyle(
                    fontSize: ESizes.fontMd,
                    color: EColors.textSecondary,
                    height: 1.5,
                  ),
                  maxLines: _bioExpanded ? null : 5,
                  overflow: _bioExpanded ? null : TextOverflow.ellipsis,
                ),
                if (bio.length > 300) ...[
                  const SizedBox(height: ESizes.xs),
                  Text(
                    _bioExpanded ? 'Show less' : 'Read more',
                    style: const TextStyle(
                      fontSize: ESizes.fontSm,
                      color: EColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCreditsSection({
    required String title,
    required List<TmdbPersonCredit> credits,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: ESizes.fontLg,
                fontWeight: FontWeight.bold,
                color: EColors.textPrimary,
              ),
            ),
            Text(
              '${credits.length} titles',
              style: const TextStyle(
                fontSize: ESizes.fontSm,
                color: EColors.textTertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: ESizes.md),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: credits.length,
            itemBuilder: (context, index) {
              return _CreditCard(credit: credits[index]);
            },
          ),
        ),
      ],
    );
  }
}

class _CreditCard extends StatelessWidget {
  final TmdbPersonCredit credit;

  const _CreditCard({required this.credit});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showContentDetail,
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: ESizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(ESizes.radiusMd),
                    child: credit.posterPath != null
                        ? CachedNetworkImage(
                            imageUrl: EImages.tmdbPoster(credit.posterPath),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            placeholder: (context, url) => _buildPlaceholder(),
                            errorWidget: (context, url, error) =>
                                _buildPlaceholder(),
                          )
                        : _buildPlaceholder(),
                  ),
                  // Year badge
                  if (credit.year != null)
                    Positioned(
                      top: ESizes.xs,
                      right: ESizes.xs,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: ESizes.xs,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: EColors.background.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(ESizes.radiusSm),
                        ),
                        child: Text(
                          credit.year!,
                          style: const TextStyle(
                            fontSize: ESizes.fontXs,
                            color: EColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  // Media type indicator
                  Positioned(
                    top: ESizes.xs,
                    left: ESizes.xs,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: EColors.background.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(ESizes.radiusSm),
                      ),
                      child: Icon(
                        credit.mediaType == MediaType.movie
                            ? Icons.movie
                            : Icons.tv,
                        size: 12,
                        color: EColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: ESizes.xs),
            // Title
            Text(
              credit.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: ESizes.fontSm,
                fontWeight: FontWeight.w500,
                color: EColors.textPrimary,
              ),
            ),
            // Character
            if (credit.character != null && credit.character!.isNotEmpty)
              Text(
                credit.character!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: ESizes.fontXs,
                  color: EColors.textTertiary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      color: EColors.surfaceLight,
      child: Center(
        child: Icon(
          credit.mediaType == MediaType.movie ? Icons.movie : Icons.tv,
          size: 32,
          color: EColors.textTertiary,
        ),
      ),
    );
  }

  void _showContentDetail() {
    // Create a TmdbSearchResult from the credit
    final result = TmdbSearchResult(
      id: credit.id,
      titleField: credit.mediaType == MediaType.movie ? credit.title : null,
      name: credit.mediaType == MediaType.tv ? credit.title : null,
      posterPath: credit.posterPath,
      mediaTypeString: credit.mediaType == MediaType.movie ? 'movie' : 'tv',
      voteAverage: credit.voteAverage,
      releaseDate: credit.mediaType == MediaType.movie ? credit.releaseDate : null,
      firstAirDate: credit.mediaType == MediaType.tv ? credit.releaseDate : null,
    );

    Get.bottomSheet(
      ContentDetailSheet(result: result),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}
