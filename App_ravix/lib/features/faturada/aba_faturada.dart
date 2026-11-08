import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ravix/app/dependencias.dart';
import 'package:ravix/core/datas.dart';
import 'package:ravix/core/tema/icones.dart';
import 'package:ravix/core/tema/tema.dart';
import 'package:ravix/core/tema/tokens.dart';
import 'package:ravix/core/valor.dart';
import 'package:ravix/data/banco.dart';
import 'package:ravix/data/fatura_repository.dart';
import 'package:ravix/data/faturado_repository.dart';
import 'package:ravix/data/recorrencia_repository.dart';
import 'package:ravix/features/cartoes/tela_cartoes.dart';
import 'package:ravix/features/faturada/aba_faturada_providers.dart';
import 'package:ravix/features/shell/divisao_por_categoria.dart';
import 'package:ravix/features/shell/estados_tela.dart';
import 'package:ravix/features/shell/mes_selecionado.dart';

/// Cor de um cartão nos gráficos, pela posição na lista.
Color corDoCartao(int posicao) =>
    CoresRavix.graficos[posicao % CoresRavix.graficos.length];

/// Aba Faturada (E01-F05): faturas do mês de todos os cartões, consumo do
/// limite, linha do tempo e os lançamentos da fatura.
class AbaFaturada extends ConsumerWidget {
  /// Cria a aba.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final faturas = ref.watch(faturasDoMesProvider);
    return switch (faturas) {
      AsyncData(:final value) when value.isEmpty => EstadoVazio(
        titulo: 'Nenhum cartão cadastrado',
        mensagem:
            'Cadastre seus cartões para acompanhar as faturas e o '
            'limite.',
        rotuloAcao: 'Cadastrar cartão',
        aoAgir: () => context.push('/configuracao/cartoes/novo'),
      ),
      AsyncData(:final value) => _Conteudo(value),
      AsyncError() => EstadoErro(
        aoTentarDeNovo: () => ref.invalidate(faturasDoMesProvider),
      ),
      _ => const EstadoCarregando(),
    };
  }
}

class _Conteudo extends ConsumerWidget {
  const new(this.faturas);

