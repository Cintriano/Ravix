import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ravix/app/dependencias.dart';
import 'package:ravix/core/datas.dart';
import 'package:ravix/core/tema/tema.dart';
import 'package:ravix/core/tema/tokens.dart';
import 'package:ravix/core/valor.dart';
import 'package:ravix/data/banco.dart';
import 'package:ravix/data/faturado_repository.dart';
import 'package:ravix/features/registro/campos_registro.dart';
import 'package:ravix/features/registro/tipo_registro.dart';

/// Nome de cada forma de pagamento de fatura.
extension RotuloFormaPagamentoFatura on FormaPagamentoFatura {
  /// Texto exibido.
  String get rotulo => switch (this) {
    FormaPagamentoFatura.pix => 'Pix',
    FormaPagamentoFatura.debito => 'Débito',
    FormaPagamentoFatura.boleto => 'Boleto',
  };
}

/// Campos validados do pagamento de fatura.
enum CampoPagamento {
  /// Valor pago.
  valor,

  /// Forma de pagamento.
  forma,

  /// Cartão.
  cartao,
}

/// Pagamento de fatura (E01-F03-T13, DP-14): não entra nas somas de
/// consumo; marca a fatura do mês escolhido como paga.
class FormularioPagamentoFatura extends ConsumerStatefulWidget {
  /// Cria o formulário; [pagamento] nulo = criar.
  const new({this.pagamento, super.key});

  /// Pagamento em edição.
  final PagamentoFatura? pagamento;

  @override
  ConsumerState<FormularioPagamentoFatura> createState() =>
      _FormularioPagamentoFaturaState();
}

