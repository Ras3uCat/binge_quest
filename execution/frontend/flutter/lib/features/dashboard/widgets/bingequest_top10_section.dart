import 'package:flutter/material.dart';
import '../../../../shared/models/top_content.dart';
import '../../../../shared/repositories/top_content_repository.dart';
import '../../../../shared/widgets/skeleton_loaders.dart';
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
  bool _showMostWatched = true; // true = Most Watched, false = Top Rated

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final items = _showMostWatched
        ? await TopContentRepository.getTop10ByUsers()
        : await TopContentRepository.getTop10ByRating();

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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: ESizes.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'BingeQuest Top 10',
                style: TextStyle(
                  fontSize: ESizes.fontXl,
                  fontWeight: FontWeight.bold,
                  color: EColors.textPrimary,
                ),
              ),
              if (!_isLoading && _items != null && _items!.isNotEmpty)
                TextButton(
                  onPressed: () {
                  },
                  child: const Text(''),
                ),
            ],
          ),
        ),
        const SizedBox(height: ESizes.sm),
        // Sort toggle chips
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
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: ESizes.lg, vertical: 20),
            child: Text(
              'No data yet. Start adding content!',
              style: TextStyle(color: EColors.textSecondary),
            ),
          )
        else
          SizedBox(
            height: 220,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: ESizes.lg),
              clipBehavior:
                  Clip.none, // Allow badges to overflow slightly if needed
              scrollDirection: Axis.horizontal,
              itemCount: _items!.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(width: ESizes.md),
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: ESizes.md,
          vertical: ESizes.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? EColors.primary : EColors.surface,
          borderRadius: BorderRadius.circular(ESizes.radiusRound),
          border: Border.all(
            color: isSelected ? EColors.primary : EColors.border,
          ),
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
