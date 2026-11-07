/// Tema do Ravix: identidade visual v2 (Floresta, Menta, cantos chanfrados).
///
/// Cores, escala e formas conforme `docs/identidade_visual/v2/README.md`.
library;

import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ravix/core/tema/tokens.dart';

/// Família do texto de interface.
const familiaTexto = 'Archivo';

/// Família dos títulos e do logotipo.
const familiaTitulo = 'ChakraPetch';

/// Família dos valores em dinheiro: Chakra Petch com dígitos de largura
/// igual, para alinhar as colunas.
const familiaValores = 'RavixValores';

/// Números tabulares, para horários e datas em Archivo.
const numerosTabulares = [FontFeature.tabularFigures()];

/// Borda chanfrada a 45°, o mesmo corte das letras e do símbolo.
BeveledRectangleBorder chanfro(
  double tamanho, {
  BorderSide lado = BorderSide.none,
}) => BeveledRectangleBorder(
  borderRadius: BorderRadius.all(Radius.circular(tamanho)),
  side: lado,
);

/// Dados de marca que o `ThemeData` não carrega. Use `context.temaRavix`.
@immutable
final class TemaRavix extends ThemeExtension<TemaRavix> {
  /// Cria a extensão com [paleta].
  const new(this.paleta);

  /// Paleta do tema ativo (claro ou escuro).
  final PaletaRavix paleta;

  /// Destaques e ícones ativos.
  Color get acento => paleta.accent;

  /// Fundo do card de resumo: Floresta nos dois temas.
  Color get resumoFundo => CoresRavix.floresta;

  /// Texto do card de resumo.
  Color get resumoTexto => const Color(0xFFE7F0EC);

  /// Texto de apoio do card de resumo.
  Color get resumoApoio => const Color(0xFF9DB8AF);

  /// Trilho das barras do card de resumo.
  Color get resumoTrilho => const Color(0xFF0D2621);

  /// Valor em destaque (total do mês): Ravix Valores 700, 40/44.
  TextStyle get valorDestaque => const TextStyle(
    fontFamily: familiaValores,
    fontWeight: FontWeight.w700,
    fontSize: 40,
    height: 44 / 40,
    letterSpacing: -0.8,
  );

  /// Valor na lista: Ravix Valores 600, 16/20.
  TextStyle get valorLista => TextStyle(
    fontFamily: familiaValores,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    height: 20 / 16,
    color: paleta.textPrimary,
  );

  /// Sobretítulo em maiúsculas (cabeçalho de dia): Archivo 600, 11,5/16.
  TextStyle get sobretitulo => TextStyle(
    fontFamily: familiaTexto,
    fontWeight: FontWeight.w600,
    fontSize: 11.5,
    height: 16 / 11.5,
    letterSpacing: 0.7,
    color: paleta.textSecondary,
  );

  @override
  TemaRavix copyWith({PaletaRavix? paleta}) => TemaRavix(paleta ?? this.paleta);

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
  final p = escuro ? TokensRavix.escuro : TokensRavix.claro;

  final cores = ColorScheme(
    brightness: brilho,
    primary: p.primary,
    onPrimary: p.onPrimary,
    primaryContainer: escuro ? CoresRavix.floresta : const Color(0xFFD3EDE0),
    onPrimaryContainer: escuro ? CoresRavix.nevoa : CoresRavix.tinta,
    secondary: p.info,
    onSecondary: escuro ? const Color(0xFF06292D) : Colors.white,
    secondaryContainer: p.surfaceAlt,
    onSecondaryContainer: p.textPrimary,
    tertiary: CoresRavix.areia,
    onTertiary: const Color(0xFF2A2213),
    error: p.danger,
    onError: p.onDanger,
    surface: p.background,
    onSurface: p.textPrimary,
    onSurfaceVariant: p.textSecondary,
    surfaceContainerLowest: p.background,
    surfaceContainerLow: p.surface,
    surfaceContainer: p.surface,
    surfaceContainerHigh: p.surfaceAlt,
    surfaceContainerHighest: p.surfaceAlt,
    outline: p.borderStrong,
    outlineVariant: p.border,
    inverseSurface: escuro ? p.textPrimary : const Color(0xFF1B3530),
    onInverseSurface: escuro ? p.surface : const Color(0xFFE7F0EC),
    inversePrimary: escuro ? CoresRavix.floresta : CoresRavix.menta,
    shadow: Colors.transparent,
    scrim: Colors.black54,
    surfaceTint: Colors.transparent,
  );

  final texto = _textos(p);
  final chanfroP = chanfro(TokensRavix.chanfroP);
  final chanfroM = chanfro(TokensRavix.chanfroM);
  final chanfroG = chanfro(TokensRavix.chanfroG);
  const alturaBotao = Size.fromHeight(52);
  // Pressionado: texto principal em baixa opacidade.
  final toque = p.textPrimary.withValues(alpha: 0.08);
  final rotulo = texto.labelLarge!;

