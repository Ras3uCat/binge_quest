import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../core/constants/e_text.dart';
import '../../../core/constants/e_images.dart';
import '../../../core/services/tmdb_service.dart';
import '../../../shared/models/tmdb_person.dart';
import '../../../shared/models/tmdb_content.dart';
import '../../../shared/models/watchlist_item.dart';
import '../../../shared/widgets/follow_talent_button.dart';
import 'content_detail_sheet.dart';

/// Bottom sheet version of person detail — self-contained, loads data directly.
class PersonDetailSheet extends StatefulWidget {
  final int personId;

  const PersonDetailSheet({super.key, required this.personId});

  @override
  State<PersonDetailSheet> createState() => _PersonDetailSheetState();
}

class _PersonDetailSheetState extends State<PersonDetailSheet> {
  TmdbPerson? _person;
  bool _isLoading = true;
  bool _bioExpanded = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPerson(widget.personId);
  }

  Future<void> _loadPerson(int personId) async {
    setState(() {
      _person = null;
      _isLoading = true;
      _error = null;
      _bioExpanded = false;
    });

    try {
      final response = await TmdbService.getPersonDetails(personId);
      final person = TmdbPerson.fromJson(response);
      if (mounted) setState(() => _person = person);
    } catch (e) {
      if (mounted) setState(() => _error = 'Failed to load person details.');
      debugPrint('Person detail sheet error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _resolvePersonType(TmdbPerson person) {
    final dept = person.knownForDepartment?.toLowerCase() ?? '';
    if (dept.contains('direct')) return 'director';
    return 'actor';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: EColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ESizes.radiusLg),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: ESizes.md),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: EColors.textTertiary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Content
          Flexible(
            child: _isLoading
                ? _buildLoading()
                : _error != null
                    ? _buildError()
                    : _person != null
                        ? _buildContent(_person!)
                        : _buildError(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Padding(
      padding: EdgeInsets.all(ESizes.xxl),
      child: Center(
        child: CircularProgressIndicator(color: EColors.primary),
      ),
    );
  }

  Widget _buildError() {
    return const Padding(
      padding: EdgeInsets.all(ESizes.xxl),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: EColors.textTertiary),
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

  Widget _buildContent(TmdbPerson person) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(ESizes.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(person),
          const SizedBox(height: ESizes.lg),
          _buildPersonalInfo(person),
          if (person.biography != null && person.biography!.isNotEmpty) ...[
            const SizedBox(height: ESizes.lg),
            _buildBiography(person),
          ],
          if (person.movieCredits.isNotEmpty) ...[
            const SizedBox(height: ESizes.xl),
            _buildCreditsSection(
              title: EText.movieCredits,
              credits: person.movieCredits,
            ),
          ],
          if (person.tvCredits.isNotEmpty) ...[
            const SizedBox(height: ESizes.xl),
            _buildCreditsSection(
              title: EText.tvCredits,
              credits: person.tvCredits,
            ),
          ],
          const SizedBox(height: ESizes.xl),
        ],
      ),
    );
  }

  Widget _buildHeader(TmdbPerson person) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Profile image
        ClipRRect(
          borderRadius: BorderRadius.circular(ESizes.radiusMd),
          child: SizedBox(
            width: 100,
            height: 140,
            child: person.profilePath != null
                ? CachedNetworkImage(
                    imageUrl: EImages.tmdbProfile(
                      person.profilePath,
                      size: 'w185',
                    ),
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _buildProfilePlaceholder(),
                    errorWidget: (_, __, ___) => _buildProfilePlaceholder(),
                  )
                : _buildProfilePlaceholder(),
          ),
        ),
        const SizedBox(width: ESizes.lg),
        // Name + department + follow
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                person.name,
                style: const TextStyle(
                  fontSize: ESizes.fontXl,
                  fontWeight: FontWeight.bold,
                  color: EColors.textPrimary,
                ),
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
                    borderRadius: BorderRadius.circular(ESizes.radiusSm),
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
              const SizedBox(height: ESizes.md),
              FollowTalentButton(
                tmdbPersonId: person.id,
                personName: person.name,
                personType: _resolvePersonType(person),
                profilePath: person.profilePath,
                showLabel: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfilePlaceholder() {
    return Container(
      color: EColors.surfaceLight,
      child: const Center(
        child: Icon(Icons.person, size: 40, color: EColors.textTertiary),
      ),
    );
  }

  Widget _buildPersonalInfo(TmdbPerson person) {
    final items = <Widget>[];

    if (person.formattedBirthday != null) {
      items.add(_buildInfoRow(
        Icons.cake,
        EText.born,
        person.formattedBirthday! +
            (person.age != null ? ' (${person.age} years old)' : ''),
      ));
    }
    if (person.isDeceased && person.formattedDeathday != null) {
      items.add(_buildInfoRow(
        Icons.favorite_border,
        EText.died,
        person.formattedDeathday!,
      ));
    }
    if (person.placeOfBirth != null) {
      items.add(_buildInfoRow(
        Icons.location_on,
        EText.placeOfBirth,
        person.placeOfBirth!,
      ));
    }

    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items,
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
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
              value,
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
    final bio = person.biography!;
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
        GestureDetector(
          onTap: () => setState(() => _bioExpanded = !_bioExpanded),
          child: Text(
            bio,
            style: const TextStyle(
              fontSize: ESizes.fontMd,
              color: EColors.textSecondary,
              height: 1.5,
            ),
            maxLines: _bioExpanded ? null : 4,
            overflow: _bioExpanded ? null : TextOverflow.ellipsis,
          ),
        ),
        if (bio.length > 200) ...[
          const SizedBox(height: ESizes.xs),
          GestureDetector(
            onTap: () => setState(() => _bioExpanded = !_bioExpanded),
            child: Text(
              _bioExpanded ? 'Show less' : 'Read more',
              style: const TextStyle(
                fontSize: ESizes.fontSm,
                color: EColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
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
              final credit = credits[index];
              return _buildCreditCard(credit);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCreditCard(TmdbPersonCredit credit) {
    return GestureDetector(
      onTap: () => _showContentDetail(credit),
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: ESizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                          )
                        : _buildCreditPlaceholder(credit),
                  ),
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
                          borderRadius:
                              BorderRadius.circular(ESizes.radiusSm),
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
                  Positioned(
                    top: ESizes.xs,
                    left: ESizes.xs,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: EColors.background.withValues(alpha: 0.8),
                        borderRadius:
                            BorderRadius.circular(ESizes.radiusSm),
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

  Widget _buildCreditPlaceholder(TmdbPersonCredit credit) {
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

  void _showContentDetail(TmdbPersonCredit credit) async {
    final result = TmdbSearchResult(
      id: credit.id,
      titleField: credit.mediaType == MediaType.movie ? credit.title : null,
      name: credit.mediaType == MediaType.tv ? credit.title : null,
      posterPath: credit.posterPath,
      mediaTypeString: credit.mediaType == MediaType.movie ? 'movie' : 'tv',
      voteAverage: credit.voteAverage,
      releaseDate:
          credit.mediaType == MediaType.movie ? credit.releaseDate : null,
      firstAirDate:
          credit.mediaType == MediaType.tv ? credit.releaseDate : null,
    );

    // Open content sheet; if user taps a cast member, it returns the personId
    final personId = await Get.bottomSheet<int>(
      ContentDetailSheet(result: result),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );

    // Reload this sheet with the new person
    if (personId != null && mounted) {
      _loadPerson(personId);
    }
  }
}
