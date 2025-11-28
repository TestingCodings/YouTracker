import 'package:flutter/material.dart';

/// Motion specification for consistent animations across the app.
/// All durations and curves follow Material 3 motion guidelines.
class MotionSpec {
  MotionSpec._();

  // Duration constants
  /// Short duration for micro-interactions (buttons, icons, toggles)
  static const Duration durationShort = Duration(milliseconds: 150);
  
  /// Medium duration for standard transitions (cards, dialogs)
  static const Duration durationMedium = Duration(milliseconds: 250);
  
  /// Long duration for complex transitions (page transitions, hero)
  static const Duration durationLong = Duration(milliseconds: 350);
  
  /// Extra long duration for elaborate sequences
  static const Duration durationExtraLong = Duration(milliseconds: 500);

  // Easing curves (Material 3)
  /// Standard easing for most animations
  static const Curve curveStandard = Curves.easeInOutCubicEmphasized;
  
  /// Decelerate easing for elements entering the screen
  static const Curve curveDecelerate = Curves.easeOutCubic;
  
  /// Accelerate easing for elements leaving the screen
  static const Curve curveAccelerate = Curves.easeInCubic;
  
  /// Emphasized easing for prominent animations
  static const Curve curveEmphasized = Curves.easeInOutCubicEmphasized;

  // Scale values for press animations
  static const double pressedScale = 0.96;
  static const double defaultScale = 1.0;
  
  // Opacity values
  static const double fadeInStart = 0.0;
  static const double fadeInEnd = 1.0;
  
  /// Checks if reduced motion is enabled in the platform settings.
  static bool shouldReduceMotion(BuildContext context) {
    return MediaQuery.of(context).disableAnimations;
  }
  
  /// Returns Duration.zero if reduced motion is enabled, otherwise the given duration.
  static Duration adaptiveDuration(BuildContext context, Duration duration) {
    return shouldReduceMotion(context) ? Duration.zero : duration;
  }
  
  /// Returns Curves.linear if reduced motion is enabled, otherwise the given curve.
  static Curve adaptiveCurve(BuildContext context, Curve curve) {
    return shouldReduceMotion(context) ? Curves.linear : curve;
  }
}

/// Spacing constants following an 8pt grid system.
/// 
/// The 8pt grid is a design system that uses multiples of 8 as the base unit
/// for all spacing and sizing. This creates visual consistency and rhythm
/// throughout the UI while ensuring alignment across components.
/// 
/// Usage:
/// ```dart
/// Padding(
///   padding: EdgeInsets.all(AppSpacing.df), // 16pt default padding
///   child: ...
/// )
/// 
/// SizedBox(height: AppSpacing.lg), // 24pt vertical spacing
/// ```
/// 
/// The scale follows: xs(4) < sm(8) < md(12) < df(16) < lg(24) < xl(32) < xxl(48)
class AppSpacing {
  AppSpacing._();
  
  /// Extra small spacing (4pt)
  static const double xs = 4.0;
  
  /// Small spacing (8pt)
  static const double sm = 8.0;
  
  /// Medium spacing (12pt)
  static const double md = 12.0;
  
  /// Default spacing (16pt)
  static const double df = 16.0;
  
  /// Large spacing (24pt)
  static const double lg = 24.0;
  
  /// Extra large spacing (32pt)
  static const double xl = 32.0;
  
  /// Extra extra large spacing (48pt)
  static const double xxl = 48.0;
  
  // Card and container sizes
  static const double cardBorderRadius = 16.0;
  static const double buttonBorderRadius = 12.0;
  static const double chipBorderRadius = 20.0;
  static const double avatarSizeSmall = 32.0;
  static const double avatarSizeMedium = 40.0;
  static const double avatarSizeLarge = 56.0;
  
  // Icon sizes
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
  
  /// Standard padding for interactive elements (buttons, icons)
  static const double interactivePadding = 8.0;
  
  // Padding shortcuts
  static const EdgeInsets paddingXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingDf = EdgeInsets.all(df);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingXl = EdgeInsets.all(xl);
  
  /// Horizontal padding for screen content
  static const EdgeInsets screenPaddingH = EdgeInsets.symmetric(horizontal: df);
  
  /// Full screen padding
  static const EdgeInsets screenPadding = EdgeInsets.all(df);
}
