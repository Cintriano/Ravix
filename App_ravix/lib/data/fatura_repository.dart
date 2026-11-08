import 'package:drift/drift.dart';
import 'package:ravix/core/datas.dart';
import 'package:ravix/data/banco.dart';

/// Fatura de um cartão num mês de vencimento, com o consumo do limite
/// (E01-F05-T01, T09; DP-27).
typedef FaturaDoCartao = ({
  CartaoCredito cartao,

  /// Parcelas que vencem no mês menos os estornos da fatura.
  int valor,

  /// Soma dos pagamentos desta fatura; zero se não foi paga.
  int pago,

  /// Último pagamento desta fatura, ou `null`.
  DateTime? pagoEm,

  /// Parcelas de faturas ainda não pagas (atual e futuras) menos os
  /// estornos delas. Não depende do mês escolhido.
  int consumo,
});

/// Tipo de uma linha da fatura.
enum TipoItemFatura {
  /// Parcela de uma compra.
  parcela,

  /// Estorno, que entra como crédito (DP-14).
  estorno,
}

/// Uma linha da fatura: parcela de compra ou estorno (E01-F05-T03, T10).
typedef ItemDaFatura = ({
  TipoItemFatura tipo,

  /// UUID da compra (parcela) ou do estorno, para abrir a edição.
  String uuid,
  String uuidCartao,
  String descricao,
  DateTime momento,

  /// Número da parcela e total de parcelas; 1 e 1 no estorno.
  int numeroParcela,
  int quantParcelas,

  /// Valor em centavos, sempre positivo; o estorno abate.
  int valor,
  int idCategoria,
  String subcategoria,
  String? tag,
  bool recorrente,
});

/// Pagamento de uma fatura do mês, para a lista (E01-F05-T09).
typedef PagamentoDoMes = ({PagamentoFatura pagamento, String nomeCartao});

/// Total de um cartão numa fatura, para a linha do tempo (E01-F05-T05).
typedef PontoDaLinhaDoTempo = ({Mes mes, String uuidCartao, int valor});

/// Leitura das faturas para a aba faturada. Só consulta; quem grava é o
/// `FaturadoRepository`.
final class FaturaRepository {
  /// Cria o repositório sobre o banco do app.
  new(this._banco);

  final BancoRavix _banco;

  Set<ResultSetImplementation<dynamic, dynamic>> get _tabelas => {
    _banco.tblCartoesCredito,
    _banco.tblCompraFaturada,
    _banco.tblParcela,
    _banco.tblPagamentoFatura,
    _banco.tblEstorno,
  };

