import 'package:flutter/material.dart';

/// Motion specification constants for consistent animations.
/// Respects reduced motion accessibility settings.

/// Animation durations for consistent timing.
class MotionDurations {
  MotionDurations._();

  /// Short duration for micro-interactions: 150ms
  static const Duration short = Duration(milliseconds: 150);

  /// Medium duration for standard animations: 250ms
  static const Duration medium = Duration(milliseconds: 250);

  /// Long duration for complex transitions: 350ms
  static const Duration long = Duration(milliseconds: 350);

  /// Extra long duration for page transitions: 450ms
  static const Duration extraLong = Duration(milliseconds: 450);
}

/// Animation curves following Material 3 motion guidelines.
class MotionCurves {
  MotionCurves._();

  /// Standard easing for most animations
  static const Curve standard = Curves.easeInOutCubic;

  /// Emphasized easing for important transitions
  static const Curve emphasized = Curves.easeInOutCubicEmphasized;

  /// Decelerate for entering elements
  static const Curve decelerate = Curves.easeOutCubic;

  /// Accelerate for exiting elements
  static const Curve accelerate = Curves.easeInCubic;
}

/// Helper class to respect reduced motion settings.
class MotionSpec {
  MotionSpec._();

  /// Returns whether animations should be reduced based on platform settings.
  static bool shouldReduceMotion(BuildContext context) {
    return MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  }

  /// Returns the appropriate duration based on reduced motion setting.
  /// Returns [Duration.zero] if animations should be reduced.
  static Duration getDuration(
    BuildContext context,
    Duration normalDuration,
  ) {
    return shouldReduceMotion(context) ? Duration.zero : normalDuration;
  }

  /// Returns the appropriate curve based on reduced motion setting.
  /// Returns [Curves.linear] for instant animations when reduced.
  static Curve getCurve(BuildContext context, Curve normalCurve) {
    return shouldReduceMotion(context) ? Curves.linear : normalCurve;
  }

  /// Returns a scale factor for animation durations.
  /// 0.0 when animations are disabled, 1.0 otherwise.
  static double getAnimationScale(BuildContext context) {
    return shouldReduceMotion(context) ? 0.0 : 1.0;
  }
}

/// Page transition builders for consistent navigation animations.
class MotionPageTransitions {
  MotionPageTransitions._();

  /// Creates a fade + scale transition for Android.
  static Widget fadeScaleTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final shouldReduce = MotionSpec.shouldReduceMotion(context);
    if (shouldReduce) {
      return child;
    }

    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: MotionCurves.decelerate,
      ),
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.92, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: MotionCurves.emphasized,
          ),
        ),
        child: child,
      ),
    );
  }

  /// Creates a slide transition from the right (iOS style).
  static Widget cupertinoTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final shouldReduce = MotionSpec.shouldReduceMotion(context);
    if (shouldReduce) {
      return child;
    }

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: animation,
          curve: MotionCurves.emphasized,
        ),
      ),
      child: child,
    );
  }
}