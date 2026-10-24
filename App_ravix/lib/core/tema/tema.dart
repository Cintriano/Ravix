/// Tema do Ravix: identidade CAPRA, área Finanças (acento Peach).
///
/// Mapeamento de cores e componentes conforme
/// `docs/identidade_visual/capra-identidade-visual-mobile.md`.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ravix/core/tema/capra_tokens.dart';

/// Família do texto.
const familiaTexto = 'Inter';

/// Família dos números grandes e títulos de tela (corte óptico de 28 pt).
const familiaTitulo = 'InterTitulo';

/// Números tabulares, para valores, horários e contadores.
const numerosTabulares = [FontFeature.tabularFigures()];

/// Dados de marca que o `ThemeData` não carrega: a paleta CAPRA completa e o
/// acento do produto. Use `Theme.of(context).extension<TemaRavix>()!` ou
/// `context.temaRavix`.
@immutable
final class TemaRavix extends ThemeExtension<TemaRavix> {
  /// Cria a extensão com [paleta]; o acento é o de Finanças.
  const new(this.paleta);

  /// Paleta do tema ativo (dark ou claro).
  final CapraPaleta paleta;

  /// Acento do Ravix: Peach, de Finanças. Não indica estado.
  Color get acento => paleta.accentFinance;

  @override
  TemaRavix copyWith({CapraPaleta? paleta}) => TemaRavix(paleta ?? this.paleta);

  // Tokens discretos não se interpolam: troca no meio da animação.
  @override
  TemaRavix lerp(TemaRavix? other, double t) =>
      other == null || t < 0.5 ? this : other;
}

/// Atalho para a extensão de tema do Ravix.
extension TemaRavixContexto on BuildContext {
  /// Extensão [TemaRavix] do tema atual.
  TemaRavix get temaRavix => Theme.of(this).extension<TemaRavix>()!;
}

/// Tema do Ravix para [brilho]. O app usa os dois e segue o sistema.
ThemeData temaRavix(Brightness brilho) {
  final escuro = brilho == Brightness.dark;
  final p = escuro ? CapraTokens.escuro : CapraTokens.claro;
  final acento = p.accentFinance;

  final cores = ColorScheme(
    brightness: brilho,
    primary: acento,
    onPrimary: p.onAccent,
    primaryContainer: p.surfaceElevated,
    onPrimaryContainer: acento,
    secondary: acento,
    onSecondary: p.onAccent,
    secondaryContainer: p.surfaceElevated,
    onSecondaryContainer: acento,
    tertiary: acento,
    onTertiary: p.onAccent,
    error: p.danger,
    onError: p.onAccent,
    surface: p.background,
    onSurface: p.textPrimary,
    onSurfaceVariant: p.textSecondary,
    surfaceContainerLowest: p.background,
    surfaceContainerLow: p.surface,
    surfaceContainer: p.surface,
    surfaceContainerHigh: p.surfaceElevated,
    surfaceContainerHighest: p.surfaceElevated,
    outline: p.borderStrong,
    outlineVariant: p.border,
    inverseSurface: p.textPrimary,
    onInverseSurface: p.background,
    inversePrimary: acento,
    shadow: Colors.transparent,
    scrim: Colors.black54,
    surfaceTint: Colors.transparent,
  );

  final texto = _textos(p);
  const raioSm = BorderRadius.all(Radius.circular(CapraTokens.radiusSm));
  const raioMd = BorderRadius.all(Radius.circular(CapraTokens.radiusMd));
  const raioLg = BorderRadius.all(Radius.circular(CapraTokens.radiusLg));
  const alturaControle = Size.fromHeight(48);
  // Pressionado: textPrimary em baixa opacidade, nunca o acento.
  final toque = p.textPrimary.withValues(alpha: 0.08);
  final rotulo = texto.labelLarge!;

  return ThemeData(
    useMaterial3: true,
    brightness: brilho,
    colorScheme: cores,
    fontFamily: familiaTexto,
    textTheme: texto,
    scaffoldBackgroundColor: p.background,
    canvasColor: p.background,
    dividerColor: p.border,
    splashColor: toque,
    highlightColor: toque,
    hoverColor: toque,
    focusColor: acento.withValues(alpha: 0.24),
    splashFactory: InkRipple.splashFactory,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    visualDensity: VisualDensity.standard,
    extensions: [TemaRavix(p)],
    appBarTheme: AppBarTheme(
      backgroundColor: p.background,
      foregroundColor: p.textPrimary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      shape: Border(bottom: BorderSide(color: p.background)),
      titleTextStyle: texto.titleLarge,
      centerTitle: false,
      systemOverlayStyle: _barrasDoSistema(brilho),
    ),
    cardTheme: CardThemeData(
      color: p.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: raioMd,
        side: BorderSide(color: p.border),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: acento,
        foregroundColor: p.onAccent,
        disabledBackgroundColor: acento.withValues(alpha: 0.38),
        disabledForegroundColor: p.onAccent.withValues(alpha: 0.38),
        minimumSize: alturaControle,
        shape: const RoundedRectangleBorder(borderRadius: raioMd),
        textStyle: rotulo,
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: p.surfaceElevated,
        foregroundColor: p.textPrimary,
        minimumSize: alturaControle,
        side: BorderSide(color: p.borderStrong),
        shape: const RoundedRectangleBorder(borderRadius: raioMd),
        textStyle: rotulo,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: acento,
        minimumSize: const Size(48, 48),
        shape: const RoundedRectangleBorder(borderRadius: raioMd),
        textStyle: rotulo,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: p.textPrimary,
        minimumSize: const Size(48, 48),
        iconSize: CapraTokens.iconSizeLg,
      ),
    ),
    iconTheme: IconThemeData(
      color: p.textPrimary,
      size: CapraTokens.iconSizeLg,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: acento,
      foregroundColor: p.onAccent,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: raioMd),
      extendedTextStyle: rotulo,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.surface,
      constraints: const BoxConstraints(minHeight: 48),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: CapraTokens.spaceMd,
        vertical: 12,
      ),
      labelStyle: texto.labelMedium?.copyWith(color: p.textSecondary),
      floatingLabelStyle: texto.labelMedium?.copyWith(color: p.textSecondary),
      hintStyle: texto.bodyLarge?.copyWith(color: p.textSecondary),
      helperStyle: texto.bodySmall,
      errorStyle: texto.bodySmall?.copyWith(color: p.danger),
      border: OutlineInputBorder(
        borderRadius: raioSm,
        borderSide: BorderSide(color: p.borderStrong),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: raioSm,
        borderSide: BorderSide(color: p.borderStrong),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: raioSm,
        borderSide: BorderSide(color: acento, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: raioSm,
        borderSide: BorderSide(color: p.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: raioSm,
        borderSide: BorderSide(color: p.danger, width: 2),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      indicatorColor: p.surfaceElevated,
      indicatorShape: const StadiumBorder(),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(
          size: CapraTokens.iconSizeLg,
          color: s.contains(WidgetState.selected) ? acento : p.textSecondary,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => texto.labelSmall?.copyWith(
          color: s.contains(WidgetState.selected) ? acento : p.textSecondary,
        ),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.surfaceElevated,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      showDragHandle: true,
      dragHandleColor: p.borderStrong,
      dragHandleSize: const Size(32, 4),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(CapraTokens.radiusLg),
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.surfaceElevated,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: raioLg),
      titleTextStyle: texto.titleLarge,
      contentTextStyle: texto.bodyLarge,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: p.surfaceElevated,
      contentTextStyle: texto.bodyLarge,
      actionTextColor: acento,
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: raioMd),
    ),
    dividerTheme: DividerThemeData(color: p.border, thickness: 1, space: 1),
    listTileTheme: ListTileThemeData(
      iconColor: p.textSecondary,
      textColor: p.textPrimary,
      minTileHeight: 56,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: CapraTokens.spaceMd,
      ),
      titleTextStyle: texto.bodyLarge,
      subtitleTextStyle: texto.bodySmall,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: p.surface,
      selectedColor: p.surfaceElevated,
      side: BorderSide(color: p.borderStrong),
      shape: const RoundedRectangleBorder(borderRadius: raioSm),
      labelStyle: texto.labelMedium,
      checkmarkColor: acento,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: acento,
      linearTrackColor: p.surfaceElevated,
      circularTrackColor: Colors.transparent,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {TargetPlatform.android: FadeForwardsPageTransitionsBuilder()},
    ),
  );
}

