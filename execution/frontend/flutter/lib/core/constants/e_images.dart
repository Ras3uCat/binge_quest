/// App image and asset path constants following the E-prefix convention.
class EImages {
  EImages._();

  // Base paths
  static const String _basePath = 'assets/images';
  static const String _iconPath = 'assets/icons';

  // App branding
  static const String appLogo = '$_iconPath/binge_quest_logo.png';
  static const String raspucatLogo = '$_iconPath/raspucat_logo.svg';
  static const String appLogoLight = '$_basePath/logo_light.png';
  static const String appIcon = '$_iconPath/app_icon.png';

  // Onboarding
  static const String onboarding1 = '$_basePath/onboarding/onboarding_1.png';
  static const String onboarding2 = '$_basePath/onboarding/onboarding_2.png';
  static const String onboarding3 = '$_basePath/onboarding/onboarding_3.png';

  // Auth providers
  static const String googleLogo = '$_iconPath/google_logo.svg';
  static const String appleLogo = '$_iconPath/apple_logo.svg';

  // Placeholders
  static const String posterPlaceholder = '$_basePath/placeholders/poster.png';
  static const String avatarPlaceholder = '$_basePath/placeholders/avatar.png';
  static const String backdropPlaceholder =
      '$_basePath/placeholders/backdrop.png';

  // Empty states
  static const String emptyWatchlist = '$_basePath/empty/watchlist.png';
  static const String emptySearch = '$_basePath/empty/search.png';
  static const String emptyBadges = '$_basePath/empty/badges.png';

  // TMDB image base URLs
  static const String tmdbPosterBase = 'https://image.tmdb.org/t/p';
  static const String tmdbPosterSm = '$tmdbPosterBase/w92';
  static const String tmdbPosterMd = '$tmdbPosterBase/w154';
  static const String tmdbPosterLg = '$tmdbPosterBase/w185';
  static const String tmdbPosterXl = '$tmdbPosterBase/w342';
  static const String tmdbPosterOriginal = '$tmdbPosterBase/original';
  static const String tmdbBackdropSm = '$tmdbPosterBase/w300';
  static const String tmdbBackdropMd = '$tmdbPosterBase/w780';
  static const String tmdbBackdropLg = '$tmdbPosterBase/w1280';

  // TMDB profile image sizes (for actors/people)
  static const String tmdbProfileSm = '$tmdbPosterBase/w45';
  static const String tmdbProfileMd = '$tmdbPosterBase/w185';
  static const String tmdbProfileLg = '$tmdbPosterBase/h632';

  // Badge icons
  static const String badgeGenreHorror = '$_iconPath/badges/genre_horror.png';
  static const String badgeGenreRomcom = '$_iconPath/badges/genre_romcom.png';
  static const String badgeGenreAction = '$_iconPath/badges/genre_action.png';
  static const String badgeSeriesSlayer = '$_iconPath/badges/series_slayer.png';
  static const String badgeSeasonCrusher =
      '$_iconPath/badges/season_crusher.png';
  static const String badgeBingeMaster = '$_iconPath/badges/binge_master.png';

  /// Builds a TMDB poster URL from a poster path
  static String tmdbPoster(String? posterPath, {String size = 'w185'}) {
    if (posterPath == null || posterPath.isEmpty) {
      return posterPlaceholder;
    }
    return '$tmdbPosterBase/$size$posterPath';
  }

  /// Builds a TMDB backdrop URL from a backdrop path
  static String tmdbBackdrop(String? backdropPath, {String size = 'w780'}) {
    if (backdropPath == null || backdropPath.isEmpty) {
      return backdropPlaceholder;
    }
    return '$tmdbPosterBase/$size$backdropPath';
  }

  /// Builds a TMDB profile URL from a profile path (for actors/people)
  static String tmdbProfile(String? profilePath, {String size = 'w185'}) {
    if (profilePath == null || profilePath.isEmpty) {
      return avatarPlaceholder;
    }
    return '$tmdbPosterBase/$size$profilePath';
  }

  /// Builds a TMDB logo URL from a logo path (for streaming providers)
  static String tmdbLogo(String? logoPath, {String size = 'w92'}) {
    if (logoPath == null || logoPath.isEmpty) {
      return posterPlaceholder;
    }
    return '$tmdbPosterBase/$size$logoPath';
  }
}
