import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../core/services/supabase_service.dart';
import '../../../shared/models/archetype.dart';
import '../../../shared/repositories/archetype_repository.dart';

/// Manages archetype state for the currently-viewed profile.
/// Call [loadForUser] each time the viewed user changes.
class ArchetypeController extends GetxController {
  static ArchetypeController get to => Get.find();

  /// All 12 scored archetypes from the latest compute run, sorted by rank.
  final RxList<UserArchetype> allScores = <UserArchetype>[].obs;

  /// Full archetype reference list (12 entries), loaded once.
  final RxList<Archetype> allArchetypes = <Archetype>[].obs;

  /// Per-compute-run history of the rank-1 archetype.
  final RxList<UserArchetype> history = <UserArchetype>[].obs;

  final RxBool isLoading = false.obs;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    final userId = SupabaseService.currentUserId;
    if (userId != null) {
      loadForUser(userId);
    } else {
      loadArchetypeReference();
    }
  }

  // ── Derived ──────────────────────────────────────────────────────────────

  /// Rank-1 archetype, or null if the user has no data yet.
  UserArchetype? get primary =>
      allScores.firstWhereOrNull((s) => s.rank == 1);

  /// Rank-2 archetype if its score is within 0.05 of the primary (dual mode).
  UserArchetype? get secondary {
    final p = primary;
    if (p == null) return null;
    final s = allScores.firstWhereOrNull((s) => s.rank == 2);
    if (s == null) return null;
    return (p.score - s.score) <= 0.05 ? s : null;
  }

  /// Look up a reference archetype by its ID. Returns null if not yet loaded.
  Archetype? archetypeById(String id) =>
      allArchetypes.firstWhereOrNull((a) => a.id == id);

  // ── Loading ───────────────────────────────────────────────────────────────

  /// Load all archetype data for [userId]. Safe to call for any user
  /// (own profile or a friend's profile, subject to RLS).
  Future<void> loadForUser(String userId) async {
    try {
      isLoading.value = true;

      final results = await Future.wait([
        ArchetypeRepository.fetchAllArchetypes(),
        ArchetypeRepository.fetchUserCurrentScores(userId),
        ArchetypeRepository.fetchArchetypeHistory(userId),
      ]);

      allArchetypes.assignAll(results[0] as List<Archetype>);
      allScores.assignAll(results[1] as List<UserArchetype>);
      history.assignAll(results[2] as List<UserArchetype>);
    } catch (e) {
      debugPrint('ArchetypeController.loadForUser error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Reload reference archetypes (called once at app start if needed).
  Future<void> loadArchetypeReference() async {
    if (allArchetypes.isNotEmpty) return;
    try {
      final archetypes = await ArchetypeRepository.fetchAllArchetypes();
      allArchetypes.assignAll(archetypes);
    } catch (e) {
      debugPrint('ArchetypeController.loadArchetypeReference error: $e');
    }
  }
}
