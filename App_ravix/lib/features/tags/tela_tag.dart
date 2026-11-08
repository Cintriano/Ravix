import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show StreamProviderFamily;
import 'package:ravix/app/dependencias.dart';
import 'package:ravix/core/datas.dart';
import 'package:ravix/core/tema/icones.dart';
import 'package:ravix/core/tema/tema.dart';
import 'package:ravix/core/tema/tokens.dart';
import 'package:ravix/core/valor.dart';
import 'package:ravix/data/analise_repository.dart';
import 'package:ravix/data/banco.dart';
import 'package:ravix/features/analise/lista_por_categoria.dart';
import 'package:ravix/features/compra_avista/aba_avista_providers.dart';
import 'package:ravix/features/shell/estados_tela.dart';
import 'package:ravix/features/tags/dialogo_nome_tag.dart';

/// Tudo que tem a tag, por subcategoria, com o pago até o mês de hoje.
final StreamProviderFamily<List<TotalPorSubcategoria>, String>
totaisDaTagProvider = StreamProvider.autoDispose.family(
  (ref, uuid) => ref
      .watch(analiseRepositoryProvider)
      .observarTag(uuid, Mes.de(ref.watch(relogioProvider).agora())),
);

/// Visão de uma tag (E01-F13-T01): total de todos os meses e a quebra por
/// categoria e subcategoria. Compras parceladas aparecem com o pago até
/// agora e o total do parcelamento, lado a lado (08/11/2026).
class TelaTag extends ConsumerStatefulWidget {
  /// Cria a visão da tag [uuid].
  const new({required this.uuid, super.key});

  /// Tag mostrada.
  final String uuid;

  @override
  ConsumerState<TelaTag> createState() => _TelaTagState();
}

class _TelaTagState extends ConsumerState<TelaTag> {
  VisaoDaLista _visao = VisaoDaLista.categoria;

  Future<void> _renomear(Tag tag) => mostrarDialogoNomeTag(
    context,
    titulo: 'Renomear tag',
    rotuloSalvar: 'Salvar',
    nomeInicial: tag.nome,
    aoSalvar: (nome) =>
        ref.read(tagRepositoryProvider).renomear(tag.uuidTag, nome),
  );

  @override
  Widget build(BuildContext context) {
    final tags = ref.watch(todasAsTagsProvider).value ?? const <Tag>[];
    final tag = tags.where((t) => t.uuidTag == widget.uuid).firstOrNull;
    final valor = ref.watch(totaisDaTagProvider(widget.uuid));
    final arquivada = tag?.status == 'arquivada';
    return Scaffold(
      appBar: AppBar(
        title: Text(
          tag == null
              ? 'Tag'
              : arquivada
              ? '${tag.nome} (arquivada)'
              : tag.nome,
        ),
        actions: [
          if (tag != null && !arquivada)
            IconButton(
              tooltip: 'Renomear ${tag.nome}',
              icon: const Icon(Icones.edit),
              onPressed: () => _renomear(tag),
            ),
        ],
      ),
      body: ConteudoAssincrono<List<TotalPorSubcategoria>>(
        valor: valor,
        estaVazio: (linhas) => linhas.isEmpty,
        aoTentarDeNovo: () => ref.invalidate(totaisDaTagProvider(widget.uuid)),
        vazio: const EstadoVazio(
          titulo: 'Nada com esta tag',
          mensagem:
              'Os gastos, compras e estornos marcados com a tag aparecem '
              'aqui, de todos os meses.',
        ),
        conteudo: (linhas) => ListView(
          padding: const EdgeInsets.only(bottom: TokensRavix.spaceLg),
          children: [
            _Resumo(linhas),
            Padding(
              padding: const EdgeInsets.all(TokensRavix.spaceMd),
              child: SeletorDeVisao(
                visao: _visao,
                aoEscolher: (v) => setState(() => _visao = v),
              ),
            ),
            ListaPorCategoria(linhas: linhas, visao: _visao, comPago: true),
          ],
        ),
      ),
    );
  }
}

class _Resumo extends StatelessWidget {
  const new(this.linhas);

  final List<TotalPorSubcategoria> linhas;

  @override
  Widget build(BuildContext context) {
    final tema = context.temaRavix;
    final texto = Theme.of(context).textTheme;
    final apoio = texto.bodySmall?.copyWith(color: tema.resumoApoio);
    final pago = linhas.fold(0, (s, l) => s + l.pago);
    final total = linhas.fold(0, (s, l) => s + l.total);
    final parcelado = pago != total;
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
          child: Semantics(
            container: true,
            label: parcelado
                ? 'Pago até agora: ${formatarCentavos(pago)}, de '
                      '${formatarCentavos(total)} no total do parcelamento'
                : 'Total: ${formatarCentavos(total)}',
            excludeSemantics: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(parcelado ? 'Pago até agora' : 'Total', style: apoio),
                const SizedBox(height: TokensRavix.spaceXs),
                Text(
                  formatarCentavos(parcelado ? pago : total),
                  style: tema.valorDestaque.copyWith(color: tema.resumoTexto),
                ),
                if (parcelado)
                  Text(
                    'de ${formatarCentavos(total)} no total do parcelamento',
                    style: texto.bodyMedium?.copyWith(color: tema.resumoTexto),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
