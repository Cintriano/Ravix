import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ravix/app/dependencias.dart';
import 'package:ravix/core/datas.dart';
import 'package:ravix/data/banco.dart';

// Escrito sem @riverpod: o gerador não resolve tipos que vêm do código gerado
// pelo drift (Renda) no mesmo build.

/// Todas as vigências da renda, da mais recente para a mais antiga.
final StreamProvider<List<Renda>> historicoRendaProvider =
    StreamProvider.autoDispose(
      (ref) => ref.watch(rendaRepositoryProvider).observarHistorico(),
    );

/// Renda que vale no mês de hoje, ou `null`.
final StreamProvider<Renda?> rendaDoMesAtualProvider =
    StreamProvider.autoDispose(
      (ref) => ref
          .watch(rendaRepositoryProvider)
          .observarVigente(Mes.de(ref.watch(relogioProvider).agora())),
    );
