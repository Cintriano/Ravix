import 'package:flutter/material.dart';

import 'ravix_colors.dart';
import 'ravix_typography.dart';

/// Tokens que o [ColorScheme] não cobre: estados do orçamento, card de resumo,
/// gráficos e estilos de valor em dinheiro.
///
/// Acesse com `context.ravix`.
@immutable
class RavixTokens extends ThemeExtension<RavixTokens> {
  const RavixTokens({
    required this.ok,
    required this.atencao,
    required this.estourado,
    required this.categoria,
    required this.info,
    required this.textMuted,
    required this.line,
    required this.summaryBackground,
    required this.summaryForeground,
    required this.summaryMuted,
    required this.summaryTrack,
    required this.chart,
    required this.moneyHero,
    required this.moneyList,
    required this.overline,
  });

  final Color ok;
  final Color atencao;
  final Color estourado;
  final Color categoria;
  final Color info;
  final Color textMuted;
  final Color line;

  /// Card de resumo do mês: Floresta nos dois temas.
  final Color summaryBackground;
  final Color summaryForeground;
  final Color summaryMuted;
  final Color summaryTrack;

  final List<Color> chart;

  /// Total do mês (Ravix Valores 700, 40sp).
  final TextStyle moneyHero;

  /// Valor em listas (Ravix Valores 600, 16sp).
  final TextStyle moneyList;

  /// Sobretítulo em maiúsculas (cabeçalho de dia, rótulos de seção).
  final TextStyle overline;

  /// Cor do orçamento conforme o quanto foi usado (0.58 = 58%).
  Color budgetColor(double ratio) => ratio < 0.8 ? ok : (ratio <= 1.0 ? atencao : estourado);

  static const light = RavixTokens(
    ok: RavixColors.ok,
    atencao: RavixColors.atencao,
    estourado: RavixColors.estourado,
    categoria: RavixColors.areia,
    info: RavixColors.petroleo,
    textMuted: RavixColors.lightTextMuted,
    line: RavixColors.lightLine,
    summaryBackground: RavixColors.floresta,
    summaryForeground: RavixColors.darkText,
    summaryMuted: Color(0xFF9DB8AF),
    summaryTrack: Color(0xFF0D2621),
    chart: RavixColors.chart,
    moneyHero: TextStyle(fontFamily: RavixFonts.values, fontWeight: FontWeight.w700, fontSize: 40, height: 44 / 40, letterSpacing: -0.8),
    moneyList: TextStyle(fontFamily: RavixFonts.values, fontWeight: FontWeight.w600, fontSize: 16, height: 20 / 16),
    overline: TextStyle(fontFamily: RavixFonts.text, fontWeight: FontWeight.w600, fontSize: 11.5, height: 16 / 11.5, letterSpacing: 0.7, color: Color(0xFF5B6F69)),
  );

  static const dark = RavixTokens(
    ok: RavixColors.menta,
    atencao: RavixColors.atencao,
    estourado: Color(0xFFE9806E),
    categoria: RavixColors.areia,
    info: RavixColors.darkInfo,
    textMuted: RavixColors.darkTextMuted,
    line: RavixColors.darkLine,
    summaryBackground: RavixColors.floresta,
    summaryForeground: RavixColors.darkText,
    summaryMuted: Color(0xFF9DB8AF),
    summaryTrack: Color(0xFF0D2621),
    chart: RavixColors.chart,
    moneyHero: TextStyle(fontFamily: RavixFonts.values, fontWeight: FontWeight.w700, fontSize: 40, height: 44 / 40, letterSpacing: -0.8),
    moneyList: TextStyle(fontFamily: RavixFonts.values, fontWeight: FontWeight.w600, fontSize: 16, height: 20 / 16),
    overline: TextStyle(fontFamily: RavixFonts.text, fontWeight: FontWeight.w600, fontSize: 11.5, height: 16 / 11.5, letterSpacing: 0.7, color: Color(0xFF7F978F)),
  );

  @override
  RavixTokens copyWith({
    Color? ok,
    Color? atencao,
    Color? estourado,
    Color? categoria,
    Color? info,
    Color? textMuted,
    Color? line,
    Color? summaryBackground,
    Color? summaryForeground,
    Color? summaryMuted,
    Color? summaryTrack,
    List<Color>? chart,
    TextStyle? moneyHero,
    TextStyle? moneyList,
    TextStyle? overline,
  }) {
    return RavixTokens(
      ok: ok ?? this.ok,
      atencao: atencao ?? this.atencao,
      estourado: estourado ?? this.estourado,
      categoria: categoria ?? this.categoria,
      info: info ?? this.info,
      textMuted: textMuted ?? this.textMuted,
      line: line ?? this.line,
      summaryBackground: summaryBackground ?? this.summaryBackground,
      summaryForeground: summaryForeground ?? this.summaryForeground,
      summaryMuted: summaryMuted ?? this.summaryMuted,
      summaryTrack: summaryTrack ?? this.summaryTrack,
      chart: chart ?? this.chart,
      moneyHero: moneyHero ?? this.moneyHero,
      moneyList: moneyList ?? this.moneyList,
      overline: overline ?? this.overline,
    );
  }

  @override
  RavixTokens lerp(ThemeExtension<RavixTokens>? other, double t) {
    if (other is! RavixTokens) return this;
    return RavixTokens(
      ok: Color.lerp(ok, other.ok, t)!,
      atencao: Color.lerp(atencao, other.atencao, t)!,
      estourado: Color.lerp(estourado, other.estourado, t)!,
      categoria: Color.lerp(categoria, other.categoria, t)!,
      info: Color.lerp(info, other.info, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      line: Color.lerp(line, other.line, t)!,
      summaryBackground: Color.lerp(summaryBackground, other.summaryBackground, t)!,
      summaryForeground: Color.lerp(summaryForeground, other.summaryForeground, t)!,
      summaryMuted: Color.lerp(summaryMuted, other.summaryMuted, t)!,
      summaryTrack: Color.lerp(summaryTrack, other.summaryTrack, t)!,
      chart: t < 0.5 ? chart : other.chart,
      moneyHero: TextStyle.lerp(moneyHero, other.moneyHero, t)!,
      moneyList: TextStyle.lerp(moneyList, other.moneyList, t)!,
      overline: TextStyle.lerp(overline, other.overline, t)!,
    );
  }
}

extension RavixContext on BuildContext {
  RavixTokens get ravix => Theme.of(this).extension<RavixTokens>()!;
}
