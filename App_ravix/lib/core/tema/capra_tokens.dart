// GERADO por tool/gerar_tokens.dart a partir de
// docs/identidade_visual/capra-tokens.json. Não edite.

/// Tokens da marca CAPRA (manual v1.6).
library;

import 'package:flutter/animation.dart';

/// Impressão digital do JSON de origem.
const capraTokensImpressao = 'caf9a668';

/// Cores de um tema CAPRA (dark ou light).
final class CapraPaleta {
  /// Cria a paleta.
  const new({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.border,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
    required this.accentData,
    required this.accentAutomation,
    required this.accentFinance,
    required this.accentInfra,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.onAccent,
    required this.focus,
    required this.data1,
    required this.data2,
    required this.data3,
    required this.data4,
    required this.dataOther,
    required this.dataSeq1,
    required this.dataSeq2,
    required this.dataSeq3,
    required this.dataSeq4,
    required this.dataSeq5,
    required this.dataDivNeg2,
    required this.dataDivNeg1,
    required this.dataDiv0,
    required this.dataDivPos1,
    required this.dataDivPos2,
  });

  /// `background`. Void.
  final Color background;

  /// `surface`. Superfícies e cartões sobre background.
  final Color surface;

  /// `surfaceElevated`. Áreas elevadas, botão secundário, linhas selecionadas.
  final Color surfaceElevated;

  /// `border`. Divisórias e contornos decorativos (1,3:1).
  final Color border;

  /// `borderStrong`. Bordas de campos, botões secundários e controles: 3:1 ou
  /// mais sobre background, surface e surfaceElevated nos dois temas.
  final Color borderStrong;

  /// `textPrimary`. Texto principal sobre background, surface e surfaceElevated
  /// (13:1 ou mais).
  final Color textPrimary;

  /// `textSecondary`. Texto secundário, metadados e legendas sobre background,
  /// surface e surfaceElevated (5,4:1 ou mais).
  final Color textSecondary;

  /// `accent`. Cyan.
  final Color accent;

  /// `accentData`. Lilac.
  final Color accentData;

  /// `accentAutomation`. Mint.
  final Color accentAutomation;

  /// `accentFinance`. Peach.
  final Color accentFinance;

  /// `accentInfra`. Gold.
  final Color accentInfra;

  /// `success`. Estado positivo: concluído, ativo, saudável.
  final Color success;

  /// `warning`. Estado de atenção: pendente, próximo do limite.
  final Color warning;

  /// `danger`. Erro e ações destrutivas.
  final Color danger;

  /// `info`. Estado informativo.
  final Color info;

  /// `onAccent`. Texto e ícones sobre preenchimentos de acento ou de estado
  /// (5,6:1 ou mais).
  final Color onAccent;

  /// `focus`. Cor do anel de foco; em produtos, troque pelo acento do contexto.
  final Color focus;

  /// `data-1`. Cyan.
  final Color data1;

  /// `data-2`. Lilac.
  final Color data2;

  /// `data-3`. Peach.
  final Color data3;

  /// `data-4`. Gold.
  final Color data4;

  /// `data-other`. Séries fora do destaque e grupo Outros (3,5:1 sobre
  /// surface).
  final Color dataOther;

  /// `data-seq-1`. Escala sequencial, passo 1 (exemplo com Cyan: mistura de
  /// surfaceElevated até o acento).
  final Color dataSeq1;

  /// `data-seq-2`. Escala sequencial, passo 2.
  final Color dataSeq2;

  /// `data-seq-3`. Escala sequencial, passo 3.
  final Color dataSeq3;

  /// `data-seq-4`. Escala sequencial, passo 4.
  final Color dataSeq4;

  /// `data-seq-5`. Escala sequencial, passo 5: o próprio acento.
  final Color dataSeq5;

  /// `data-div-neg-2`. Escala divergente: muito abaixo da referência (Peach).
  final Color dataDivNeg2;

  /// `data-div-neg-1`. Escala divergente: abaixo da referência.
  final Color dataDivNeg1;

  /// `data-div-0`. Escala divergente: na referência.
  final Color dataDiv0;

  /// `data-div-pos-1`. Escala divergente: acima da referência.
  final Color dataDivPos1;

  /// `data-div-pos-2`. Escala divergente: muito acima da referência (Cyan).
  final Color dataDivPos2;
}

/// Valores dos tokens CAPRA.
abstract final class CapraTokens {
  /// Paleta do tema dark.
  static const escuro = CapraPaleta(
    background: Color(0xFF121416),
    surface: Color(0xFF181B1E),
    surfaceElevated: Color(0xFF202428),
    border: Color(0xFF2A3035),
    borderStrong: Color(0xFF68737A),
    textPrimary: Color(0xFFE8ECEE),
    textSecondary: Color(0xFFAAB4B9),
    accent: Color(0xFF8FB8C5),
    accentData: Color(0xFFB3A6C9),
    accentAutomation: Color(0xFF9DBBAA),
    accentFinance: Color(0xFFD7AFA3),
    accentInfra: Color(0xFFD6C58F),
    success: Color(0xFF9DBBAA),
    warning: Color(0xFFD6C58F),
    danger: Color(0xFFE8877F),
    info: Color(0xFF8FB8C5),
    onAccent: Color(0xFF121416),
    focus: Color(0xFF8FB8C5),
    data1: Color(0xFF8FB8C5),
    data2: Color(0xFFB3A6C9),
    data3: Color(0xFFD7AFA3),
    data4: Color(0xFFD6C58F),
    dataOther: Color(0xFF68737A),
    dataSeq1: Color(0xFF313A40),
    dataSeq2: Color(0xFF47585F),
    dataSeq3: Color(0xFF5D757E),
    dataSeq4: Color(0xFF73939E),
    dataSeq5: Color(0xFF8FB8C5),
    dataDivNeg2: Color(0xFFD7AFA3),
    dataDivNeg1: Color(0xFF80706C),
    dataDiv0: Color(0xFF2A3035),
    dataDivPos1: Color(0xFF5C747D),
    dataDivPos2: Color(0xFF8FB8C5),
  );

