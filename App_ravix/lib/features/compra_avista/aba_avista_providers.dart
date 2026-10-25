// Escritos sem @riverpod: o gerador não resolve tipos que vêm do código
// gerado pelo drift (CompraDoMes, Tag) no mesmo build.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ravix/app/dependencias.dart';
import 'package:ravix/data/banco.dart';
import 'package:ravix/data/compra_avista_repository.dart';
import 'package:ravix/features/shell/mes_selecionado.dart';

/// Filtros da tabela da aba À vista (E01-F04-T05). Valem para todos os
/// meses até serem limpos.
final class FiltroDaTabela extends Notifier<FiltroCompras> {
  @override
  FiltroCompras build() => semFiltro;

  /// Filtra pela categoria [id] (ou tira o filtro). Trocar a categoria
  /// limpa a subcategoria.
  void categoria(int? id) => state = (
    idCategoria: id,
    idSubcategoria: id == state.idCategoria ? state.idSubcategoria : null,
    uuidTag: state.uuidTag,
  );

  /// Filtra pela subcategoria [id] (ou tira o filtro).
  void subcategoria(int? id) => state = (
    idCategoria: state.idCategoria,
    idSubcategoria: id,
    uuidTag: state.uuidTag,
  );

  /// Filtra pela tag [uuid] (ou tira o filtro).
  void tag(String? uuid) => state = (
    idCategoria: state.idCategoria,
    idSubcategoria: state.idSubcategoria,
    uuidTag: uuid,
  );

  /// Tira todos os filtros.
  void limpar() => state = semFiltro;
}

/// Filtros ativos da tabela.
final NotifierProvider<FiltroDaTabela, FiltroCompras> filtroDaTabelaProvider =
    NotifierProvider(FiltroDaTabela.new);

/// Total do mês selecionado, em centavos. Ignora os filtros (E01-F04-T01).
final StreamProvider<int> acumuladoDoMesProvider = StreamProvider.autoDispose(
  (ref) => ref
      .watch(compraAvistaRepositoryProvider)
      .observarAcumulado(ref.watch(mesSelecionadoProvider)),
);

/// Gastos do mês selecionado com os filtros, mais recentes primeiro.
final StreamProvider<List<CompraDoMes>> comprasDoMesProvider =
    StreamProvider.autoDispose(
      (ref) => ref
          .watch(compraAvistaRepositoryProvider)
          .observarMes(
            ref.watch(mesSelecionadoProvider),
            filtro: ref.watch(filtroDaTabelaProvider),
          ),
    );

/// Todas as tags (ativas e arquivadas), para o filtro.
final StreamProvider<List<Tag>> todasAsTagsProvider =
    StreamProvider.autoDispose(
      (ref) => ref.watch(tagRepositoryProvider).observarTodas(),
    );
