import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_component_themes.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Builds the single [ThemeData] used by every screen.
///
/// The scheme is declared explicitly rather than seeded so the palette in
/// [AppColors] is the only source of colour truth in the app.
abstract final class AppTheme {
  static const ColorScheme colorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.primary,
    onPrimary: AppColors.textOnAccent,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.primaryOnContainer,
    secondary: AppColors.secondary,
    onSecondary: AppColors.textOnAccent,
    secondaryContainer: AppColors.secondaryContainer,
    onSecondaryContainer: AppColors.secondaryOnContainer,
    tertiary: AppColors.tertiary,
    onTertiary: AppColors.textOnAccent,
    tertiaryContainer: AppColors.tertiaryContainer,
    onTertiaryContainer: AppColors.tertiaryOnContainer,
    error: AppColors.danger,
    onError: AppColors.textOnAccent,
    errorContainer: AppColors.dangerContainer,
    onErrorContainer: Color(0xFFFFDAD4),
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    onSurfaceVariant: AppColors.textSecondary,
    surfaceContainerLowest: AppColors.background,
    surfaceContainerLow: Color(0xFF10202A),
    surfaceContainer: AppColors.surface,
    surfaceContainerHigh: AppColors.surfaceRaised,
    surfaceContainerHighest: AppColors.surfaceHigh,
    outline: AppColors.outline,
    outlineVariant: AppColors.divider,
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: AppColors.textPrimary,
    onInverseSurface: AppColors.background,
    inversePrimary: AppColors.primaryContainer,
  );

  /// The app theme. Screens should not construct [ThemeData] themselves.
  static ThemeData build() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      splashFactory: InkRipple.splashFactory,
      textTheme: AppTypography.textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
    );
    return base.copyWith(
      appBarTheme: AppComponentThemes.appBar,
      filledButtonTheme: AppComponentThemes.filledButton,
      outlinedButtonTheme: AppComponentThemes.outlinedButton,
      textButtonTheme: AppComponentThemes.textButton,
      iconButtonTheme: AppComponentThemes.iconButton,
      iconTheme: const IconThemeData(color: AppColors.textSecondary, size: 22),
      primaryIconTheme: const IconThemeData(color: AppColors.textOnAccent),
      cardTheme: AppComponentThemes.card,
      chipTheme: AppComponentThemes.chip,
      navigationBarTheme: AppComponentThemes.navigationBar,
      inputDecorationTheme: AppComponentThemes.input,
      dividerTheme: const DividerThemeData(
          color: AppColors.divider, thickness: 1, space: 1),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.surfaceHigh,
        circularTrackColor: AppColors.surfaceHigh,
      ),
      snackBarTheme: AppComponentThemes.snackBar,
      dialogTheme: AppComponentThemes.dialog,
      bottomSheetTheme: AppComponentThemes.bottomSheet,
      listTileTheme: AppComponentThemes.listTile,
      tooltipTheme: AppComponentThemes.tooltip,
      switchTheme: AppComponentThemes.switchTheme,
      segmentedButtonTheme: AppComponentThemes.segmentedButton,
      sliderTheme: AppComponentThemes.slider,
      scrollbarTheme: ScrollbarThemeData(
        thickness: WidgetStateProperty.all(6),
        radius: const Radius.circular(AppRadius.pill),
        thumbColor: WidgetStateProperty.all(
            AppColors.outlineStrong.withValues(alpha: .7)),
      ),
    );
  }
}