class _FormularioPagamentoFaturaState
    extends ConsumerState<FormularioPagamentoFatura> {
  late final PagamentoFatura? _pagamento = widget.pagamento;
  late DateTime _momento = _pagamento == null
      ? ref.read(relogioProvider).agora()
      : DateTime.parse(_pagamento.timestampPagamento);
  late int _valor = _pagamento?.valorPagamento ?? 0;
  late FormaPagamentoFatura? _forma = _pagamento == null
      ? null
      : FormaPagamentoFatura.deCodigo(_pagamento.tipoPagamento);
  CartaoCredito? _cartao;
  late Mes? _fatura = _pagamento == null
      ? null
      : Mes(_pagamento.anoVencimento, _pagamento.mesVencimento);
  late bool _faturaManual = _pagamento != null;
  Map<CampoPagamento, String> _erros = const {};
  bool _salvando = false;

  late final _campoValor = TextEditingController(
    text: _valor == 0 ? '' : formatarCentavosSemSimbolo(_valor),
  );

  bool get _editando => _pagamento != null;

  @override
  void initState() {
    super.initState();
    if (_pagamento case final p?) {
      unawaited(
        ref.read(cartaoRepositoryProvider).buscar(p.uuidCartaoCredito).then((
          c,
        ) {
          if (mounted) setState(() => _cartao = c);
        }),
      );
    }
  }

  @override
  void dispose() {
    _campoValor.dispose();
    super.dispose();
  }

  Mes get _mesDaFatura =>
      (_faturaManual ? _fatura : null) ??
      sugerirFaturaPaga(_momento, diaVencimento: _cartao?.diaVencimento);

  void _limpar(CampoPagamento campo) {
    if (_erros.containsKey(campo)) _erros = {..._erros}..remove(campo);
  }

  Future<void> _salvar() async {
    final erros = {
      if (_valor <= 0) CampoPagamento.valor: 'Informe um valor maior que zero.',
      if (_forma == null) CampoPagamento.forma: 'Escolha a forma de pagamento.',
      if (_cartao == null) CampoPagamento.cartao: 'Escolha o cartão.',
    };
    if (erros.isNotEmpty) {
      setState(() => _erros = erros);
      unawaited(HapticFeedback.heavyImpact());
      return;
    }
    setState(() => _salvando = true);
    final dados = (
      momento: _momento,
      valorCentavos: _valor,
      forma: _forma!,
      uuidCartao: _cartao!.uuidCartaoCredito,
      fatura: _mesDaFatura,
    );
    final repositorio = ref.read(faturadoRepositoryProvider);
    final mensageiro = ScaffoldMessenger.of(context);
    try {
      if (_editando) {
        await repositorio.editarPagamento(
          _pagamento!.uuidPagamentoFatura,
          dados,
        );
      } else {
        await repositorio.criarPagamento(dados);
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
    unawaited(HapticFeedback.mediumImpact());
    mensageiro
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            _editando ? 'Pagamento atualizado.' : 'Pagamento de fatura salvo.',
          ),
        ),
      );
    if (mounted) context.pop();
  }

  Future<void> _excluir() async {
    if (!await confirmarExclusao(context, titulo: 'Excluir este pagamento?')) {
      return;
    }
    if (!mounted) return;
    final mensageiro = ScaffoldMessenger.of(context);
    await ref
        .read(faturadoRepositoryProvider)
        .excluirPagamento(_pagamento!.uuidPagamentoFatura);
    mensageiro
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Pagamento excluído.')));
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    const espaco = SizedBox(height: TokensRavix.spaceMd);
    final texto = Theme.of(context).textTheme;
    final paleta = context.temaRavix.paleta;
    return EsqueletoFormulario(
      titulo: _editando
          ? const Text('Editar pagamento de fatura')
          : const TituloNovoRegistro(TipoRegistro.pagamento),
      rotuloSalvar: 'Salvar pagamento',
      salvando: _salvando,
      aoSalvar: _salvar,
      rotuloExcluir: 'Excluir pagamento',
      aoExcluir: _editando ? _excluir : null,
      campos: [
        CampoValorDestaque(
          controle: _campoValor,
          rotulo: 'Valor pago',
          autofoco: !_editando,
          erro: _erros[CampoPagamento.valor],
          ajuda: 'Não conta como gasto: o gasto são as compras da fatura.',
          aoMudar: (v) => setState(() {
            _valor = v;
            _limpar(CampoPagamento.valor);
          }),
        ),
        espaco,
        CamposDataHora(
          momento: _momento,
          ajudaData: 'Data do pagamento',
          ajudaHora: 'Hora do pagamento',
          aoMudar: (m) => setState(() => _momento = m),
        ),
        const SizedBox(height: TokensRavix.spaceLg),
        Text('FORMA DE PAGAMENTO', style: context.temaRavix.sobretitulo),
        const SizedBox(height: TokensRavix.spaceSm),
        Wrap(
          spacing: TokensRavix.spaceSm,
          children: [
            for (final f in FormaPagamentoFatura.values)
              ChoiceChip(
                label: Text(f.rotulo),
                selected: _forma == f,
                onSelected: (_) => setState(() {
                  _forma = f;
                  _limpar(CampoPagamento.forma);
                }),
              ),
          ],
        ),
        if (_erros[CampoPagamento.forma] case final erro?)
          Padding(
            padding: const EdgeInsets.only(top: TokensRavix.spaceSm),
            child: Text(
              erro,
              style: texto.bodySmall?.copyWith(color: paleta.danger),
            ),
          ),
        const SizedBox(height: TokensRavix.spaceLg),
        CampoCartao(
          uuidCartao: _cartao?.uuidCartaoCredito,
          cartaoAtual: _editando ? _cartao : null,
          erro: _erros[CampoPagamento.cartao],
          aoEscolher: (c) => setState(() {
            _cartao = c;
            _limpar(CampoPagamento.cartao);
          }),
        ),
        espaco,
        CampoMes(
          rotulo: 'Fatura paga',
          mes: _mesDaFatura,
          ajuda: 'Mês de vencimento da fatura que este pagamento quita.',
          aoMudar: (novo) => setState(() {
            _fatura = novo;
            _faturaManual = true;
          }),
        ),
      ],
    );
  }
}
