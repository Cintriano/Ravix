import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ravix/app/dependencias.dart';
import 'package:ravix/core/datas.dart';
import 'package:ravix/core/tema/tema.dart';
import 'package:ravix/core/tema/tokens.dart';
import 'package:ravix/core/valor.dart';
import 'package:ravix/data/compra_avista_repository.dart';
import 'package:ravix/data/recorrencia_repository.dart';
import 'package:ravix/features/compra_avista/aba_avista_providers.dart';
import 'package:ravix/features/compra_avista/formulario_compra.dart';
import 'package:ravix/features/registro/campos_registro.dart';

/// Cobranças à vista previstas no mês, pré-registradas (E01-F04-T07):
/// ficam fora do acumulado até o usuário tocar em Registrar ao pagar.
class SecaoPrevistas extends ConsumerWidget {
  /// Cria a seção.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final previstas = ref.watch(previstasDoMesProvider).value ?? const [];
    if (previstas.isEmpty) return const SizedBox.shrink();
    final hoje = ref.watch(relogioProvider).agora();
    final hojeSemHora = DateTime(hoje.year, hoje.month, hoje.day);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            TokensRavix.spaceMd,
            TokensRavix.spaceMd,
            TokensRavix.spaceMd,
            TokensRavix.spaceXs,
          ),
          child: Text('PREVISTOS', style: context.temaRavix.sobretitulo),
        ),
        for (final p in previstas)
          _LinhaPrevista(
            prevista: p,
            atrasada: p.ocorrencia.isBefore(hojeSemHora),
          ),
      ],
    );
  }
}

class _LinhaPrevista extends StatelessWidget {
  const new({required this.prevista, required this.atrasada});

  final Prevista prevista;
  final bool atrasada;

  @override
  Widget build(BuildContext context) {
    final paleta = context.temaRavix.paleta;
    final regra = prevista.regra;
    final data = formatarData(prevista.ocorrencia);
    final detalhe = atrasada ? 'Atrasado desde $data' : 'Previsto para $data';
    return ListTile(
      minTileHeight: 64,
      title: Text(
        regra.descricao,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '$detalhe · ${formatarCentavos(regra.valorRecorrencia)}',
        style: atrasada ? TextStyle(color: paleta.danger) : null,
      ),
      trailing: FilledButton.tonal(
        // O tema dá largura total aos botões; aqui ele vai ao lado do texto.
        style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
        onPressed: () => registrarPrevista(context, prevista),
        child: const Text('Registrar'),
      ),
    );
  }
}

/// Abre o registro do pagamento de [prevista], com valor e forma de
/// pagamento editáveis; também permite pular este mês.
Future<void> registrarPrevista(BuildContext context, Prevista prevista) =>
    showModalBottomSheet<void>(
      context: context,
      // Por cima da barra de abas, não dentro da aba.
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _FolhaRegistrar(prevista: prevista),
    );

class _FolhaRegistrar extends ConsumerStatefulWidget {
  const new({required this.prevista});

  final Prevista prevista;

  @override
  ConsumerState<_FolhaRegistrar> createState() => _FolhaRegistrarState();
}

class _FolhaRegistrarState extends ConsumerState<_FolhaRegistrar> {
  late int _valor = widget.prevista.regra.valorRecorrencia;
  late TipoPagamento _forma = TipoPagamento.deCodigo(
    widget.prevista.regra.tipoPagamento!,
  );
  late DateTime _momento = ref.read(relogioProvider).agora();
  late final _campoValor = TextEditingController(
    text: formatarCentavosSemSimbolo(_valor),
  );
  String? _erro;
  bool _salvando = false;

  @override
  void dispose() {
    _campoValor.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    if (_valor <= 0) {
      setState(() => _erro = 'Informe um valor maior que zero.');
      return;
    }
    setState(() => _salvando = true);
    final mensageiro = ScaffoldMessenger.of(context);
    await ref
        .read(recorrenciaRepositoryProvider)
        .registrarAvista(
          widget.prevista,
          momento: _momento,
          valorCentavos: _valor,
          tipoPagamento: _forma,
        );
    unawaited(HapticFeedback.mediumImpact());
    mensageiro
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${widget.prevista.regra.descricao} registrado.'),
        ),
      );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _pular() async {
    final mensageiro = ScaffoldMessenger.of(context);
    final regra = widget.prevista.regra;
    await ref
        .read(recorrenciaRepositoryProvider)
        .pular(regra.uuidRecorrencia, widget.prevista.ocorrencia);
    mensageiro
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('${regra.descricao} pulado neste mês.')),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.prevista.regra.descricao, style: texto.titleLarge),
          Text(
            'Cobrança de ${formatarData(widget.prevista.ocorrencia)}',
            style: texto.bodySmall,
          ),
          espaco,
          CampoValorDestaque(
            controle: _campoValor,
            rotulo: 'Valor pago',
            erro: _erro,
            aoMudar: (v) => setState(() {
              _valor = v;
              _erro = null;
            }),
          ),
          espaco,
          CamposDataHora(
            momento: _momento,
            ajudaData: 'Data do pagamento',
            ajudaHora: 'Hora do pagamento',
            aoMudar: (m) => setState(() => _momento = m),
          ),
          espaco,
          Wrap(
            spacing: TokensRavix.spaceSm,
            runSpacing: TokensRavix.spaceSm,
            children: [
              for (final f in TipoPagamento.values)
                ChoiceChip(
                  label: Text(f.rotulo),
                  selected: _forma == f,
                  onSelected: (_) => setState(() => _forma = f),
                ),
            ],
          ),
          const SizedBox(height: TokensRavix.spaceLg),
          FilledButton(
            onPressed: _salvando ? null : _registrar,
            child: const Text('Registrar pagamento'),
          ),
          TextButton(
            onPressed: _salvando ? null : _pular,
            child: const Text('Pular este mês'),
          ),
        ],
      ),
    );
  }
}
