// Escritos sem @riverpod: o gerador não resolve tipos que vêm do código
// gerado pelo drift no mesmo build.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ravix/app/dependencias.dart';
import 'package:ravix/data/banco.dart';
import 'package:ravix/data/fatura_repository.dart';
import 'package:ravix/data/recorrencia_repository.dart';
import 'package:ravix/features/shell/mes_selecionado.dart';

/// Cartão escolhido na aba faturada (E01-F05-T02); `null` = todos.
final class CartaoDaAba extends Notifier<String?> {
  @override
  String? build() => null;

  /// Escolhe [uuid]; escolher o que já está escolhido volta para todos.
  void alternar(String uuid) => state = state == uuid ? null : uuid;

  /// Volta para todos os cartões.
  void todos() => state = null;
}

/// Cartão escolhido na aba faturada.
final NotifierProvider<CartaoDaAba, String?> cartaoDaAbaProvider =
    NotifierProvider(CartaoDaAba.new);

/// Faturas do mês selecionado por cartão.
final StreamProvider<List<FaturaDoCartao>> faturasDoMesProvider =
    StreamProvider.autoDispose(
      (ref) => ref
          .watch(faturaRepositoryProvider)
          .observarFaturas(ref.watch(mesSelecionadoProvider)),
    );

/// Parcelas e estornos do mês selecionado, do cartão escolhido.
final StreamProvider<List<ItemDaFatura>> itensDaFaturaProvider =
    StreamProvider.autoDispose(
      (ref) => ref
          .watch(faturaRepositoryProvider)
          .observarItens(
            ref.watch(mesSelecionadoProvider),
            uuidCartao: ref.watch(cartaoDaAbaProvider),
          ),
    );

/// Pagamentos das faturas do mês selecionado.
final StreamProvider<List<PagamentoDoMes>> pagamentosDoMesProvider =
    StreamProvider.autoDispose(
      (ref) => ref
          .watch(faturaRepositoryProvider)
          .observarPagamentos(ref.watch(mesSelecionadoProvider)),
    );

/// Cobranças recorrentes do cartão previstas nas faturas do mês.
final StreamProvider<List<Prevista>> previstasDaFaturaProvider =
    StreamProvider.autoDispose(
      (ref) => ref
          .watch(recorrenciaRepositoryProvider)
          .observarPrevistasNaFatura(ref.watch(mesSelecionadoProvider)),
    );

/// Meses da linha do tempo: cinco antes do selecionado e seis depois.
const mesesAntesNaLinhaDoTempo = 5;

/// Quantos meses a linha do tempo mostra.
const mesesNaLinhaDoTempo = 12;

/// Totais por cartão nos meses da linha do tempo.
final StreamProvider<List<PontoDaLinhaDoTempo>> linhaDoTempoProvider =
    StreamProvider.autoDispose((ref) {
      final mes = ref.watch(mesSelecionadoProvider);
      var de = mes;
      for (var i = 0; i < mesesAntesNaLinhaDoTempo; i++) {
        de = de.anterior;
      }
      var ate = de;
      for (var i = 1; i < mesesNaLinhaDoTempo; i++) {
        ate = ate.proximo;
      }
      return ref.watch(faturaRepositoryProvider).observarLinhaDoTempo(de, ate);
    });

/// Faturas do mês por categoria, todos os cartões.
final StreamProvider<List<TotalPorCategoria>> faturasPorCategoriaProvider =
    StreamProvider.autoDispose(
      (ref) => ref
          .watch(faturaRepositoryProvider)
          .observarPorCategoria(ref.watch(mesSelecionadoProvider)),
    );
