import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ravix/app/preferencias.dart';
import 'package:ravix/core/tema/capra_tokens.dart';
import 'package:ravix/core/tema/icones.dart';

/// Configuração (E01-F07). Na v1: aparência e tags. Renda e cartões entram
/// na v2 como novas linhas.
class TelaConfiguracao extends ConsumerWidget {
  /// Cria a tela.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final texto = Theme.of(context).textTheme;
    final aparencia = ref.watch(aparenciaEscolhidaProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Configuração')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: CapraTokens.spaceSm),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              CapraTokens.spaceMd,
              CapraTokens.spaceSm,
              CapraTokens.spaceMd,
              CapraTokens.spaceSm,
            ),
            child: Text('Aparência', style: texto.titleLarge),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: CapraTokens.spaceMd,
            ),
            child: SegmentedButton<Aparencia>(
              showSelectedIcon: false,
              segments: [
                for (final a in Aparencia.values)
                  ButtonSegment(
                    value: a,
                    label: Text(a.rotulo),
                    icon: Icon(a.icone, size: CapraTokens.iconSizeMd),
                  ),
              ],
              selected: {aparencia},
              onSelectionChanged: (escolha) => ref
                  .read(aparenciaEscolhidaProvider.notifier)
                  .escolher(escolha.single),
            ),
          ),
          const SizedBox(height: CapraTokens.spaceLg),
          const Divider(),
          ListTile(
            leading: const Icon(Icones.tag),
            title: const Text('Tags'),
            subtitle: const Text('Contexto dos gastos, como viagem ou rolê'),
            trailing: const Icon(Icones.chevronRight),
            onTap: () => context.push('/configuracao/tags'),
          ),
        ],
      ),
    );
  }
}
