import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:get/get.dart';
import '../constants/e_colors.dart';
import '../constants/e_text.dart';

/// Service for handling and reporting errors via Firebase Crashlytics.
class ErrorService {
  ErrorService._();

  static bool _initialized = false;

  /// Initialize error handling and Crashlytics.
  /// Call this in main() after Firebase.initializeApp().
  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // Disable Crashlytics in debug mode
    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(!kDebugMode);

    // Catch Flutter framework errors
    FlutterError.onError =
        FirebaseCrashlytics.instance.recordFlutterFatalError;

    // Catch errors outside of Flutter framework
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  /// Set the user identifier for crash reports.
  static void setUserIdentifier(String? userId) {
    FirebaseCrashlytics.instance.setUserIdentifier(userId ?? '');
  }

  /// Manually report an error with context.
  static void reportError(
    Object error, {
    StackTrace? stack,
    String? context,
    Map<String, dynamic>? extras,
  }) {
    if (kDebugMode) {
      debugPrint('=== MANUAL ERROR REPORT ===');
      if (context != null) debugPrint('Context: $context');
      debugPrint('Error: $error');
      if (extras != null) debugPrint('Extras: $extras');
      debugPrint('Stack: $stack');
      debugPrint('===========================');
    }

    if (context != null) {
      FirebaseCrashlytics.instance.setCustomKey('context', context);
    }
    if (extras != null) {
      for (final entry in extras.entries) {
        FirebaseCrashlytics.instance
            .setCustomKey(entry.key, entry.value.toString());
      }
    }
    FirebaseCrashlytics.instance.recordError(error, stack);
  }

  /// Log a non-fatal issue for tracking.
  static void logIssue(String message, {Map<String, dynamic>? extras}) {
    if (kDebugMode) {
      debugPrint('=== ISSUE LOG ===');
      debugPrint('Message: $message');
      if (extras != null) debugPrint('Extras: $extras');
      debugPrint('=================');
    }

    FirebaseCrashlytics.instance.log(message);
    if (extras != null) {
      for (final entry in extras.entries) {
        FirebaseCrashlytics.instance
            .setCustomKey(entry.key, entry.value.toString());
      }
    }
  }

  /// Show a user-friendly error snackbar.
  static void showErrorSnackbar({
    String? message,
    VoidCallback? onRetry,
  }) {
    if (Get.context == null) return;

    Get.showSnackbar(
      GetSnackBar(
        message: message ?? EText.errorGeneric,
        backgroundColor: EColors.error,
        duration: const Duration(seconds: 4),
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        mainButton: onRetry != null
            ? TextButton(
                onPressed: () {
                  Get.closeCurrentSnackbar();
                  onRetry();
                },
                child: const Text(
                  EText.tryAgain,
                  style: TextStyle(color: EColors.textOnPrimary),
                ),
              )
            : null,
      ),
    );
  }

  /// Show a network error snackbar.
  static void showNetworkError({VoidCallback? onRetry}) {
    showErrorSnackbar(
      message: EText.errorNetwork,
      onRetry: onRetry,
    );
  }
}

/// Wrapper to run code with error handling.
Future<T?> runWithErrorHandling<T>(
  Future<T> Function() action, {
  String? context,
  VoidCallback? onError,
  bool showSnackbar = true,
}) async {
  try {
    return await action();
  } catch (e, stack) {
    ErrorService.reportError(e, stack: stack, context: context);
    if (showSnackbar) {
      ErrorService.showErrorSnackbar(onRetry: onError);
    }
    return null;
  }
}
