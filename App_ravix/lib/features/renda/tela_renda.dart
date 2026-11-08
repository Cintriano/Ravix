import 'dart:async';

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
import 'package:ravix/data/renda_repository.dart';
import 'package:ravix/features/compra_avista/mascara_valor.dart';
import 'package:ravix/features/renda/renda_providers.dart';
import 'package:ravix/features/shell/estados_tela.dart';

String _comMaiuscula(String texto) =>
    '${texto[0].toUpperCase()}${texto.substring(1)}';

/// Resumo de uma vigência: "Salário R$ 5.000,00 · Voucher R$ 800,00".
String resumoDaRenda(Renda renda) =>
    'Salário ${formatarCentavos(renda.salario)} · '
    'Voucher ${formatarCentavos(renda.voucher)}';

/// Configuração > Renda (E01-F07-T01, T02): salário e voucher por vigência
/// (DP-6). Alterar a renda pergunta a partir de qual mês o valor vale; os
/// meses anteriores não mudam.
class TelaRenda extends ConsumerWidget {
  /// Cria a tela.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hoje = Mes.de(ref.watch(relogioProvider).agora());
    final vigente = ref.watch(rendaDoMesAtualProvider).value;
    return Scaffold(
      appBar: AppBar(title: const Text('Renda')),
      body: ConteudoAssincrono<List<Renda>>(
        valor: ref.watch(historicoRendaProvider),
        estaVazio: (lista) => lista.isEmpty,
        aoTentarDeNovo: () => ref.invalidate(historicoRendaProvider),
        vazio: EstadoVazio(
          titulo: 'Nenhuma renda',
          mensagem:
              'Cadastre salário e voucher para a visão macro comparar os '
              'gastos com o que entra.',
          rotuloAcao: 'Cadastrar renda',
          aoAgir: () => editarRenda(context, ref, mesInicial: hoje),
        ),
        conteudo: (lista) => ListView.separated(
          padding: const EdgeInsets.only(bottom: 96),
          itemCount: lista.length,
          separatorBuilder: (_, _) =>
              const Divider(indent: TokensRavix.spaceMd),
          itemBuilder: (context, i) {
            final renda = lista[i];
            final emVigor = renda.uuidRenda == vigente?.uuidRenda;
            return ListTile(
              title: Text(
                'A partir de ${renda.aPartirDe.rotulo}',
                style: emVigor
                    ? TextStyle(color: context.temaRavix.acento)
                    : null,
              ),
              subtitle: Text(
                emVigor
                    ? '${resumoDaRenda(renda)}\nEm vigor neste mês'
                    : resumoDaRenda(renda),
              ),
              isThreeLine: emVigor,
              onTap: () => editarRenda(
                context,
                ref,
                mesInicial: renda.aPartirDe,
                atual: renda,
              ),
              trailing: IconButton(
                tooltip: 'Remover a renda de ${renda.aPartirDe.rotulo}',
                icon: const Icon(Icones.trash2),
                onPressed: () => _remover(context, ref, renda),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            editarRenda(context, ref, mesInicial: hoje, atual: vigente),
        icon: const Icon(Icones.plus),
        label: const Text('Alterar renda'),
      ),
    );
  }

  Future<void> _remover(
    BuildContext context,
    WidgetRef ref,
    Renda renda,
  ) async {
    final paleta = context.temaRavix.paleta;
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('Remover esta renda?'),
        content: Text(
          'Os meses a partir de ${renda.aPartirDe.rotulo} passam a usar a '
          'renda anterior, se houver.',
        ),
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
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (confirmou != true) return;
    await ref.read(rendaRepositoryProvider).remover(renda.uuidRenda);
  }
}

/// Abre o formulário de renda, começando em [mesInicial] e com os valores
/// de [atual], se houver.
Future<void> editarRenda(
  BuildContext context,
  WidgetRef ref, {
  required Mes mesInicial,
  Renda? atual,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _FormularioRenda(mesInicial: mesInicial, atual: atual),
);

class _FormularioRenda extends ConsumerStatefulWidget {
  const new({required this.mesInicial, this.atual});

  final Mes mesInicial;
  final Renda? atual;

  @override
  ConsumerState<_FormularioRenda> createState() => _FormularioRendaState();
}

class _FormularioRendaState extends ConsumerState<_FormularioRenda> {
  late final _salario = TextEditingController(
    text: widget.atual == null
        ? ''
        : formatarCentavosSemSimbolo(widget.atual!.salario),
  );
  late final _voucher = TextEditingController(
    text: widget.atual == null
        ? ''
        : formatarCentavosSemSimbolo(widget.atual!.voucher),
  );
  late Mes _mes = widget.mesInicial;
  Map<CampoRenda, String> _erros = const {};
  bool _salvando = false;

  @override
  void dispose() {
    _salario.dispose();
    _voucher.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    setState(() => _salvando = true);
    try {
      await ref
          .read(rendaRepositoryProvider)
          .definir(
            salarioCentavos: centavosDeDigitos(_salario.text),
            voucherCentavos: centavosDeDigitos(_voucher.text),
            aPartirDe: _mes,
          );
      if (mounted) Navigator.of(context).pop();
    } on RendaInvalida catch (e) {
      setState(() {
        _erros = e.erros;
        _salvando = false;
      });
    }
  }

  void _mudarMes(Mes mes) {
    unawaited(HapticFeedback.selectionClick());
    setState(() => _mes = mes);
  }

  Widget _campo(
    TextEditingController controle,
    String rotulo,
    CampoRenda campo,
  ) => TextField(
    controller: controle,
    keyboardType: TextInputType.number,
    inputFormatters: [MascaraValor()],
    onChanged: (_) => setState(() => _erros = {..._erros}..remove(campo)),
    decoration: InputDecoration(
      labelText: rotulo,
      prefixText: r'R$ ',
      hintText: '0,00',
      errorText: _erros[campo],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
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
          Text('Renda', style: texto.titleLarge),
          const SizedBox(height: TokensRavix.spaceMd),
          _campo(_salario, 'Salário', CampoRenda.salario),
          const SizedBox(height: TokensRavix.spaceMd),
          _campo(_voucher, 'Voucher/benefícios', CampoRenda.voucher),
          const SizedBox(height: TokensRavix.spaceLg),
          Text('VALE A PARTIR DE', style: context.temaRavix.sobretitulo),
          Row(
            children: [
              IconButton(
                tooltip: 'Mês anterior',
                icon: const Icon(Icones.chevronLeft),
                onPressed: () => _mudarMes(_mes.anterior),
              ),
              Expanded(
                child: Text(
                  _comMaiuscula(_mes.rotulo),
                  textAlign: TextAlign.center,
                  style: texto.titleMedium,
                ),
              ),
              IconButton(
                tooltip: 'Próximo mês',
                icon: const Icon(Icones.chevronRight),
                onPressed: () => _mudarMes(_mes.proximo),
              ),
            ],
          ),
          Text(
            'Os meses anteriores continuam com a renda que tinham.',
            style: texto.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: TokensRavix.spaceLg),
          FilledButton(
            onPressed: _salvando ? null : _salvar,
            child: const Text('Salvar renda'),
          ),
        ],
      ),
    );
  }
}
