import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../models/playlist.dart';

class PlaylistRepository {
  PlaylistRepository._();

  static SupabaseClient get _client => Supabase.instance.client;

  static const _itemSelect =
      'id, playlist_id, tmdb_id, media_type, title, poster_path, position, note, added_at';
  static const _playlistSelect =
      'id, user_id, name, description, is_public, is_ranked, created_at, updated_at';
  static const _playlistWithItemsSelect =
      'id, user_id, name, description, is_public, is_ranked, created_at, updated_at, playlist_items($_itemSelect)';

  static Future<List<Playlist>> getUserPlaylists(String userId) async {
    final response = await _client
        .from('playlists')
        .select(_playlistWithItemsSelect)
        .eq('user_id', userId)
        .order('created_at', ascending: true);
    return response.map((e) => Playlist.fromJson(e)).toList();
  }

  static Future<Playlist> getPlaylistById(String id) async {
    final response = await _client
        .from('playlists')
        .select(_playlistWithItemsSelect)
        .eq('id', id)
        .single();
    final playlist = Playlist.fromJson(response);
    final sorted = List<PlaylistItem>.from(playlist.items)
      ..sort((a, b) => a.position.compareTo(b.position));
    return playlist.copyWith(items: sorted);
  }

  static Future<Playlist> createPlaylist({
    required String name,
    String? description,
    bool isPublic = true,
    bool isRanked = false,
  }) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) throw Exception('User not authenticated');
    final response = await _client
        .from('playlists')
        .insert({
          'user_id': userId,
          'name': name,
          'description': description,
          'is_public': isPublic,
          'is_ranked': isRanked,
        })
        .select(_playlistSelect)
        .single();
    return Playlist.fromJson(response);
  }

  static Future<Playlist> updatePlaylist({
    required String id,
    String? name,
    String? description,
    bool? isPublic,
    bool? isRanked,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;
    if (isPublic != null) updates['is_public'] = isPublic;
    if (isRanked != null) updates['is_ranked'] = isRanked;

    final response = await _client
        .from('playlists')
        .update(updates)
        .eq('id', id)
        .select(_playlistSelect)
        .single();
    return Playlist.fromJson(response);
  }

  static Future<void> deletePlaylist(String id) async {
    await _client.from('playlists').delete().eq('id', id);
  }

  static Future<PlaylistItem> addItem({
    required String playlistId,
    required int tmdbId,
    required String mediaType,
    required String title,
    String? posterPath,
  }) async {
    final countResponse = await _client
        .from('playlist_items')
        .select('id')
        .eq('playlist_id', playlistId);
    final position = countResponse.length;

    final response = await _client
        .from('playlist_items')
        .insert({
          'playlist_id': playlistId,
          'tmdb_id': tmdbId,
          'media_type': mediaType,
          'title': title,
          'poster_path': posterPath,
          'position': position,
        })
        .select(_itemSelect)
        .single();
    return PlaylistItem.fromJson(response);
  }

  static Future<void> removeItem(String itemId) async {
    await _client.from('playlist_items').delete().eq('id', itemId);
  }

  static Future<void> reorderItems({
    required String playlistId,
    required List<String> orderedIds,
  }) async {
    for (int i = 0; i < orderedIds.length; i++) {
      await _client.from('playlist_items').update({'position': i}).eq('id', orderedIds[i]);
    }
  }
}
