import 'package:upgrader/upgrader.dart';

import '../constants/e_config.dart';
import '../services/analytics_service.dart';

Upgrader buildAppUpgrader() {
  return Upgrader(
    debugLogging: EConfig.kDevMode,
    durationUntilAlertAgain: EConfig.kUpgradeAlertRecheckInterval,
    willDisplayUpgrade: ({required display, installedVersion, versionInfo}) {
      AnalyticsService.logUpgradePromptEvaluated(
        display: display,
        installedVersion: installedVersion,
        storeVersion: versionInfo?.appStoreVersion?.toString(),
      );
    },
  );
}
