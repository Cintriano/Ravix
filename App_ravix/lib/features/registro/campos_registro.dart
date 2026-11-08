/// Campos comuns aos formulários de registro (E01-F03): valor em destaque,
/// data e hora, classificação (categoria, subcategoria e tag), cartão e mês
/// da fatura.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ravix/app/dependencias.dart';
import 'package:ravix/core/datas.dart';
import 'package:ravix/core/tema/icones.dart';
import 'package:ravix/core/tema/tema.dart';
import 'package:ravix/core/tema/tokens.dart';
import 'package:ravix/core/valor.dart';
import 'package:ravix/data/banco.dart';
import 'package:ravix/data/carga_inicial.dart';
import 'package:ravix/features/cartoes/cartoes_providers.dart';
import 'package:ravix/features/cartoes/tela_cartoes.dart';
import 'package:ravix/features/compra_avista/formulario_providers.dart';
import 'package:ravix/features/compra_avista/mascara_valor.dart';
import 'package:ravix/features/tags/dialogo_nome_tag.dart';
import 'package:ravix/features/tags/tags_providers.dart';

final Map<int, String> _descricoesDasSubcategorias = {
  for (final s in subcategoriasIniciais) s.id: s.descricao,
};

/// Valor em destaque, o primeiro campo dos formulários: é o que a pessoa já
/// sabe na hora de anotar.
class CampoValorDestaque extends StatelessWidget {
  /// Cria o campo.
  const new({
    required this.controle,
    required this.aoMudar,
    this.rotulo = 'Valor',
    this.erro,
    this.ajuda,
    this.autofoco = false,
    super.key,
  });

  /// Controlador do texto (máscara monetária).
  final TextEditingController controle;

  /// Recebe o valor em centavos a cada tecla.
  final ValueChanged<int> aoMudar;

  /// Rótulo do campo.
  final String rotulo;

  /// Mensagem de erro.
  final String? erro;

  /// Texto de apoio abaixo do campo.
  final String? ajuda;

  /// Abre com o teclado.
  final bool autofoco;

  @override
  Widget build(BuildContext context) {
    final paleta = context.temaRavix.paleta;
    final destaque = context.temaRavix.valorDestaque.copyWith(
      color: paleta.textPrimary,
      fontSize: 32,
      height: 40 / 32,
    );
    return TextField(
      controller: controle,
      autofocus: autofoco,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      inputFormatters: [MascaraValor()],
      style: destaque,
      onChanged: (t) => aoMudar(centavosDeDigitos(t)),
      decoration: InputDecoration(
        labelText: rotulo,
        prefixText: r'R$ ',
        prefixStyle: destaque.copyWith(
          color: paleta.textSecondary,
          fontSize: 24,
        ),
        hintText: '0,00',
        hintStyle: destaque.copyWith(color: paleta.borderStrong),
        errorText: erro,
        helperText: ajuda,
        contentPadding: const EdgeInsets.fromLTRB(
          TokensRavix.spaceMd,
          14,
          TokensRavix.spaceMd,
          14,
        ),
      ),
    );
  }
}

/// Campo que abre um seletor ao toque (data, hora).
class CampoDeToque extends StatelessWidget {
  /// Cria o campo.
  const new({
    required this.rotulo,
    required this.valor,
    required this.icone,
    required this.aoTocar,
    super.key,
  });

  /// Rótulo do campo.
  final String rotulo;

  /// Valor exibido.
  final String valor;

  /// Ícone à direita.
  final IconData icone;

  /// Ação ao tocar.
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$rotulo: $valor',
      excludeSemantics: true,
      child: InkWell(
        onTap: aoTocar,
        customBorder: chanfro(TokensRavix.chanfroM),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: rotulo,
            suffixIcon: Icon(icone, size: TokensRavix.iconSizeMd),
          ),
          child: Text(
            valor,
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(fontFeatures: numerosTabulares),
          ),
        ),
      ),
    );
  }
}

/// Data e hora lado a lado, com os seletores do sistema.
class CamposDataHora extends StatelessWidget {
  /// Cria os campos.
  const new({
    required this.momento,
    required this.aoMudar,
    this.ajudaData = 'Data',
    this.ajudaHora = 'Hora',
    super.key,
  });

  /// Momento atual.
  final DateTime momento;

  /// Recebe o novo momento.
  final ValueChanged<DateTime> aoMudar;

  /// Título do seletor de data.
  final String ajudaData;

  /// Título do seletor de hora.
  final String ajudaHora;

  Future<void> _escolherData(BuildContext context) async {
    final data = await showDatePicker(
      context: context,
      initialDate: momento,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: ajudaData,
    );
    if (data == null) return;
    aoMudar(
      DateTime(data.year, data.month, data.day, momento.hour, momento.minute),
    );
  }