/// Escala tipográfica mobile do guia CAPRA (tamanho / entrelinha).
TextTheme _textos(CapraPaleta p) {
  TextStyle estilo(
    double tamanho,
    double entrelinha,
    FontWeight peso, {
    String familia = familiaTexto,
    Color? cor,
    double espacamento = 0,
  }) => TextStyle(
    fontFamily: familia,
    fontSize: tamanho,
    height: entrelinha / tamanho,
    fontWeight: peso,
    letterSpacing: espacamento,
    color: cor ?? p.textPrimary,
    leadingDistribution: TextLeadingDistribution.even,
  );

  final display = estilo(
    34,
    40,
    FontWeight.w700,
    familia: familiaTitulo,
    espacamento: -0.34,
  ).copyWith(fontFeatures: numerosTabulares);
  final h1 = estilo(28, 34, FontWeight.w700, familia: familiaTitulo);
  final h2 = estilo(20, 26, FontWeight.w700);
  final corpo = estilo(16, 24, FontWeight.w400);
  final rotulo = estilo(16, 20, FontWeight.w500);
  final legenda = estilo(13, 18, FontWeight.w400, cor: p.textSecondary);

  return TextTheme(
    displayLarge: display,
    displayMedium: display,
    displaySmall: display,
    headlineLarge: h1,
    headlineMedium: h1,
    headlineSmall: h1,
    titleLarge: h2,
    titleMedium: corpo.copyWith(fontWeight: FontWeight.w600),
    titleSmall: rotulo,
    bodyLarge: corpo,
    bodyMedium: corpo,
    bodySmall: legenda,
    labelLarge: rotulo,
    labelMedium: legenda.copyWith(fontWeight: FontWeight.w500),
    labelSmall: legenda,
  );
}

/// Barras do sistema transparentes, com ícones claros no dark e escuros no
/// claro.
SystemUiOverlayStyle _barrasDoSistema(Brightness brilho) {
  final escuro = brilho == Brightness.dark;
  return SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarContrastEnforced: false,
    statusBarIconBrightness: escuro ? Brightness.light : Brightness.dark,
    statusBarBrightness: brilho,
    systemNavigationBarIconBrightness: escuro
        ? Brightness.light
        : Brightness.dark,
  );
}
