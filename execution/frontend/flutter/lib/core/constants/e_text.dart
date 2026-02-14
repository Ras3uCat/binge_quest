/// App text/string constants following the E-prefix convention.
class EText {
  EText._();

  // App info
  static const String appName = 'BingeQuest';
  static const String appTagline = 'Finish your watchlist faster';
  static const String appDescription =
      'A gamified watchlist tracker that transforms streaming backlog management into a quest.';

  // Auth screens
  static const String signIn = 'Sign In';
  static const String signOut = 'Sign Out';
  static const String continueWithGoogle = 'Continue with Google';
  static const String continueWithApple = 'Continue with Apple';
  static const String welcomeBack = 'Welcome back!';
  static const String getStarted = 'Get Started';

  // Onboarding
  static const String onboardingTitle1 = 'Track Your Queue';
  static const String onboardingDesc1 =
      'Add movies and TV shows from TMDB. Track progress episode by episode.';
  static const String onboardingTitle2 = 'Finish Fast';
  static const String onboardingDesc2 =
      'Smart recommendations help you clear your backlog efficiently.';
  static const String onboardingTitle3 = 'Earn Badges';
  static const String onboardingDesc3 =
      'Complete achievements and show off your binge-watching prowess.';

  // Navigation
  static const String dashboard = 'Dashboard';
  static const String watchlist = 'Watchlist';
  static const String search = 'Search';
  static const String profile = 'Profile';

  // Dashboard
  static const String queueHealth = 'Queue Health';
  static const String hoursRemaining = 'Hours Remaining';
  static const String almostDone = 'Almost Done';
  static const String totalItems = 'Total Items';
  static const String finishFast = 'Finish Fast';
  static const String finishInMinutes = 'Finish in %d min';

  // Queue Efficiency
  static const String queueEfficiency = 'Queue Efficiency';
  static const String efficiencyScore = 'Efficiency Score';
  static const String activeItems = 'Active';
  static const String idleItems = 'Idle';
  static const String staleItems = 'Stale';
  static const String completionRate = 'Completion Rate';
  static const String recentCompletions = 'Recent Completions';
  static const String needsAttention = 'Needs Attention';
  static const String tipsToImprove = 'Tips to Improve';

  // Watchlist
  static const String myWatchlists = 'My Watchlists';
  static const String createWatchlist = 'Create Watchlist';
  static const String editWatchlist = 'Edit Watchlist';
  static const String deleteWatchlist = 'Delete Watchlist';
  static const String watchlistName = 'Watchlist Name';
  static const String defaultWatchlist = 'My Queue';
  static const String emptyWatchlist = 'Your watchlist is empty';
  static const String addSomething = 'Search and add your first title!';
  static const String moveToWatchlist = 'Move to Watchlist';
  static const String moveTo = 'Move to...';
  static const String moveItem = 'Move Item';
  static const String movingItem = 'Moving %s';
  static const String currentlyIn = 'Currently in: %s';
  static const String alreadyInThisWatchlist = 'Already in this watchlist';
  static const String moveConfirmTitle = 'Move to %s?';
  static const String moveConfirmDesc = 'All watch progress will be preserved.';
  static const String moveSuccess = 'Moved to %s';

  // Search
  static const String searchHint = 'Search movies & TV shows...';
  static const String noResults = 'No results found';
  static const String tryDifferentSearch = 'Try a different search term';
  static const String movies = 'Movies';
  static const String tvShows = 'TV Shows';
  static const String all = 'All';
  static const String people = 'People';
  static const String searchPeopleHint = 'Search actors, directors...';

  // Streaming provider filter
  static const String streamingServices = 'Streaming Services';
  static const String filterByStreaming = 'Filter by streaming service';
  static const String clearFilters = 'Clear';
  static const String browseByProvider = 'Browse by Service';
  static const String availableOn = 'Available on';

