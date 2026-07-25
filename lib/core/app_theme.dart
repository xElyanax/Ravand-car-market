import 'package:flutter/material.dart';

/// Brand and semantic colors that are safe to use outside a [ThemeData].
abstract final class AppColors {
  static const canvas = Color(0xFFF4F6FB);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFEBEEF5);
  static const ink = Color(0xFF111827);
  static const inkMuted = Color(0xFF667085);
  static const outline = Color(0xFFE1E6EF);

  static const primary = Color(0xFF3158FF);
  static const primaryContainer = Color(0xFFE8EDFF);
  static const secondary = Color(0xFF20BFAE);
  static const secondaryContainer = Color(0xFFD8F8F2);

  static const positive = Color(0xFF12956F);
  static const negative = Color(0xFFDC5260);
  static const warning = Color(0xFFE8A62A);

  static const heroStart = Color(0xFF101A38);
  static const heroEnd = Color(0xFF273B80);

  static const darkCanvas = Color(0xFF080D1B);
  static const darkSurface = Color(0xFF111A2F);
  static const darkSurfaceMuted = Color(0xFF18233B);
  static const darkInk = Color(0xFFF5F7FF);
  static const darkInkMuted = Color(0xFFADB6CB);
  static const darkOutline = Color(0xFF37445F);
}

/// An 8-point spacing system with a few half-steps for compact UI.
abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// Shared radii for cards, controls, sheets and pill-shaped indicators.
abstract final class AppRadius {
  static const double controlValue = 14;
  static const double cardValue = 22;
  static const double sheetValue = 28;

  static const control = BorderRadius.all(Radius.circular(controlValue));
  static const card = BorderRadius.all(Radius.circular(cardValue));
  static const sheet = BorderRadius.vertical(top: Radius.circular(sheetValue));
  static const pill = BorderRadius.all(Radius.circular(999));
}

/// Market-specific colors not represented by Material's [ColorScheme].
///
/// Use [MarketColors.of] instead of hard-coding rise, fall and chart colors so
/// widgets remain legible in both light and dark themes.
@immutable
class MarketColors extends ThemeExtension<MarketColors> {
  const MarketColors({
    required this.positive,
    required this.positiveContainer,
    required this.onPositiveContainer,
    required this.negative,
    required this.negativeContainer,
    required this.onNegativeContainer,
    required this.warning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.neutralTrend,
    required this.chartPrimary,
    required this.chartSecondary,
    required this.chartGrid,
    required this.heroStart,
    required this.heroEnd,
  });

  final Color positive;
  final Color positiveContainer;
  final Color onPositiveContainer;
  final Color negative;
  final Color negativeContainer;
  final Color onNegativeContainer;
  final Color warning;
  final Color warningContainer;
  final Color onWarningContainer;
  final Color neutralTrend;
  final Color chartPrimary;
  final Color chartSecondary;
  final Color chartGrid;
  final Color heroStart;
  final Color heroEnd;

