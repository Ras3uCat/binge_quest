# Frontend Design — Detailed Implementation Guide

## Design Token System Setup

### lib/core/theme/e_colors.dart
```dart
import 'package:flutter/material.dart';

abstract class EColors {
  // Brand primaries
  static const primary     = Color(0xFF58E3EF); // P-Cyan
  static const accent      = Color(0xFFD34CF1); // A-Magenta
  static const gold        = Color(0xFFFFD700);

  // Backgrounds
  static const background  = Color(0xFF0A0E1A); // Midnight-Base
  static const surface     = Color(0xFF111827); // Circuit-Slate
  static const surfaceAlt  = Color(0xFF1A2332);

  // Text
  static const textPrimary    = Color(0xFFF0F8FF); // cyanTintedWhite
  static const textSecondary  = Color(0xFF8BA3BF);
  static const textMuted      = Color(0xFF4A6080);

  // Semantic
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const error   = Color(0xFFEF4444);

  // Neon glows (use sparingly — for brand moments)
  static const neonCyan    = Color(0x4058E3EF); // 25% opacity cyan
  static const neonMagenta = Color(0x40D34CF1); // 25% opacity magenta
}
```

### lib/core/theme/e_spacing.dart
```dart
abstract class ESpacing {
  static const double xs  = 4.0;
  static const double sm  = 8.0;
  static const double md  = 16.0;
  static const double lg  = 24.0;
  static const double xl  = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;
}
```

### lib/core/theme/e_text_styles.dart
```dart
import 'package:flutter/material.dart';
import 'e_colors.dart';

abstract class ETextStyles {
  static const _fontPlay    = 'Play';
  static const _fontGrotesk = 'SpaceGrotesk';
  static const _fontInter   = 'Inter';

  static const display = TextStyle(
    fontFamily: _fontPlay,
    fontSize: 48,
    fontWeight: FontWeight.w700,
    color: EColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const headline = TextStyle(
    fontFamily: _fontPlay,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: EColors.textPrimary,
  );

  static const title = TextStyle(
    fontFamily: _fontGrotesk,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: EColors.textPrimary,
  );

  static const body = TextStyle(
    fontFamily: _fontInter,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: EColors.textSecondary,
    height: 1.6,
  );

  static const label = TextStyle(
    fontFamily: _fontGrotesk,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: EColors.textMuted,
    letterSpacing: 0.8,
  );

  static const neonCyan = TextStyle(
    fontFamily: _fontPlay,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: EColors.primary,
    shadows: [
      Shadow(color: EColors.primary, blurRadius: 8),
      Shadow(color: EColors.primary, blurRadius: 16),
    ],
  );
}
```

## Animation Patterns

### Entrance Animation (every new screen)
```dart
class _FadeSlideIn extends StatefulWidget {
  final Widget child;
  final int delayMs;
  const _FadeSlideIn({required this.child, this.delayMs = 0});

  @override
  State<_FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<_FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _opacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _slide = Tween(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: widget.delayMs), _ctrl.forward);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _opacity,
    child: SlideTransition(position: _slide, child: widget.child),
  );
}
```

### Neon Pulse (brand accent elements)
```dart
class NeonPulse extends StatefulWidget {
  final Widget child;
  const NeonPulse({super.key, required this.child});

  @override
  State<NeonPulse> createState() => _NeonPulseState();
}

class _NeonPulseState extends State<NeonPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _opacity = Tween(begin: 0.7, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) =>
      FadeTransition(opacity: _opacity, child: widget.child);
}
```

### Press Scale (interactive elements)
```dart
class PressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const PressScale({super.key, required this.child, required this.onTap});

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scale = Tween(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => _ctrl.forward(),
    onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
    onTapCancel: () => _ctrl.reverse(),
    child: ScaleTransition(scale: _scale, child: widget.child),
  );
}
```

## NeonButton Component
```dart
class NeonButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;
  final bool isLoading;

  const NeonButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color = EColors.primary,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: isLoading ? () {} : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: ESpacing.xl,
          vertical: ESpacing.md,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color, width: 1.5),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.3), blurRadius: 12, spreadRadius: 0),
          ],
          gradient: LinearGradient(
            colors: [color.withOpacity(0.15), Colors.transparent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: color, strokeWidth: 2),
              )
            : Text(label, style: ETextStyles.title.copyWith(color: color)),
      ),
    );
  }
}
```

## Responsive Layout Pattern
```dart
// lib/core/utils/responsive/responsive_layout.dart
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  static bool isMobile(BuildContext ctx) => MediaQuery.sizeOf(ctx).width < 600;
  static bool isTablet(BuildContext ctx) {
    final w = MediaQuery.sizeOf(ctx).width;
    return w >= 600 && w < 1200;
  }
  static bool isDesktop(BuildContext ctx) => MediaQuery.sizeOf(ctx).width >= 1200;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        if (constraints.maxWidth >= 1200) return desktop ?? tablet ?? mobile;
        if (constraints.maxWidth >= 600) return tablet ?? mobile;
        return mobile;
      },
    );
  }
}
```
