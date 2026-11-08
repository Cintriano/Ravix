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
import 'package:ravix/core/texto.dart';
import 'package:ravix/core/valor.dart';
import 'package:ravix/data/banco.dart';
import 'package:ravix/data/compra_avista_repository.dart';
import 'package:ravix/data/recorrencia_repository.dart';
import 'package:ravix/features/compra_avista/formulario_providers.dart';
import 'package:ravix/features/compra_avista/rascunho_compra.dart';
import 'package:ravix/features/registro/campos_registro.dart';
import 'package:ravix/features/registro/tipo_registro.dart';

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
    TipoPagamento.boleto => 'Boleto',
  };
}

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

  /// Cobrança recorrente (E01-F03-T08); só ao criar.
  late ConfigRecorrencia _recorrencia = (
    ativa: false,
    periodicidade: Periodicidade.mensal,
    dia: _rascunho.momento.day,
    fim: null,
  );

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
        if (_recorrencia.ativa) {
          await _criarRecorrente();
        } else {
          await repositorio.criar(_rascunho.paraDados());
        }
      } else {
        final dados = _rascunho.paraDados();
        final alcance = await _alcanceDaEdicao(compra, dados);
        if (alcance == null) return;
        await repositorio.editar(compra.uuidCompraAvista, dados);
        if (alcance == AlcanceRecorrente.esteEProximos) {
          await ref
              .read(recorrenciaRepositoryProvider)
              .aplicarAosProximos(
                compra.uuidRecorrencia!,
                ocorrencia: deIsoData(compra.ocorrencia!),
                valorCentavos: dados.valorCentavos,
                idSubcategoria: dados.idSubcategoria,
              );
        }
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
                ? 'Gasto atualizado.'
                : _recorrencia.ativa
                ? 'Gasto salvo e cobrança recorrente criada.'
                : 'Gasto salvo.',
          ),
        ),
      );
    if (mounted) context.pop();
  }

  /// Cria a regra a partir deste gasto e registra este gasto como a
  /// cobrança do mês dele (DP-13, DP-25).
  Future<void> _criarRecorrente() async {
    final dados = _rascunho.paraDados();
    final recorrencias = ref.read(recorrenciaRepositoryProvider);
    final uuid = await recorrencias.criar((
      descricao: dados.descricao,
      valorCentavos: dados.valorCentavos,
      idSubcategoria: dados.idSubcategoria,
      periodicidade: _recorrencia.periodicidade,
      diaCobranca: _recorrencia.dia,
      inicio: dados.momento,
      fim: _recorrencia.fim,
      uuidCartao: null,
      tipoPagamento: dados.tipoPagamento,
      documentoBeneficiario: null,
    ));
    final regra = (await recorrencias.buscar(uuid))!;
    final ocorrencias = ocorrenciasNoMes(regra, Mes.de(dados.momento));
    if (ocorrencias.isEmpty) {
      await ref.read(compraAvistaRepositoryProvider).criar(dados);
      return;
    }
    await recorrencias.registrarAvista(
      (regra: regra, ocorrencia: ocorrencias.single),
      momento: dados.momento,
      valorCentavos: dados.valorCentavos,
      tipoPagamento: dados.tipoPagamento,
    );
  }

  /// Num gasto de recorrência com valor ou categoria mudados, pergunta se a
  /// mudança vale para as próximas cobranças (T12). Sem recorrência ou sem
  /// mudança dessas, é só este. `null` = cancelou.
  Future<AlcanceRecorrente?> _alcanceDaEdicao(
    CompraAvista compra,
    DadosCompraAvista dados,
  ) async {
    final mudouARegra =
        dados.valorCentavos != compra.valorCompraAvista ||
        dados.idSubcategoria != compra.idSubcategoria;
    if (compra.uuidRecorrencia == null || !mudouARegra) {
      return AlcanceRecorrente.soEste;
    }
    return await perguntarAlcance(
      context,
      titulo: 'Gasto recorrente',
      acao: 'Alterar',
    );
  }

  Future<void> _excluirRecorrente(CompraAvista compra) async {
    final alcance = await perguntarAlcance(
      context,
      titulo: 'Excluir gasto recorrente?',
      acao: 'Excluir',
    );
    if (alcance == null || !mounted) return;
    final mensageiro = ScaffoldMessenger.of(context);
    final recorrencias = ref.read(recorrenciaRepositoryProvider);
    final ocorrencia = deIsoData(compra.ocorrencia!);
    if (alcance == AlcanceRecorrente.soEste) {
      await recorrencias.pular(compra.uuidRecorrencia!, ocorrencia);
    } else {
      await recorrencias.excluirDaqui(compra.uuidRecorrencia!, ocorrencia);
    }
    mensageiro
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            alcance == AlcanceRecorrente.soEste
                ? 'Gasto excluído; a cobrança deste mês foi pulada.'
                : 'Gasto excluído e recorrência encerrada.',
          ),
        ),
      );
    if (mounted) context.pop();
  }

  Future<void> _excluir() async {
    final compra = widget.compra!;
    if (compra.uuidRecorrencia != null) {
      await _excluirRecorrente(compra);
      return;
    }
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
              foregroundColor: paleta.onDanger,
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
    const espaco = SizedBox(height: TokensRavix.spaceMd);

    return Scaffold(
      appBar: AppBar(
        title: _editando
            ? const Text('Editar gasto')
            : const TituloNovoRegistro(TipoRegistro.avista),
        actions: [
          if (_editando)
            IconButton(
              tooltip: 'Excluir gasto',
              icon: Icon(Icones.trash2, color: paleta.danger),
              onPressed: _excluir,
            ),
        ],
      ),
      // Formulário curto: tudo construído de uma vez, para os avisos de
      // validação existirem mesmo fora da tela.
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TokensRavix.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CampoValorDestaque(
              controle: _valor,
              autofoco: !_editando,
              erro: _erros[CampoCompra.valor],
              aoMudar: (centavos) => setState(() {
                _rascunho.valorCentavos = centavos;
                _limparErro(CampoCompra.valor);
              }),
            ),
            espaco,
            TextField(
              controller: _descricao,
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
            CamposDataHora(
              momento: _rascunho.momento,
              ajudaData: 'Data do gasto',
              ajudaHora: 'Hora do gasto',
              aoMudar: (m) => setState(() => _rascunho.momento = m),
            ),
            const SizedBox(height: TokensRavix.spaceLg),
            Text('FORMA DE PAGAMENTO', style: context.temaRavix.sobretitulo),
            const SizedBox(height: TokensRavix.spaceSm),
            Wrap(
              spacing: TokensRavix.spaceSm,
              runSpacing: TokensRavix.spaceSm,
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
                padding: const EdgeInsets.only(top: TokensRavix.spaceSm),
                child: Text(
                  erro,
                  style: texto.bodySmall?.copyWith(color: paleta.danger),
                ),
              ),
            if (!_editando) ...[
              espaco,
              CamposRecorrencia(
                config: _recorrencia,
                explicacao:
                    'Este gasto conta como a cobrança deste mês; as próximas '
                    'aparecem como previstas até você registrar.',
                aoMudar: (c) => setState(() => _recorrencia = c),
              ),
            ],
            const SizedBox(height: TokensRavix.spaceLg),
            CamposClassificacao(
              idCategoria: _rascunho.idCategoria,
              idSubcategoria: _rascunho.idSubcategoria,
              tag: _tagSelecionada,
              sugerida: _sugerida,
              erroCategoria: _erros[CampoCompra.categoria],
              erroSubcategoria: _erros[CampoCompra.subcategoria],
              aoEscolherCategoria: (id) => setState(() {
                _categoriaManual = true;
                _sugerida = false;
                if (id != _rascunho.idCategoria) {
                  _rascunho.idSubcategoria = null;
                }
                _rascunho.idCategoria = id;
                _limparErro(CampoCompra.categoria);
              }),
              aoEscolherSubcategoria: (id) => setState(() {
                _categoriaManual = true;
                _sugerida = false;
                _rascunho.idSubcategoria = id;
                _limparErro(CampoCompra.subcategoria);
              }),
              aoEscolherTag: (tag) => setState(() {
                _tagSelecionada = tag;
                _rascunho.uuidTag = tag?.uuidTag;
              }),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            TokensRavix.spaceMd,
            TokensRavix.spaceSm,
            TokensRavix.spaceMd,
            TokensRavix.spaceMd,
          ),
          child: FilledButton(
            onPressed: _salvando ? null : _salvar,
            child: const Text('Salvar gasto'),
          ),
        ),
      ),
    );
  }
}