  LinearGradient get heroGradient => LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [heroStart, heroEnd],
  );

  static const light = MarketColors(
    positive: AppColors.positive,
    positiveContainer: Color(0xFFDDF7EC),
    onPositiveContainer: Color(0xFF07543E),
    negative: AppColors.negative,
    negativeContainer: Color(0xFFFFE3E6),
    onNegativeContainer: Color(0xFF8D1F2D),
    warning: AppColors.warning,
    warningContainer: Color(0xFFFFF1D2),
    onWarningContainer: Color(0xFF6A4700),
    neutralTrend: Color(0xFF667085),
    chartPrimary: AppColors.primary,
    chartSecondary: AppColors.secondary,
    chartGrid: Color(0xFFDDE3EE),
    heroStart: AppColors.heroStart,
    heroEnd: AppColors.heroEnd,
  );

  static const dark = MarketColors(
    positive: Color(0xFF4AD6A4),
    positiveContainer: Color(0xFF103E32),
    onPositiveContainer: Color(0xFFA9F4D7),
    negative: Color(0xFFFF8994),
    negativeContainer: Color(0xFF53242C),
    onNegativeContainer: Color(0xFFFFC4C9),
    warning: Color(0xFFFFC45C),
    warningContainer: Color(0xFF4B3712),
    onWarningContainer: Color(0xFFFFE2A9),
    neutralTrend: AppColors.darkInkMuted,
    chartPrimary: Color(0xFF9BB0FF),
    chartSecondary: Color(0xFF5DE2D2),
    chartGrid: Color(0xFF2A3650),
    heroStart: AppColors.heroStart,
    heroEnd: AppColors.heroEnd,
  );

  static MarketColors of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<MarketColors>() ??
        (theme.brightness == Brightness.dark ? dark : light);
  }

  @override
  MarketColors copyWith({
    Color? positive,
    Color? positiveContainer,
    Color? onPositiveContainer,
    Color? negative,
    Color? negativeContainer,
    Color? onNegativeContainer,
    Color? warning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? neutralTrend,
    Color? chartPrimary,
    Color? chartSecondary,
    Color? chartGrid,
    Color? heroStart,
    Color? heroEnd,
  }) {
    return MarketColors(
      positive: positive ?? this.positive,
      positiveContainer: positiveContainer ?? this.positiveContainer,
      onPositiveContainer: onPositiveContainer ?? this.onPositiveContainer,
      negative: negative ?? this.negative,
      negativeContainer: negativeContainer ?? this.negativeContainer,
      onNegativeContainer: onNegativeContainer ?? this.onNegativeContainer,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      neutralTrend: neutralTrend ?? this.neutralTrend,
      chartPrimary: chartPrimary ?? this.chartPrimary,
      chartSecondary: chartSecondary ?? this.chartSecondary,
      chartGrid: chartGrid ?? this.chartGrid,
      heroStart: heroStart ?? this.heroStart,
      heroEnd: heroEnd ?? this.heroEnd,
    );
  }

  @override
  MarketColors lerp(covariant MarketColors? other, double t) {
    if (other == null) return this;
    return MarketColors(
      positive: Color.lerp(positive, other.positive, t)!,
      positiveContainer: Color.lerp(
        positiveContainer,
        other.positiveContainer,
        t,
      )!,
      onPositiveContainer: Color.lerp(
        onPositiveContainer,
        other.onPositiveContainer,
        t,
      )!,
      negative: Color.lerp(negative, other.negative, t)!,
      negativeContainer: Color.lerp(
        negativeContainer,
        other.negativeContainer,
        t,
      )!,
      onNegativeContainer: Color.lerp(
        onNegativeContainer,
        other.onNegativeContainer,
        t,
      )!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      onWarningContainer: Color.lerp(
        onWarningContainer,
        other.onWarningContainer,
        t,
      )!,
      neutralTrend: Color.lerp(neutralTrend, other.neutralTrend, t)!,
      chartPrimary: Color.lerp(chartPrimary, other.chartPrimary, t)!,
      chartSecondary: Color.lerp(chartSecondary, other.chartSecondary, t)!,
      chartGrid: Color.lerp(chartGrid, other.chartGrid, t)!,
      heroStart: Color.lerp(heroStart, other.heroStart, t)!,
      heroEnd: Color.lerp(heroEnd, other.heroEnd, t)!,
    );
  }
}

/// Material 3 themes for Ravand's Persian, RTL-first interface.
abstract final class AppTheme {
  static final ThemeData lightTheme = _buildTheme(
    brightness: Brightness.light,
    colors: MarketColors.light,
  );

  static final ThemeData darkTheme = _buildTheme(
    brightness: Brightness.dark,
    colors: MarketColors.dark,
  );

  static ThemeData get light => lightTheme;
  static ThemeData get dark => darkTheme;

