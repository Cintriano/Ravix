import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ravix/app/dependencias.dart';
import 'package:ravix/core/datas.dart';
import 'package:ravix/core/tema/capra_tokens.dart';
import 'package:ravix/core/tema/icones.dart';
import 'package:ravix/core/tema/tema.dart';
import 'package:ravix/core/texto.dart';
import 'package:ravix/core/valor.dart';
import 'package:ravix/data/banco.dart';
import 'package:ravix/data/carga_inicial.dart';
import 'package:ravix/data/compra_avista_repository.dart';
import 'package:ravix/features/compra_avista/formulario_providers.dart';
import 'package:ravix/features/compra_avista/mascara_valor.dart';
import 'package:ravix/features/compra_avista/rascunho_compra.dart';
import 'package:ravix/features/tags/dialogo_nome_tag.dart';
import 'package:ravix/features/tags/tags_providers.dart';

/// Espera depois da última tecla antes de consultar a sugestão (DP-36).
const esperaDaSugestao = Duration(milliseconds: 300);

/// Nome de cada forma de pagamento no formulário.
extension RotuloTipoPagamento on TipoPagamento {
  /// Texto exibido.
  String get rotulo => switch (this) {
    TipoPagamento.pix => 'Pix',
    TipoPagamento.debito => 'Débito',
    TipoPagamento.dinheiro => 'Dinheiro',
    TipoPagamento.voucher => 'Voucher',
  };
}

final Map<int, String> _descricoesDasSubcategorias = {
  for (final s in subcategoriasIniciais) s.id: s.descricao,
};

/// Formulário de gasto à vista (E01-F03), nos modos criar e editar.
/// [compra] nula = criar.
class FormularioCompra extends ConsumerStatefulWidget {
  /// Cria o formulário.
  const new({this.compra, super.key});

  /// Gasto em edição.
  final CompraAvista? compra;

  @override
  ConsumerState<FormularioCompra> createState() => _FormularioCompraState();
}

class _FormularioCompraState extends ConsumerState<FormularioCompra> {
  late final RascunhoCompra _rascunho;
  late final TextEditingController _descricao;
  late final TextEditingController _valor;
  Map<CampoCompra, String> _erros = const {};
  Timer? _espera;

  /// O usuário escolheu a categoria: a sugestão não sobrescreve mais.
  late bool _categoriaManual;

  /// A categoria atual veio da sugestão.
  bool _sugerida = false;

  /// Tag selecionada que pode não estar na lista de ativas (recém-criada ou
  /// arquivada).
  Tag? _tagSelecionada;

  bool _salvando = false;

  bool get _editando => widget.compra != null;

  @override
  void initState() {
    super.initState();
    final compra = widget.compra;
    _rascunho = compra == null
        ? RascunhoCompra(momento: ref.read(relogioProvider).agora())
        : RascunhoCompra.deCompra(compra);
    _categoriaManual = compra != null;
    _descricao = TextEditingController(text: _rascunho.descricao);
    _valor = TextEditingController(
      text: _rascunho.valorCentavos == 0
          ? ''
          : formatarCentavosSemSimbolo(_rascunho.valorCentavos),
    );
    final uuidTag = _rascunho.uuidTag;
    if (uuidTag != null) {
      unawaited(
        ref.read(tagRepositoryProvider).buscar(uuidTag).then((tag) {
          if (mounted) setState(() => _tagSelecionada = tag);
        }),
      );
    }
  }

  @override
  void dispose() {
    _espera?.cancel();
    _descricao.dispose();
    _valor.dispose();
    super.dispose();
  }

  void _limparErro(CampoCompra campo) {
    if (_erros.containsKey(campo)) {
      _erros = {..._erros}..remove(campo);
    }
  }

  void _aoMudarDescricao(String texto) {
    setState(() {
      _rascunho.descricao = texto;
      _limparErro(CampoCompra.descricao);
    });
    _espera?.cancel();
    if (_categoriaManual ||
        normalizarTexto(texto).length <
            CompraAvistaRepository.minimoParaSugestao) {
      return;
    }
    _espera = Timer(esperaDaSugestao, () => unawaited(_sugerir(texto)));
  }

  Future<void> _sugerir(String texto) async {
    final id = await ref.read(sugestaoDeSubcategoriaProvider)(texto);
    if (!mounted || id == null || _categoriaManual) return;
    if (_rascunho.descricao != texto) return;
    setState(() {
      _rascunho
        ..idCategoria = id ~/ 100
        ..idSubcategoria = id;
      _sugerida = true;
      _limparErro(CampoCompra.categoria);
      _limparErro(CampoCompra.subcategoria);
    });
  }

