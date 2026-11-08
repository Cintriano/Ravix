import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ravix/app/dependencias.dart';
import 'package:ravix/app/preferencias.dart';
import 'package:ravix/core/datas.dart';
import 'package:ravix/core/tema/icones.dart';
import 'package:ravix/core/tema/tokens.dart';
import 'package:ravix/features/cartoes/cartoes_providers.dart';
import 'package:ravix/features/renda/renda_providers.dart';
import 'package:ravix/features/renda/tela_renda.dart';

/// Configuração (E01-F07): aparência, renda, cartões, tags e exportação do
/// backup. É o único ponto de entrada da renda.
class TelaConfiguracao extends ConsumerWidget {
  /// Cria a tela.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final texto = Theme.of(context).textTheme;
    final aparencia = ref.watch(aparenciaEscolhidaProvider);
    final ultimoBackup = ref.watch(ultimoBackupProvider);
    final renda = ref.watch(rendaDoMesAtualProvider).value;
    final cartoes = ref.watch(cartoesAtivosProvider).value;
    final totalCartoes = cartoes?.length ?? 0;
    return Scaffold(
      appBar: AppBar(title: const Text('Configuração')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: TokensRavix.spaceSm),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              TokensRavix.spaceMd,
              TokensRavix.spaceSm,
              TokensRavix.spaceMd,
              TokensRavix.spaceSm,
            ),
            child: Text('Aparência', style: texto.titleLarge),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: TokensRavix.spaceMd,
            ),
            child: SegmentedButton<Aparencia>(
              showSelectedIcon: false,
              segments: [
                for (final a in Aparencia.values)
                  ButtonSegment(
                    value: a,
                    label: Text(a.rotulo),
                    icon: Icon(a.icone, size: TokensRavix.iconSizeMd),
                  ),
              ],
              selected: {aparencia},
              onSelectionChanged: (escolha) => ref
                  .read(aparenciaEscolhidaProvider.notifier)
                  .escolher(escolha.single),
            ),
          ),
          const SizedBox(height: TokensRavix.spaceLg),
          const Divider(),
          ListTile(
            leading: const Icon(Icones.wallet),
            title: const Text('Renda'),
            subtitle: Text(
              renda == null ? 'Salário e voucher' : resumoDaRenda(renda),
            ),
            trailing: const Icon(Icones.chevronRight),
            onTap: () => context.push('/configuracao/renda'),
          ),
          ListTile(
            leading: const Icon(Icones.creditCard),
            title: const Text('Cartões'),
            subtitle: Text(switch (totalCartoes) {
              0 => 'Cartões de crédito',
              1 => '1 cartão',
              _ => '$totalCartoes cartões',
            }),
            trailing: const Icon(Icones.chevronRight),
            onTap: () => context.push('/configuracao/cartoes'),
          ),
          ListTile(
            leading: const Icon(Icones.tag),
            title: const Text('Tags'),
            subtitle: const Text('Contexto dos gastos, como viagem ou rolê'),
            trailing: const Icon(Icones.chevronRight),
            onTap: () => context.push('/configuracao/tags'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icones.backup),
            title: const Text('Exportar backup'),
            subtitle: Text(
              ultimoBackup == null
                  ? 'Nenhum backup exportado ainda'
                  : 'Último backup: ${formatarData(ultimoBackup)} às '
                        '${formatarHora(ultimoBackup)}',
            ),
            onTap: () => _exportarBackup(context, ref),
          ),
        ],
      ),
    );
  }
}

/// Gera o backup e abre o compartilhamento; avisa se der errado.
Future<void> _exportarBackup(BuildContext context, WidgetRef ref) async {
  final mensagens = ScaffoldMessenger.of(context);
  try {
    final arquivo = await ref.read(backupRepositoryProvider).exportar();
    final compartilhou = await ref
        .read(compartilhadorProvider)
        .compartilharArquivo(arquivo, assunto: 'Backup do Ravix');
    if (compartilhou) {
      await ref
          .read(ultimoBackupProvider.notifier)
          .registrar(ref.read(relogioProvider).agora());
    }
  } on Exception {
    mensagens.showSnackBar(
      const SnackBar(content: Text('Não foi possível exportar o backup.')),
    );
  }
}