  static ThemeData _buildTheme({
    required Brightness brightness,
    required MarketColors colors,
  }) {
    final isDark = brightness == Brightness.dark;
    final canvas = isDark ? AppColors.darkCanvas : AppColors.canvas;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final surfaceMuted = isDark
        ? AppColors.darkSurfaceMuted
        : AppColors.surfaceMuted;
    final ink = isDark ? AppColors.darkInk : AppColors.ink;
    final inkMuted = isDark ? AppColors.darkInkMuted : AppColors.inkMuted;
    final outline = isDark ? AppColors.darkOutline : AppColors.outline;

    final seedScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
    );
    final scheme = seedScheme.copyWith(
      primary: isDark ? const Color(0xFF9BB0FF) : AppColors.primary,
      onPrimary: isDark ? const Color(0xFF0B1B5C) : Colors.white,
      primaryContainer: isDark
          ? const Color(0xFF243A86)
          : AppColors.primaryContainer,
      onPrimaryContainer: isDark
          ? const Color(0xFFDCE4FF)
          : const Color(0xFF10256F),
      secondary: isDark ? const Color(0xFF5DE2D2) : AppColors.secondary,
      onSecondary: isDark ? const Color(0xFF003732) : const Color(0xFF073C37),
      secondaryContainer: isDark
          ? const Color(0xFF123F3B)
          : AppColors.secondaryContainer,
      onSecondaryContainer: isDark
          ? const Color(0xFFB8F5ED)
          : const Color(0xFF07554D),
      surface: surface,
      onSurface: ink,
      surfaceContainerLowest: surface,
      surfaceContainerLow: surface,
      surfaceContainer: surfaceMuted,
      surfaceContainerHigh: surfaceMuted,
      surfaceContainerHighest: surfaceMuted,
      onSurfaceVariant: inkMuted,
      outline: outline,
      outlineVariant: outline,
      error: isDark ? const Color(0xFFFFB3BA) : const Color(0xFFB42332),
      onError: isDark ? const Color(0xFF680012) : Colors.white,
      errorContainer: isDark
          ? const Color(0xFF53242C)
          : const Color(0xFFFFE3E6),
      onErrorContainer: isDark
          ? const Color(0xFFFFC4C9)
          : const Color(0xFF7A1523),
      shadow: const Color(0xFF07102A),
      scrim: const Color(0xFF07102A),
      inverseSurface: isDark ? AppColors.surface : AppColors.heroStart,
      onInverseSurface: isDark ? AppColors.ink : Colors.white,
      inversePrimary: isDark ? AppColors.primary : const Color(0xFFAFC0FF),
    );