  Future<void> _escolherData() async {
    final atual = _rascunho.momento;
    final data = await showDatePicker(
      context: context,
      initialDate: atual,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Data do gasto',
    );
    if (data == null || !mounted) return;
    setState(
      () => _rascunho.momento = DateTime(
        data.year,
        data.month,
        data.day,
        atual.hour,
        atual.minute,
      ),
    );
  }

  Future<void> _escolherHora() async {
    final atual = _rascunho.momento;
    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(atual),
      helpText: 'Hora do gasto',
    );
    if (hora == null || !mounted) return;
    setState(
      () => _rascunho.momento = DateTime(
        atual.year,
        atual.month,
        atual.day,
        hora.hour,
        hora.minute,
      ),
    );
  }

  Future<void> _criarTag() => mostrarDialogoNomeTag(
    context,
    titulo: 'Nova tag',
    rotuloSalvar: 'Criar',
    aoSalvar: (nome) async {
      final tag = await ref.read(tagRepositoryProvider).criar(nome);
      if (!mounted) return;
      setState(() {
        _tagSelecionada = tag;
        _rascunho.uuidTag = tag.uuidTag;
      });
    },
  );

  Future<void> _salvar() async {
    if (_salvando) return;
    final erros = _rascunho.validar();
    if (erros.isNotEmpty) {
      setState(() => _erros = erros);
      unawaited(HapticFeedback.heavyImpact());
      return;
    }
    setState(() => _salvando = true);
    final repositorio = ref.read(compraAvistaRepositoryProvider);
    final mensageiro = ScaffoldMessenger.of(context);
    try {
      final compra = widget.compra;
      if (compra == null) {
        await repositorio.criar(_rascunho.paraDados());
      } else {
        await repositorio.editar(
          compra.uuidCompraAvista,
          _rascunho.paraDados(),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
    unawaited(HapticFeedback.mediumImpact());
    mensageiro
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(_editando ? 'Gasto atualizado.' : 'Gasto salvo.'),
        ),
      );
    if (mounted) context.pop();
  }

  Future<void> _excluir() async {
    final paleta = context.temaRavix.paleta;
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('Excluir este gasto?'),
        content: const Text('O gasto será apagado e não dá para desfazer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(contexto).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: paleta.danger,
              foregroundColor: paleta.onAccent,
            ),
            onPressed: () => Navigator.of(contexto).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmou != true || !mounted) return;
    final mensageiro = ScaffoldMessenger.of(context);
    await ref
        .read(compraAvistaRepositoryProvider)
        .excluir(widget.compra!.uuidCompraAvista);
    mensageiro
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Gasto excluído.')));
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final paleta = context.temaRavix.paleta;
    const espaco = SizedBox(height: CapraTokens.spaceMd);

    return Scaffold(
      appBar: AppBar(
        title: Text(_editando ? 'Editar gasto' : 'Novo gasto'),
        actions: [
          if (_editando)
            IconButton(
              tooltip: 'Excluir gasto',
              icon: Icon(Icones.trash2, color: paleta.danger),
              onPressed: _excluir,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(CapraTokens.spaceMd),
        children: [
          TextField(
            controller: _descricao,
            autofocus: !_editando,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            onChanged: _aoMudarDescricao,
            decoration: InputDecoration(
              labelText: 'Descrição',
              hintText: 'Ex.: Padaria do Zé',
              errorText: _erros[CampoCompra.descricao],
            ),
          ),
          espaco,
          TextField(
            controller: _valor,
            keyboardType: TextInputType.number,
            inputFormatters: [MascaraValor()],
            style: texto.bodyLarge?.copyWith(fontFeatures: numerosTabulares),
            onChanged: (t) => setState(() {
              _rascunho.valorCentavos = centavosDeDigitos(t);
              _limparErro(CampoCompra.valor);
            }),
            decoration: InputDecoration(
              labelText: 'Valor',
              prefixText: r'R$ ',
              hintText: '0,00',
              errorText: _erros[CampoCompra.valor],
            ),
          ),
          espaco,
          Row(
            children: [
              Expanded(
                child: _CampoDeToque(
                  rotulo: 'Data',
                  valor: formatarData(_rascunho.momento),
                  icone: Icones.calendar,
                  aoTocar: _escolherData,
                ),
              ),
              const SizedBox(width: CapraTokens.spaceMd),
              Expanded(
                child: _CampoDeToque(
                  rotulo: 'Hora',
                  valor: formatarHora(_rascunho.momento),
                  icone: Icones.clock,
                  aoTocar: _escolherHora,
                ),
              ),
            ],
          ),
          const SizedBox(height: CapraTokens.spaceLg),
          Text('Forma de pagamento', style: texto.labelMedium),
          const SizedBox(height: CapraTokens.spaceSm),
          Wrap(
            spacing: CapraTokens.spaceSm,
            runSpacing: CapraTokens.spaceSm,
            children: [
              for (final tipo in TipoPagamento.values)
                ChoiceChip(
                  label: Text(tipo.rotulo),
                  selected: _rascunho.tipoPagamento == tipo,
                  onSelected: (_) {
                    unawaited(HapticFeedback.selectionClick());
                    setState(() {
                      _rascunho.tipoPagamento = tipo;
                      _limparErro(CampoCompra.tipoPagamento);
                    });
                  },
                ),
            ],
          ),
          if (_erros[CampoCompra.tipoPagamento] case final erro?)
            Padding(
              padding: const EdgeInsets.only(top: CapraTokens.spaceSm),
              child: Text(
                erro,
                style: texto.bodySmall?.copyWith(color: paleta.danger),
              ),
            ),
          const SizedBox(height: CapraTokens.spaceLg),
          _campoCategoria(),
          if (_sugerida)
            Padding(
              padding: const EdgeInsets.only(top: CapraTokens.spaceSm),
              child: Row(
                children: [
                  Icon(
                    Icones.sparkles,
                    size: CapraTokens.iconSizeSm,
                    color: context.temaRavix.acento,
                  ),
                  const SizedBox(width: CapraTokens.spaceSm),
                  Text('Sugerida pelo histórico', style: texto.bodySmall),
                ],
              ),
            ),
          espaco,
          _campoSubcategoria(),
          espaco,
          _campoTag(),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _criarTag,
              icon: const Icon(Icones.plus, size: CapraTokens.iconSizeMd),
              label: const Text('Nova tag'),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            CapraTokens.spaceMd,
            CapraTokens.spaceSm,
            CapraTokens.spaceMd,
            CapraTokens.spaceMd,
          ),
          child: FilledButton(
            onPressed: _salvando ? null : _salvar,
            child: const Text('Salvar'),
          ),
        ),
      ),
    );
  }

  Widget _campoCategoria() {
    final categorias = ref.watch(categoriasProvider).value ?? const [];
    return DropdownButtonFormField<int>(
      key: ValueKey(('categoria', _rascunho.idCategoria, categorias.length)),
      initialValue:
          categorias.any((c) => c.idCategoria == _rascunho.idCategoria)
          ? _rascunho.idCategoria
          : null,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Categoria',
        errorText: _erros[CampoCompra.categoria],
      ),
      items: [
        for (final c in categorias)
          DropdownMenuItem(value: c.idCategoria, child: Text(c.nome)),
      ],
      onChanged: (id) => setState(() {
        _categoriaManual = true;
        _sugerida = false;
        if (id != _rascunho.idCategoria) _rascunho.idSubcategoria = null;
        _rascunho.idCategoria = id;
        _limparErro(CampoCompra.categoria);
      }),
    );
  }

  Widget _campoSubcategoria() {
    final idCategoria = _rascunho.idCategoria;
    final subcategorias = idCategoria == null
        ? const <Subcategoria>[]
        : ref.watch(subcategoriasProvider(idCategoria)).value ?? const [];
    final escolhida =
        subcategorias.any((s) => s.idSubcategoria == _rascunho.idSubcategoria)
        ? _rascunho.idSubcategoria
        : null;
    return DropdownButtonFormField<int>(
      key: ValueKey((
        'subcategoria',
        idCategoria,
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
        errorText: _erros[CampoCompra.subcategoria],
      ),
      items: [
        for (final s in subcategorias)
          DropdownMenuItem(value: s.idSubcategoria, child: Text(s.nome)),
      ],
      onChanged: idCategoria == null
          ? null
          : (id) => setState(() {
              _categoriaManual = true;
              _sugerida = false;
              _rascunho.idSubcategoria = id;
              _limparErro(CampoCompra.subcategoria);
            }),
    );
  }

  Widget _campoTag() {
    final ativas = ref.watch(tagsAtivasProvider).value ?? const <Tag>[];
    final selecionada = _tagSelecionada;
    final opcoes = [
      ...ativas,
      if (selecionada != null &&
          !ativas.any((t) => t.uuidTag == selecionada.uuidTag))
        selecionada,
    ];
    final uuid = opcoes.any((t) => t.uuidTag == _rascunho.uuidTag)
        ? _rascunho.uuidTag
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
      onChanged: (valor) => setState(() {
        _rascunho.uuidTag = valor;
        _tagSelecionada = valor == null
            ? null
            : opcoes.firstWhere((t) => t.uuidTag == valor);
      }),
    );
  }
}

class _CampoDeToque extends StatelessWidget {
  const new({
    required this.rotulo,
    required this.valor,
    required this.icone,
    required this.aoTocar,
  });

  final String rotulo;
  final String valor;
  final IconData icone;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$rotulo: $valor',
      excludeSemantics: true,
      child: InkWell(
        onTap: aoTocar,
        borderRadius: BorderRadius.circular(CapraTokens.radiusSm),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: rotulo,
            suffixIcon: Icon(icone, size: CapraTokens.iconSizeMd),
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
