import 'package:flutter/material.dart';

/// Shared spacing, radius, motion, and layout tokens.
///
/// Using these instead of ad-hoc numbers keeps rhythm consistent across every
/// screen and makes it obvious where a layout deviates from the system.
abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;

  /// Horizontal page gutter used by every scrollable screen.
  static const double gutter = 20;

  /// Minimum tappable size required for accessibility.
  static const double minTouchTarget = 48;

  /// Maximum content width before a screen stops stretching on tablets.
  static const double maxContentWidth = 720;
}

/// Corner radius scale.
abstract final class AppRadius {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 26;
  static const double pill = 999;

  static const BorderRadius cardBorder = BorderRadius.all(Radius.circular(md));
  static const BorderRadius panelBorder = BorderRadius.all(Radius.circular(lg));
}

/// Motion tokens. Durations collapse to zero when the platform asks for
/// reduced motion, which every animated widget checks through [motion].
abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);

  /// Returns [duration], or [Duration.zero] when animations are disabled.
  static Duration motion(BuildContext context, Duration duration) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
}
