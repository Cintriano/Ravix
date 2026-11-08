import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show StreamProviderFamily;
import 'package:ravix/app/dependencias.dart';
import 'package:ravix/core/tema/tema.dart';
import 'package:ravix/core/tema/tokens.dart';
import 'package:ravix/core/valor.dart';
import 'package:ravix/data/analise_repository.dart';
import 'package:ravix/features/analise/lista_por_categoria.dart';
import 'package:ravix/features/shell/estados_tela.dart';
import 'package:ravix/features/shell/mes_selecionado.dart';
import 'package:ravix/features/shell/seletor_mes.dart';

/// De onde vêm os gastos da tela por categoria.
enum OrigemAnalise {
  /// Gastos à vista do mês (E01-F04-T06).
  avista('avista', 'Gastos à vista'),

  /// Faturas do mês, todos os cartões (E01-F05-T06).
  faturada('faturada', 'Faturas');

  new(this.codigo, this.titulo);

  /// Código na rota.
  final String codigo;

  /// Título da tela.
  final String titulo;

  /// Origem pelo [codigo]; desconhecido vira à vista.
  static OrigemAnalise deCodigo(String? codigo) => values.firstWhere(
    (o) => o.codigo == codigo,
    orElse: () => OrigemAnalise.avista,
  );
}

/// Totais do mês selecionado por subcategoria, da `origem`.
final StreamProviderFamily<List<TotalPorSubcategoria>, OrigemAnalise>
porSubcategoriaProvider = StreamProvider.autoDispose.family((ref, origem) {
  final mes = ref.watch(mesSelecionadoProvider);
  final analise = ref.watch(analiseRepositoryProvider);
  return switch (origem) {
    OrigemAnalise.avista => analise.observarAvista(mes),
    OrigemAnalise.faturada => analise.observarFaturada(mes),
  };
});

/// Gasto do mês por categoria ou subcategoria, com o seletor de visão
/// (E01-F04-T06, E01-F05-T06). Segue o seletor de mês global.
class TelaPorCategoria extends ConsumerStatefulWidget {
  /// Cria a tela da [origem].
  const new({required this.origem, super.key});

  /// À vista ou faturas.
  final OrigemAnalise origem;

  @override
  ConsumerState<TelaPorCategoria> createState() => _TelaPorCategoriaState();
}

class _TelaPorCategoriaState extends ConsumerState<TelaPorCategoria> {
  VisaoDaLista _visao = VisaoDaLista.categoria;

  @override
  Widget build(BuildContext context) {
    final tema = context.temaRavix;
    final mes = ref.watch(mesSelecionadoProvider);
    final valor = ref.watch(porSubcategoriaProvider(widget.origem));
    return Scaffold(
      appBar: AppBar(titleSpacing: 0, title: const SeletorMes()),
      body: ConteudoAssincrono<List<TotalPorSubcategoria>>(
        valor: valor,
        estaVazio: (linhas) => linhas.isEmpty,
        aoTentarDeNovo: () =>
            ref.invalidate(porSubcategoriaProvider(widget.origem)),
        vazio: EstadoVazio(
          titulo: 'Nada em ${mes.nome}',
          mensagem:
              '${widget.origem.titulo} de ${mes.rotulo} aparecem aqui por '
              'categoria.',
        ),
        conteudo: (linhas) => ListView(
          padding: const EdgeInsets.only(bottom: TokensRavix.spaceLg),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                TokensRavix.spaceMd,
                TokensRavix.spaceSm,
                TokensRavix.spaceMd,
                0,
              ),
              child: Semantics(
                header: true,
                child: Text(
                  '${widget.origem.titulo.toUpperCase()} POR CATEGORIA',
                  style: tema.sobretitulo,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: TokensRavix.spaceMd,
              ),
              child: Text(
                formatarCentavos(linhas.fold(0, (s, l) => s + l.total)),
                style: tema.valorDestaque,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(TokensRavix.spaceMd),
              child: SeletorDeVisao(
                visao: _visao,
                aoEscolher: (v) => setState(() => _visao = v),
              ),
            ),
            ListaPorCategoria(linhas: linhas, visao: _visao),
          ],
        ),
      ),
    );
  }
}
