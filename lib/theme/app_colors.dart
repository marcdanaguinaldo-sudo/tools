import 'package:flutter/material.dart';

import '../models/tool_model.dart';

/// Single source of truth for the Kusina colour system.
///
/// A warm, earthy kitchen palette: deep charcoal-teal grounds, toasted amber
/// as the accent, and sage green for progress and confirmation. Every screen
/// reads from here so colour never drifts between features.
abstract final class AppColors {
  // -----------------------------------------------------------------------
  // Grounds
  // -----------------------------------------------------------------------

  /// Page background behind every screen.
  static const Color background = Color(0xFF0B161C);

  /// Default card and panel surface.
  static const Color surface = Color(0xFF14242E);

  /// Raised surface for nested panels, inputs, and list tiles.
  static const Color surfaceRaised = Color(0xFF1B303C);

  /// Highest surface step for chips, selected rows, and pressed states.
  static const Color surfaceHigh = Color(0xFF24404E);

  /// Ambient wash used behind hero panels.
  static const Color glow = Color(0xFF1F3A34);

  /// Deepest ground used for the camera stage.
  static const Color stage = Color(0xFF050C11);

  // -----------------------------------------------------------------------
  // Lines and separators
  // -----------------------------------------------------------------------

  static const Color outline = Color(0xFF2C4753);
  static const Color outlineStrong = Color(0xFF3D5F6E);
  static const Color divider = Color(0xFF203640);

  // -----------------------------------------------------------------------
  // Content
  // -----------------------------------------------------------------------

  static const Color textPrimary = Color(0xFFECF2F5);
  static const Color textSecondary = Color(0xFFB3C6D0);
  static const Color textMuted = Color(0xFF8298A4);
  static const Color textOnAccent = Color(0xFF241A09);

  // -----------------------------------------------------------------------
  // Accents
  // -----------------------------------------------------------------------

  /// Toasted amber — primary actions and the app mark.
  static const Color primary = Color(0xFFF2B457);
  static const Color primaryStrong = Color(0xFFFFC978);
  static const Color primaryContainer = Color(0xFF3A2D16);
  static const Color primaryOnContainer = Color(0xFFFFE2B4);

  /// Sage green — progress, completion, and confirmation.
  static const Color secondary = Color(0xFF86C9A4);
  static const Color secondaryContainer = Color(0xFF1E3A2E);
  static const Color secondaryOnContainer = Color(0xFFC4E8D3);

  /// Terracotta — heat, handling, and cautionary tool accents.
  static const Color tertiary = Color(0xFFD98A5F);
  static const Color tertiaryContainer = Color(0xFF3A2418);
  static const Color tertiaryOnContainer = Color(0xFFF5D2BC);

  // -----------------------------------------------------------------------
  // Semantic states
  // -----------------------------------------------------------------------

  static const Color success = Color(0xFF86C9A4);
  static const Color successContainer = Color(0xFF17342A);

  static const Color warning = Color(0xFFE8B04B);
  static const Color warningContainer = Color(0xFF352913);

  static const Color danger = Color(0xFFEF8C7C);
  static const Color dangerContainer = Color(0xFF3A1F1A);

  static const Color info = Color(0xFF9CC7D8);
  static const Color infoContainer = Color(0xFF17303A);

  // -----------------------------------------------------------------------
  // Overlays
  // -----------------------------------------------------------------------

  /// Scrim painted over the camera preview behind the alignment guides.
  static const Color cameraScrim = Color(0xCC050B0F);

  /// Soft shadow used under illustrations and floating panels.
  static const Color shadow = Color(0x66000000);

  // -----------------------------------------------------------------------
  // Tool category accents
  // -----------------------------------------------------------------------

  /// Accent used to tint a tool card by its catalog category.
  ///
  /// Keyed off [ToolCategories] so a renamed or added category cannot silently
  /// fall through to [primary] again, which is what happened when these keys
  /// still named the old six-tool categories.
  static const Map<String, Color> categoryAccents = {
    ToolCategories.cutting: Color(0xFFE08A6E),
    ToolCategories.measuring: Color(0xFF6FC3E8),
    ToolCategories.mixing: Color(0xFF74D69B),
    ToolCategories.straining: Color(0xFFB39BE8),
    ToolCategories.cooking: Color(0xFFEF7A9C),
    ToolCategories.misc: Color(0xFFC9A227),
  };

  /// Accent for [category], falling back to the primary accent.
  static Color forCategory(String category) =>
      categoryAccents[category] ?? primary;
}
