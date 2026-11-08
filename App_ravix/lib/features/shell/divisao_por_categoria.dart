import 'package:flutter/material.dart';
import 'package:ravix/core/tema/icones.dart';
import 'package:ravix/core/tema/tema.dart';
import 'package:ravix/core/tema/tokens.dart';
import 'package:ravix/data/banco.dart';

/// Cor de uma categoria, na ordem das cores de gráfico da marca.
Color corDaCategoria(int idCategoria) =>
    CoresRavix.graficos[idCategoria % CoresRavix.graficos.length];

/// Card de resumo do mês, em Floresta: total à vista e divisão por
/// categoria. Ignora os filtros.
/// Barra empilhada com a parte de cada categoria e a legenda das maiores.
class DivisaoPorCategoria extends StatelessWidget {
  /// Cria a divisão de [total] entre [categorias].
  const new(this.categorias, this.total, {this.aoTocar, super.key});

  /// Totais por categoria, do maior para o menor.
  final List<TotalPorCategoria> categorias;

  /// Abre o detalhe por categoria; sem ele, a barra não é tocável.
  final VoidCallback? aoTocar;

  /// Total que as partes dividem.
  final int total;

  static const _naLegenda = 3;

  @override
  Widget build(BuildContext context) {
    final tema = context.temaRavix;
    final legenda = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: tema.resumoTexto);
    final maiores = categorias.take(_naLegenda).toList();
    final outras = categorias.skip(_naLegenda).fold(0, (s, c) => s + c.total);
    String parte(int valor) => '${(valor * 100 / total).round()}%';
    final partes = [
      for (final c in categorias) '${c.categoria} ${parte(c.total)}',
    ];

    final divisao = Semantics(
      container: true,
      button: aoTocar != null,
      label: [
        'Por categoria: ${partes.join(', ')}',
        if (aoTocar != null) 'Toque para ver por categoria',
      ].join('. '),
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 8,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 2,
              children: [
                for (final c in categorias)
                  Expanded(
                    flex: c.total,
                    child: ColoredBox(color: corDaCategoria(c.idCategoria)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: TokensRavix.spaceSm + 4),
          Wrap(
            spacing: TokensRavix.spaceMd,
            runSpacing: TokensRavix.spaceXs,
            children: [
              for (final c in maiores)
                _ItemDaLegenda(
                  cor: corDaCategoria(c.idCategoria),
                  rotulo: '${c.categoria} ${parte(c.total)}',
                  estilo: legenda,
                ),
              if (outras > 0)
                _ItemDaLegenda(
                  cor: tema.resumoApoio,
                  rotulo: 'Outras ${parte(outras)}',
                  estilo: legenda,
                ),
              if (aoTocar != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Ver por categoria',
                      style: legenda?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Icon(
                      Icones.chevronRight,
                      size: 16,
                      color: tema.resumoTexto,
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
    final tocar = aoTocar;
    if (tocar == null) return divisao;
    return InkWell(onTap: tocar, child: divisao);
  }
}

class _ItemDaLegenda extends StatelessWidget {
  const new({required this.cor, required this.rotulo, this.estilo});

  final Color cor;
  final String rotulo;
  final TextStyle? estilo;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox.square(dimension: 8, child: ColoredBox(color: cor)),
      const SizedBox(width: 6),
      Text(rotulo, style: estilo),
    ],
  );
}

/// Quadrado de 36 dp com chanfro de 4 dp, na cor da categoria a 20%.
class IconeDaCategoria extends StatelessWidget {
  /// Cria o ícone [icone] na cor [cor].
  const new({required this.icone, required this.cor, super.key});

  /// Ícone no centro.
  final IconData icone;

  /// Cor da categoria.
  final Color cor;

  @override
  Widget build(BuildContext context) {
    final escuro = Theme.of(context).brightness == Brightness.dark;
    final frente = escuro
        ? Color.lerp(cor, Colors.white, 0.35)!
        : Color.lerp(cor, CoresRavix.tinta, 0.35)!;
    return DecoratedBox(
      decoration: ShapeDecoration(
        // 15–25% da cor da categoria; mais forte no escuro, onde Floresta e
        // Petróleo quase somem.
        color: cor.withValues(alpha: escuro ? 0.25 : 0.18),
        shape: chanfro(TokensRavix.chanfroP),
      ),
      child: SizedBox.square(
        dimension: 36,
        child: Icon(icone, size: TokensRavix.iconSizeMd, color: frente),
      ),
    );
  }
}