  /// Paleta do tema claro.
  static const claro = CapraPaleta(
    background: Color(0xFFF3F5F6),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFE8ECEE),
    border: Color(0xFFD0D7DB),
    borderStrong: Color(0xFF7E8990),
    textPrimary: Color(0xFF121416),
    textSecondary: Color(0xFF55606A),
    accent: Color(0xFF3B6A79),
    accentData: Color(0xFF665789),
    accentAutomation: Color(0xFF45705A),
    accentFinance: Color(0xFF93503E),
    accentInfra: Color(0xFF776220),
    success: Color(0xFF45705A),
    warning: Color(0xFF776220),
    danger: Color(0xFFB23A31),
    info: Color(0xFF3B6A79),
    onAccent: Color(0xFFFFFFFF),
    focus: Color(0xFF3B6A79),
    data1: Color(0xFF3B6A79),
    data2: Color(0xFF665789),
    data3: Color(0xFF93503E),
    data4: Color(0xFF776220),
    dataOther: Color(0xFF7E8990),
    dataSeq1: Color(0xFFCED8DC),
    dataSeq2: Color(0xFFABBEC5),
    dataSeq3: Color(0xFF89A4AE),
    dataSeq4: Color(0xFF668A96),
    dataSeq5: Color(0xFF3B6A79),
    dataDivNeg2: Color(0xFF93503E),
    dataDivNeg1: Color(0xFFB2948C),
    dataDiv0: Color(0xFFD0D7DB),
    dataDivPos1: Color(0xFF86A0AA),
    dataDivPos2: Color(0xFF3B6A79),
  );

  /// `space-xs`. Ícone e rótulo; ajustes finos.
  static const double spaceXs = 4;

  /// `space-sm`. Itens próximos, padding de badges.
  static const double spaceSm = 8;

  /// `space-md`. Padding de cartões e campos; gutter padrão.
  static const double spaceMd = 16;

  /// `space-lg`. Entre grupos de conteúdo.
  static const double spaceLg = 24;

  /// `space-xl`. Entre seções de uma tela.
  static const double spaceXl = 32;

  /// `space-xxl`. Margens de página e respiro de banners.
  static const double spaceXxl = 48;

  /// `radius-sm`. Campos, chips, badges retangulares.
  static const double radiusSm = 8;

  /// `radius-md`. Botões e cartões.
  static const double radiusMd = 12;

  /// `radius-lg`. Painéis grandes e modais.
  static const double radiusLg = 16;

  /// `radius-pill`. Badges e controles em pílula.
  static const double radiusPill = 999;

  /// `icon-stroke-dense`. Traço de ícones em interfaces densas.
  static const double iconStrokeDense = 1.5;

  /// `icon-stroke`. Traço de ícones em destaque.
  static const double iconStroke = 2;

  /// `icon-size-sm`. Ícones em texto e badges.
  static const double iconSizeSm = 16;

  /// `icon-size-md`. Ícones de botões e campos.
  static const double iconSizeMd = 20;

  /// `icon-size-lg`. Navegação e ações principais.
  static const double iconSizeLg = 24;

  /// `motion-fast`. Pressionar, hover, troca de cor.
  static const motionFast = Duration(milliseconds: 100);

  /// `motion-base`. Chaves, seleção, menus, dicas, troca de valores.
  static const motionBase = Duration(milliseconds: 200);

  /// `motion-screen`. Troca de tela, painel, folha inferior, diálogo.
  static const motionScreen = Duration(milliseconds: 300);

  /// `motion-slow`. Onboarding, entrada de banner, gráficos que se desenham.
  static const motionSlow = Duration(milliseconds: 450);

  /// `motion-brand`. Entrada do logo CAPRA.
  static const motionBrand = Duration(milliseconds: 1400);

  /// `motion-brand-short`. Entrada curta do símbolo e entrada das logos filhas.
  static const motionBrandShort = Duration(milliseconds: 800);

  /// `motion-loop`. Uma volta do carregamento orbital, em velocidade constante.
  static const motionLoop = Duration(milliseconds: 1200);

  /// `ease-enter`. Entrada: desacelera ao chegar.
  static const easeEnter = Cubic(0.2, 0, 0, 1);

  /// `ease-exit`. Saída: acelera ao sair; usa o token de duração imediatamente
  /// menor que o da entrada.
  static const easeExit = Cubic(0.3, 0, 1, 1);

  /// `motion-distance`. Deslocamento máximo de um elemento ao entrar ou sair.
  static const double motionDistance = 16;
}