  Future<void> _escolherHora(BuildContext context) async {
    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(momento),
      helpText: ajudaHora,
    );
    if (hora == null) return;
    aoMudar(
      DateTime(
        momento.year,
        momento.month,
        momento.day,
        hora.hour,
        hora.minute,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: CampoDeToque(
          rotulo: 'Data',
          valor: formatarData(momento),
          icone: Icones.calendar,
          aoTocar: () => _escolherData(context),
        ),
      ),
      const SizedBox(width: TokensRavix.spaceMd),
      Expanded(
        child: CampoDeToque(
          rotulo: 'Hora',
          valor: formatarHora(momento),
          icone: Icones.clock,
          aoTocar: () => _escolherHora(context),
        ),
      ),
    ],
  );
}

/// Categoria, subcategoria e tag (DP-32). O formulário guarda o estado e
/// recebe as escolhas pelos callbacks.
class CamposClassificacao extends ConsumerWidget {
  /// Cria os campos.
  const new({
    required this.idCategoria,
    required this.idSubcategoria,
    required this.tag,
    required this.aoEscolherCategoria,
    required this.aoEscolherSubcategoria,
    required this.aoEscolherTag,
    this.erroCategoria,
    this.erroSubcategoria,
    this.sugerida = false,
    super.key,
  });

  /// Categoria escolhida.
  final int? idCategoria;

  /// Subcategoria escolhida.
  final int? idSubcategoria;

  /// Tag escolhida; pode estar arquivada ou ter acabado de ser criada.
  final Tag? tag;

  /// Escolha da categoria.
  final ValueChanged<int?> aoEscolherCategoria;

  /// Escolha da subcategoria.
  final ValueChanged<int?> aoEscolherSubcategoria;

  /// Escolha da tag (`null` = sem tag).
  final ValueChanged<Tag?> aoEscolherTag;

  /// Erro da categoria.
  final String? erroCategoria;

  /// Erro da subcategoria.
  final String? erroSubcategoria;

  /// A categoria atual veio da sugestão pelo histórico.
  final bool sugerida;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final texto = Theme.of(context).textTheme;
    const espaco = SizedBox(height: TokensRavix.spaceMd);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _categoria(ref),
        if (sugerida)
          Padding(
            padding: const EdgeInsets.only(top: TokensRavix.spaceSm),
            child: Row(
              children: [
                Icon(
                  Icones.sparkles,
                  size: TokensRavix.iconSizeSm,
                  color: context.temaRavix.acento,
                ),
                const SizedBox(width: TokensRavix.spaceSm),
                Text('Sugerida pelo histórico', style: texto.bodySmall),
              ],
            ),
          ),
        espaco,
        _subcategoria(ref),
        espaco,
        _tag(ref),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => mostrarDialogoNomeTag(
              context,
              titulo: 'Nova tag',
              rotuloSalvar: 'Criar',
              aoSalvar: (nome) async => aoEscolherTag(
                await ref.read(tagRepositoryProvider).criar(nome),
              ),
            ),
            icon: const Icon(Icones.plus, size: TokensRavix.iconSizeMd),
            label: const Text('Nova tag'),
          ),
        ),
      ],
    );
  }

  Widget _categoria(WidgetRef ref) {
    final categorias = ref.watch(categoriasProvider).value ?? const [];
    return DropdownButtonFormField<int>(
      key: ValueKey(('categoria', idCategoria, categorias.length)),
      initialValue: categorias.any((c) => c.idCategoria == idCategoria)
          ? idCategoria
          : null,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Categoria',
        errorText: erroCategoria,
      ),
      items: [
        for (final c in categorias)
          DropdownMenuItem(value: c.idCategoria, child: Text(c.nome)),
      ],
      onChanged: aoEscolherCategoria,
    );
  }

  Widget _subcategoria(WidgetRef ref) {
    final categoria = idCategoria;
    final subcategorias = categoria == null
        ? const <Subcategoria>[]
        : ref.watch(subcategoriasProvider(categoria)).value ?? const [];
    final escolhida =
        subcategorias.any((s) => s.idSubcategoria == idSubcategoria)
        ? idSubcategoria
        : null;
    return DropdownButtonFormField<int>(
      key: ValueKey((
        'subcategoria',
        categoria,
        escolhida,
        subcategorias.length,
      )),
      initialValue: escolhida,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Subcategoria',
        helperText: escolhida == null
            ? null
            : _descricoesDasSubcategorias[escolhida],
        helperMaxLines: 2,
        errorText: erroSubcategoria,
      ),
      items: [
        for (final s in subcategorias)
          DropdownMenuItem(value: s.idSubcategoria, child: Text(s.nome)),
      ],
      onChanged: categoria == null ? null : aoEscolherSubcategoria,
    );
  }

  Widget _tag(WidgetRef ref) {
    final ativas = ref.watch(tagsAtivasProvider).value ?? const <Tag>[];
    final selecionada = tag;
    final opcoes = [
      ...ativas,
      if (selecionada != null &&
          !ativas.any((t) => t.uuidTag == selecionada.uuidTag))
        selecionada,
    ];
    final uuid =
        selecionada != null &&
            opcoes.any((t) => t.uuidTag == selecionada.uuidTag)
        ? selecionada.uuidTag
        : null;
    return DropdownButtonFormField<String?>(
      key: ValueKey(('tag', uuid, opcoes.length)),
      initialValue: uuid,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Tag (opcional)',
        helperText: 'Contexto do gasto, como viagem ou rolê',
      ),
      items: [
        const DropdownMenuItem(child: Text('Sem tag')),
        for (final t in opcoes)
          DropdownMenuItem(
            value: t.uuidTag,
            child: Text(
              t.status == 'arquivada' ? '${t.nome} (arquivada)' : t.nome,
            ),
          ),
      ],
      onChanged: (valor) => aoEscolherTag(
        valor == null ? null : opcoes.firstWhere((t) => t.uuidTag == valor),
      ),
    );
  }
}

