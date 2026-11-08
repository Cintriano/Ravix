import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ravix/app/dependencias.dart';
import 'package:ravix/core/datas.dart';
import 'package:ravix/core/tema/tokens.dart';
import 'package:ravix/core/valor.dart';
import 'package:ravix/data/banco.dart';
import 'package:ravix/data/faturado_repository.dart';
import 'package:ravix/features/registro/campos_registro.dart';
import 'package:ravix/features/registro/tipo_registro.dart';

/// Campos validados do estorno.
enum CampoEstorno {
  /// Valor estornado.
  valor,

  /// Descrição.
  descricao,

  /// Cartão.
  cartao,

  /// Categoria.
  categoria,

  /// Subcategoria.
  subcategoria,
}

/// Estorno de cartão (E01-F03-T17, DP-14): valor positivo que abate da
/// fatura do mês escolhido, do consumo e dos totais da categoria e da tag.
class FormularioEstorno extends ConsumerStatefulWidget {
  /// Cria o formulário; [estorno] nulo = criar.
  const new({this.estorno, super.key});

  /// Estorno em edição.
  final Estorno? estorno;

  @override
  ConsumerState<FormularioEstorno> createState() => _FormularioEstornoState();
}

class _FormularioEstornoState extends ConsumerState<FormularioEstorno> {
  late final Estorno? _estorno = widget.estorno;
  late DateTime _momento = _estorno == null
      ? ref.read(relogioProvider).agora()
      : DateTime.parse(_estorno.timestampEstorno);
  late int _valor = _estorno?.valorEstorno ?? 0;
  late String _descricao = _estorno?.descricao ?? '';
  CartaoCredito? _cartao;
  late Mes? _fatura = _estorno == null
      ? null
      : Mes(_estorno.anoVencimento, _estorno.mesVencimento);
  late bool _faturaManual = _estorno != null;
  late int? _idCategoria = _estorno == null
      ? null
      : _estorno.idSubcategoria ~/ 100;
  late int? _idSubcategoria = _estorno?.idSubcategoria;
  Tag? _tag;
  Map<CampoEstorno, String> _erros = const {};
  bool _salvando = false;

  late final _campoValor = TextEditingController(
    text: _valor == 0 ? '' : formatarCentavosSemSimbolo(_valor),
  );
  late final _campoDescricao = TextEditingController(text: _descricao);

  bool get _editando => _estorno != null;

  @override
  void initState() {
    super.initState();
    final estorno = _estorno;
    if (estorno == null) return;
    unawaited(
      ref.read(cartaoRepositoryProvider).buscar(estorno.uuidCartaoCredito).then(
        (c) {
          if (mounted) setState(() => _cartao = c);
        },
      ),
    );
    if (estorno.uuidTag case final uuid?) {
      unawaited(
        ref.read(tagRepositoryProvider).buscar(uuid).then((t) {
          if (mounted) setState(() => _tag = t);
        }),
      );
    }
  }

  @override
  void dispose() {
    _campoValor.dispose();
    _campoDescricao.dispose();
    super.dispose();
  }

  Mes get _mesDaFatura =>
      (_faturaManual ? _fatura : null) ??
      sugerirVencimento(
        _momento,
        diaFechamento: _cartao?.diaFechamento,
        diaVencimento: _cartao?.diaVencimento,
      );

  void _limpar(CampoEstorno campo) {
    if (_erros.containsKey(campo)) _erros = {..._erros}..remove(campo);
  }

