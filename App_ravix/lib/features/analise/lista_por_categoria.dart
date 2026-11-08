import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ravix/core/tema/icones.dart';
import 'package:ravix/core/tema/tema.dart';
import 'package:ravix/core/tema/tokens.dart';
import 'package:ravix/core/valor.dart';
import 'package:ravix/data/analise_repository.dart';
import 'package:ravix/features/shell/divisao_por_categoria.dart';

/// Visão da lista: por categoria (com as subcategorias dentro) ou só as
/// subcategorias (E01-F04-T06, "seletor de visão").
enum VisaoDaLista {
  /// Uma linha por categoria; tocar abre as subcategorias.
  categoria('Categoria'),

  /// Uma linha por subcategoria, de todas as categorias.
  subcategoria('Subcategoria');

  new(this.rotulo);

  /// Nome no seletor.
  final String rotulo;
}

/// Seletor entre categoria e subcategoria.
class SeletorDeVisao extends StatelessWidget {
  /// Cria o seletor com [visao] escolhida.
  const new({required this.visao, required this.aoEscolher, super.key});

  /// Visão escolhida.
  final VisaoDaLista visao;

  /// Recebe a nova visão.
  final ValueChanged<VisaoDaLista> aoEscolher;

  @override
  Widget build(BuildContext context) => SegmentedButton<VisaoDaLista>(
    showSelectedIcon: false,
    segments: [
      for (final v in VisaoDaLista.values)
        ButtonSegment(value: v, label: Text(v.rotulo)),
    ],
    selected: {visao},
    onSelectionChanged: (e) => aoEscolher(e.single),
  );
}

/// Valor de uma linha: só o total ou "pago de total" quando diferem.
String valorDaLinha(int pago, int total, {required bool comPago}) =>
    comPago && pago != total
    ? '${formatarCentavos(pago)} de ${formatarCentavos(total)}'
    : formatarCentavos(total);

/// Lista com barra horizontal por categoria ou subcategoria. Com [comPago],
/// mostra também o pago até agora (visão por tag).
class ListaPorCategoria extends StatefulWidget {
  /// Cria a lista de [linhas] na [visao].
  const new({
    required this.linhas,
    required this.visao,
    this.comPago = false,
    super.key,
  });

  /// Totais por subcategoria.
  final List<TotalPorSubcategoria> linhas;

  /// Categoria ou subcategoria.
  final VisaoDaLista visao;

  /// Mostrar "pago de total".
  final bool comPago;

  @override
  State<ListaPorCategoria> createState() => _ListaPorCategoriaState();
}

class _ListaPorCategoriaState extends State<ListaPorCategoria> {
  final _abertas = <int>{};

  @override
  Widget build(BuildContext context) {
    final comPago = widget.comPago;
    final soma = widget.linhas.fold(0, (s, l) => s + l.total);
    if (widget.visao == VisaoDaLista.subcategoria) {
      final linhas = [...widget.linhas]
        ..sort((a, b) => b.total.compareTo(a.total));
      final maior = linhas.fold(0, (m, l) => math.max(m, l.total));
      return Column(
        children: [
          for (final l in linhas)
            _LinhaDeBarra(
              rotulo: l.subcategoria,
              apoio: l.categoria,
              valor: valorDaLinha(l.pago, l.total, comPago: comPago),
              parte: maior <= 0 ? 0 : l.total / maior,
              porcento: soma <= 0 ? null : l.total * 100 / soma,
              cor: corDaCategoria(l.idCategoria),
            ),
        ],
      );
    }
    final categorias = agruparPorCategoria(widget.linhas);
    final maior = categorias.fold(0, (m, c) => math.max(m, c.total));
    return Column(
      children: [
        for (final c in categorias) ...[
          _LinhaDeBarra(
            rotulo: c.categoria,
            valor: valorDaLinha(c.pago, c.total, comPago: comPago),
            parte: maior <= 0 ? 0 : c.total / maior,
            porcento: soma <= 0 ? null : c.total * 100 / soma,
            cor: corDaCategoria(c.idCategoria),
            aberta: _abertas.contains(c.idCategoria),
            aoTocar: () => setState(() {
              if (!_abertas.remove(c.idCategoria)) _abertas.add(c.idCategoria);
            }),
          ),
          if (_abertas.contains(c.idCategoria))
            for (final s in c.subcategorias)
              _LinhaDeBarra(
                rotulo: s.subcategoria,
                valor: valorDaLinha(s.pago, s.total, comPago: comPago),
                parte: c.total <= 0 ? 0 : s.total / c.total,
                porcento: c.total <= 0 ? null : s.total * 100 / c.total,
                cor: corDaCategoria(c.idCategoria).withValues(alpha: 0.6),
                recuo: true,
              ),
        ],
      ],
    );
  }
}

class _LinhaDeBarra extends StatelessWidget {
  const new({
    required this.rotulo,
    required this.valor,
    required this.parte,
    required this.porcento,
    required this.cor,
    this.apoio,
    this.aberta,
    this.aoTocar,
    this.recuo = false,
  });

  final String rotulo;
  final String? apoio;
  final String valor;
  final double parte;
  final double? porcento;
  final Color cor;
  final bool? aberta;
  final VoidCallback? aoTocar;
  final bool recuo;

  @override
  Widget build(BuildContext context) {
    final tema = context.temaRavix;
    final paleta = tema.paleta;
    final texto = Theme.of(context).textTheme;
    final parteTexto = porcento == null ? null : '${porcento!.round()}%';
    final aberta = this.aberta;
    return Semantics(
      button: aoTocar != null,
      expanded: aberta,
      label: [
        rotulo,
        ?apoio,
        valor,
        if (parteTexto != null)
          '$parteTexto ${recuo ? 'da categoria' : 'do total'}',
      ].join(', '),
      excludeSemantics: true,
      child: InkWell(
        onTap: aoTocar,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            recuo
                ? TokensRavix.spaceLg + TokensRavix.spaceMd
                : TokensRavix.spaceMd,
            TokensRavix.spaceSm,
            TokensRavix.spaceMd,
            TokensRavix.spaceSm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      rotulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: recuo ? texto.bodyMedium : texto.titleSmall,
                    ),
                  ),
                  const SizedBox(width: TokensRavix.spaceSm),
                  // "R$ 200,00 de R$ 1.200,00" encolhe em vez de estourar.
                  Flexible(
                    flex: 4,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(valor, style: tema.valorLista),
                    ),
                  ),
                  if (aberta != null)
                    Icon(
                      aberta ? Icones.chevronDown : Icones.chevronRight,
                      size: TokensRavix.iconSizeSm,
                      color: paleta.textSecondary,
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: parte.clamp(0, 1).toDouble(),
                        child: SizedBox(
                          height: 6,
                          child: ColoredBox(color: cor),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: TokensRavix.spaceSm),
                  SizedBox(
                    width: 40,
                    child: Text(
                      parteTexto ?? '',
                      textAlign: TextAlign.end,
                      style: texto.bodySmall?.copyWith(
                        color: paleta.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              if (apoio != null)
                Text(
                  apoio!,
                  style: texto.bodySmall?.copyWith(color: paleta.textSecondary),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
