import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Per-component Material themes.
///
/// Everything that can drift between screens - button shapes, surface tones,
/// border widths, and state colours - is decided once here.
abstract final class AppComponentThemes {
  // -----------------------------------------------------------------------
  // Navigation and chrome
  // -----------------------------------------------------------------------

  static const AppBarTheme appBar = AppBarTheme(
    backgroundColor: AppColors.background,
    foregroundColor: AppColors.textPrimary,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: false,
    toolbarHeight: 60,
    titleSpacing: AppSpacing.gutter,
    titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.2),
    iconTheme: IconThemeData(color: AppColors.textSecondary, size: 22),
    actionsIconTheme: IconThemeData(color: AppColors.textSecondary, size: 22),
  );

  static final NavigationBarThemeData navigationBar = NavigationBarThemeData(
    backgroundColor: AppColors.surface,
    surfaceTintColor: Colors.transparent,
    shadowColor: Colors.transparent,
    elevation: 0,
    height: 70,
    indicatorColor: AppColors.primaryContainer,
    indicatorShape: const StadiumBorder(),
    labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
          size: 24,
          color: states.contains(WidgetState.selected)
              ? AppColors.primaryOnContainer
              : AppColors.textMuted,
        )),
    labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          color: states.contains(WidgetState.selected)
              ? AppColors.primaryOnContainer
              : AppColors.textMuted,
        )),
  );

  // -----------------------------------------------------------------------
  // Buttons
  // -----------------------------------------------------------------------

  static final FilledButtonThemeData filledButton = FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.textOnAccent,
      disabledBackgroundColor: AppColors.surfaceHigh,
      disabledForegroundColor: AppColors.textMuted,
      minimumSize: const Size(64, 52),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.sm + 2),
      textStyle: AppTypography.textTheme.labelLarge,
      elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.cardBorder),
    ),
  );

  static final OutlinedButtonThemeData outlinedButton = OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.textPrimary,
      disabledForegroundColor: AppColors.textMuted,
      minimumSize: const Size(64, 52),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.sm + 2),
      textStyle: AppTypography.textTheme.labelLarge,
      side: const BorderSide(color: AppColors.outlineStrong, width: 1.4),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.cardBorder),
    ),
  );

  static final TextButtonThemeData textButton = TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primaryStrong,
      disabledForegroundColor: AppColors.textMuted,
      minimumSize: const Size(48, 44),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      textStyle: AppTypography.textTheme.labelLarge,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.sm))),
    ),
  );

  static final IconButtonThemeData iconButton = IconButtonThemeData(
    style: ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(
          Size(AppSpacing.minTouchTarget, AppSpacing.minTouchTarget)),
      iconSize: const WidgetStatePropertyAll(22),
      padding: const WidgetStatePropertyAll(EdgeInsets.all(AppSpacing.sm)),
      foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? AppColors.textMuted
              : states.contains(WidgetState.selected)
                  ? AppColors.primary
                  : AppColors.textSecondary),
      shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: AppRadius.cardBorder)),
    ),
  );

  // -----------------------------------------------------------------------
  // Surfaces
  // -----------------------------------------------------------------------

  static const CardThemeData card = CardThemeData(
    color: AppColors.surface,
    surfaceTintColor: Colors.transparent,
    shadowColor: Colors.transparent,
    elevation: 0,
    margin: EdgeInsets.zero,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: AppRadius.cardBorder,
      side: BorderSide(color: AppColors.outline),
    ),
  );

  static const ChipThemeData chip = ChipThemeData(
    backgroundColor: AppColors.surfaceRaised,
    selectedColor: AppColors.primaryContainer,
    disabledColor: AppColors.surface,
    surfaceTintColor: Colors.transparent,
    side: BorderSide(color: AppColors.outline),
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.pill))),
    labelStyle: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary),
    secondaryLabelStyle: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        color: AppColors.primaryOnContainer),
    checkmarkColor: AppColors.primaryOnContainer,
    iconTheme: IconThemeData(color: AppColors.textSecondary, size: 18),
    padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
  );

  // -----------------------------------------------------------------------
  // Inputs
  // -----------------------------------------------------------------------

  static final InputDecorationTheme input = InputDecorationTheme(
    filled: true,
    fillColor: AppColors.surfaceRaised,
    contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md, vertical: AppSpacing.md),
    hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 15),
    labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
    floatingLabelStyle: const TextStyle(color: AppColors.primary, fontSize: 15),
    helperStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
    errorStyle: const TextStyle(color: AppColors.danger, fontSize: 12.5),
    prefixIconColor: AppColors.textMuted,
    suffixIconColor: AppColors.textMuted,
    border: _inputBorder(AppColors.outline),
    enabledBorder: _inputBorder(AppColors.outline),
    focusedBorder: _inputBorder(AppColors.primary, width: 1.6),
    errorBorder: _inputBorder(AppColors.danger),
    focusedErrorBorder: _inputBorder(AppColors.danger, width: 1.6),
    disabledBorder: _inputBorder(AppColors.divider),
  );

  static OutlineInputBorder _inputBorder(Color color, {double width = 1.2}) =>
      OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.md)),
        borderSide: BorderSide(color: color, width: width),
      );

  // -----------------------------------------------------------------------
  // Feedback surfaces
  // -----------------------------------------------------------------------

  static const SnackBarThemeData snackBar = SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: AppColors.surfaceHigh,
    elevation: 0,
    showCloseIcon: true,
    closeIconColor: AppColors.textSecondary,
    actionTextColor: AppColors.primaryStrong,
    contentTextStyle:
        TextStyle(color: AppColors.textPrimary, fontSize: 14, height: 1.4),
    shape: RoundedRectangleBorder(borderRadius: AppRadius.cardBorder),
  );

  static const DialogThemeData dialog = DialogThemeData(
    backgroundColor: AppColors.surfaceRaised,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    iconColor: AppColors.primary,
    titleTextStyle: TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.3),
    contentTextStyle:
        TextStyle(fontSize: 14.5, color: AppColors.textSecondary, height: 1.5),
    shape: RoundedRectangleBorder(borderRadius: AppRadius.panelBorder),
  );

  static const BottomSheetThemeData bottomSheet = BottomSheetThemeData(
    backgroundColor: AppColors.surfaceRaised,
    modalBackgroundColor: AppColors.surfaceRaised,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    modalElevation: 0,
    showDragHandle: true,
    dragHandleColor: AppColors.outlineStrong,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
  );

  static const ListTileThemeData listTile = ListTileThemeData(
    textColor: AppColors.textPrimary,
    iconColor: AppColors.textSecondary,
    titleTextStyle: TextStyle(
        fontSize: 15.5,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary),
    subtitleTextStyle:
        TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.4),
    leadingAndTrailingTextStyle:
        TextStyle(fontSize: 13, color: AppColors.textMuted),
    contentPadding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md, vertical: AppSpacing.xxs),
    minVerticalPadding: AppSpacing.sm,
    selectedColor: AppColors.primaryOnContainer,
    selectedTileColor: AppColors.primaryContainer,
    shape: RoundedRectangleBorder(borderRadius: AppRadius.cardBorder),
  );

  static const TooltipThemeData tooltip = TooltipThemeData(
    decoration: BoxDecoration(
      color: AppColors.surfaceHigh,
      borderRadius: BorderRadius.all(Radius.circular(AppRadius.xs)),
    ),
    textStyle:
        TextStyle(color: AppColors.textPrimary, fontSize: 12.5, height: 1.35),
    padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
    waitDuration: Duration(milliseconds: 400),
    showDuration: Duration(seconds: 4),
  );

  // -----------------------------------------------------------------------
  // Selection controls
  // -----------------------------------------------------------------------

  static final SwitchThemeData switchTheme = SwitchThemeData(
    materialTapTargetSize: MaterialTapTargetSize.padded,
    thumbColor: WidgetStateProperty.resolveWith((states) =>
        states.contains(WidgetState.selected)
            ? AppColors.primary
            : AppColors.outlineStrong),
    trackColor: WidgetStateProperty.resolveWith((states) =>
        states.contains(WidgetState.selected)
            ? AppColors.primaryContainer
            : AppColors.surfaceHigh),
    trackOutlineColor: WidgetStateProperty.resolveWith((states) =>
        states.contains(WidgetState.selected)
            ? AppColors.primary
            : AppColors.outline),
  );

  static final SegmentedButtonThemeData segmentedButton =
      SegmentedButtonThemeData(
    style: ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(0, 44)),
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs)),
      textStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      backgroundColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? AppColors.primaryContainer
              : Colors.transparent),
      foregroundColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? AppColors.primaryOnContainer
              : AppColors.textSecondary),
      side: const WidgetStatePropertyAll(
          BorderSide(color: AppColors.outlineStrong, width: 1.2)),
      shape: const WidgetStatePropertyAll(RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.pill)))),
    ),
  );

  static final SliderThemeData slider = SliderThemeData(
    activeTrackColor: AppColors.primary,
    inactiveTrackColor: AppColors.surfaceHigh,
    disabledActiveTrackColor: AppColors.outline,
    disabledInactiveTrackColor: AppColors.surface,
    thumbColor: AppColors.primary,
    disabledThumbColor: AppColors.outlineStrong,
    overlayColor: AppColors.primary.withValues(alpha: .14),
    valueIndicatorColor: AppColors.primaryContainer,
    valueIndicatorTextStyle: const TextStyle(
        color: AppColors.primaryOnContainer, fontWeight: FontWeight.w700),
    trackHeight: 5,
  );
}
