import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ravix/core/tema/icones.dart';
import 'package:ravix/features/shell/seletor_mes.dart';

/// Uma aba do shell e o novo registro que o botão flutuante abre nela.
typedef AbaShell = ({
  String rotulo,
  IconData icone,
  String rotuloNovo,
  String rotaNovo,
});

/// Abas na ordem dos ramos do `StatefulShellRoute`. A Macro entra na v2,
/// junto com a visão macro (E01-F06).
const List<AbaShell> abasDoShell = [
  (
    rotulo: 'À vista',
    icone: Icones.wallet,
    rotuloNovo: 'Novo gasto',
    rotaNovo: '/registro/novo',
  ),
  (
    rotulo: 'Faturada',
    icone: Icones.creditCard,
    rotuloNovo: 'Nova compra',
    rotaNovo: '/registro/novo?tipo=faturado',
  ),
];

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
        onPressed: () =>
            context.push(abasDoShell[navegacao.currentIndex].rotaNovo),
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