  // Content details
  static const String addToWatchlist = 'Add to Watchlist';
  static const String removeFromWatchlist = 'Remove from Watchlist';
  static const String alreadyInWatchlist = 'Already in watchlist';
  static const String markWatched = 'Mark as Watched';
  static const String markUnwatched = 'Mark as Unwatched';
  static const String seasons = 'Seasons';
  static const String episodes = 'Episodes';
  static const String runtime = 'Runtime';
  static const String releaseDate = 'Release Date';
  static const String firstAired = 'First Aired';
  static const String overview = 'Overview';
  static const String cast = 'Cast';
  static const String genres = 'Genres';

  // Person/Actor
  static const String knownFor = 'Known For';
  static const String biography = 'Biography';
  static const String born = 'Born';
  static const String died = 'Died';
  static const String placeOfBirth = 'Place of Birth';
  static const String filmography = 'Filmography';
  static const String movieCredits = 'Movies';
  static const String tvCredits = 'TV Shows';
  static const String asCharacter = 'as %s';
  static const String noBiography = 'No biography available.';

  // Trailers
  static const String watchTrailer = 'Watch Trailer';
  static const String noTrailerAvailable = 'No trailer available';
  static const String trailer = 'Trailer';
  static const String playTrailer = 'Play Trailer';

  // Where to Watch
  static const String whereToWatch = 'Where to Watch';
  static const String stream = 'Stream';
  static const String rent = 'Rent';
  static const String buy = 'Buy';
  static const String checkAvailability = 'Check Availability';
  static const String notAvailableInRegion = 'Not available in your region';
  static const String poweredByJustWatch = 'Powered by JustWatch';

  // Progress
  static const String progress = 'Progress';
  static const String completed = 'Completed';
  static const String inProgress = 'In Progress';
  static const String notStarted = 'Not Started';
  static const String minutesLeft = '%d min left';
  static const String hoursLeft = '%d hr %d min left';

  // Profile
  static const String myProfile = 'My Profile';
  static const String badges = 'Badges';
  static const String stats = 'Stats';
  static const String settings = 'Settings';
  static const String premium = 'Premium';
  static const String upgradeToPremium = 'Upgrade to Premium';
  static const String removeAds = 'Remove ads and support development';

  // Badges
  static const String noBadgesYet = 'No badges yet';
  static const String startWatching =
      'Start watching to earn your first badge!';
  static const String badgeUnlocked = 'Badge Unlocked!';
  static const String earnedOn = 'Earned on %s';
  static const String notYetEarned = 'Not yet earned';
  static const String viewAllBadges = 'View All Badges';
  static const String completionBadges = 'Completion';
  static const String milestoneBadges = 'Milestones';
  static const String genreBadges = 'Genres';
  static const String activityBadges = 'Activity';

  // Errors
  static const String errorGeneric = 'Something went wrong';
  static const String errorNetwork = 'Check your internet connection';
  static const String errorAuth = 'Authentication failed';
  static const String tryAgain = 'Try Again';
  static const String cancel = 'Cancel';
  static const String ok = 'OK';
  static const String confirm = 'Confirm';
  static const String delete = 'Delete';
  static const String save = 'Save';

  // Confirmation dialogs
  static const String deleteWatchlistConfirm =
      'Are you sure you want to delete this watchlist?';
  static const String signOutConfirm = 'Are you sure you want to sign out?';

  // Settings
  static const String privacyPolicy = 'Privacy Policy';
  static const String termsOfService = 'Terms of Service';
  static const String appVersion = 'App Version';
  static const String deleteAccount = 'Delete Account';
  static const String deleteAccountWarning =
      'This will permanently delete your account and all your data including watchlists, progress, and badges. This action cannot be undone.';
  static const String areYouSure = 'Are you absolutely sure?';
  static const String deleteAccountFinal =
      'Type DELETE to confirm. This is your final warning.';
  static const String deleteForever = 'Delete Forever';

  // Connectivity
  static const String offline = 'You\'re offline';
  static const String offlineMessage = 'Some features may be unavailable';
  static const String backOnline = 'Back online';
}