  final List<FaturaDoCartao> faturas;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mes = ref.watch(mesSelecionadoProvider);
    final escolhido = ref.watch(cartaoDaAbaProvider);
    final cartaoEscolhido = faturas
        .where((f) => f.cartao.uuidCartaoCredito == escolhido)
        .firstOrNull;
    final itens = ref.watch(itensDaFaturaProvider);
    final previstas = [
      for (final p
          in ref.watch(previstasDaFaturaProvider).value ?? const <Prevista>[])
        if (escolhido == null || p.regra.uuidCartaoCredito == escolhido) p,
    ];
    final pagamentos = [
      for (final p
          in ref.watch(pagamentosDoMesProvider).value ??
              const <PagamentoDoMes>[])
        if (escolhido == null || p.pagamento.uuidCartaoCredito == escolhido) p,
    ];
    final cores = {
      for (final (i, f) in faturas.indexed)
        f.cartao.uuidCartaoCredito: corDoCartao(i),
    };

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _Resumo(faturas, previstas: previstas)),
        SliverToBoxAdapter(child: _LinhaDoTempo(cores: cores)),
        const SliverToBoxAdapter(child: _Sobretitulo('CARTÕES')),
        SliverList.list(
          children: [
            for (final f in faturas)
              _LinhaCartao(
                fatura: f,
                mes: mes,
                cor: cores[f.cartao.uuidCartaoCredito]!,
                escolhido: f.cartao.uuidCartaoCredito == escolhido,
              ),
          ],
        ),
        if (pagamentos.isNotEmpty) ...[
          const SliverToBoxAdapter(child: _Sobretitulo('PAGAMENTOS')),
          SliverList.list(
            children: [for (final p in pagamentos) _LinhaPagamento(p)],
          ),
        ],
        if (previstas.isNotEmpty) ...[
          const SliverToBoxAdapter(child: _Sobretitulo('PREVISTOS')),
          SliverList.list(
            children: [for (final p in previstas) _LinhaPrevista(p)],
          ),
        ],
        SliverToBoxAdapter(
          child: _Sobretitulo(
            'LANÇAMENTOS',
            acao: cartaoEscolhido == null
                ? null
                : InputChip(
                    label: Text(cartaoEscolhido.cartao.nomeCartao),
                    tooltip: 'Mostrar todos os cartões',
                    onDeleted: ref.read(cartaoDaAbaProvider.notifier).todos,
                    deleteButtonTooltipMessage: 'Mostrar todos os cartões',
                  ),
          ),
        ),
        ...switch (itens) {
          AsyncData(:final value) when value.isEmpty => [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  TokensRavix.spaceMd,
                  TokensRavix.spaceSm,
                  TokensRavix.spaceMd,
                  96,
                ),
                child: Text(
                  cartaoEscolhido == null
                      ? 'Nenhum lançamento nas faturas de ${mes.rotulo}.'
                      : 'Nenhum lançamento na fatura de ${mes.rotulo} do '
                            '${cartaoEscolhido.cartao.nomeCartao}.',
                  style: TextStyle(
                    color: context.temaRavix.paleta.textSecondary,
                  ),
                ),
              ),
            ),
          ],
          AsyncData(:final value) => [
            SliverPadding(
              // Espaço para o botão flutuante não cobrir o último item.
              padding: const EdgeInsets.only(bottom: 96),
              sliver: SliverList.builder(
                itemCount: value.length,
                itemBuilder: (context, i) => _LinhaItem(
                  value[i],
                  cor: cores[value[i].uuidCartao] ?? corDoCartao(0),
                  comCartao: escolhido == null && faturas.length > 1,
                  nomeCartao: faturas
                      .firstWhere(
                        (f) =>
                            f.cartao.uuidCartaoCredito == value[i].uuidCartao,
                        orElse: () => faturas.first,
                      )
                      .cartao
                      .nomeCartao,
                ),
              ),
            ),
          ],
          AsyncError() => [
            SliverToBoxAdapter(
              child: EstadoErro(
                aoTentarDeNovo: () => ref.invalidate(itensDaFaturaProvider),
              ),
            ),
          ],
          _ => [const SliverToBoxAdapter(child: EstadoCarregando())],
        },
      ],
    );
  }
}

class _Sobretitulo extends StatelessWidget {
  const new(this.texto, {this.acao});

  final String texto;
  final Widget? acao;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      TokensRavix.spaceMd,
      TokensRavix.spaceLg,
      TokensRavix.spaceMd,
      TokensRavix.spaceXs,
    ),
    child: Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(texto, style: context.temaRavix.sobretitulo),
          ),
        ),
        ?acao,
      ],
    ),
  );
}

/// Card de resumo em Floresta: total das faturas do mês, previstos à parte
/// e divisão por categoria (E01-F05-T06, T07).
class _Resumo extends ConsumerWidget {
  const new(this.faturas, {required this.previstas});

