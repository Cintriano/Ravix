import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ravix/app/dependencias.dart';
import 'package:ravix/core/datas.dart';
import 'package:ravix/core/tema/tokens.dart';
import 'package:ravix/core/texto.dart';
import 'package:ravix/core/valor.dart';
import 'package:ravix/data/banco.dart';
import 'package:ravix/data/compra_avista_repository.dart';
import 'package:ravix/data/faturado_repository.dart';
import 'package:ravix/data/recorrencia_repository.dart';
import 'package:ravix/features/compra_avista/formulario_compra.dart';
import 'package:ravix/features/compra_avista/formulario_providers.dart';
import 'package:ravix/features/registro/campos_registro.dart';
import 'package:ravix/features/registro/tipo_registro.dart';

/// Campos validados da compra no cartão.
enum CampoFaturado {
  /// Valor total.
  valor,

  /// Descrição.
  descricao,

  /// Cartão.
  cartao,

  /// Quantidade de parcelas.
  parcelas,

  /// Categoria.
  categoria,

  /// Subcategoria.
  subcategoria,
}

/// Formulário de compra no cartão (E01-F03-T06, T07): valor total, cartão,
/// parcelas e o mês da fatura da 1ª parcela, sugerido pelo cartão (DP-28).
class FormularioCompraFaturada extends ConsumerStatefulWidget {
  /// Cria o formulário; [compra] nula = criar.
  const new({this.compra, super.key});

  /// Compra em edição.
  final CompraFaturada? compra;

  @override
  ConsumerState<FormularioCompraFaturada> createState() =>
      _FormularioCompraFaturadaState();
}

