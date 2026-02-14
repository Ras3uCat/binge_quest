import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_text.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../core/constants/e_images.dart';
import '../controllers/auth_controller.dart';
import '../widgets/social_sign_in_button.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.put(AuthController());

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              EColors.primaryDark,
              EColors.background,
              EColors.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(ESizes.lg),
            child: Column(
              children: [
                const Spacer(),
                // App branding
                _buildBranding(),
                const Spacer(),
                // Sign-in buttons
                _buildSignInButtons(authController),
                const SizedBox(height: ESizes.lg),
                // Terms and privacy
                _buildTermsText(),
                const SizedBox(height: ESizes.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBranding() {
    return Column(
      children: [
        // App icon
        Image.asset(EImages.appLogo, height: 150, fit: BoxFit.contain),
        const SizedBox(height: ESizes.xl),
        // App name
        ShaderMask(
          shaderCallback: (bounds) =>
              EColors.primaryGradient.createShader(bounds),
          child: const Text(
            EText.appName,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const SizedBox(height: ESizes.sm),
        // Tagline
        const Text(
          EText.appTagline,
          style: TextStyle(
            fontSize: ESizes.fontLg,
            color: EColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSignInButtons(AuthController authController) {
    return Obx(() {
      final isLoading = authController.isLoading;
      final errorMessage = authController.errorMessage;

      return Column(
        children: [
          // Error message
          if (errorMessage.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(ESizes.md),
              decoration: BoxDecoration(
                color: EColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(ESizes.radiusMd),
                border: Border.all(color: EColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: EColors.error),
                  const SizedBox(width: ESizes.sm),
                  Expanded(
                    child: Text(
                      errorMessage,
                      style: const TextStyle(color: EColors.error),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: EColors.error),
                    onPressed: authController.clearError,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: ESizes.md),
          ],
          // Google Sign-In
          SocialSignInButton(
            label: EText.continueWithGoogle,
            icon: Icons.g_mobiledata,
            iconColor: Colors.red,
            onPressed: isLoading ? null : authController.signInWithGoogle,
            isLoading: isLoading,
          ),
          const SizedBox(height: ESizes.md),
          // Apple Sign-In (only on iOS/macOS or web)
          if (!kIsWeb && Platform.isIOS ||
              !kIsWeb && Platform.isMacOS ||
              kIsWeb)
            SocialSignInButton(
              label: EText.continueWithApple,
              icon: Icons.apple,
              iconColor: EColors.textPrimary,
              onPressed: isLoading ? null : authController.signInWithApple,
              isLoading: isLoading,
            ),
        ],
      );
    });
  }

  Widget _buildTermsText() {
    return const Text(
      'By continuing, you agree to our Terms of Service\nand Privacy Policy',
      style: TextStyle(
        fontSize: ESizes.fontSm,
        color: EColors.textTertiary,
        height: 1.5,
      ),
      textAlign: TextAlign.center,
    );
  }
}
