import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../core/constants/e_text.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(ESizes.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Last updated: January 2026',
                        style: TextStyle(
                          fontSize: ESizes.fontSm,
                          color: EColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: ESizes.lg),
                      _buildSection(
                        title: 'Introduction',
                        content:
                            'BingeQuest ("we", "our", or "us") is committed to protecting your privacy. '
                            'This Privacy Policy explains how we collect, use, and safeguard your information '
                            'when you use our mobile application.',
                      ),
                      _buildSection(
                        title: 'Information We Collect',
                        content:
                            'We collect information you provide directly to us:\n\n'
                            '• Account information (email, name) when you sign in with Google or Apple\n'
                            '• Watchlist data including movies and TV shows you add\n'
                            '• Watch progress and completion data\n'
                            '• Badge and achievement data',
                      ),
                      _buildSection(
                        title: 'How We Use Your Information',
                        content:
                            'We use the information we collect to:\n\n'
                            '• Provide and maintain the app\n'
                            '• Sync your watchlist across devices\n'
                            '• Generate personalized recommendations\n'
                            '• Track your achievements and badges\n'
                            '• Improve our services',
                      ),
                      _buildSection(
                        title: 'Data Storage',
                        content:
                            'Your data is securely stored using Supabase, a trusted cloud platform. '
                            'We implement industry-standard security measures to protect your information.',
                      ),
                      _buildSection(
                        title: 'Third-Party Services',
                        content:
                            'We use the following third-party services:\n\n'
                            '• TMDB (The Movie Database) for movie and TV show information\n'
                            '• Google Sign-In for authentication\n'
                            '• Apple Sign-In for authentication\n'
                            '• Supabase for data storage',
                      ),
                      _buildSection(
                        title: 'Data Deletion',
                        content:
                            'You can delete your account and all associated data at any time through '
                            'the Settings screen. This action is permanent and cannot be undone.',
                      ),
                      _buildSection(
                        title: 'Children\'s Privacy',
                        content:
                            'Our app is not intended for children under 13. We do not knowingly '
                            'collect personal information from children under 13.',
                      ),
                      _buildSection(
                        title: 'Changes to This Policy',
                        content:
                            'We may update this Privacy Policy from time to time. We will notify you '
                            'of any changes by posting the new Privacy Policy in the app.',
                      ),
                      _buildSection(
                        title: 'Contact Us',
                        content:
                            'If you have questions about this Privacy Policy, please contact us at:\n\n'
                            'support@bingequest.app',
                      ),
                      const SizedBox(height: ESizes.xl),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(ESizes.lg),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.arrow_back),
            color: EColors.textPrimary,
          ),
          const SizedBox(width: ESizes.sm),
          const Text(
            EText.privacyPolicy,
            style: TextStyle(
              fontSize: ESizes.fontXxl,
              fontWeight: FontWeight.bold,
              color: EColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ESizes.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: ESizes.fontLg,
              fontWeight: FontWeight.bold,
              color: EColors.textPrimary,
            ),
          ),
          const SizedBox(height: ESizes.sm),
          Text(
            content,
            style: const TextStyle(
              fontSize: ESizes.fontMd,
              color: EColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
