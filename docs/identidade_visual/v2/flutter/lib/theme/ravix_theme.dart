import 'package:flutter/material.dart';

import 'ravix_colors.dart';
import 'ravix_shapes.dart';
import 'ravix_tokens.dart';
import 'ravix_typography.dart';

export 'ravix_colors.dart';
export 'ravix_shapes.dart';
export 'ravix_tokens.dart';
export 'ravix_typography.dart';

/// Tema Material 3 do Ravix.
///
/// ```dart
/// MaterialApp(
///   theme: RavixTheme.light,
///   darkTheme: RavixTheme.dark,
///   themeMode: ThemeMode.system,
/// )
/// ```
abstract final class RavixTheme {
  static final ThemeData light = _build(
    scheme: RavixColors.lightScheme,
    background: RavixColors.lightBackground,
    textColor: RavixColors.lightText,
    muted: RavixColors.lightTextMuted,
    line: RavixColors.lightLine,
    focus: RavixColors.petroleo,
    fab: RavixColors.menta,
    onFab: RavixColors.tinta,
    tokens: RavixTokens.light,
  );

  static final ThemeData dark = _build(
    scheme: RavixColors.darkScheme,
    background: RavixColors.darkBackground,
    textColor: RavixColors.darkText,
    muted: RavixColors.darkTextMuted,
    line: RavixColors.darkLine,
    focus: RavixColors.darkInfo,
    fab: RavixColors.menta,
    onFab: RavixColors.tinta,
    tokens: RavixTokens.dark,
  );

  static ThemeData _build({
    required ColorScheme scheme,
    required Color background,
    required Color textColor,
    required Color muted,
    required Color line,
    required Color focus,
    required Color fab,
    required Color onFab,
    required RavixTokens tokens,
  }) {
    final text = RavixTypography.textTheme(text: textColor, muted: muted);
    final lineSide = BorderSide(color: line);

    RavixCutInputBorder field(Color color, [double width = 1]) =>
        RavixCutInputBorder(borderSide: BorderSide(color: color, width: width));

    return ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      fontFamily: RavixFonts.text,
      textTheme: text,
      primaryTextTheme: text,
      extensions: <ThemeExtension<dynamic>>[tokens],
      dividerColor: line,
      dividerTheme: DividerThemeData(color: line, thickness: 1, space: 1),
      iconTheme: IconThemeData(color: textColor, size: 24),

      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: textColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.headlineSmall,
      ),

      // Botões: chanfro de 8, 52 de altura
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          shape: RavixShapes.cut(RavixShapes.m),
          textStyle: text.labelLarge,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          shape: RavixShapes.cut(RavixShapes.m),
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          foregroundColor: textColor,
          side: lineSide,
          shape: RavixShapes.cut(RavixShapes.m),
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.brightness == Brightness.light ? RavixColors.petroleo : RavixColors.menta,
          shape: RavixShapes.cut(RavixShapes.p),
          textStyle: text.labelLarge,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(shape: WidgetStatePropertyAll(RavixShapes.cut(RavixShapes.m))),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: fab,
        foregroundColor: onFab,
        elevation: 2,
        focusElevation: 2,
        hoverElevation: 3,
        highlightElevation: 1,
        shape: RavixShapes.cut(RavixShapes.g),
        extendedTextStyle: text.labelLarge,
      ),

      // Campos: preenchidos, chanfro de 8, rótulo flutuando dentro
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        border: field(line),
        enabledBorder: field(line),
        disabledBorder: field(line.withValues(alpha: 0.5)),
        focusedBorder: field(focus, 2),
        errorBorder: field(scheme.error),
        focusedErrorBorder: field(scheme.error, 2),
        labelStyle: text.bodyLarge?.copyWith(color: muted),
        floatingLabelStyle: WidgetStateTextStyle.resolveWith((states) {
          final color = states.contains(WidgetState.error)
              ? scheme.error
              : states.contains(WidgetState.focused)
                  ? focus
                  : muted;
          return TextStyle(fontFamily: RavixFonts.text, fontWeight: FontWeight.w600, fontSize: 13, color: color);
        }),
        hintStyle: text.bodyLarge?.copyWith(color: muted.withValues(alpha: 0.7)),
        helperStyle: text.bodySmall,
        errorStyle: text.bodySmall?.copyWith(color: scheme.error),
        prefixIconColor: muted,
        suffixIconColor: muted,
      ),

      // Chips: chanfro de 4, selecionado em Floresta (claro) ou Menta (escuro)
      chipTheme: ChipThemeData(
        shape: RavixShapes.cut(RavixShapes.p, side: lineSide),
        side: lineSide,
        backgroundColor: scheme.surface,
        selectedColor: scheme.primary,
        disabledColor: scheme.surfaceContainerHigh,
        labelStyle: text.labelMedium,
        secondaryLabelStyle: text.labelMedium?.copyWith(color: scheme.onPrimary),
        checkmarkColor: scheme.onPrimary,
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      ),

      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RavixShapes.cut(RavixShapes.g, side: lineSide),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: muted,
        titleTextStyle: text.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
        subtitleTextStyle: text.bodySmall,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        minVerticalPadding: 10,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        indicatorShape: RavixShapes.cut(RavixShapes.m),
        labelTextStyle: WidgetStatePropertyAll(text.labelMedium),
        height: 68,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: line,
        shape: RavixShapes.cutTop(RavixShapes.g),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RavixShapes.cut(RavixShapes.g),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyLarge,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: RavixColors.floresta,
        contentTextStyle: text.bodyMedium?.copyWith(color: RavixColors.nevoa),
        actionTextColor: RavixColors.menta,
        shape: RavixShapes.cut(RavixShapes.m),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.brightness == Brightness.light ? RavixColors.menta600 : RavixColors.menta,
        linearTrackColor: scheme.surfaceContainerHigh,
        linearMinHeight: 8,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RavixShapes.cut(RavixShapes.g),
        dayShape: WidgetStatePropertyAll(RavixShapes.cut(RavixShapes.p)),
        headerHeadlineStyle: text.headlineSmall,
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: scheme.surface,
        shape: RavixShapes.cut(RavixShapes.g),
        hourMinuteShape: RavixShapes.cut(RavixShapes.m),
        dayPeriodShape: RavixShapes.cut(RavixShapes.m),
      ),
    );
  }
}
