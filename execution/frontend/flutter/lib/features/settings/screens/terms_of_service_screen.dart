import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../core/constants/e_text.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

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
                        title: 'Agreement to Terms',
                        content:
                            'By using BingeQuest, you agree to be bound by these Terms of Service. '
                            'If you do not agree to these terms, please do not use our app.',
                      ),
                      _buildSection(
                        title: 'Description of Service',
                        content:
                            'BingeQuest is a watchlist tracking application that helps users manage '
                            'their movie and TV show backlog. We provide tools to track progress, '
                            'receive recommendations, and earn achievements.',
                      ),
                      _buildSection(
                        title: 'User Accounts',
                        content:
                            'You must create an account using Google or Apple Sign-In to use the app. '
                            'You are responsible for maintaining the security of your account and all '
                            'activities that occur under your account.',
                      ),
                      _buildSection(
                        title: 'Acceptable Use',
                        content:
                            'You agree not to:\n\n'
                            '• Use the app for any unlawful purpose\n'
                            '• Attempt to gain unauthorized access to our systems\n'
                            '• Interfere with or disrupt the app\'s functionality\n'
                            '• Share your account credentials with others\n'
                            '• Use automated systems to access the app',
                      ),
                      _buildSection(
                        title: 'Content',
                        content:
                            'Movie and TV show data is provided by TMDB (The Movie Database). '
                            'This product uses the TMDB API but is not endorsed or certified by TMDB. '
                            'We do not host or provide any streaming content.',
                      ),
                      _buildSection(
                        title: 'Intellectual Property',
                        content:
                            'The BingeQuest app, including its design, features, and content, '
                            'is owned by us and protected by intellectual property laws. '
                            'You may not copy, modify, or distribute our app without permission.',
                      ),
                      _buildSection(
                        title: 'Disclaimer of Warranties',
                        content:
                            'The app is provided "as is" without warranties of any kind. '
                            'We do not guarantee that the app will be error-free or uninterrupted.',
                      ),
                      _buildSection(
                        title: 'Limitation of Liability',
                        content:
                            'To the maximum extent permitted by law, we shall not be liable for '
                            'any indirect, incidental, special, or consequential damages arising '
                            'from your use of the app.',
                      ),
                      _buildSection(
                        title: 'Account Termination',
                        content:
                            'You may delete your account at any time through the Settings screen. '
                            'We reserve the right to suspend or terminate accounts that violate '
                            'these terms.',
                      ),
                      _buildSection(
                        title: 'Changes to Terms',
                        content:
                            'We may modify these terms at any time. Continued use of the app '
                            'after changes constitutes acceptance of the new terms.',
                      ),
                      _buildSection(
                        title: 'Contact',
                        content:
                            'For questions about these Terms of Service, contact us at:\n\n'
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
            EText.termsOfService,
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
