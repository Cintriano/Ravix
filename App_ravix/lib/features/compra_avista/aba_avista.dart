import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ravix/core/datas.dart';
import 'package:ravix/core/tema/icones.dart';
import 'package:ravix/core/tema/tema.dart';
import 'package:ravix/core/tema/tokens.dart';
import 'package:ravix/core/valor.dart';
import 'package:ravix/data/banco.dart';
import 'package:ravix/data/compra_avista_repository.dart';
import 'package:ravix/features/compra_avista/aba_avista_providers.dart';
import 'package:ravix/features/compra_avista/formulario_compra.dart';
import 'package:ravix/features/compra_avista/formulario_providers.dart';
import 'package:ravix/features/shell/estados_tela.dart';
import 'package:ravix/features/shell/mes_selecionado.dart';

/// Ícone de cada forma de pagamento na lista.
IconData iconeDoPagamento(TipoPagamento tipo) => switch (tipo) {
  TipoPagamento.pix => Icones.qrCode,
  TipoPagamento.debito => Icones.creditCard,
  TipoPagamento.dinheiro => Icones.banknote,
  TipoPagamento.voucher => Icones.ticket,
  TipoPagamento.boleto => Icones.receipt,
};

/// Aba À vista (E01-F04): total do mês, filtros e gastos agrupados por dia.
/// Tocar num gasto abre a edição (T03).
class AbaAvista extends ConsumerWidget {
  /// Cria a aba.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mes = ref.watch(mesSelecionadoProvider);
    final filtro = ref.watch(filtroDaTabelaProvider);
    final filtrando = filtro != semFiltro;

    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: _Total()),
        const SliverToBoxAdapter(child: _Filtros()),
        ...switch (ref.watch(comprasDoMesProvider)) {
          AsyncData(:final value) when value.isEmpty => [
            SliverFillRemaining(
              hasScrollBody: false,
              child: filtrando
                  ? EstadoVazio(
                      titulo: 'Nada com esses filtros',
                      mensagem:
                          'Nenhum gasto de ${mes.rotulo} combina com '
                          'os filtros escolhidos.',
                      rotuloAcao: 'Limpar filtros',
                      aoAgir: ref.read(filtroDaTabelaProvider.notifier).limpar,
                    )
                  : EstadoVazio(
                      titulo: 'Nenhum gasto em ${mes.nome}',
                      mensagem:
                          'Os gastos à vista de ${mes.rotulo} aparecem '
                          'aqui.',
                    ),
            ),
          ],
          AsyncData(:final value) => [_Lista(value)],
          AsyncError() => [
            SliverFillRemaining(
              hasScrollBody: false,
              child: EstadoErro(
                aoTentarDeNovo: () => ref.invalidate(comprasDoMesProvider),
              ),
            ),
          ],
          _ => [
            const SliverFillRemaining(
              hasScrollBody: false,
              child: EstadoCarregando(),
            ),
          ],
        },
      ],
    );
  }
}

/// Cor de uma categoria, na ordem das cores de gráfico da marca.
Color corDaCategoria(int idCategoria) =>
    CoresRavix.graficos[idCategoria % CoresRavix.graficos.length];

/// Card de resumo do mês, em Floresta: total à vista e divisão por
/// categoria. Ignora os filtros.
class _Total extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = context.temaRavix;
    final texto = Theme.of(context).textTheme;
    final mes = ref.watch(mesSelecionadoProvider);
    final total = ref.watch(acumuladoDoMesProvider).value;
    final categorias =
        ref.watch(totaisPorCategoriaProvider).value ??
        const <TotalPorCategoria>[];
    final valor = total == null ? '—' : formatarCentavos(total);
    final apoio = texto.bodySmall?.copyWith(color: tema.resumoApoio);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TokensRavix.spaceMd,
        TokensRavix.spaceSm,
        TokensRavix.spaceMd,
        TokensRavix.spaceMd,
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
                label: 'Total à vista em ${mes.rotulo}: $valor',
                excludeSemantics: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total à vista em ${mes.nome}', style: apoio),
                    const SizedBox(height: TokensRavix.spaceXs),
                    Text(
                      valor,
                      style: tema.valorDestaque.copyWith(
                        color: tema.resumoTexto,
                      ),
                    ),
                  ],
                ),
              ),
              if (total != null && total > 0 && categorias.isNotEmpty) ...[
                const SizedBox(height: TokensRavix.spaceMd),
                _DivisaoPorCategoria(categorias, total),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Barra empilhada com a parte de cada categoria e a legenda das maiores.
class _DivisaoPorCategoria extends StatelessWidget {
  const new(this.categorias, this.total);

  final List<TotalPorCategoria> categorias;
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

    return Semantics(
      container: true,
      label: 'Por categoria: ${partes.join(', ')}',
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
            ],
          ),
        ],
      ),
    );
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

