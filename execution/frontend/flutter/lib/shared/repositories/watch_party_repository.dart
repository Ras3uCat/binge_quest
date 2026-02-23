import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/watch_party.dart';
import '../models/user_profile.dart';

/// Repository for Watch Party data access.
/// Handles party CRUD, membership, and progress queries.
class WatchPartyRepository {
  final SupabaseClient _supabase;

  WatchPartyRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  String? get _currentUserId => _supabase.auth.currentUser?.id;

  // ---------------------------------------------------------------------------
  // Party CRUD
  // ---------------------------------------------------------------------------

  /// Create a new watch party. Creator is automatically added as active member.
  Future<WatchParty> createParty(
    String name,
    int tmdbId,
    String mediaType,
  ) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final row = await _supabase.from('watch_parties').insert({
      'name': name,
      'tmdb_id': tmdbId,
      'media_type': mediaType,
      'created_by': userId,
    }).select().single();

    final party = WatchParty.fromJson(row);

    // Creator is auto-added as active member
    await _supabase.from('watch_party_members').insert({
      'party_id': party.id,
      'user_id': userId,
      'status': 'active',
      'joined_at': DateTime.now().toIso8601String(),
    });

    return party;
  }

  /// Invite a user to a party (inserts a pending member row).
  Future<void> inviteMember(String partyId, String userId) async {
    await _supabase.from('watch_party_members').insert({
      'party_id': partyId,
      'user_id': userId,
      'status': 'pending',
    });
  }

  /// Accept a pending invite — UPDATE status pending → active.
  Future<void> acceptInvite(String partyId) async {
    final userId = _currentUserId;
    if (userId == null) return;
    await _supabase
        .from('watch_party_members')
        .update({
          'status': 'active',
          'joined_at': DateTime.now().toIso8601String(),
        })
        .eq('party_id', partyId)
        .eq('user_id', userId)
        .eq('status', 'pending');
  }

  /// Decline a pending invite — DELETE own member row.
  Future<void> declineInvite(String partyId) async {
    final userId = _currentUserId;
    if (userId == null) return;
    await _supabase
        .from('watch_party_members')
        .delete()
        .eq('party_id', partyId)
        .eq('user_id', userId)
        .eq('status', 'pending');
  }

  /// Leave a party — UPDATE status → 'left'.
  Future<void> leaveParty(String partyId) async {
    final userId = _currentUserId;
    if (userId == null) return;
    await _supabase
        .from('watch_party_members')
        .update({'status': 'left'})
        .eq('party_id', partyId)
        .eq('user_id', userId);
  }

  /// Re-invite a member who previously left or was removed.
  Future<void> reinviteMember(String partyId, String userId) async {
    await _supabase.from('watch_party_members').insert({
      'party_id': partyId,
      'user_id': userId,
      'status': 'pending',
    });
  }

  /// Delete a watch party (creator only; RLS enforces ownership).
  Future<void> deleteParty(String partyId) async {
    await _supabase.from('watch_parties').delete().eq('id', partyId);
  }

  /// Fetch all parties where the current user is creator OR active/pending member.
  Future<List<WatchParty>> fetchUserParties() async {
    final userId = _currentUserId;
    if (userId == null) return [];

    // Fetch party IDs where the user is a member
    final memberRows = await _supabase
        .from('watch_party_members')
        .select('party_id')
        .eq('user_id', userId)
        .inFilter('status', ['active', 'pending']);

    final memberPartyIds = (memberRows as List)
        .map((r) => r['party_id'] as String)
        .toList();

    if (memberPartyIds.isEmpty) return [];

    final rows = await _supabase
        .from('watch_parties')
        .select()
        .inFilter('id', memberPartyIds)
        .order('created_at', ascending: false);

    final parties = (rows as List).map((r) => WatchParty.fromJson(r)).toList();

    // Secondary query: resolve creator display names for pending invite subtitles.
    final creatorIds = parties.map((p) => p.createdBy).toSet().toList();
    final userRows = await _supabase
        .from('users')
        .select('id, display_name, username')
        .inFilter('id', creatorIds);

    final creatorMap = <String, String>{};
    for (final u in userRows as List) {
      final displayName = u['display_name'] as String?;
      final username = u['username'] as String?;
      final label = displayName ?? (username != null ? '@$username' : null);
      if (label != null) creatorMap[u['id'] as String] = label;
    }

    return parties.map((p) {
      final name = creatorMap[p.createdBy];
      return name != null ? p.copyWith(creatorUsername: name) : p;
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Members
  // ---------------------------------------------------------------------------

  /// Fetch all active + pending members for a party, with display names.
  Future<List<WatchPartyMember>> fetchPartyMembers(String partyId) async {
    final rows = await _supabase
        .from('watch_party_members')
        .select()
        .eq('party_id', partyId)
        .inFilter('status', ['active', 'pending']);
    final members =
        (rows as List).map((r) => WatchPartyMember.fromJson(r)).toList();

    final userIds = members.map((m) => m.userId).toList();
    if (userIds.isEmpty) return members;

    final profileRows = await _supabase
        .from('users')
        .select('id, display_name, avatar_url, username')
        .inFilter('id', userIds);

    final profileMap = <String, UserProfile>{};
    for (final p in profileRows as List) {
      final profile = UserProfile.fromJson(p);
      profileMap[profile.id] = profile;
    }

    return members.map((m) {
      final profile = profileMap[m.userId];
      return m.copyWith(
        displayName: profile?.displayLabel ?? 'Member',
        avatarUrl: profile?.avatarUrl,
      );
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Progress
  // ---------------------------------------------------------------------------

  /// Fetch full progress snapshot for a party, grouped by member.
  /// Always returns one entry per active member; members with no progress
  /// rows are included with an empty episodes list (renders as "Not started").
  Future<List<WatchPartyMemberProgress>> fetchProgress(String partyId) async {
    // Step 1: all active members for this party.
    final memberRows = await _supabase
        .from('watch_party_members')
        .select('user_id')
        .eq('party_id', partyId)
        .eq('status', 'active');

    final allMemberIds = (memberRows as List)
        .map((r) => r['user_id'] as String)
        .toList();

    if (allMemberIds.isEmpty) return [];

    // Step 2: existing progress rows.
    final progressRows = await _supabase
        .from('watch_party_progress')
        .select()
        .eq('party_id', partyId);

    // Step 3: batch fetch profiles for all active members.
    final profileRows = await _supabase
        .from('users')
        .select('id, display_name, avatar_url, username')
        .inFilter('id', allMemberIds);

    final profileMap = <String, UserProfile>{};
    for (final p in profileRows as List) {
      final profile = UserProfile.fromJson(p);
      profileMap[profile.id] = profile;
    }

    // Step 4: group progress rows by user_id.
    final grouped = <String, List<EpisodeProgress>>{};
    for (final uid in allMemberIds) {
      grouped[uid] = [];
    }
    for (final row in progressRows as List) {
      final uid = row['user_id'] as String;
      grouped.putIfAbsent(uid, () => []);
      grouped[uid]!.add(EpisodeProgress.fromJson(row));
    }

    // Step 5: one entry per active member; empty episodes = "Not started".
    return allMemberIds.map((uid) {
      final profile = profileMap[uid];
      return WatchPartyMemberProgress(
        userId: uid,
        displayName: profile?.displayLabel ?? 'Member',
        avatarUrl: profile?.avatarUrl,
        episodes: grouped[uid] ?? [],
      );
    }).toList();
  }

  /// Subscribe to Realtime updates on watch_party_progress for a party.
  RealtimeChannel subscribeToProgress(
    String partyId,
    void Function(Map<String, dynamic> payload) onUpdate,
  ) {
    return _supabase
        .channel('watch_party_progress:$partyId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'watch_party_progress',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'party_id',
            value: partyId,
          ),
          callback: (payload) => onUpdate({
            'type': payload.eventType.name.toUpperCase(),
            'new': payload.newRecord,
            'old': payload.oldRecord,
          }),
        )
        .subscribe();
  }

  /// Unsubscribe from a Realtime channel.
  Future<void> unsubscribeFromProgress(RealtimeChannel channel) async {
    await channel.unsubscribe();
  }

  // ---------------------------------------------------------------------------
  // Notifications
  // ---------------------------------------------------------------------------

  /// Returns user IDs of all active members for a party.
  Future<List<String>> fetchActiveMemberIds(String partyId) async {
    final rows = await _supabase
        .from('watch_party_members')
        .select('user_id')
        .eq('party_id', partyId)
        .eq('status', 'active');
    return (rows as List).map((r) => r['user_id'] as String).toList();
  }

  /// Send a push notification via the send-notification edge function.
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    String category = 'social',
    Map<String, String> data = const {},
  }) async {
    await _supabase.functions.invoke(
      'send-notification',
      body: {
        'user_id': userId,
        'category': category,
        'title': title,
        'body': body,
        'data': data,
      },
    );
  }
}
