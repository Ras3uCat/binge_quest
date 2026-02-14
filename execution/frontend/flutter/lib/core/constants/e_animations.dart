import 'package:flutter/material.dart';

/// Animation constants for consistent motion throughout the app.
class EAnimations {
  EAnimations._();

  // Durations
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration shimmer = Duration(milliseconds: 1500);

  // Stagger delays for list animations
  static const Duration staggerDelay = Duration(milliseconds: 50);
  static const Duration staggerDelayLong = Duration(milliseconds: 100);

  // Curves
  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve entryCurve = Curves.easeOut;
  static const Curve exitCurve = Curves.easeIn;
  static const Curve bounceCurve = Curves.elasticOut;
  static const Curve sharpCurve = Curves.easeInOutCubic;

  // Common animation values
  static const double fadeStart = 0.0;
  static const double fadeEnd = 1.0;
  static const double slideOffset = 20.0;
  static const double scaleStart = 0.95;
  static const double scaleEnd = 1.0;
}
