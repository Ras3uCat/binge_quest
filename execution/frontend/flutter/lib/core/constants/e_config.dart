/// App-level build configuration.
/// Set [kDevMode] to false before publishing to the store.
class EConfig {
  EConfig._();

  /// Controls visibility of Developer and Data sections in Settings.
  /// Flip to false before release.
  static const bool kDevMode = false;

  /// Minimum time between repeated in-app update prompts.
  static const Duration kUpgradeAlertRecheckInterval = Duration(days: 3);
}
