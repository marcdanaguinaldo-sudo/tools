import 'package:flutter/material.dart';

/// Typographic scale for the app.
///
/// Sizes step gently so large accessibility text scales still fit, and every
/// style carries an explicit line height so multi-line copy stays readable.
abstract final class AppTypography {
  static const TextTheme textTheme = TextTheme(
    // Hero copy on the home screen.
    displayLarge: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        height: 1.14,
        letterSpacing: -0.9),
    displayMedium: TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w800,
        height: 1.16,
        letterSpacing: -0.7),

    // Screen titles.
    headlineLarge: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        height: 1.2,
        letterSpacing: -0.6),
    headlineMedium: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.24,
        letterSpacing: -0.4),
    headlineSmall: TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w700,
        height: 1.3,
        letterSpacing: -0.2),

    // Section and card titles.
    titleLarge:
        TextStyle(fontSize: 17, fontWeight: FontWeight.w700, height: 1.3),
    titleMedium:
        TextStyle(fontSize: 15, fontWeight: FontWeight.w700, height: 1.35),
    titleSmall: TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w700,
        height: 1.35,
        letterSpacing: 0.1),

    // Reading copy.
    bodyLarge: TextStyle(fontSize: 16, height: 1.55),
    bodyMedium: TextStyle(fontSize: 14, height: 1.5),
    bodySmall: TextStyle(fontSize: 12.5, height: 1.45),

    // Buttons, chips, and metadata.
    labelLarge: TextStyle(
        fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.1),
    labelMedium: TextStyle(
        fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5),
    labelSmall: TextStyle(
        fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.3),
  );

  /// Small uppercase label that introduces a section ("CONTINUE LEARNING").
  static const TextStyle eyebrow = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.6,
      height: 1.2);
}