  /// Faturas de [mes] por cartão: os ativos e os arquivados que tenham
  /// movimento no mês, em ordem alfabética.
  Stream<List<FaturaDoCartao>> observarFaturas(Mes mes) {
    const parcelasDaFatura = '''
      SELECT p.valor_parcela FROM tbl_parcela p
      JOIN tbl_compra_faturada c USING (uuid_compra_faturada)
      WHERE c.uuid_cartao_credito = k.uuid_cartao_credito
        AND p.ano_vencimento = ?1 AND p.mes_vencimento = ?2''';
    const estornosDaFatura = '''
      SELECT e.valor_estorno FROM tbl_estorno e
      WHERE e.uuid_cartao_credito = k.uuid_cartao_credito
        AND e.ano_vencimento = ?1 AND e.mes_vencimento = ?2''';
    const pagamentosDaFatura = '''
      FROM tbl_pagamento_fatura g
      WHERE g.uuid_cartao_credito = k.uuid_cartao_credito
        AND g.ano_vencimento = ?1 AND g.mes_vencimento = ?2''';
    // Fatura paga = existe pagamento do cartão para aquele vencimento.
    String naoPaga(String t) =>
        '''
      NOT EXISTS (SELECT 1 FROM tbl_pagamento_fatura g
        WHERE g.uuid_cartao_credito = k.uuid_cartao_credito
          AND g.ano_vencimento = $t.ano_vencimento
          AND g.mes_vencimento = $t.mes_vencimento)''';
    return _banco
        .customSelect(
          '''
          SELECT k.*,
            COALESCE((SELECT SUM(valor_parcela) FROM ($parcelasDaFatura)), 0)
              - COALESCE((SELECT SUM(valor_estorno) FROM ($estornosDaFatura)), 0)
              AS valor_fatura,
            COALESCE((SELECT SUM(g.valor_pagamento) $pagamentosDaFatura), 0)
              AS pago,
            (SELECT MAX(g.timestamp_pagamento) $pagamentosDaFatura) AS pago_em,
            COALESCE((SELECT SUM(p.valor_parcela) FROM tbl_parcela p
              JOIN tbl_compra_faturada c USING (uuid_compra_faturada)
              WHERE c.uuid_cartao_credito = k.uuid_cartao_credito
                AND ${naoPaga('p')}), 0)
              - COALESCE((SELECT SUM(e.valor_estorno) FROM tbl_estorno e
              WHERE e.uuid_cartao_credito = k.uuid_cartao_credito
                AND ${naoPaga('e')}), 0)
              AS consumo
          FROM tbl_cartoes_credito k
          WHERE k.status = 'ativo'
             OR EXISTS ($parcelasDaFatura)
             OR EXISTS ($estornosDaFatura)
             OR EXISTS (SELECT 1 $pagamentosDaFatura)
          ORDER BY k.nome_cartao COLLATE NOCASE
          ''',
          variables: [Variable.withInt(mes.ano), Variable.withInt(mes.mes)],
          readsFrom: _tabelas,
        )
        .watch()
        .asyncMap(
          (linhas) async => [
            for (final l in linhas)
              (
                cartao: await _banco.tblCartoesCredito.mapFromRow(l),
                valor: l.read<int>('valor_fatura'),
                pago: l.read<int>('pago'),
                pagoEm: switch (l.readNullable<String>('pago_em')) {
                  final iso? => DateTime.parse(iso),
                  null => null,
                },
                consumo: l.read<int>('consumo'),
              ),
          ],
        );
  }

  /// Parcelas e estornos das faturas de [mes], mais recentes primeiro.
  /// Com [uuidCartao], só desse cartão.
  Stream<List<ItemDaFatura>> observarItens(Mes mes, {String? uuidCartao}) =>
      _banco
          .customSelect(
            '''
            SELECT i.*, s.id_categoria, s.nome AS subcategoria,
              t.nome AS nome_tag
            FROM (
              SELECT 'parcela' AS tipo, c.uuid_compra_faturada AS uuid,
                c.uuid_cartao_credito AS cartao, c.descricao,
                c.timestamp_compra_faturada AS momento, c.criado_em,
                p.numero_parcela, c.quant_parcela, p.valor_parcela AS valor,
                c.id_subcategoria, c.uuid_tag,
                c.uuid_recorrencia IS NOT NULL AS recorrente
              FROM tbl_parcela p
              JOIN tbl_compra_faturada c USING (uuid_compra_faturada)
              WHERE p.ano_vencimento = ?1 AND p.mes_vencimento = ?2
              UNION ALL
              SELECT 'estorno', e.uuid_estorno, e.uuid_cartao_credito,
                e.descricao, e.timestamp_estorno, e.criado_em, 1, 1,
                e.valor_estorno, e.id_subcategoria, e.uuid_tag, 0
              FROM tbl_estorno e
              WHERE e.ano_vencimento = ?1 AND e.mes_vencimento = ?2
            ) i
            JOIN tbl_subcategoria s ON s.id_subcategoria = i.id_subcategoria
            LEFT JOIN tbl_tag t ON t.uuid_tag = i.uuid_tag
            WHERE ?3 IS NULL OR i.cartao = ?3
            ORDER BY i.momento DESC, i.criado_em DESC
            ''',
            variables: [
              Variable.withInt(mes.ano),
              Variable.withInt(mes.mes),
              Variable(uuidCartao),
            ],
            readsFrom: {..._tabelas, _banco.tblSubcategoria, _banco.tblTag},
          )
          .watch()
          .map(
            (linhas) => [
              for (final l in linhas)
                (
                  tipo: TipoItemFatura.values.byName(l.read<String>('tipo')),
                  uuid: l.read<String>('uuid'),
                  uuidCartao: l.read<String>('cartao'),
                  descricao: l.read<String>('descricao'),
                  momento: DateTime.parse(l.read<String>('momento')),
                  numeroParcela: l.read<int>('numero_parcela'),
                  quantParcelas: l.read<int>('quant_parcela'),
                  valor: l.read<int>('valor'),
                  idCategoria: l.read<int>('id_categoria'),
                  subcategoria: l.read<String>('subcategoria'),
                  tag: l.readNullable<String>('nome_tag'),
                  recorrente: l.read<int>('recorrente') == 1,
                ),
            ],
          );

