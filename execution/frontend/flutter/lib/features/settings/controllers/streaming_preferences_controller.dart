import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../shared/models/streaming_provider.dart';
import '../../../shared/models/user_streaming_preference.dart';
import '../../../shared/repositories/streaming_preferences_repository.dart';
import '../../auth/controllers/auth_controller.dart';

class StreamingPreferencesController extends GetxController {
  final StreamingPreferencesRepository _repository =
      StreamingPreferencesRepository();
  final AuthController _authController = Get.find<AuthController>();

  final RxList<UserStreamingPreference> preferences =
      <UserStreamingPreference>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool includeRentBuy = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadPreferences();
  }

  String? get _userId => _authController.user?.id;

  Set<int> get selectedProviderIds =>
      preferences.map((p) => p.providerId).toSet();

  Future<void> loadPreferences() async {
    final userId = _userId;
    if (userId == null) return;

    try {
      isLoading.value = true;
      final prefs = await _repository.getUserPreferences(userId);
      preferences.assignAll(prefs);
      if (prefs.isNotEmpty) {
        includeRentBuy.value = prefs.first.includeRentBuy;
      }
    } catch (e) {
      debugPrint('Error loading streaming preferences: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleProvider(StreamingProvider provider) async {
    final userId = _userId;
    if (userId == null) return;

    try {
      if (selectedProviderIds.contains(provider.id)) {
        // Optimistic remove
        preferences.removeWhere((p) => p.providerId == provider.id);
        await _repository.removePreference(
          userId: userId,
          providerId: provider.id,
        );
      } else {
        // Optimistic add — update UI immediately, persist in background
        preferences.add(UserStreamingPreference(
          id: '',
          userId: userId,
          providerId: provider.id,
          providerName: provider.name,
          providerLogoPath: provider.logoPath,
          includeRentBuy: includeRentBuy.value,
          createdAt: DateTime.now(),
        ));
        await _repository.addPreference(
          userId: userId,
          providerId: provider.id,
          providerName: provider.name,
          providerLogoPath: provider.logoPath,
        );
      }
    } catch (e) {
      debugPrint('Error toggling provider: $e');
      // Revert on failure
      await loadPreferences();
    }
  }

  Future<void> toggleIncludeRentBuy(bool value) async {
    final userId = _userId;
    if (userId == null) return;

    try {
      includeRentBuy.value = value;
      await _repository.updateIncludeRentBuy(
        userId: userId,
        includeRentBuy: value,
      );
    } catch (e) {
      debugPrint('Error updating rent/buy preference: $e');
      includeRentBuy.value = !value;
    }
  }
}
