import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_text.dart';
import '../../../core/constants/e_sizes.dart';
import 'sign_in_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = const [
    OnboardingPage(
      icon: Icons.playlist_add_check,
      title: EText.onboardingTitle1,
      description: EText.onboardingDesc1,
      gradient: LinearGradient(
        colors: [EColors.primary, EColors.secondary],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    OnboardingPage(
      icon: Icons.speed,
      title: EText.onboardingTitle2,
      description: EText.onboardingDesc2,
      gradient: LinearGradient(
        colors: [EColors.accent, Color(0xFFFF5722)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    OnboardingPage(
      icon: Icons.emoji_events,
      title: EText.onboardingTitle3,
      description: EText.onboardingDesc3,
      gradient: LinearGradient(
        colors: [EColors.tertiary, Color(0xFF26A69A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
  ];

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _goToSignIn();
    }
  }

  void _goToSignIn() {
    Get.off(() => const SignInScreen());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(ESizes.md),
                  child: TextButton(
                    onPressed: _goToSignIn,
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        color: EColors.textSecondary,
                        fontSize: ESizes.fontMd,
                      ),
                    ),
                  ),
                ),
              ),
              // Page content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return _buildPage(_pages[index]);
                  },
                ),
              ),
              // Page indicators
              Padding(
                padding: const EdgeInsets.symmetric(vertical: ESizes.lg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => _buildIndicator(index),
                  ),
                ),
              ),
              // Bottom buttons
              Padding(
                padding: const EdgeInsets.all(ESizes.lg),
                child: SizedBox(
                  width: double.infinity,
                  height: ESizes.buttonHeightLg,
                  child: ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(ESizes.radiusMd),
                      ),
                    ),
                    child: Text(
                      _currentPage == _pages.length - 1
                          ? EText.getStarted
                          : 'Next',
                      style: const TextStyle(
                        fontSize: ESizes.fontLg,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ESizes.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon container with gradient
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              gradient: page.gradient,
              borderRadius: BorderRadius.circular(ESizes.radiusXl),
              boxShadow: [
                BoxShadow(
                  color: (page.gradient.colors.first).withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              page.icon,
              size: 72,
              color: EColors.textOnPrimary,
            ),
          ),
          const SizedBox(height: ESizes.xxl),
          // Title
          Text(
            page.title,
            style: const TextStyle(
              fontSize: ESizes.fontXxl,
              fontWeight: FontWeight.bold,
              color: EColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: ESizes.md),
          // Description
          Text(
            page.description,
            style: const TextStyle(
              fontSize: ESizes.fontLg,
              color: EColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator(int index) {
    final isActive = index == _currentPage;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? EColors.primary : EColors.surfaceLight,
        borderRadius: BorderRadius.circular(ESizes.radiusRound),
      ),
    );
  }
}

class OnboardingPage {
  final IconData icon;
  final String title;
  final String description;
  final Gradient gradient;

  const OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradient,
  });
}
