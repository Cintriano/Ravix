/// Tokens da identidade visual v2 do Ravix (`docs/identidade_visual/v2`).
///
/// Cores fixas da marca, paletas dos temas claro e escuro, espaçamento,
/// chanfros e movimento.
library;

import 'package:flutter/animation.dart';

/// Cores da marca, iguais nos dois temas.
abstract final class CoresRavix {
  /// Base da marca: cabeçalhos, botão principal, fundo do ícone e do resumo.
  static const floresta = Color(0xFF163730);

  /// Seta, ações, progresso.
  static const menta = Color(0xFF78CFA5);

  /// Menta mais escura, para texto e seta em fundo claro.
  static const menta600 = Color(0xFF3FB282);

  /// Gráficos, links, foco.
  static const petroleo = Color(0xFF22727B);

  /// Categorias e detalhes.
  static const areia = Color(0xFFC9AD78);

  /// Neutro claro; texto sobre Floresta.
  static const nevoa = Color(0xFFEEF4F0);

  /// Texto sobre Menta.
  static const tinta = Color(0xFF0C2420);

  /// Orçamento perto do limite (80% a 100%).
  static const atencao = Color(0xFFD9A441);

  /// Ordem das cores nos gráficos de categoria.
  static const graficos = <Color>[
    Color(0xFF78CFA5),
    Color(0xFF22727B),
    Color(0xFFC9AD78),
    Color(0xFF4FA3A0),
    Color(0xFF163730),
    Color(0xFFA9C9BC),
  ];
}

/// Cores de um tema (claro ou escuro).
final class PaletaRavix {
  /// Cria a paleta.
  const new({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.primary,
    required this.onPrimary,
    required this.accent,
    required this.info,
    required this.ok,
    required this.danger,
    required this.onDanger,
  });

  /// Fundo da tela.
  final Color background;

  /// Campos, cards, folhas.
  final Color surface;

  /// Áreas secundárias, chips escolhidos.
  final Color surfaceAlt;

  /// Divisórias e contornos decorativos.
  final Color border;

  /// Contorno de campos e botões secundários.
  final Color borderStrong;

  /// Texto principal.
  final Color textPrimary;

  /// Rótulos e textos de apoio.
  final Color textSecondary;

  /// Botão principal: Floresta no claro, Menta no escuro.
  final Color primary;

  /// Texto sobre [primary].
  final Color onPrimary;

  /// Destaques e ícones ativos.
  final Color accent;

  /// Foco, links, gráficos.
  final Color info;

  /// Dentro do orçamento (abaixo de 80%).
  final Color ok;

  /// Orçamento estourado; só para alertas e ações destrutivas.
  final Color danger;

  /// Texto sobre [danger].
  final Color onDanger;
}

/// Medidas, paletas e movimento.
abstract final class TokensRavix {
  /// Tema claro.
  static const claro = PaletaRavix(
    background: Color(0xFFF4F7F4),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFE9F0EC),
    border: Color(0xFFD2DFD8),
    borderStrong: Color(0xFFB5C7BE),
    textPrimary: Color(0xFF11241F),
    textSecondary: Color(0xFF5B6F69),
    primary: CoresRavix.floresta,
    onPrimary: CoresRavix.nevoa,
    accent: CoresRavix.menta600,
    info: CoresRavix.petroleo,
    ok: CoresRavix.menta600,
    danger: Color(0xFFD0614E),
    onDanger: Color(0xFFFFFFFF),
  );

  /// Tema escuro. O botão principal vira Menta, porque o Floresta some no
  /// fundo escuro.
  static const escuro = PaletaRavix(
    background: Color(0xFF0D1C19),
    surface: Color(0xFF132823),
    surfaceAlt: Color(0xFF1B3530),
    border: Color(0xFF244038),
    borderStrong: Color(0xFF3A5A51),
    textPrimary: Color(0xFFE7F0EC),
    textSecondary: Color(0xFF93A9A2),
    primary: CoresRavix.menta,
    onPrimary: CoresRavix.tinta,
    accent: CoresRavix.menta,
    info: Color(0xFF6CC1C8),
    ok: CoresRavix.menta,
    danger: Color(0xFFE9806E),
    onDanger: Color(0xFF3A0D06),
  );

  /// Grade de 4 dp.
  static const double spaceXs = 4;

  /// 8 dp.
  static const double spaceSm = 8;

  /// 12 dp.
  static const double spaceSmMd = 12;

  /// 16 dp: margem lateral da tela.
  static const double spaceMd = 16;

  /// 24 dp.
  static const double spaceLg = 24;

  /// 32 dp.
  static const double spaceXl = 32;

  /// 48 dp.
  static const double spaceXxl = 48;

  /// Chanfro pequeno: chips, ícone de categoria.
  static const double chanfroP = 4;

  /// Chanfro médio: botões, campos.
  static const double chanfroM = 8;

  /// Chanfro grande: cards, FAB, card de resumo, folhas.
  static const double chanfroG = 12;

  /// Ícone pequeno.
  static const double iconSizeSm = 16;

  /// Ícone médio.
  static const double iconSizeMd = 20;

  /// Ícone padrão (grade de 24 dp).
  static const double iconSizeLg = 24;

  /// Toque, troca de estado.
  static const motionRapido = Duration(milliseconds: 120);

  /// Abrir e fechar folhas, trocar de mês, entrada de linhas.
  static const motionPadrao = Duration(milliseconds: 220);

  /// Seta na confirmação, barra do orçamento.
  static const motionEnfase = Duration(milliseconds: 420);

  /// Curva única da marca: `cubic-bezier(.2, .8, .2, 1)`.
  static const curva = Cubic(0.2, 0.8, 0.2, 1);
}