  final List<FaturaDoCartao> faturas;
  final List<Prevista> previstas;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = context.temaRavix;
    final texto = Theme.of(context).textTheme;
    final mes = ref.watch(mesSelecionadoProvider);
    final total = faturas.fold(0, (s, f) => s + f.valor);
    final previsto = previstas.fold(0, (s, p) => s + p.regra.valorRecorrencia);
    final categorias =
        ref.watch(faturasPorCategoriaProvider).value ??
        const <TotalPorCategoria>[];
    final apoio = texto.bodySmall?.copyWith(color: tema.resumoApoio);
    final valor = formatarCentavos(total);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TokensRavix.spaceMd,
        TokensRavix.spaceSm,
        TokensRavix.spaceMd,
        0,
      ),
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: tema.resumoFundo,
          shape: chanfro(TokensRavix.chanfroG),
        ),
        child: Padding(
          padding: const EdgeInsets.all(TokensRavix.spaceMd + 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                container: true,
                label: [
                  'Faturas de ${mes.rotulo}: $valor',
                  if (previsto > 0)
                    'mais ${formatarCentavos(previsto)} previstos',
                ].join(', '),
                excludeSemantics: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Faturas de ${mes.nome}', style: apoio),
                    const SizedBox(height: TokensRavix.spaceXs),
                    Text(
                      valor,
                      style: tema.valorDestaque.copyWith(
                        color: tema.resumoTexto,
                      ),
                    ),
                    if (previsto > 0)
                      Text(
                        '+ ${formatarCentavos(previsto)} previstos',
                        style: apoio,
                      ),
                  ],
                ),
              ),
              if (total > 0 && categorias.isNotEmpty) ...[
                const SizedBox(height: TokensRavix.spaceMd),
                DivisaoPorCategoria(
                  categorias,
                  categorias.fold(0, (s, c) => s + c.total),
                  aoTocar: () => context.push('/categorias/faturada'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Barras das faturas mês a mês, com os cartões empilhados (E01-F05-T05).
/// Tocar num mês vai para ele.
class _LinhaDoTempo extends ConsumerWidget {
  const new({required this.cores});

  final Map<String, Color> cores;

  static const _altura = 88.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = context.temaRavix;
    final selecionado = ref.watch(mesSelecionadoProvider);
    final pontos =
        ref.watch(linhaDoTempoProvider).value ?? const <PontoDaLinhaDoTempo>[];
    var mes = selecionado;
    for (var i = 0; i < mesesAntesNaLinhaDoTempo; i++) {
      mes = mes.anterior;
    }
    final meses = <Mes>[];
    for (var i = 0; i < mesesNaLinhaDoTempo; i++) {
      meses.add(mes);
      mes = mes.proximo;
    }
    final porMes = {
      for (final m in meses)
        m: [
          for (final p in pontos)
            if (p.mes == m && p.valor > 0) p,
        ],
    };
    final totais = {
      for (final m in meses) m: porMes[m]!.fold(0, (s, p) => s + p.valor),
    };
    final maior = totais.values.fold(0, math.max);
    if (maior == 0) return const SizedBox.shrink();
    final rotulo = Theme.of(context).textTheme.labelSmall;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TokensRavix.spaceMd,
        TokensRavix.spaceLg,
        TokensRavix.spaceMd,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text('FATURAS MÊS A MÊS', style: tema.sobretitulo),
          ),
          const SizedBox(height: TokensRavix.spaceSm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            spacing: 4,
            children: [
              for (final m in meses)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: m == selecionado,
                    label: '${m.rotulo}: ${formatarCentavos(totais[m]!)}',
                    excludeSemantics: true,
                    child: InkWell(
                      onTap: () =>
                          ref.read(mesSelecionadoProvider.notifier).ir(m),
                      child: Column(
                        children: [
                          SizedBox(
                            height: _altura,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                for (final p in porMes[m]!.reversed)
                                  Container(
                                    height: math.max(
                                      2,
                                      _altura * p.valor / maior,
                                    ),
                                    color:
                                        (cores[p.uuidCartao] ??
                                                tema.paleta.textSecondary)
                                            .withValues(
                                              alpha: m == selecionado
                                                  ? 1
                                                  : 0.55,
                                            ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            m.nome.substring(0, 3),
                            style: rotulo?.copyWith(
                              fontWeight: m == selecionado
                                  ? FontWeight.w700
                                  : null,
                              color: m == selecionado
                                  ? tema.acento
                                  : tema.paleta.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Vencimento da fatura de [mes] no cartão, se o dia é conhecido.
DateTime? vencimentoDaFatura(CartaoCredito cartao, Mes mes) =>
    switch (cartao.diaVencimento) {
      final dia? => DateTime(mes.ano, mes.mes, math.min(dia, ultimoDiaDo(mes))),
      null => null,
    };

/// Situação da fatura: paga, vencida sem pagamento ou a vencer.
String situacaoDaFatura(FaturaDoCartao fatura, Mes mes, DateTime hoje) {
  if (fatura.pagoEm case final pagoEm?) {
    return 'Paga em ${formatarData(pagoEm)}';
  }
  if (fatura.valor <= 0) return 'Sem lançamentos';
  final vence = vencimentoDaFatura(fatura.cartao, mes);
  final hojeSemHora = DateTime(hoje.year, hoje.month, hoje.day);
  if (vence == null) {
    return mes.compareTo(Mes.de(hoje)) < 0 ? 'Sem pagamento' : 'Em aberto';
  }
  return vence.isBefore(hojeSemHora)
      ? 'Venceu em ${formatarData(vence)}, sem pagamento'
      : 'Vence em ${formatarData(vence)}';
}

/// Linha de um cartão: fatura do mês, situação e consumo do limite
/// (E01-F05-T01, T09). Tocar mostra só os lançamentos dele (T02).
class _LinhaCartao extends ConsumerWidget {
  const new({
    required this.fatura,
    required this.mes,
    required this.cor,
    required this.escolhido,
  });

  final FaturaDoCartao fatura;
  final Mes mes;
  final Color cor;
  final bool escolhido;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = context.temaRavix;
    final paleta = tema.paleta;
    final texto = Theme.of(context).textTheme;
    final cartao = fatura.cartao;
    final hoje = ref.watch(relogioProvider).agora();
    final situacao = situacaoDaFatura(fatura, mes, hoje);
    final paga = fatura.pagoEm != null;
    final vencida = situacao.startsWith('Venceu');
    final parte = fatura.consumo / cartao.limiteCartao;
    final porcento = (parte * 100).round();
    final consumo =
        '${formatarCentavos(fatura.consumo)} de '
        '${formatarCentavos(cartao.limiteCartao)} do limite ($porcento%)';
    final valor = formatarCentavos(fatura.valor);
    final arquivado = cartao.status == 'arquivado';

    return Semantics(
      button: true,
      selected: escolhido,
      label:
          '${nomeComFinal(cartao)}${arquivado ? ' (arquivado)' : ''}, '
          'fatura de $valor, $situacao. $consumo. '
          '${escolhido ? 'Toque para ver todos.' : 'Toque para ver só este.'}',
      excludeSemantics: true,
      child: InkWell(
        onTap: () => ref
            .read(cartaoDaAbaProvider.notifier)
            .alternar(cartao.uuidCartaoCredito),
        child: Container(
          decoration: BoxDecoration(
            color: escolhido ? paleta.surfaceAlt : null,
            border: Border(
              left: BorderSide(color: cor, width: escolhido ? 4 : 2),
            ),
          ),
          margin: const EdgeInsets.symmetric(
            horizontal: TokensRavix.spaceMd,
            vertical: TokensRavix.spaceXs,
          ),
          padding: const EdgeInsets.fromLTRB(
            TokensRavix.spaceMd,
            TokensRavix.spaceSm,
            0,
            TokensRavix.spaceSm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      arquivado
                          ? '${nomeComFinal(cartao)} (arquivado)'
                          : nomeComFinal(cartao),
                      style: texto.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(valor, style: tema.valorLista),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                situacao,
                style: texto.bodySmall?.copyWith(
                  color: paga
                      ? paleta.ok
                      : vencida
                      ? paleta.danger
                      : paleta.textSecondary,
                ),
              ),
              const SizedBox(height: TokensRavix.spaceSm),
              LinearProgressIndicator(
                value: parte.clamp(0, 1).toDouble(),
                minHeight: 6,
                color: parte > 1 ? paleta.danger : cor,
                backgroundColor: paleta.border,
                borderRadius: BorderRadius.zero,
              ),
              const SizedBox(height: 4),
              Text(
                consumo,
                style: texto.bodySmall?.copyWith(
                  color: parte > 1 ? paleta.danger : paleta.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LinhaPagamento extends StatelessWidget {
  const new(this.linha);

  final PagamentoDoMes linha;

  @override
  Widget build(BuildContext context) {
    final p = linha.pagamento;
    final forma = switch (FormaPagamentoFatura.deCodigo(p.tipoPagamento)) {
      FormaPagamentoFatura.pix => 'Pix',
      FormaPagamentoFatura.debito => 'Débito',
      FormaPagamentoFatura.boleto => 'Boleto',
    };
    final data = formatarData(DateTime.parse(p.timestampPagamento));
    final valor = formatarCentavos(p.valorPagamento);
    return Semantics(
      button: true,
      label:
          'Pagamento da fatura ${linha.nomeCartao}, $valor, $forma, $data. '
          'Toque para editar.',
      excludeSemantics: true,
      child: ListTile(
        leading: const Icon(Icones.check),
        title: Text('Pagamento ${linha.nomeCartao}'),
        subtitle: Text('$forma · $data'),
        trailing: Text(valor, style: context.temaRavix.valorLista),
        onTap: () =>
            context.push('/registro/pagamento/${p.uuidPagamentoFatura}'),
      ),
    );
  }
}

/// Cobrança recorrente do cartão ainda não lançada: entra sozinha no dia
/// (DP-25), então aqui só aparece, sem botão.
class _LinhaPrevista extends StatelessWidget {
  const new(this.prevista);

  final Prevista prevista;

  @override
  Widget build(BuildContext context) {
    final regra = prevista.regra;
    final data = formatarData(prevista.ocorrencia);
    final valor = formatarCentavos(regra.valorRecorrencia);
    return ListTile(
      leading: const Icon(Icones.clock),
      title: Text(
        regra.descricao,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text('Previsto para $data'),
      trailing: Text(
        valor,
        style: context.temaRavix.valorLista.copyWith(
          color: context.temaRavix.paleta.textSecondary,
        ),
      ),
    );
  }
}

/// Parcela ou estorno da fatura (E01-F05-T03, T04, T10). Tocar abre a
/// edição.
class _LinhaItem extends StatelessWidget {
  const new(
    this.item, {
    required this.cor,
    required this.comCartao,
    required this.nomeCartao,
  });

  final ItemDaFatura item;
  final Color cor;
  final bool comCartao;
  final String nomeCartao;

  @override
  Widget build(BuildContext context) {
    final tema = context.temaRavix;
    final estorno = item.tipo == TipoItemFatura.estorno;
    final valor = estorno
        ? '− ${formatarCentavos(item.valor)}'
        : formatarCentavos(item.valor);
    final detalhe = [
      if (estorno) 'Estorno',
      if (item.quantParcelas > 1) '${item.numeroParcela}/${item.quantParcelas}',
      if (item.recorrente) 'Recorrente',
      item.subcategoria,
      formatarData(item.momento),
      if (comCartao) nomeCartao,
      ?item.tag,
    ].join(' · ');
    final rota = estorno
        ? '/registro/estorno/${item.uuid}'
        : '/registro/faturado/${item.uuid}';

    return Semantics(
      button: true,
      label: '${item.descricao}, $valor, $detalhe. Toque para editar.',
      excludeSemantics: true,
      child: ListTile(
        minTileHeight: 64,
        leading: IconeDaCategoria(
          icone: estorno ? Icones.refreshCw : Icones.creditCard,
          cor: corDaCategoria(item.idCategoria),
        ),
        title: Text(
          item.descricao,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(detalhe, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Text(
          valor,
          style: tema.valorLista.copyWith(
            color: estorno ? tema.paleta.ok : null,
          ),
        ),
        onTap: () => context.push(rota),
      ),
    );
  }
}
