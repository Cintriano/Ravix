import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ravix/core/tema/icones.dart';
import 'package:ravix/features/registro/tipo_registro.dart';
import 'package:ravix/features/shell/seletor_mes.dart';

/// Uma aba do shell e o novo registro que o botão flutuante abre nela.
/// Sem `rotaNovo`, o botão pergunta o tipo (DP-16).
typedef AbaShell = ({
  String rotulo,
  IconData icone,
  String rotuloNovo,
  String? rotaNovo,
});

/// Abas na ordem dos ramos do `StatefulShellRoute`. A Macro é a inicial.
const List<AbaShell> abasDoShell = [
  (
    rotulo: 'Macro',
    icone: Icones.macro,
    rotuloNovo: 'Novo registro',
    rotaNovo: null,
  ),
  (
    rotulo: 'Faturada',
    icone: Icones.creditCard,
    rotuloNovo: 'Nova compra',
    rotaNovo: '/registro/novo?tipo=faturado',
  ),
  (
    rotulo: 'À vista',
    icone: Icones.wallet,
    rotuloNovo: 'Novo gasto',
    rotaNovo: '/registro/novo',
  ),
];

/// Pergunta o tipo do novo registro e abre o formulário nele.
Future<void> escolherTipoDoRegistro(BuildContext context) async {
  final tipo = await showModalBottomSheet<TipoRegistro>(
    context: context,
    useRootNavigator: true,
    showDragHandle: true,
    builder: (contexto) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Novo registro',
              style: Theme.of(contexto).textTheme.titleLarge,
            ),
          ),
          for (final t in TipoRegistro.values)
            ListTile(
              title: Text(t.rotulo),
              onTap: () => Navigator.of(contexto).pop(t),
            ),
        ],
      ),
    ),
  );
  if (tipo != null && context.mounted) {
    await context.push('/registro/novo?tipo=${tipo.codigo}');
  }
}

/// Casca do app (E01-F02): cabeçalho com o seletor de mês, acesso à
/// Configuração, botão flutuante de novo registro e as abas.
class ShellRavix extends StatelessWidget {
  /// Cria o shell sobre [navegacao].
  const new({required this.navegacao, super.key});

  /// Estado dos ramos do `StatefulShellRoute`.
  final StatefulNavigationShell navegacao;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 4,
        title: const SeletorMes(),
        actions: [
          IconButton(
            tooltip: 'Configuração',
            icon: const Icon(Icones.settings),
            onPressed: () => context.push('/configuracao'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: navegacao,
      // O tipo do registro é o da aba ativa (DP-16).
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => switch (abasDoShell[navegacao.currentIndex].rotaNovo) {
          final rota? => context.push(rota),
          null => escolherTipoDoRegistro(context),
        },
        icon: const Icon(Icones.plus),
        label: Text(abasDoShell[navegacao.currentIndex].rotuloNovo),
      ),
      // Navegação inferior só faz sentido com duas abas ou mais.
      bottomNavigationBar: abasDoShell.length < 2
          ? null
          : NavigationBar(
              selectedIndex: navegacao.currentIndex,
              onDestinationSelected: (i) => navegacao.goBranch(
                i,
                initialLocation: i == navegacao.currentIndex,
              ),
              destinations: [
                for (final aba in abasDoShell)
                  NavigationDestination(
                    icon: Icon(aba.icone),
                    label: aba.rotulo,
                  ),
              ],
            ),
    );
  }
}
