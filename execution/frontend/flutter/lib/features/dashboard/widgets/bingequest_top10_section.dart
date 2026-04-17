import 'package:flutter/material.dart';
import '../../../../shared/models/top_content.dart';
import '../../../../shared/repositories/top_content_repository.dart';
import '../../../../shared/widgets/skeleton_loaders.dart';
import '../../../../shared/widgets/top10_guide_sheet.dart';
import '../../../../core/constants/e_colors.dart';
import '../../../../core/constants/e_sizes.dart';
import 'top10_item_card.dart';

class BingeQuestTop10Section extends StatefulWidget {
  const BingeQuestTop10Section({super.key});

  @override
  State<BingeQuestTop10Section> createState() => _BingeQuestTop10SectionState();
}

class _BingeQuestTop10SectionState extends State<BingeQuestTop10Section> {
  List<TopContent>? _items;
  bool _isLoading = true;
  bool _showMostWatched = true;
  bool _isFriendsMode = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final List<TopContent> items;
    if (_isFriendsMode) {
      items = _showMostWatched
          ? await TopContentRepository.getFriendsTop10ByUsers()
          : await TopContentRepository.getFriendsTop10ByRating();
    } else {
      items = _showMostWatched
          ? await TopContentRepository.getTop10ByUsers()
          : await TopContentRepository.getTop10ByRating();
    }

    if (mounted) {
      setState(() {
        _items = items;
        _isLoading = false;
      });
    }
  }

  void _toggleSort(bool mostWatched) {
    if (_showMostWatched != mostWatched) {
      setState(() => _showMostWatched = mostWatched);
      _loadData();
    }
  }

  void _toggleFriends() {
    setState(() => _isFriendsMode = !_isFriendsMode);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: ESizes.lg),
          child: Row(
            children: [
              const Text(
                'BingeQuest Top 10',
                style: TextStyle(
                  fontSize: ESizes.fontXl,
                  fontWeight: FontWeight.bold,
                  color: EColors.textPrimary,
                ),
              ),
              InkWell(
                onTap: Top10GuideSheet.show,
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Icon(Icons.info_outline, size: 16, color: EColors.textSecondary),
                ),
              ),
              const Spacer(),
              _FriendsTogglePill(isFriendsMode: _isFriendsMode, onToggle: _toggleFriends),
            ],
          ),
        ),
        const SizedBox(height: ESizes.sm),
        // Sort chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          padding: const EdgeInsets.symmetric(horizontal: ESizes.lg),
          child: Row(
            children: [
              _FilterChip(
                label: 'Most Watched',
                isSelected: _showMostWatched,
                onTap: () => _toggleSort(true),
              ),
              const SizedBox(width: ESizes.sm),
              _FilterChip(
                label: 'Top Rated',
                isSelected: !_showMostWatched,
                onTap: () => _toggleSort(false),
              ),
            ],
          ),
        ),
        const SizedBox(height: ESizes.md),
        // Content
        if (_isLoading)
          const PosterListSkeleton(count: 5, height: 220)
        else if (_items == null || _items!.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: ESizes.lg, vertical: 20),
            child: Text(
              _isFriendsMode
                  ? 'None of your friends have added this type of content yet.'
                  : 'No data yet. Start adding content!',
              style: const TextStyle(color: EColors.textSecondary),
            ),
          )
        else
          SizedBox(
            height: 220,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: ESizes.lg),
              clipBehavior: Clip.none,
              scrollDirection: Axis.horizontal,
              itemCount: _items!.length,
              separatorBuilder: (context, index) => const SizedBox(width: ESizes.md),
              itemBuilder: (context, index) => Top10ItemCard(
                item: _items![index],
                rank: index + 1,
                showUserCount: _showMostWatched,
              ),
            ),
          ),
      ],
    );
  }
}

class _FriendsTogglePill extends StatelessWidget {
  final bool isFriendsMode;
  final VoidCallback onToggle;

  const _FriendsTogglePill({required this.isFriendsMode, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        decoration: BoxDecoration(
          color: EColors.surface,
          borderRadius: BorderRadius.circular(ESizes.radiusRound),
          border: Border.all(color: EColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Segment(label: 'Global', isActive: !isFriendsMode),
            _Segment(label: 'Friends', isActive: isFriendsMode),
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool isActive;

  const _Segment({required this.label, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: ESizes.md, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? EColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(ESizes.radiusRound),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isActive ? EColors.textOnPrimary : EColors.textSecondary,
          fontWeight: FontWeight.w600,
          fontSize: ESizes.fontSm,
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: ESizes.md, vertical: ESizes.sm),
        decoration: BoxDecoration(
          color: isSelected ? EColors.primary : EColors.surface,
          borderRadius: BorderRadius.circular(ESizes.radiusRound),
          border: Border.all(color: isSelected ? EColors.primary : EColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? EColors.textOnPrimary : EColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: ESizes.fontSm,
          ),
        ),
      ),
    );
  }
}