/// Seletor do cartão entre os ativos. Sem nenhum cartão, oferece o
/// cadastro (E01-F03-T07).
class CampoCartao extends ConsumerWidget {
  /// Cria o campo.
  const new({
    required this.uuidCartao,
    required this.aoEscolher,
    this.erro,
    this.cartaoAtual,
    super.key,
  });

  /// Cartão escolhido.
  final String? uuidCartao;

  /// Recebe o cartão escolhido.
  final ValueChanged<CartaoCredito> aoEscolher;

  /// Mensagem de erro.
  final String? erro;

  /// Cartão do registro em edição, mesmo se já arquivado.
  final CartaoCredito? cartaoAtual;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final valor = ref.watch(cartoesAtivosProvider);
    final ativos = valor.value ?? const <CartaoCredito>[];
    final atual = cartaoAtual;
    final opcoes = [
      ...ativos,
      if (atual != null &&
          !ativos.any((c) => c.uuidCartaoCredito == atual.uuidCartaoCredito))
        atual,
    ];
    if (valor.hasValue && opcoes.isEmpty) {
      return InputDecorator(
        decoration: InputDecoration(labelText: 'Cartão', errorText: erro),
        child: Row(
          children: [
            const Expanded(child: Text('Nenhum cartão cadastrado')),
            TextButton(
              onPressed: () => context.push('/configuracao/cartoes/novo'),
              child: const Text('Cadastrar'),
            ),
          ],
        ),
      );
    }
    final escolhido = opcoes.any((c) => c.uuidCartaoCredito == uuidCartao)
        ? uuidCartao
        : null;
    return DropdownButtonFormField<String>(
      key: ValueKey(('cartao', escolhido, opcoes.length)),
      initialValue: escolhido,
      isExpanded: true,
      decoration: InputDecoration(labelText: 'Cartão', errorText: erro),
      items: [
        for (final c in opcoes)
          DropdownMenuItem(
            value: c.uuidCartaoCredito,
            child: Text(
              c.status == 'arquivado'
                  ? '${nomeComFinal(c)} (arquivado)'
                  : nomeComFinal(c),
            ),
          ),
      ],
      onChanged: (uuid) {
        if (uuid == null) return;
        aoEscolher(opcoes.firstWhere((c) => c.uuidCartaoCredito == uuid));
      },
    );
  }
}

/// Mês de uma fatura, com anterior e próximo (DP-3, DP-9).
class CampoMes extends StatelessWidget {
  /// Cria o campo.
  const new({
    required this.rotulo,
    required this.mes,
    required this.aoMudar,
    this.ajuda,
    super.key,
  });

  /// Rótulo do campo.
  final String rotulo;

  /// Mês atual.
  final Mes mes;

  /// Recebe o novo mês.
  final ValueChanged<Mes> aoMudar;

  /// Texto de apoio.
  final String? ajuda;

  void _mudar(Mes novo) {
    unawaited(HapticFeedback.selectionClick());
    aoMudar(novo);
  }

  @override
  Widget build(BuildContext context) {
    final nome = mes.rotulo;
    return InputDecorator(
      decoration: InputDecoration(
        labelText: rotulo,
        helperText: ajuda,
        helperMaxLines: 2,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: TokensRavix.spaceXs,
          vertical: TokensRavix.spaceXs,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: '$rotulo: mês anterior',
            icon: const Icon(Icones.chevronLeft),
            onPressed: () => _mudar(mes.anterior),
          ),
          Expanded(
            child: Text(
              '${nome[0].toUpperCase()}${nome.substring(1)}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          IconButton(
            tooltip: '$rotulo: próximo mês',
            icon: const Icon(Icones.chevronRight),
            onPressed: () => _mudar(mes.proximo),
          ),
        ],
      ),
    );
  }
}
