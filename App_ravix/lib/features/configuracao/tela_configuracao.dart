import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ravix/core/tema/icones.dart';
import 'package:ravix/features/tags/aba_tags.dart';

/// Configuração (E01-F07). Na v1 tem só a aba Tags; renda e cartões entram
/// na v2 como novas abas, e a barra de abas aparece quando houver mais de
/// uma.
class TelaConfiguracao extends ConsumerWidget {
  /// Cria a tela.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tags')),
      body: const AbaTags(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => criarTag(context, ref),
        icon: const Icon(Icones.plus),
        label: const Text('Nova tag'),
      ),
    );
  }
}
