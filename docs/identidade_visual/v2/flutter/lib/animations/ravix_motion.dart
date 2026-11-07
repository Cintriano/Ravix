import 'package:flutter/material.dart';

/// Tokens de movimento do Ravix (manual v2, seção "Movimento").
///
/// A haste desce, a seta sobe. Sem quique, sombra ou elástico: só deslocamento,
/// opacidade e cor.
abstract final class RavixMotion {
  static const Duration rapido = Duration(milliseconds: 120); // toque, troca de estado
  static const Duration padrao = Duration(milliseconds: 220); // folhas, mês, linhas de lista
  static const Duration enfase = Duration(milliseconds: 420); // seta na confirmação
  static const Duration abertura = Duration(milliseconds: 900); // seta na abertura (só ela)
  static const Duration stagger = Duration(milliseconds: 40); // entre linhas de uma lista

  /// cubic-bezier(.2, .8, .2, 1)
  static const Curve curve = Cubic(.2, .8, .2, 1);

  /// `true` quando o sistema pede para reduzir movimento.
  static bool reduced(BuildContext context) => MediaQuery.disableAnimationsOf(context);

  /// Duração a usar: some (zero) quando o movimento está reduzido.
  static Duration of(BuildContext context, Duration d) => reduced(context) ? Duration.zero : d;
}