  RavixBordaDeCampo campo(Color cor, [double largura = 1]) => RavixBordaDeCampo(
    borderSide: BorderSide(color: cor, width: largura),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brilho,
    colorScheme: cores,
    fontFamily: familiaTexto,
    textTheme: texto,
    scaffoldBackgroundColor: p.background,
    canvasColor: p.surface,
    dividerColor: p.border,
    splashColor: toque,
    highlightColor: toque,
    hoverColor: toque,
    focusColor: p.info.withValues(alpha: 0.24),
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
      titleTextStyle: texto.headlineSmall,
      centerTitle: false,
      systemOverlayStyle: _barrasDoSistema(brilho),
    ),
    cardTheme: CardThemeData(
      color: p.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: chanfro(TokensRavix.chanfroG, lado: BorderSide(color: p.border)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.primary,
        foregroundColor: p.onPrimary,
        disabledBackgroundColor: p.primary.withValues(alpha: 0.38),
        disabledForegroundColor: p.onPrimary.withValues(alpha: 0.6),
        minimumSize: alturaBotao,
        shape: chanfroM,
        textStyle: rotulo,
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: p.surface,
        foregroundColor: p.textPrimary,
        minimumSize: const Size(48, 48),
        side: BorderSide(color: p.borderStrong),
        shape: chanfroM,
        textStyle: rotulo,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: escuro ? CoresRavix.menta : CoresRavix.petroleo,
        minimumSize: const Size(48, 48),
        shape: chanfroM,
        textStyle: rotulo,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: p.textPrimary,
        minimumSize: const Size(48, 48),
        iconSize: TokensRavix.iconSizeLg,
        shape: chanfroM,
      ),
    ),
    iconTheme: IconThemeData(
      color: p.textPrimary,
      size: TokensRavix.iconSizeLg,
    ),
    // Novo gasto: Menta nos dois temas, chanfro de 12 dp.
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: CoresRavix.menta,
      foregroundColor: CoresRavix.tinta,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      shape: chanfroG,
      extendedTextStyle: rotulo,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.surface,
      constraints: const BoxConstraints(minHeight: 56),
      contentPadding: const EdgeInsets.fromLTRB(
        TokensRavix.spaceMd,
        10,
        TokensRavix.spaceMd,
        10,
      ),
      labelStyle: texto.labelMedium?.copyWith(color: p.textSecondary),
      floatingLabelStyle: WidgetStateTextStyle.resolveWith(
        (s) => texto.bodySmall!.copyWith(
          color: s.contains(WidgetState.error)
              ? p.danger
              : s.contains(WidgetState.focused)
              ? p.info
              : p.textSecondary,
        ),
      ),
      hintStyle: texto.bodyLarge?.copyWith(color: p.textSecondary),
      prefixStyle: texto.bodyLarge?.copyWith(color: p.textSecondary),
      helperStyle: texto.bodySmall,
      errorStyle: texto.bodySmall?.copyWith(color: p.danger),
      border: campo(p.borderStrong),
      enabledBorder: campo(p.borderStrong),
      disabledBorder: campo(p.border),
      focusedBorder: campo(p.info, 2),
      errorBorder: campo(p.danger),
      focusedErrorBorder: campo(p.danger, 2),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      indicatorColor: p.surfaceAlt,
      indicatorShape: chanfroM,
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(
          size: TokensRavix.iconSizeLg,
          color: s.contains(WidgetState.selected) ? p.accent : p.textSecondary,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => texto.bodySmall?.copyWith(
          color: s.contains(WidgetState.selected) ? p.accent : p.textSecondary,
        ),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      showDragHandle: true,
      dragHandleColor: p.borderStrong,
      dragHandleSize: const Size(32, 4),
      shape: const BeveledRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(TokensRavix.chanfroG),
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: chanfroG,
      titleTextStyle: texto.titleLarge,
      contentTextStyle: texto.bodyLarge,
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: chanfroG,
      headerHeadlineStyle: texto.headlineSmall,
      dayShape: WidgetStatePropertyAll(chanfroP),
      todayBorder: BorderSide(color: p.accent),
    ),
    timePickerTheme: TimePickerThemeData(
      backgroundColor: p.surface,
      elevation: 0,
      shape: chanfroG,
      hourMinuteShape: chanfroM,
      dayPeriodShape: chanfroM,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: p.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: chanfro(TokensRavix.chanfroM, lado: BorderSide(color: p.border)),
      textStyle: texto.bodyLarge,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: CoresRavix.floresta,
      contentTextStyle: texto.bodyLarge?.copyWith(color: CoresRavix.nevoa),
      actionTextColor: CoresRavix.menta,
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      shape: chanfroM,
    ),
    dividerTheme: DividerThemeData(color: p.border, thickness: 1, space: 1),
    listTileTheme: ListTileThemeData(
      iconColor: p.textSecondary,
      textColor: p.textPrimary,
      minTileHeight: 64,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: TokensRavix.spaceMd,
      ),
      titleTextStyle: texto.bodyLarge,
      subtitleTextStyle: texto.bodySmall,
      selectedColor: p.accent,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: p.surface,
      selectedColor: escuro ? CoresRavix.floresta : const Color(0xFFD3EDE0),
      side: BorderSide(color: p.borderStrong),
      shape: chanfroP,
      labelStyle: texto.labelMedium,
      checkmarkColor: p.accent,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: p.accent,
      linearTrackColor: p.surfaceAlt,
      circularTrackColor: Colors.transparent,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {TargetPlatform.android: FadeForwardsPageTransitionsBuilder()},
    ),
  );
}