class _Filtros extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtro = ref.watch(filtroDaTabelaProvider);
    final controle = ref.read(filtroDaTabelaProvider.notifier);
    final categorias = ref.watch(categoriasProvider).value ?? const [];
    final idCategoria = filtro.idCategoria;
    final subcategorias = idCategoria == null
        ? const <Subcategoria>[]
        : ref.watch(subcategoriasProvider(idCategoria)).value ?? const [];
    final tags = ref.watch(todasAsTagsProvider).value ?? const <Tag>[];

    String? nomeDe<T>(
      Iterable<T> itens,
      bool Function(T) igual,
      String Function(T) nome,
    ) {
      for (final item in itens) {
        if (igual(item)) return nome(item);
      }
      return null;
    }

    final nomeCategoria = nomeDe(
      categorias,
      (c) => c.idCategoria == idCategoria,
      (c) => c.nome,
    );
    final nomeSubcategoria = nomeDe(
      subcategorias,
      (s) => s.idSubcategoria == filtro.idSubcategoria,
      (s) => s.nome,
    );
    final nomeTag = nomeDe(
      tags,
      (t) => t.uuidTag == filtro.uuidTag,
      (t) => t.nome,
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: TokensRavix.spaceMd),
      child: Row(
        spacing: TokensRavix.spaceSm,
        children: [
          _ChipDeFiltro(
            rotulo: 'Categoria',
            escolhido: idCategoria == null ? null : nomeCategoria,
            aoTocar: () async {
              final escolha = await _escolherNaFolha(
                context,
                titulo: 'Filtrar por categoria',
                opcoes: [for (final c in categorias) (c.idCategoria, c.nome)],
                atual: idCategoria,
              );
              if (escolha != null) controle.categoria(escolha.valor);
            },
          ),
          if (idCategoria != null)
            _ChipDeFiltro(
              rotulo: 'Subcategoria',
              escolhido: filtro.idSubcategoria == null
                  ? null
                  : nomeSubcategoria,
              aoTocar: () async {
                final escolha = await _escolherNaFolha(
                  context,
                  titulo: 'Filtrar por subcategoria',
                  opcoes: [
                    for (final s in subcategorias) (s.idSubcategoria, s.nome),
                  ],
                  atual: filtro.idSubcategoria,
                );
                if (escolha != null) controle.subcategoria(escolha.valor);
              },
            ),
          _ChipDeFiltro(
            rotulo: 'Tag',
            escolhido: filtro.uuidTag == null ? null : nomeTag,
            aoTocar: () async {
              final escolha = await _escolherNaFolha(
                context,
                titulo: 'Filtrar por tag',
                opcoes: [
                  for (final t in tags)
                    (
                      t.uuidTag,
                      t.status == 'arquivada'
                          ? '${t.nome} (arquivada)'
                          : t.nome,
                    ),
                ],
                atual: filtro.uuidTag,
              );
              if (escolha != null) controle.tag(escolha.valor);
            },
          ),
          if (filtro != semFiltro)
            TextButton(onPressed: controle.limpar, child: const Text('Limpar')),
        ],
      ),
    );
  }
}

class _ChipDeFiltro extends StatelessWidget {
  const new({
    required this.rotulo,
    required this.escolhido,
    required this.aoTocar,
  });

  final String rotulo;
  final String? escolhido;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final ativo = escolhido != null;
    return FilterChip(
      label: Text(ativo ? escolhido! : rotulo),
      tooltip: ativo
          ? '$rotulo: $escolhido'
          : 'Filtrar por ${rotulo.toLowerCase()}',
      selected: ativo,
      showCheckmark: false,
      avatar: ativo
          ? null
          : const Icon(Icones.chevronDown, size: TokensRavix.iconSizeSm),
      onSelected: (_) => aoTocar(),
    );
  }
}

/// Escolha feita na folha: `valor` nulo = "Todas" (sem filtro).
typedef _Escolha<T> = ({T? valor});

