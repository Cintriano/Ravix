import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ravix/features/shell/estados_tela.dart';
import 'package:ravix/features/shell/mes_selecionado.dart';

/// Aba À vista (E01-F04). Acumulado, tabela e filtros entram no M6; por ora
/// mostra o estado vazio do mês selecionado.
class AbaAvista extends ConsumerWidget {
  /// Cria a aba.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mes = ref.watch(mesSelecionadoProvider);
    return EstadoVazio(
      titulo: 'Nenhum gasto em ${mes.nome}',
      mensagem: 'Os gastos à vista de ${mes.rotulo} aparecem aqui.',
    );
  }
}
