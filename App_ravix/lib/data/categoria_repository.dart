import 'package:ravix/core/texto.dart';
import 'package:ravix/data/banco.dart';

const _diversos = 'diversos';

int _compararNomes(String a, String b) {
  final na = normalizarTexto(a);
  final nb = normalizarTexto(b);
  if ((na == _diversos) != (nb == _diversos)) {
    return na == _diversos ? 1 : -1;
  }
  return na.compareTo(nb);
}

/// Categorias e subcategorias da carga inicial (somente leitura na v1).
///
/// Ordem dos seletores: alfabética, sem considerar acentos, com Diversos por
/// último (DP-36).
final class CategoriaRepository {
  /// Cria o repositório sobre o banco do app.
  new(this._banco);

  final BancoRavix _banco;

  /// Todas as categorias, ordenadas.
  Future<List<Categoria>> listarCategorias() async {
    final categorias = await _banco.select(_banco.tblCategoria).get();
    return categorias..sort((a, b) => _compararNomes(a.nome, b.nome));
  }

  /// Subcategorias de [idCategoria], ordenadas.
  Future<List<Subcategoria>> listarSubcategorias(int idCategoria) async {
    final subcategorias = await (_banco.select(
      _banco.tblSubcategoria,
    )..where((s) => s.idCategoria.equals(idCategoria))).get();
    return subcategorias..sort((a, b) => _compararNomes(a.nome, b.nome));
  }

  /// Subcategoria pelo ID, ou `null`. Usada para preencher a categoria a
  /// partir da sugestão.
  Future<Subcategoria?> buscarSubcategoria(int idSubcategoria) =>
      (_banco.select(_banco.tblSubcategoria)
            ..where((s) => s.idSubcategoria.equals(idSubcategoria)))
          .getSingleOrNull();
}
