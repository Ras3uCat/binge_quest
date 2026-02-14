import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/e_colors.dart';
import '../constants/e_text.dart';

/// Service for monitoring network connectivity.
class ConnectivityService extends GetxController {
  static ConnectivityService get to => Get.find();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  final _isConnected = true.obs;
  final _connectionType = Rxn<ConnectivityResult>();

  bool get isConnected => _isConnected.value;
  bool get isOffline => !_isConnected.value;
  ConnectivityResult? get connectionType => _connectionType.value;

  @override
  void onInit() {
    super.onInit();
    _initConnectivity();
    _startListening();
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }

  Future<void> _initConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectionStatus(results);
    } catch (e) {
      debugPrint('Connectivity check failed: $e');
    }
  }

  void _startListening() {
    _subscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
      onError: (e) {
        debugPrint('Connectivity stream error: $e');
      },
    );
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final wasConnected = _isConnected.value;

    // Check if we have any actual connectivity
    final hasConnection = results.isNotEmpty &&
        !results.contains(ConnectivityResult.none);

    _isConnected.value = hasConnection;

    // Store primary connection type
    if (results.isNotEmpty) {
      _connectionType.value = results.first;
    }

    // Show snackbar on status change
    if (wasConnected && !hasConnection) {
      _showOfflineSnackbar();
    } else if (!wasConnected && hasConnection) {
      _showOnlineSnackbar();
    }
  }

  void _showOfflineSnackbar() {
    if (Get.context == null) return;

    Get.showSnackbar(
      GetSnackBar(
        message: EText.offline,
        messageText: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              EText.offline,
              style: TextStyle(
                color: EColors.textOnPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              EText.offlineMessage,
              style: TextStyle(
                color: EColors.textOnPrimary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        icon: const Icon(
          Icons.wifi_off,
          color: EColors.textOnPrimary,
        ),
        backgroundColor: EColors.error,
        duration: const Duration(seconds: 4),
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      ),
    );
  }

  void _showOnlineSnackbar() {
    if (Get.context == null) return;

    Get.showSnackbar(
      GetSnackBar(
        message: EText.backOnline,
        icon: const Icon(
          Icons.wifi,
          color: EColors.textOnPrimary,
        ),
        backgroundColor: EColors.success,
        duration: const Duration(seconds: 2),
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      ),
    );
  }

  /// Check current connectivity (useful for manual refresh)
  Future<bool> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectionStatus(results);
      return _isConnected.value;
    } catch (e) {
      return false;
    }
  }
}
