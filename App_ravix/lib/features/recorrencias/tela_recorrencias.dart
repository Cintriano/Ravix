import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ravix/app/dependencias.dart';
import 'package:ravix/core/datas.dart';
import 'package:ravix/core/tema/icones.dart';
import 'package:ravix/core/tema/tema.dart';
import 'package:ravix/core/tema/tokens.dart';
import 'package:ravix/core/valor.dart';
import 'package:ravix/data/banco.dart';
import 'package:ravix/data/compra_avista_repository.dart';
import 'package:ravix/data/recorrencia_repository.dart';
import 'package:ravix/features/cartoes/cartoes_providers.dart';
import 'package:ravix/features/compra_avista/formulario_compra.dart';
import 'package:ravix/features/registro/campos_registro.dart';
import 'package:ravix/features/shell/estados_tela.dart';

/// Todas as regras de recorrência (E01-F12).
final StreamProvider<List<Recorrencia>> recorrenciasProvider =
    StreamProvider.autoDispose(
      (ref) => ref.watch(recorrenciaRepositoryProvider).observarTodas(),
    );

/// Nome da situação na tela.
extension RotuloSituacao on SituacaoRecorrencia {
  /// Texto exibido.
  String get rotulo => switch (this) {
    SituacaoRecorrencia.ativa => 'Ativa',
    SituacaoRecorrencia.pausada => 'Pausada',
    SituacaoRecorrencia.cancelada => 'Cancelada',
  };
}

enum _Acao { editar, pausar, retomar, cancelar, excluir }

/// Configuração > Recorrências (E01-F12): lista por situação, com pausar,
/// retomar, cancelar e editar (valor, dia e categoria valem daqui pra
/// frente; os lançamentos já feitos não mudam).
class TelaRecorrencias extends ConsumerWidget {
  /// Cria a tela.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ativos =
        ref.watch(cartoesAtivosProvider).value ?? const <CartaoCredito>[];
    final cartoes = <String, String>{
      for (final c in ativos) c.uuidCartaoCredito: c.nomeCartao,
    };
    return Scaffold(
      appBar: AppBar(title: const Text('Recorrências')),
      body: ConteudoAssincrono<List<Recorrencia>>(
        valor: ref.watch(recorrenciasProvider),
        estaVazio: (lista) => lista.isEmpty,
        aoTentarDeNovo: () => ref.invalidate(recorrenciasProvider),
        vazio: const EstadoVazio(
          titulo: 'Nenhuma recorrência',
          mensagem:
              'Ligue "Cobrança recorrente" ao registrar um gasto, como '
              'aluguel ou assinatura.',
        ),
        conteudo: (lista) => ListView(
          children: [
            for (final situacao in SituacaoRecorrencia.values)
              if (lista.where((r) => r.status == situacao.codigo).toList()
                  case final daSituacao when daSituacao.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    TokensRavix.spaceMd,
                    TokensRavix.spaceMd,
                    TokensRavix.spaceMd,
                    TokensRavix.spaceXs,
                  ),
                  child: Text(
                    situacao.rotulo.toUpperCase(),
                    style: context.temaRavix.sobretitulo,
                  ),
                ),
                for (final r in daSituacao)
                  _LinhaRecorrencia(regra: r, nomeDoCartao: cartoes),
              ],
          ],
        ),
      ),
    );
  }
}

class _LinhaRecorrencia extends ConsumerWidget {
  const new({required this.regra, required this.nomeDoCartao});

  final Recorrencia regra;
  final Map<String, String> nomeDoCartao;

  String get _resumo {
    final quando = regra.periodicidade == Periodicidade.anual.codigo
        ? 'anual, dia ${regra.diaCobranca} de '
              '${Mes.de(deIsoData(regra.dataInicio)).nome}'
        : 'dia ${regra.diaCobranca}';
    final como = regra.uuidCartaoCredito == null
        ? TipoPagamento.deCodigo(regra.tipoPagamento!).rotulo
        : nomeDoCartao[regra.uuidCartaoCredito] ?? 'Cartão';
    final fim = regra.dataFim == null
        ? ''
        : ' · até ${formatarData(deIsoData(regra.dataFim!))}';
    return '${formatarCentavos(regra.valorRecorrencia)} · $quando · $como$fim';
  }

