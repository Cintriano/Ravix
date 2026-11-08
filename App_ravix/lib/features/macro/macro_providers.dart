// Escritos sem @riverpod: o gerador não resolve tipos que vêm do código
// gerado pelo drift no mesmo build.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ravix/app/dependencias.dart';
import 'package:ravix/data/banco.dart';
import 'package:ravix/data/macro_repository.dart';
import 'package:ravix/features/shell/mes_selecionado.dart';

/// Base de comparação escolhida (E01-F06-T02). Abre sempre em renda total
/// (DP-1).
final class BaseDaMacro extends Notifier<BaseComparacao> {
  @override
  BaseComparacao build() => BaseComparacao.rendaTotal;

  /// Troca a base.
  // Método, e não setter, como nos outros notifiers do app.
  // ignore: use_setters_to_change_properties
  void escolher(BaseComparacao base) => state = base;
}

/// Base de comparação escolhida.
final NotifierProvider<BaseDaMacro, BaseComparacao> baseDaMacroProvider =
    NotifierProvider(BaseDaMacro.new);

/// À vista do mês selecionado por dia e forma de pagamento.
final StreamProvider<List<AvistaDoDia>> avistaPorDiaProvider =
    StreamProvider.autoDispose(
      (ref) => ref
          .watch(macroRepositoryProvider)
          .observarAvistaPorDia(ref.watch(mesSelecionadoProvider)),
    );

/// Renda que vale no mês selecionado, ou `null`.
final StreamProvider<Renda?> rendaDoMesSelecionadoProvider =
    StreamProvider.autoDispose(
      (ref) => ref
          .watch(rendaRepositoryProvider)
          .observarVigente(ref.watch(mesSelecionadoProvider)),
    );
