import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/e_colors.dart';
import '../models/mood_tag.dart';

class MoodGuideSheet extends StatelessWidget {
  const MoodGuideSheet({super.key});

  static void show() {
    Get.bottomSheet(
      const MoodGuideSheet(),
      backgroundColor: EColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      decoration: const BoxDecoration(
        color: EColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: EColors.textSecondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mood Guide',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: EColors.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: EColors.textPrimary),
                onPressed: () => Get.back(),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Text(
            'Understand what genres map to each mood filter.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: EColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          // Mood List
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: MoodTag.values.length,
              separatorBuilder: (context, index) => const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(color: EColors.surface, height: 1),
              ),
              itemBuilder: (context, index) {
                final mood = MoodTag.values[index];
                return _buildMoodRow(mood);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodRow(MoodTag mood) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mood Icon & Color
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: mood.color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(mood.icon, color: mood.color, size: 20),
        ),
        const SizedBox(width: 16),

        // Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    mood.displayName,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: EColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: mood.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                mood.description,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: EColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _getGenresForMood(
                  mood,
                ).map((genre) => _buildGenreChip(genre)).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGenreChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: EColors.textSecondary.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(fontSize: 11, color: EColors.textSecondary),
      ),
    );
  }

  List<String> _getGenresForMood(MoodTag mood) {
    switch (mood) {
      case MoodTag.comfort:
        return ['Comedy', 'Family', 'Animation'];
      case MoodTag.thriller:
        return ['Thriller', 'Horror', 'Crime', 'Mystery'];
      case MoodTag.lighthearted:
        return ['Comedy', 'Romance', 'Animation'];
      case MoodTag.intense:
        return ['Action', 'Thriller'];
      case MoodTag.emotional:
        return ['Drama', 'Romance'];
      case MoodTag.escapism:
        return ['Fantasy', 'Sci-Fi', 'Adventure'];
    }
  }
}