    final textTheme = _textTheme(ink, inkMuted);
    final inputBorder = OutlineInputBorder(
      borderRadius: AppRadius.control,
      borderSide: BorderSide(color: outline),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: canvas,
      canvasColor: canvas,
      cardColor: surface,
      dividerColor: outline,
      focusColor: scheme.primary.withValues(alpha: 0.14),
      hoverColor: scheme.primary.withValues(alpha: 0.06),
      highlightColor: scheme.primary.withValues(alpha: 0.08),
      splashColor: scheme.primary.withValues(alpha: 0.10),
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[colors],
      appBarTheme: AppBarThemeData(
        backgroundColor: canvas,
        foregroundColor: ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: AppSpacing.md,
        toolbarHeight: 64,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: ink, size: 24),
        actionsIconTheme: IconThemeData(color: ink, size: 24),
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: scheme.shadow.withValues(alpha: isDark ? 0.30 : 0.08),
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.card,
          side: BorderSide(
            color: outline.withValues(alpha: isDark ? 0.7 : 0.8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsetsDirectional.fromSTEB(16, 15, 16, 15),
        hintStyle: textTheme.bodyMedium?.copyWith(color: inkMuted),
        labelStyle: textTheme.bodyMedium?.copyWith(color: inkMuted),
        floatingLabelStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.primary,
        ),
        prefixIconColor: inkMuted,
        suffixIconColor: inkMuted,
        border: inputBorder,
        enabledBorder: inputBorder,
        disabledBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: outline.withValues(alpha: 0.55)),
        ),
        focusedBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        errorBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: scheme.error, width: 1.6),
        ),
        errorStyle: textTheme.bodySmall?.copyWith(color: scheme.error),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 20),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.control),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: const Size(48, 52),
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 20),
          side: BorderSide(color: outline),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.control),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.control),
          textStyle: textTheme.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size.square(48)),
          foregroundColor: WidgetStatePropertyAll(ink),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: AppRadius.control),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 3,
        focusElevation: 3,
        hoverElevation: 4,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.control),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: scheme.primaryContainer,
        disabledColor: surfaceMuted,
        checkmarkColor: scheme.primary,
        showCheckmark: false,
        side: BorderSide(color: outline),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.pill),
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 10,
          vertical: 8,
        ),
        labelStyle: textTheme.labelMedium,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 76,
        elevation: 0,
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: AppRadius.pill,
        ),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelMedium?.copyWith(
            color: selected ? scheme.primary : inkMuted,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? scheme.primary : inkMuted,
            size: selected ? 25 : 24,
          );
        }),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: scheme.scrim.withValues(alpha: 0.48),
        elevation: 12,
        showDragHandle: true,
        dragHandleColor: outline,
        dragHandleSize: const Size(40, 4),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheet),
        clipBehavior: Clip.antiAlias,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.card),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? AppColors.darkInk : AppColors.heroStart,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: isDark ? AppColors.ink : Colors.white,
        ),
        actionTextColor: isDark ? AppColors.primary : const Color(0xFFAFC0FF),
        elevation: 4,
        insetPadding: const EdgeInsets.all(16),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.control),
      ),
      dividerTheme: DividerThemeData(color: outline, thickness: 1, space: 1),
      listTileTheme: ListTileThemeData(
        iconColor: inkMuted,
        textColor: ink,
        contentPadding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.md,
        ),
        minTileHeight: 56,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.control),
        titleTextStyle: textTheme.titleMedium,
        subtitleTextStyle: textTheme.bodySmall,
      ),
      tabBarTheme: TabBarThemeData(
        dividerColor: Colors.transparent,
        indicatorColor: scheme.primary,
        labelColor: scheme.primary,
        unselectedLabelColor: inkMuted,
        labelStyle: textTheme.labelLarge,
        unselectedLabelStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkInk : AppColors.heroStart,
          borderRadius: AppRadius.control,
        ),
        textStyle: textTheme.bodySmall?.copyWith(
          color: isDark ? AppColors.ink : Colors.white,
        ),
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        waitDuration: const Duration(milliseconds: 450),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.primaryContainer,
        circularTrackColor: scheme.primaryContainer,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: scheme.primary,
        selectionColor: scheme.primary.withValues(alpha: 0.22),
        selectionHandleColor: scheme.primary,
      ),
    );
  }

  static TextTheme _textTheme(Color ink, Color inkMuted) {
    return TextTheme(
      displayLarge: TextStyle(
        color: ink,
        fontSize: 40,
        height: 1.25,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
      displayMedium: TextStyle(
        color: ink,
        fontSize: 36,
        height: 1.28,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
      displaySmall: TextStyle(
        color: ink,
        fontSize: 32,
        height: 1.3,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
      headlineLarge: TextStyle(
        color: ink,
        fontSize: 28,
        height: 1.35,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
      headlineMedium: TextStyle(
        color: ink,
        fontSize: 24,
        height: 1.4,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      headlineSmall: TextStyle(
        color: ink,
        fontSize: 22,
        height: 1.4,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      titleLarge: TextStyle(
        color: ink,
        fontSize: 20,
        height: 1.4,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      titleMedium: TextStyle(
        color: ink,
        fontSize: 16,
        height: 1.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      titleSmall: TextStyle(
        color: ink,
        fontSize: 14,
        height: 1.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      bodyLarge: TextStyle(
        color: ink,
        fontSize: 16,
        height: 1.6,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
      ),
      bodyMedium: TextStyle(
        color: ink,
        fontSize: 14,
        height: 1.6,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
      ),
      bodySmall: TextStyle(
        color: inkMuted,
        fontSize: 12,
        height: 1.55,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
      ),
      labelLarge: TextStyle(
        color: ink,
        fontSize: 14,
        height: 1.4,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      labelMedium: TextStyle(
        color: ink,
        fontSize: 12,
        height: 1.4,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      labelSmall: TextStyle(
        color: inkMuted,
        fontSize: 11,
        height: 1.4,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
    );
  }
}
