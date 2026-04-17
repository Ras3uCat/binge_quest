import 'package:get/get.dart';
import '../../features/playlists/screens/playlist_detail_screen.dart';
import '../../features/profile/screens/user_profile_screen.dart';
import '../../features/search/screens/content_deep_link_screen.dart';
import '../../shared/models/watchlist_item.dart';

class DeepLinkService extends GetxService {
  static DeepLinkService get to => Get.find();

  Uri? _pending;

  /// Store a link to dispatch once the navigator is ready (cold start).
  void schedule(Uri uri) => _pending = uri;

  /// Consume and dispatch the stored link, if any. Call from DashboardScreen.
  void consumeAndDispatch() {
    final uri = _pending;
    if (uri == null) return;
    _pending = null;
    dispatch(uri);
  }

  /// Immediately navigate to the destination for [uri].
  void dispatch(Uri uri) {
    final isCustom = uri.scheme == 'bingequest';
    final isUniversal =
        uri.scheme == 'https' &&
        uri.host == 'raspucat.com' &&
        uri.pathSegments.firstOrNull == 'bingequest';
    if (!isCustom && !isUniversal) return;

    final type = isCustom ? uri.host : uri.pathSegments.elementAtOrNull(1);

    switch (type) {
      case 'profile':
        final username = uri.queryParameters['u'];
        final userId = uri.queryParameters['id'];
        if (username != null) {
          Get.to(() => UserProfileScreen(username: username));
        } else if (userId != null) {
          Get.to(() => UserProfileScreen(userId: userId));
        }
      case 'playlist':
        final id = uri.queryParameters['id'];
        if (id != null) Get.to(() => PlaylistDetailScreen(playlistId: id));
      case 'content':
        final id = int.tryParse(uri.queryParameters['id'] ?? '');
        final mediaType = uri.queryParameters['type'] == 'tv' ? MediaType.tv : MediaType.movie;
        if (id != null) {
          Get.to(() => ContentDeepLinkScreen(tmdbId: id, mediaType: mediaType));
        }
    }
  }
}