  Future<void> _agir(BuildContext context, WidgetRef ref, _Acao acao) async {
    final repositorio = ref.read(recorrenciaRepositoryProvider);
    final mensageiro = ScaffoldMessenger.of(context);
    void avisar(String texto) => mensageiro
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
    switch (acao) {
      case _Acao.editar:
        await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (_) => _EditarRecorrencia(regra: regra),
        );
      case _Acao.pausar:
        await repositorio.mudarSituacao(
          regra.uuidRecorrencia,
          SituacaoRecorrencia.pausada,
        );
        avisar('${regra.descricao} pausada.');
      case _Acao.retomar:
        await repositorio.mudarSituacao(
          regra.uuidRecorrencia,
          SituacaoRecorrencia.ativa,
        );
        avisar('${regra.descricao} retomada.');
      case _Acao.cancelar:
        await repositorio.mudarSituacao(
          regra.uuidRecorrencia,
          SituacaoRecorrencia.cancelada,
        );
        avisar('${regra.descricao} cancelada. Os lançamentos ficam.');
      case _Acao.excluir:
        final excluiu = await repositorio.remover(regra.uuidRecorrencia);
        avisar(
          excluiu
              ? '${regra.descricao} excluída.'
              : '${regra.descricao} tem lançamentos e foi cancelada.',
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final situacao = SituacaoRecorrencia.deCodigo(regra.status);
    return ListTile(
      leading: Icon(
        regra.uuidCartaoCredito == null ? Icones.wallet : Icones.creditCard,
      ),
      title: Text(regra.descricao),
      subtitle: Text(_resumo),
      trailing: PopupMenuButton<_Acao>(
        tooltip: 'Ações de ${regra.descricao}',
        onSelected: (acao) => _agir(context, ref, acao),
        itemBuilder: (_) => [
          if (situacao != SituacaoRecorrencia.cancelada)
            const PopupMenuItem(value: _Acao.editar, child: Text('Editar')),
          if (situacao == SituacaoRecorrencia.ativa)
            const PopupMenuItem(value: _Acao.pausar, child: Text('Pausar')),
          if (situacao == SituacaoRecorrencia.pausada)
            const PopupMenuItem(value: _Acao.retomar, child: Text('Retomar')),
          if (situacao != SituacaoRecorrencia.cancelada)
            const PopupMenuItem(value: _Acao.cancelar, child: Text('Cancelar')),
          const PopupMenuItem(value: _Acao.excluir, child: Text('Excluir')),
        ],
      ),
    );
  }
}

class _EditarRecorrencia extends ConsumerStatefulWidget {
  const new({required this.regra});

  final Recorrencia regra;

  @override
  ConsumerState<_EditarRecorrencia> createState() => _EditarRecorrenciaState();
}

class _EditarRecorrenciaState extends ConsumerState<_EditarRecorrencia> {
  late int _valor = widget.regra.valorRecorrencia;
  late int _dia = widget.regra.diaCobranca;
  late int? _idCategoria = widget.regra.idSubcategoria ~/ 100;
  late int? _idSubcategoria = widget.regra.idSubcategoria;
  late final _campoValor = TextEditingController(
    text: formatarCentavosSemSimbolo(_valor),
  );
  String? _erro;

  @override
  void dispose() {
    _campoValor.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (_valor <= 0 || _idSubcategoria == null || _dia < 1 || _dia > 31) {
      setState(
        () => _erro = _valor <= 0
            ? 'Informe um valor maior que zero.'
            : 'Confira o dia e a subcategoria.',
      );
      return;
    }
    final mensageiro = ScaffoldMessenger.of(context);
    await ref
        .read(recorrenciaRepositoryProvider)
        .editarDaquiPraFrente(
          widget.regra.uuidRecorrencia,
          valorCentavos: _valor,
          diaCobranca: _dia,
          idSubcategoria: _idSubcategoria!,
        );
    mensageiro
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${widget.regra.descricao} alterada daqui pra frente.'),
        ),
      );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    const espaco = SizedBox(height: TokensRavix.spaceMd);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        TokensRavix.spaceMd,
        0,
        TokensRavix.spaceMd,
        TokensRavix.spaceMd + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.regra.descricao, style: texto.titleLarge),
            Text(
              'Vale para as próximas cobranças; as já lançadas não mudam.',
              style: texto.bodySmall,
            ),
            espaco,
            CampoValorDestaque(
              controle: _campoValor,
              erro: _erro,
              aoMudar: (v) => setState(() {
                _valor = v;
                _erro = null;
              }),
            ),
            espaco,
            TextFormField(
              initialValue: '$_dia',
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(2),
              ],
              onChanged: (t) => setState(() => _dia = int.tryParse(t) ?? 0),
              decoration: const InputDecoration(labelText: 'Dia de cobrança'),
            ),
            espaco,
            CamposClassificacao(
              idCategoria: _idCategoria,
              idSubcategoria: _idSubcategoria,
              tag: null,
              comTag: false,
              aoEscolherCategoria: (id) => setState(() {
                if (id != _idCategoria) _idSubcategoria = null;
                _idCategoria = id;
              }),
              aoEscolherSubcategoria: (id) =>
                  setState(() => _idSubcategoria = id),
              aoEscolherTag: (_) {},
            ),
            const SizedBox(height: TokensRavix.spaceLg),
            FilledButton(onPressed: _salvar, child: const Text('Salvar')),
          ],
        ),
      ),
    );
  }
}