/// Escala do app em sp (manual v2, seção 3).
TextTheme _textos(PaletaRavix p) {
  TextStyle estilo(
    String familia,
    double tamanho,
    double entrelinha,
    FontWeight peso, {
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

  const d = familiaTitulo;
  const t = familiaTexto;
  return TextTheme(
    displayLarge: estilo(d, 57, 60, FontWeight.w700, espacamento: -1.1),
    displayMedium: estilo(d, 45, 48, FontWeight.w700, espacamento: -0.9),
    // Valor destaque.
    displaySmall: estilo(d, 40, 44, FontWeight.w700, espacamento: -0.8),
    headlineLarge: estilo(d, 32, 36, FontWeight.w700, espacamento: -0.6),
    headlineMedium: estilo(d, 28, 32, FontWeight.w700, espacamento: -0.4),
    // Título de tela.
    headlineSmall: estilo(d, 24, 28, FontWeight.w700, espacamento: -0.24),
    titleLarge: estilo(d, 22, 28, FontWeight.w700, espacamento: -0.2),
    // Seção.
    titleMedium: estilo(d, 18, 24, FontWeight.w600),
    titleSmall: estilo(t, 14, 20, FontWeight.w600),
    // Corpo e texto digitado nos campos.
    bodyLarge: estilo(t, 16, 24, FontWeight.w400),
    bodyMedium: estilo(t, 14, 20, FontWeight.w400),
    // Legenda.
    bodySmall: estilo(
      t,
      12,
      16,
      FontWeight.w500,
      cor: p.textSecondary,
      espacamento: 0.12,
    ),
    // Botões.
    labelLarge: estilo(t, 16, 20, FontWeight.w600),
    // Rótulo.
    labelMedium: estilo(t, 14, 20, FontWeight.w500),
    // Sobretítulo (use em maiúsculas).
    labelSmall: estilo(
      t,
      11,
      16,
      FontWeight.w600,
      cor: p.textSecondary,
      espacamento: 1.1,
    ),
  );
}

/// Barras do sistema transparentes, com ícones claros no escuro e escuros no
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

/// Borda chanfrada dos campos. Funciona como borda preenchida: o rótulo
/// flutua dentro do campo.
@immutable
final class RavixBordaDeCampo extends InputBorder {
  /// Cria a borda com corte de [corte] dp.
  const new({
    super.borderSide = const BorderSide(),
    this.corte = TokensRavix.chanfroM,
  });

  /// Tamanho do chanfro.
  final double corte;

  @override
  bool get isOutline => false;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(borderSide.width);

  @override
  RavixBordaDeCampo copyWith({BorderSide? borderSide, double? corte}) =>
      RavixBordaDeCampo(
        borderSide: borderSide ?? this.borderSide,
        corte: corte ?? this.corte,
      );

  @override
  ShapeBorder scale(double t) =>
      RavixBordaDeCampo(borderSide: borderSide.scale(t), corte: corte * t);

  Path _caminho(Rect r) {
    final c = math.max(0, math.min(corte, r.shortestSide / 2)).toDouble();
    return Path()
      ..moveTo(r.left + c, r.top)
      ..lineTo(r.right - c, r.top)
      ..lineTo(r.right, r.top + c)
      ..lineTo(r.right, r.bottom - c)
      ..lineTo(r.right - c, r.bottom)
      ..lineTo(r.left + c, r.bottom)
      ..lineTo(r.left, r.bottom - c)
      ..lineTo(r.left, r.top + c)
      ..close();
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      _caminho(rect.deflate(borderSide.width));

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      _caminho(rect);

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    double? gapStart,
    double gapExtent = 0.0,
    double gapPercentage = 0.0,
    TextDirection? textDirection,
  }) {
    if (borderSide.style == BorderStyle.none || borderSide.width == 0) return;
    canvas.drawPath(
      _caminho(rect.deflate(borderSide.width / 2)),
      borderSide.toPaint(),
    );
  }

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) => a is RavixBordaDeCampo
      ? RavixBordaDeCampo(
          borderSide: BorderSide.lerp(a.borderSide, borderSide, t),
          corte: lerpDouble(a.corte, corte, t)!,
        )
      : super.lerpFrom(a, t);

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) => b is RavixBordaDeCampo
      ? RavixBordaDeCampo(
          borderSide: BorderSide.lerp(borderSide, b.borderSide, t),
          corte: lerpDouble(corte, b.corte, t)!,
        )
      : super.lerpTo(b, t);

  @override
  bool operator ==(Object other) =>
      other is RavixBordaDeCampo &&
      other.borderSide == borderSide &&
      other.corte == corte;

  @override
  int get hashCode => Object.hash(borderSide, corte);
}