/// Folha inferior com as opções e "Todas". Devolve `null` se fechada sem
/// escolher.
Future<_Escolha<T>?> _escolherNaFolha<T>(
  BuildContext context, {
  required String titulo,
  required List<(T, String)> opcoes,
  required T? atual,
}) => showModalBottomSheet<_Escolha<T>>(
  context: context,
  isScrollControlled: true,
  builder: (contexto) {
    final acento = contexto.temaRavix.acento;
    Widget opcao(T? valor, String rotulo) => ListTile(
      title: Text(rotulo),
      trailing: valor == atual ? Icon(Icones.check, color: acento) : null,
      selected: valor == atual,
      onTap: () => Navigator.of(contexto).pop((valor: valor)),
    );
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(contexto).height * 0.7,
        ),
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                TokensRavix.spaceMd,
                0,
                TokensRavix.spaceMd,
                TokensRavix.spaceSm,
              ),
              child: Text(
                titulo,
                style: Theme.of(contexto).textTheme.titleLarge,
              ),
            ),
            opcao(null, 'Todas'),
            for (final (valor, rotulo) in opcoes) opcao(valor, rotulo),
          ],
        ),
      ),
    );
  },
);

/// Linha da lista: um cabeçalho de dia ou um gasto.
sealed class _Item;

final class _Dia extends _Item {
  new(this.data);
  final DateTime data;
  int subtotal = 0;
}

final class _Gasto extends _Item {
  new(this.linha);
  final CompraDoMes linha;
}

class _Lista extends StatelessWidget {
  new(List<CompraDoMes> linhas) : _itens = _agrupar(linhas);

  final List<_Item> _itens;

  static List<_Item> _agrupar(List<CompraDoMes> linhas) {
    final itens = <_Item>[];
    _Dia? diaAtual;
    for (final linha in linhas) {
      final momento = DateTime.parse(linha.c.timestampCompraAvista);
      final dia = DateTime(momento.year, momento.month, momento.day);
      if (dia != diaAtual?.data) {
        diaAtual = _Dia(dia);
        itens.add(diaAtual);
      }
      diaAtual!.subtotal += linha.c.valorCompraAvista;
      itens.add(_Gasto(linha));
    }
    return itens;
  }

  @override
  Widget build(BuildContext context) {
    final tema = context.temaRavix;
    return SliverPadding(
      // Espaço para o botão flutuante não cobrir o último gasto.
      padding: const EdgeInsets.only(bottom: 96),
      sliver: SliverList.builder(
        itemCount: _itens.length,
        itemBuilder: (context, i) => switch (_itens[i]) {
          _Dia(:final data, :final subtotal) => Padding(
            padding: const EdgeInsets.fromLTRB(
              TokensRavix.spaceMd,
              TokensRavix.spaceLg,
              TokensRavix.spaceMd,
              TokensRavix.spaceXs,
            ),
            child: Semantics(
              header: true,
              label:
                  '${formatarDiaPorExtenso(data)}: '
                  '${formatarCentavos(subtotal)}',
              excludeSemantics: true,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      formatarDiaPorExtenso(data).toUpperCase(),
                      style: tema.sobretitulo,
                    ),
                  ),
                  Text(
                    formatarCentavos(subtotal),
                    style: tema.valorLista.copyWith(
                      fontSize: 13,
                      color: tema.paleta.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _Gasto(:final linha) => _LinhaGasto(linha),
        },
      ),
    );
  }
}

class _LinhaGasto extends StatelessWidget {
  const new(this.linha);

  final CompraDoMes linha;

  @override
  Widget build(BuildContext context) {
    final compra = linha.c;
    final tipo = TipoPagamento.deCodigo(compra.tipoPagamento);
    final hora = formatarHora(DateTime.parse(compra.timestampCompraAvista));
    final valor = formatarCentavos(compra.valorCompraAvista);
    final tag = linha.tag;
    final detalhe = [linha.subcategoria, hora, ?tag].join(' · ');

    return Semantics(
      button: true,
      label:
          '${compra.descricao}, $valor, ${tipo.rotulo}, $detalhe. '
          'Toque para editar.',
      excludeSemantics: true,
      child: ListTile(
        minTileHeight: 64,
        leading: _IconeDaCategoria(
          icone: iconeDoPagamento(tipo),
          cor: corDaCategoria(linha.idCategoria),
        ),
        title: Text(
          compra.descricao,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(detalhe, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Text(valor, style: context.temaRavix.valorLista),
        onTap: () => context.push('/registro/${compra.uuidCompraAvista}'),
      ),
    );
  }
}

/// Quadrado de 36 dp com chanfro de 4 dp, na cor da categoria a 20%.
class _IconeDaCategoria extends StatelessWidget {
  const new({required this.icone, required this.cor});

  final IconData icone;
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
