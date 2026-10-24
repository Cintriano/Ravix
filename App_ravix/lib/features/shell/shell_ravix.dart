import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ravix/core/tema/icones.dart';
import 'package:ravix/features/shell/seletor_mes.dart';

/// Uma aba do shell.
typedef AbaShell = ({String rotulo, IconData icone});

/// Abas na ordem dos ramos do `StatefulShellRoute`. Na v1 só existe a aba À
/// vista; Macro e Faturada entram na v2.
const List<AbaShell> abasDoShell = [(rotulo: 'À vista', icone: Icones.wallet)];

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
      // O tipo do registro é o da aba ativa (DP-16); na v1, sempre à vista.
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/registro/novo'),
        icon: const Icon(Icones.plus),
        label: const Text('Novo gasto'),
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
