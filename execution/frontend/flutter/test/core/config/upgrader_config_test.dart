import 'package:flutter_test/flutter_test.dart';
import 'package:binge_quest/core/config/upgrader_config.dart';
import 'package:binge_quest/core/constants/e_config.dart';

void main() {
  group('buildAppUpgrader', () {
    test('uses the named re-check interval and dev-mode debug flag', () {
      final upgrader = buildAppUpgrader();

      expect(upgrader.state.durationUntilAlertAgain, EConfig.kUpgradeAlertRecheckInterval);
      expect(upgrader.state.debugLogging, EConfig.kDevMode);
    });
  });
}
