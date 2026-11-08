import 'package:drift/drift.dart';
import 'package:ravix/core/datas.dart';
import 'package:ravix/data/banco.dart';

/// Total de uma subcategoria. Na visão por tag, `pago` e `total` diferem
/// nas compras parceladas; nos outros recortes são iguais.
typedef TotalPorSubcategoria = ({
  int idCategoria,
  String categoria,
  int idSubcategoria,
  String subcategoria,

  /// O que já saiu: à vista, parcelas de faturas que já venceram e
  /// estornos (negativos).
  int pago,

  /// O valor cheio: à vista, total das compras e estornos (negativos).
  int total,
});

/// Totais de uma categoria, somando as subcategorias.
typedef TotalDaCategoria = ({
  int idCategoria,
  String categoria,
  int pago,
  int total,
  List<TotalPorSubcategoria> subcategorias,
});

/// Agrupa [linhas] por categoria, da maior para a menor pelo total.
List<TotalDaCategoria> agruparPorCategoria(List<TotalPorSubcategoria> linhas) {
  final grupos = <int, List<TotalPorSubcategoria>>{};
  for (final l in linhas) {
    grupos.putIfAbsent(l.idCategoria, () => []).add(l);
  }
  final categorias = [
    for (final MapEntry(key: id, value: subs) in grupos.entries)
      (
        idCategoria: id,
        categoria: subs.first.categoria,
        pago: subs.fold(0, (s, l) => s + l.pago),
        total: subs.fold(0, (s, l) => s + l.total),
        subcategorias: [...subs]..sort((a, b) => b.total.compareTo(a.total)),
      ),
  ]..sort((a, b) => b.total.compareTo(a.total));
  return categorias;
}

/// Recortes por categoria e subcategoria (E01-F04-T06, E01-F05-T06) e a
/// visão por tag (E01-F13-T01). Só consulta.
final class AnaliseRepository {
  /// Cria o repositório sobre o banco do app.
  new(this._banco);

  final BancoRavix _banco;

  static const _colunas = '''
    k.id_categoria, k.nome AS categoria, s.id_subcategoria,
    s.nome AS subcategoria''';

  static const _juntas = '''
    JOIN tbl_subcategoria s ON s.id_subcategoria = i.id_subcategoria
    JOIN tbl_categoria    k ON k.id_categoria    = s.id_categoria''';

  /// Gastos à vista de [mes] por subcategoria, do maior para o menor.
  Stream<List<TotalPorSubcategoria>> observarAvista(Mes mes) => _observar(
    '''
    SELECT $_colunas, SUM(i.valor_compra_avista) AS pago,
      SUM(i.valor_compra_avista) AS total
    FROM tbl_compra_avista i $_juntas
    WHERE i.timestamp_compra_avista >= ?1 AND i.timestamp_compra_avista < ?2
    GROUP BY s.id_subcategoria
    ORDER BY total DESC
    ''',
    [Variable.withString(mes.inicioIso), Variable.withString(mes.fimIso)],
  );

  /// Faturas de [mes] (todos os cartões) por subcategoria: parcelas menos
  /// estornos. Subcategorias zeradas saem.
  Stream<List<TotalPorSubcategoria>> observarFaturada(Mes mes) => _observar(
    '''
    SELECT $_colunas, SUM(i.valor) AS pago, SUM(i.valor) AS total
    FROM (
      SELECT c.id_subcategoria, p.valor_parcela AS valor
      FROM tbl_parcela p
      JOIN tbl_compra_faturada c USING (uuid_compra_faturada)
      WHERE p.ano_vencimento = ?1 AND p.mes_vencimento = ?2
      UNION ALL
      SELECT id_subcategoria, -valor_estorno FROM tbl_estorno
      WHERE ano_vencimento = ?1 AND mes_vencimento = ?2
    ) i $_juntas
    GROUP BY s.id_subcategoria
    HAVING SUM(i.valor) > 0
    ORDER BY total DESC
    ''',
    [Variable.withInt(mes.ano), Variable.withInt(mes.mes)],
  );

  /// Tudo que tem a tag [uuidTag], de todos os meses, por subcategoria
  /// (E01-F13-T01). Compra parcelada entra com o pago até [ate] (parcelas
  /// de faturas que vencem até esse mês) e com o total da compra.
  Stream<List<TotalPorSubcategoria>> observarTag(String uuidTag, Mes ate) =>
      _observar(
        '''
        SELECT $_colunas, SUM(i.pago) AS pago, SUM(i.total) AS total
        FROM (
          SELECT id_subcategoria, valor_compra_avista AS pago,
            valor_compra_avista AS total
          FROM tbl_compra_avista WHERE uuid_tag = ?1
          UNION ALL
          SELECT c.id_subcategoria,
            COALESCE((SELECT SUM(p.valor_parcela) FROM tbl_parcela p
              WHERE p.uuid_compra_faturada = c.uuid_compra_faturada
                AND p.ano_vencimento * 12 + p.mes_vencimento <= ?2), 0),
            c.valor_total
          FROM tbl_compra_faturada c WHERE c.uuid_tag = ?1
          UNION ALL
          SELECT id_subcategoria, -valor_estorno, -valor_estorno
          FROM tbl_estorno WHERE uuid_tag = ?1
        ) i $_juntas
        GROUP BY s.id_subcategoria
        ORDER BY total DESC
        ''',
        [
          Variable.withString(uuidTag),
          Variable.withInt(ate.ano * 12 + ate.mes),
        ],
        tabelas: {_banco.tblCompraAvista, _banco.tblTag},
      );

  Stream<List<TotalPorSubcategoria>> _observar(
    String sql,
    List<Variable<Object>> variaveis, {
    Set<ResultSetImplementation<dynamic, dynamic>> tabelas = const {},
  }) => _banco
      .customSelect(
        sql,
        variables: variaveis,
        readsFrom: {
          _banco.tblCompraAvista,
          _banco.tblCompraFaturada,
          _banco.tblParcela,
          _banco.tblEstorno,
          _banco.tblSubcategoria,
          _banco.tblCategoria,
          ...tabelas,
        },
      )
      .watch()
      .map(
        (linhas) => [
          for (final l in linhas)
            (
              idCategoria: l.read<int>('id_categoria'),
              categoria: l.read<String>('categoria'),
              idSubcategoria: l.read<int>('id_subcategoria'),
              subcategoria: l.read<String>('subcategoria'),
              pago: l.read<int>('pago'),
              total: l.read<int>('total'),
            ),
        ],
      );
}