  Future<void> _salvar() async {
    final erros = {
      if (_valor <= 0) CampoEstorno.valor: 'Informe um valor maior que zero.',
      if (_descricao.trim().isEmpty)
        CampoEstorno.descricao: 'Informe a descrição.',
      if (_cartao == null) CampoEstorno.cartao: 'Escolha o cartão.',
      if (_idCategoria == null) CampoEstorno.categoria: 'Escolha a categoria.',
      if (_idSubcategoria == null)
        CampoEstorno.subcategoria: 'Escolha a subcategoria.',
    };
    if (erros.isNotEmpty) {
      setState(() => _erros = erros);
      unawaited(HapticFeedback.heavyImpact());
      return;
    }
    setState(() => _salvando = true);
    final dados = (
      momento: _momento,
      descricao: _descricao,
      valorCentavos: _valor,
      uuidCartao: _cartao!.uuidCartaoCredito,
      fatura: _mesDaFatura,
      idSubcategoria: _idSubcategoria!,
      uuidTag: _tag?.uuidTag,
      uuidCompraOriginal: _estorno?.uuidCompraFaturada,
    );
    final repositorio = ref.read(faturadoRepositoryProvider);
    final mensageiro = ScaffoldMessenger.of(context);
    try {
      if (_editando) {
        await repositorio.editarEstorno(_estorno!.uuidEstorno, dados);
      } else {
        await repositorio.criarEstorno(dados);
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
    unawaited(HapticFeedback.mediumImpact());
    mensageiro
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(_editando ? 'Estorno atualizado.' : 'Estorno salvo.'),
        ),
      );
    if (mounted) context.pop();
  }

  Future<void> _excluir() async {
    if (!await confirmarExclusao(context, titulo: 'Excluir este estorno?')) {
      return;
    }
    if (!mounted) return;
    final mensageiro = ScaffoldMessenger.of(context);
    await ref
        .read(faturadoRepositoryProvider)
        .excluirEstorno(_estorno!.uuidEstorno);
    mensageiro
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Estorno excluído.')));
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    const espaco = SizedBox(height: TokensRavix.spaceMd);
    return EsqueletoFormulario(
      titulo: _editando
          ? const Text('Editar estorno')
          : const TituloNovoRegistro(TipoRegistro.estorno),
      rotuloSalvar: 'Salvar estorno',
      salvando: _salvando,
      aoSalvar: _salvar,
      rotuloExcluir: 'Excluir estorno',
      aoExcluir: _editando ? _excluir : null,
      campos: [
        CampoValorDestaque(
          controle: _campoValor,
          rotulo: 'Valor estornado',
          autofoco: !_editando,
          erro: _erros[CampoEstorno.valor],
          ajuda: 'Abate da fatura e do consumo do mês.',
          aoMudar: (v) => setState(() {
            _valor = v;
            _limpar(CampoEstorno.valor);
          }),
        ),
        espaco,
        TextField(
          controller: _campoDescricao,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (t) => setState(() {
            _descricao = t;
            _limpar(CampoEstorno.descricao);
          }),
          decoration: InputDecoration(
            labelText: 'Descrição',
            hintText: 'Ex.: Estorno da compra devolvida',
            errorText: _erros[CampoEstorno.descricao],
          ),
        ),
        espaco,
        CamposDataHora(
          momento: _momento,
          ajudaData: 'Data do estorno',
          ajudaHora: 'Hora do estorno',
          aoMudar: (m) => setState(() => _momento = m),
        ),
        espaco,
        CampoCartao(
          uuidCartao: _cartao?.uuidCartaoCredito,
          cartaoAtual: _editando ? _cartao : null,
          erro: _erros[CampoEstorno.cartao],
          aoEscolher: (c) => setState(() {
            _cartao = c;
            _limpar(CampoEstorno.cartao);
          }),
        ),
        espaco,
        CampoMes(
          rotulo: 'Fatura',
          mes: _mesDaFatura,
          ajuda: 'Fatura em que o estorno aparece.',
          aoMudar: (novo) => setState(() {
            _fatura = novo;
            _faturaManual = true;
          }),
        ),
        const SizedBox(height: TokensRavix.spaceLg),
        CamposClassificacao(
          idCategoria: _idCategoria,
          idSubcategoria: _idSubcategoria,
          tag: _tag,
          erroCategoria: _erros[CampoEstorno.categoria],
          erroSubcategoria: _erros[CampoEstorno.subcategoria],
          aoEscolherCategoria: (id) => setState(() {
            if (id != _idCategoria) _idSubcategoria = null;
            _idCategoria = id;
            _limpar(CampoEstorno.categoria);
          }),
          aoEscolherSubcategoria: (id) => setState(() {
            _idSubcategoria = id;
            _limpar(CampoEstorno.subcategoria);
          }),
          aoEscolherTag: (t) => setState(() => _tag = t),
        ),
      ],
    );
  }
}
