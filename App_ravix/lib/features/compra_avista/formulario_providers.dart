// Escritos sem @riverpod: o gerador não resolve tipos que vêm do código
// gerado pelo drift (Categoria, Subcategoria, CompraAvista) no mesmo build.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:ravix/app/dependencias.dart';
import 'package:ravix/data/banco.dart';

/// Categorias em ordem alfabética.
final FutureProvider<List<Categoria>> categoriasProvider = FutureProvider(
  (ref) => ref.watch(categoriaRepositoryProvider).listarCategorias(),
);

/// Subcategorias de uma categoria, em ordem alfabética com Diversos por
/// último.
final FutureProviderFamily<List<Subcategoria>, int> subcategoriasProvider =
    FutureProvider.family(
      (ref, idCategoria) => ref
          .watch(categoriaRepositoryProvider)
          .listarSubcategorias(idCategoria),
    );

/// Sugestão de subcategoria pela descrição (E01-F03-T16). Separada do
/// repositório para os testes contarem as consultas.
final Provider<Future<int?> Function(String descricao)>
sugestaoDeSubcategoriaProvider = Provider(
  (ref) => ref.watch(compraAvistaRepositoryProvider).sugerirSubcategoria,
);

/// Gasto a editar.
final FutureProviderFamily<CompraAvista?, String> compraParaEditarProvider =
    FutureProvider.autoDispose.family(
      (ref, uuid) => ref.watch(compraAvistaRepositoryProvider).buscar(uuid),
    );
