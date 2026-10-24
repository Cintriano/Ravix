import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ravix/app/dependencias.dart';
import 'package:ravix/core/datas.dart';
import 'package:ravix/core/tema/icones.dart';
import 'package:ravix/features/shell/mes_selecionado.dart';

/// Seletor de mês global do cabeçalho (E01-F02-T02): anterior, mês atual e
/// próximo. Tocar no nome volta para o mês de hoje.
class SeletorMes extends ConsumerWidget {
  /// Cria o seletor.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mes = ref.watch(mesSelecionadoProvider);
    final controle = ref.read(mesSelecionadoProvider.notifier);
    final hoje = Mes.de(ref.watch(relogioProvider).agora());
    final rotulo = mes.rotulo;
    final titulo = '${rotulo[0].toUpperCase()}${rotulo.substring(1)}';

    void mudar(VoidCallback acao) {
      unawaited(HapticFeedback.selectionClick());
      acao();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Mês anterior',
          icon: const Icon(Icones.chevronLeft),
          onPressed: () => mudar(controle.voltar),
        ),
        Flexible(
          child: Semantics(
            label: 'Mês selecionado: $rotulo',
            hint: mes == hoje ? null : 'Toque para voltar ao mês atual',
            button: mes != hoje,
            excludeSemantics: true,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: mes == hoje ? null : () => mudar(controle.irParaHoje),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
                child: Text(
                  titulo,
                  style: Theme.of(context).textTheme.titleLarge,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: 'Próximo mês',
          icon: const Icon(Icones.chevronRight),
          onPressed: () => mudar(controle.avancar),
        ),
      ],
    );
  }
}
