import 'package:flutter_test/flutter_test.dart';
import 'package:binge_quest/core/constants/e_text.dart';
import 'package:binge_quest/core/constants/e_colors.dart';
import 'package:binge_quest/core/constants/e_sizes.dart';

void main() {
  group('E-prefixed constants', () {
    test('EText contains app name', () {
      expect(EText.appName, 'BingeQuest');
      expect(EText.appTagline, isNotEmpty);
    });

    test('EColors has valid primary colors', () {
      expect(EColors.primary, isNotNull);
      expect(EColors.background, isNotNull);
      expect(EColors.textPrimary, isNotNull);
    });

    test('ESizes has valid dimensions', () {
      expect(ESizes.md, greaterThan(0));
      expect(ESizes.buttonHeightMd, greaterThan(0));
      expect(ESizes.radiusMd, greaterThan(0));
    });
  });
}