class _FormularioCompraFaturadaState
    extends ConsumerState<FormularioCompraFaturada> {
  late final CompraFaturada? _compra = widget.compra;
  late DateTime _momento = _compra == null
      ? ref.read(relogioProvider).agora()
      : DateTime.parse(_compra.timestampCompraFaturada);
  late int _valor = _compra?.valorTotal ?? 0;
  late String _descricao = _compra?.descricao ?? '';
  late int _parcelas = _compra?.quantParcela ?? 1;
  CartaoCredito? _cartao;
  late Mes? _vencimento = _compra == null
      ? null
      : Mes(_compra.anoVencimento, _compra.mesVencimento);
  late bool _vencimentoManual = _compra != null;
  late int? _idCategoria = _compra == null
      ? null
      : _compra.idSubcategoria ~/ 100;
  late int? _idSubcategoria = _compra?.idSubcategoria;
  Tag? _tag;
  late bool _categoriaManual = _compra != null;
  bool _sugerida = false;
  Map<CampoFaturado, String> _erros = const {};
  bool _salvando = false;
  Timer? _espera;

  /// Cobrança recorrente no cartão (E01-F03-T08); só ao criar.
  late ConfigRecorrencia _recorrencia = (
    ativa: false,
    periodicidade: Periodicidade.mensal,
    dia: _momento.day,
    fim: null,
  );

  late final _campoValor = TextEditingController(
    text: _valor == 0 ? '' : formatarCentavosSemSimbolo(_valor),
  );
  late final _campoDescricao = TextEditingController(text: _descricao);
  late final _campoParcelas = TextEditingController(text: '$_parcelas');

  bool get _editando => _compra != null;

  @override
  void initState() {
    super.initState();
    final compra = _compra;
    if (compra == null) return;
    unawaited(
      ref.read(cartaoRepositoryProvider).buscar(compra.uuidCartaoCredito).then((
        c,
      ) {
        if (mounted) setState(() => _cartao = c);
      }),
    );
    if (compra.uuidTag case final uuid?) {
      unawaited(
        ref.read(tagRepositoryProvider).buscar(uuid).then((t) {
          if (mounted) setState(() => _tag = t);
        }),
      );
    }
  }

  @override
  void dispose() {
    _espera?.cancel();
    _campoValor.dispose();
    _campoDescricao.dispose();
    _campoParcelas.dispose();
    super.dispose();
  }

  void _limpar(CampoFaturado campo) {
    if (_erros.containsKey(campo)) _erros = {..._erros}..remove(campo);
  }

  /// Mês da 1ª fatura: o escolhido ou o sugerido pelo cartão.
  Mes get _mesDaFatura =>
      (_vencimentoManual ? _vencimento : null) ??
      sugerirVencimento(
        _momento,
        diaFechamento: _cartao?.diaFechamento,
        diaVencimento: _cartao?.diaVencimento,
      );

  void _aoMudarDescricao(String texto) {
    setState(() {
      _descricao = texto;
      _limpar(CampoFaturado.descricao);
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
    if (!mounted || id == null || _categoriaManual || _descricao != texto) {
      return;
    }
    setState(() {
      _idCategoria = id ~/ 100;
      _idSubcategoria = id;
      _sugerida = true;
      _limpar(CampoFaturado.categoria);
      _limpar(CampoFaturado.subcategoria);
    });
  }

  Map<CampoFaturado, String> _validar() => {
    if (_valor <= 0) CampoFaturado.valor: 'Informe um valor maior que zero.',
    if (_descricao.trim().isEmpty)
      CampoFaturado.descricao: 'Informe a descrição.',
    if (_cartao == null) CampoFaturado.cartao: 'Escolha o cartão.',
    if (!_recorrencia.ativa && (_parcelas < 1 || _parcelas > 99))
      CampoFaturado.parcelas: 'Use de 1 a 99 parcelas.'
    else if (!_recorrencia.ativa && _valor > 0 && _valor < _parcelas)
      CampoFaturado.parcelas: 'Valor pequeno demais para tantas parcelas.',
    if (_idCategoria == null) CampoFaturado.categoria: 'Escolha a categoria.',
    if (_idSubcategoria == null)
      CampoFaturado.subcategoria: 'Escolha a subcategoria.',
  };

  Future<void> _salvar() async {
    final erros = _validar();
    if (erros.isNotEmpty) {
      setState(() => _erros = erros);
      unawaited(HapticFeedback.heavyImpact());
      return;
    }
    setState(() => _salvando = true);
    final dados = (
      momento: _momento,
      descricao: _descricao,
      valorTotalCentavos: _valor,
      parcelas: _parcelas,
      uuidCartao: _cartao!.uuidCartaoCredito,
      vencimento: _mesDaFatura,
      idSubcategoria: _idSubcategoria!,
      uuidTag: _tag?.uuidTag,
    );
    final repositorio = ref.read(faturadoRepositoryProvider);
    final mensageiro = ScaffoldMessenger.of(context);
    try {
      if (_editando) {
        final compra = _compra!;
        final mudouARegra =
            dados.valorTotalCentavos != compra.valorTotal ||
            dados.idSubcategoria != compra.idSubcategoria;
        var alcance = AlcanceRecorrente.soEste;
        if (compra.uuidRecorrencia != null && mudouARegra) {
          final escolha = await perguntarAlcance(
            context,
            titulo: 'Cobrança recorrente',
            acao: 'Alterar',
          );
          if (escolha == null) return;
          alcance = escolha;
        }
        await repositorio.editarCompra(compra.uuidCompraFaturada, dados);
        if (alcance == AlcanceRecorrente.esteEProximos) {
          await ref
              .read(recorrenciaRepositoryProvider)
              .aplicarAosProximos(
                compra.uuidRecorrencia!,
                ocorrencia: deIsoData(compra.ocorrencia!),
                valorCentavos: dados.valorTotalCentavos,
                idSubcategoria: dados.idSubcategoria,
              );
        }
      } else if (_recorrencia.ativa) {
        // A regra gera os lançamentos: as cobranças até hoje entram já.
        final recorrencias = ref.read(recorrenciaRepositoryProvider);
        await recorrencias.criar((
          descricao: _descricao,
          valorCentavos: _valor,
          idSubcategoria: _idSubcategoria!,
          periodicidade: _recorrencia.periodicidade,
          diaCobranca: _recorrencia.dia,
          inicio: _momento,
          fim: _recorrencia.fim,
          uuidCartao: _cartao!.uuidCartaoCredito,
          tipoPagamento: null,
          documentoBeneficiario: null,
        ));
        await recorrencias.materializarFaturadas();
      } else {
        await repositorio.criarCompra(dados);
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
            _editando
                ? 'Compra atualizada.'
                : _recorrencia.ativa
                ? 'Cobrança recorrente criada.'
                : 'Compra salva.',
          ),
        ),
      );
    if (mounted) context.pop();
  }

  Future<void> _excluir() async {
    final compra = _compra!;
    final uuidRecorrencia = compra.uuidRecorrencia;
    if (uuidRecorrencia != null) {
      final alcance = await perguntarAlcance(
        context,
        titulo: 'Excluir cobrança recorrente?',
        acao: 'Excluir',
      );
      if (alcance == null || !mounted) return;
      final mensageiro = ScaffoldMessenger.of(context);
      final recorrencias = ref.read(recorrenciaRepositoryProvider);
      final ocorrencia = deIsoData(compra.ocorrencia!);
      if (alcance == AlcanceRecorrente.soEste) {
        await recorrencias.pular(uuidRecorrencia, ocorrencia);
      } else {
        await recorrencias.excluirDaqui(uuidRecorrencia, ocorrencia);
      }
      mensageiro
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Compra excluída.')));
      if (mounted) context.pop();
      return;
    }
    if (!await confirmarExclusao(context, titulo: 'Excluir esta compra?')) {
      return;
    }
    if (!mounted) return;
    final mensageiro = ScaffoldMessenger.of(context);
    await ref
        .read(faturadoRepositoryProvider)
        .excluirCompra(compra.uuidCompraFaturada);
    mensageiro
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Compra excluída.')));
    if (mounted) context.pop();
  }

  String? get _resumoParcelas {
    if (_valor <= 0 || _parcelas < 2 || _valor < _parcelas) return null;
    final valores = dividirEmParcelas(_valor, _parcelas);
    final iguais = valores.first == valores.last;
    return iguais
        ? '${_parcelas}x de ${formatarCentavos(valores.last)}'
        : '1ª de ${formatarCentavos(valores.first)} e '
              '${_parcelas - 1}x de ${formatarCentavos(valores.last)}';
  }

  @override
  Widget build(BuildContext context) {
    const espaco = SizedBox(height: TokensRavix.spaceMd);
    final mes = _mesDaFatura;
    return EsqueletoFormulario(
      titulo: _editando
          ? const Text('Editar compra no cartão')
          : const TituloNovoRegistro(TipoRegistro.faturado),
      rotuloSalvar: 'Salvar compra',
      salvando: _salvando,
      aoSalvar: _salvar,
      rotuloExcluir: 'Excluir compra',
      aoExcluir: _editando ? _excluir : null,
      campos: [
        CampoValorDestaque(
          controle: _campoValor,
          rotulo: 'Valor total',
          autofoco: !_editando,
          erro: _erros[CampoFaturado.valor],
          aoMudar: (v) => setState(() {
            _valor = v;
            _limpar(CampoFaturado.valor);
            _limpar(CampoFaturado.parcelas);
          }),
        ),
        espaco,
        TextField(
          controller: _campoDescricao,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.next,
          onChanged: _aoMudarDescricao,
          decoration: InputDecoration(
            labelText: 'Descrição',
            hintText: 'Ex.: Mercado Livre',
            errorText: _erros[CampoFaturado.descricao],
          ),
        ),
        espaco,
        CamposDataHora(
          momento: _momento,
          ajudaData: 'Data da compra',
          ajudaHora: 'Hora da compra',
          aoMudar: (m) => setState(() => _momento = m),
        ),
        espaco,
        CampoCartao(
          uuidCartao: _cartao?.uuidCartaoCredito,
          cartaoAtual: _editando ? _cartao : null,
          erro: _erros[CampoFaturado.cartao],
          aoEscolher: (c) => setState(() {
            _cartao = c;
            _limpar(CampoFaturado.cartao);
          }),
        ),
        if (!_editando) ...[
          espaco,
          CamposRecorrencia(
            config: _recorrencia,
            explicacao:
                'O cartão cobra sozinho: cada cobrança vira lançamento no '
                'dia, na fatura sugerida pelo cartão.',
            aoMudar: (c) => setState(() {
              _recorrencia = c;
              _limpar(CampoFaturado.parcelas);
            }),
          ),
        ],
        if (!_recorrencia.ativa) ...[
          espaco,
          TextField(
            controller: _campoParcelas,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
            onChanged: (t) => setState(() {
              _parcelas = int.tryParse(t) ?? 0;
              _limpar(CampoFaturado.parcelas);
            }),
            decoration: InputDecoration(
              labelText: 'Parcelas',
              helperText: _resumoParcelas ?? '1 = à vista no cartão',
              errorText: _erros[CampoFaturado.parcelas],
            ),
          ),
          espaco,
          CampoMes(
            rotulo: _parcelas > 1 ? 'Fatura da 1ª parcela' : 'Fatura',
            mes: mes,
            ajuda: _vencimentoManual
                ? 'Escolhida por você.'
                : 'Sugerida pelo fechamento do cartão; confira na fatura.',
            aoMudar: (novo) => setState(() {
              _vencimento = novo;
              _vencimentoManual = true;
            }),
          ),
        ],
        const SizedBox(height: TokensRavix.spaceLg),
        CamposClassificacao(
          idCategoria: _idCategoria,
          idSubcategoria: _idSubcategoria,
          tag: _tag,
          sugerida: _sugerida,
          erroCategoria: _erros[CampoFaturado.categoria],
          erroSubcategoria: _erros[CampoFaturado.subcategoria],
          aoEscolherCategoria: (id) => setState(() {
            _categoriaManual = true;
            _sugerida = false;
            if (id != _idCategoria) _idSubcategoria = null;
            _idCategoria = id;
            _limpar(CampoFaturado.categoria);
          }),
          aoEscolherSubcategoria: (id) => setState(() {
            _categoriaManual = true;
            _sugerida = false;
            _idSubcategoria = id;
            _limpar(CampoFaturado.subcategoria);
          }),
          aoEscolherTag: (t) => setState(() => _tag = t),
        ),
      ],
    );
  }
}