  /// Pagamentos das faturas que vencem em [mes].
  Stream<List<PagamentoDoMes>> observarPagamentos(Mes mes) {
    final g = _banco.tblPagamentoFatura;
    final k = _banco.tblCartoesCredito;
    final consulta =
        _banco.select(g).join([
            innerJoin(k, k.uuidCartaoCredito.equalsExp(g.uuidCartaoCredito)),
          ])
          ..where(
            g.anoVencimento.equals(mes.ano) & g.mesVencimento.equals(mes.mes),
          )
          ..orderBy([OrderingTerm.desc(g.timestampPagamento)]);
    return consulta.watch().map(
      (linhas) => [
        for (final l in linhas)
          (pagamento: l.readTable(g), nomeCartao: l.readTable(k).nomeCartao),
      ],
    );
  }

  /// Total de cada cartão nas faturas de [de] a [ate], para a linha do
  /// tempo. Meses sem movimento não aparecem.
  Stream<List<PontoDaLinhaDoTempo>> observarLinhaDoTempo(Mes de, Mes ate) =>
      _banco
          .customSelect(
            '''
            SELECT cartao, ano, mes, SUM(valor) AS valor FROM (
              SELECT c.uuid_cartao_credito AS cartao, p.ano_vencimento AS ano,
                p.mes_vencimento AS mes, p.valor_parcela AS valor
              FROM tbl_parcela p
              JOIN tbl_compra_faturada c USING (uuid_compra_faturada)
              UNION ALL
              SELECT uuid_cartao_credito, ano_vencimento, mes_vencimento,
                -valor_estorno
              FROM tbl_estorno
            )
            WHERE ano * 12 + mes BETWEEN ?1 AND ?2
            GROUP BY cartao, ano, mes
            ORDER BY ano, mes
            ''',
            variables: [
              Variable.withInt(de.ano * 12 + de.mes),
              Variable.withInt(ate.ano * 12 + ate.mes),
            ],
            readsFrom: _tabelas,
          )
          .watch()
          .map(
            (linhas) => [
              for (final l in linhas)
                (
                  mes: Mes(l.read<int>('ano'), l.read<int>('mes')),
                  uuidCartao: l.read<String>('cartao'),
                  valor: l.read<int>('valor'),
                ),
            ],
          );

  /// Faturas de [mes] somando todos os cartões, por categoria
  /// (E01-F05-T06). Estornos abatem; categorias zeradas saem.
  Stream<List<TotalPorCategoria>> observarPorCategoria(Mes mes) => _banco
      .customSelect(
        '''
        SELECT k.id_categoria, k.nome AS categoria, SUM(i.valor) AS total
        FROM (
          SELECT c.id_subcategoria, p.valor_parcela AS valor
          FROM tbl_parcela p
          JOIN tbl_compra_faturada c USING (uuid_compra_faturada)
          WHERE p.ano_vencimento = ?1 AND p.mes_vencimento = ?2
          UNION ALL
          SELECT id_subcategoria, -valor_estorno FROM tbl_estorno
          WHERE ano_vencimento = ?1 AND mes_vencimento = ?2
        ) i
        JOIN tbl_subcategoria s ON s.id_subcategoria = i.id_subcategoria
        JOIN tbl_categoria    k ON k.id_categoria    = s.id_categoria
        GROUP BY k.id_categoria, k.nome
        HAVING SUM(i.valor) > 0
        ORDER BY total DESC, k.nome
        ''',
        variables: [Variable.withInt(mes.ano), Variable.withInt(mes.mes)],
        readsFrom: {..._tabelas, _banco.tblSubcategoria, _banco.tblCategoria},
      )
      .watch()
      .map(
        (linhas) => [
          for (final l in linhas)
            TotalPorCategoria(
              idCategoria: l.read<int>('id_categoria'),
              categoria: l.read<String>('categoria'),
              total: l.read<int>('total'),
            ),
        ],
      );
}
