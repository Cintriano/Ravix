import 'package:flutter_test/flutter_test.dart';
import 'package:ravix/data/banco.dart';
import 'package:ravix/data/carga_inicial.dart';
import 'package:sqlite3/sqlite3.dart';

import '../helpers/banco_de_teste.dart';

const _agora = '2026-10-24T12:00:00Z';

void main() {
  late BancoRavix banco;

  setUp(() => banco = bancoEmMemoria());
  tearDown(() => banco.close());

  Future<void> inserirCompra({
    String uuid = 'c1',
    String timestamp = '2026-10-15T08:30:00',
    int fuso = -180,
    String descricao = 'Padaria',
    int valor = 1250,
    String tipo = 'pix',
    int subcategoria = 101,
    String? tag,
  }) => banco.customStatement(
    'INSERT INTO tbl_compra_avista (uuid_compra_avista, '
    'timestamp_compra_avista, fuso_minutos, descricao, descricao_normalizada, '
    'valor_compra_avista, '
    'tipo_pagamento, id_subcategoria, uuid_tag, criado_em, atualizado_em) '
    'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
    [
      uuid,
      timestamp,
      fuso,
      descricao,
      descricao.toLowerCase(),
      valor,
      tipo,
      subcategoria,
      tag,
      _agora,
      _agora,
    ],
  );

  Future<void> inserirTag(String uuid, String nome) => banco.customStatement(
    "INSERT INTO tbl_tag VALUES (?, ?, 'ativa', ?, ?)",
    [uuid, nome, _agora, _agora],
  );

  final violaRestricao = throwsA(isA<SqliteException>());

  group('esquema', () {
    test('cria as 12 tabelas e liga as FKs', () async {
      final tabelas = await banco
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' "
            "AND name LIKE 'tbl_%' ORDER BY name",
          )
          .map((r) => r.read<String>('name'))
          .get();
      expect(tabelas, [
        'tbl_cartoes_credito',
        'tbl_categoria',
        'tbl_compra_avista',
        'tbl_compra_faturada',
        'tbl_estorno',
        'tbl_pagamento_fatura',
        'tbl_parcela',
        'tbl_recorrencia',
        'tbl_recorrencia_excecao',
        'tbl_renda',
        'tbl_subcategoria',
        'tbl_tag',
      ]);

      final fk = await banco.customSelect('PRAGMA foreign_keys').getSingle();
      expect(fk.data.values.single, 1);
    });

    test('carga inicial: 8 categorias e 34 subcategorias, sem o 403', () async {
      final categorias = await banco.select(banco.tblCategoria).get();
      final subcategorias = await banco.select(banco.tblSubcategoria).get();

      expect(categorias, hasLength(8));
      expect(subcategorias, hasLength(34));
      expect(subcategorias.map((s) => s.idSubcategoria), isNot(contains(403)));
      expect(
        {for (final c in categorias) c.idCategoria: c.nome},
        {for (final c in categoriasIniciais) c.id: c.nome},
      );
      for (final s in subcategorias) {
        expect(s.idSubcategoria ~/ 100, s.idCategoria);
      }
    });
  });

  group('restrições', () {
    test('aceita um gasto válido', () async {
      await inserirCompra();
      expect(await banco.select(banco.tblCompraAvista).get(), hasLength(1));
    });

    test('rejeita valor zero ou negativo', () async {
      await expectLater(inserirCompra(valor: 0), violaRestricao);
      await expectLater(inserirCompra(valor: -100), violaRestricao);
    });

    test('rejeita descrição vazia ou só com espaços', () async {
      await expectLater(inserirCompra(descricao: ''), violaRestricao);
      await expectLater(inserirCompra(descricao: '   '), violaRestricao);
    });

    test('rejeita forma de pagamento fora do domínio', () async {
      await expectLater(inserirCompra(tipo: 'credito'), violaRestricao);
      await expectLater(inserirCompra(tipo: 'Pix'), violaRestricao);
    });

    test('rejeita fuso fora de −720 a +840', () async {
      await expectLater(inserirCompra(fuso: -721), violaRestricao);
      await expectLater(inserirCompra(fuso: 841), violaRestricao);
      await inserirCompra(uuid: 'limite-baixo', fuso: -720);
      await inserirCompra(uuid: 'limite-alto', fuso: 840);
    });

    test('rejeita subcategoria inexistente na compra', () async {
      await expectLater(inserirCompra(subcategoria: 403), violaRestricao);
    });

    test('rejeita subcategoria incoerente com a categoria', () async {
      await expectLater(
        banco.customStatement(
          "INSERT INTO tbl_subcategoria VALUES (901, 1, 'Fora de lugar')",
        ),
        violaRestricao,
      );
    });

    test('rejeita tag inexistente na compra', () async {
      await expectLater(inserirCompra(tag: 'nao-existe'), violaRestricao);
    });

    test('impede excluir tag com registros', () async {
      await inserirTag('t1', 'Viagem');
      await inserirCompra(tag: 't1');
      await expectLater(
        banco.customStatement("DELETE FROM tbl_tag WHERE uuid_tag = 't1'"),
        violaRestricao,
      );
    });

    test('nome de tag é único sem diferenciar maiúsculas', () async {
      await inserirTag('t1', 'Viagem');
      await expectLater(inserirTag('t2', 'VIAGEM'), violaRestricao);
    });
  });

  group('restrições do schema 2', () {
    Future<void> inserirCartao({
      String uuid = 'k1',
      String nome = 'Itaú',
      String? finalCartao = '9827',
      String? cnpj = '60872504000123',
    }) => banco.customStatement(
      'INSERT INTO tbl_cartoes_credito (uuid_cartao_credito, nome_cartao, '
      'final_cartao, limite_cartao, dia_fechamento, dia_vencimento, '
      'cnpj_emissor, criado_em, atualizado_em) '
      'VALUES (?, ?, ?, 590000, 29, 5, ?, ?, ?)',
      [uuid, nome, finalCartao, cnpj, _agora, _agora],
    );

    Future<void> inserirRecorrencia({
      String uuid = 'r1',
      String tipo = 'avista',
      String? cartao,
      String? pagamento = 'pix',
      String? documento,
    }) => banco.customStatement(
      'INSERT INTO tbl_recorrencia (uuid_recorrencia, tipo_registro, '
      'uuid_cartao_credito, tipo_pagamento, documento_beneficiario, '
      'descricao, descricao_normalizada, valor_recorrencia, id_subcategoria, '
      'periodicidade, dia_cobranca, data_inicio, criado_em, atualizado_em) '
      "VALUES (?, ?, ?, ?, ?, 'Aluguel', 'aluguel', 150000, 701, 'mensal', "
      "25, '2026-11-01', ?, ?)",
      [uuid, tipo, cartao, pagamento, documento, _agora, _agora],
    );

    Future<void> inserirCompraFaturada({
      String uuid = 'f1',
      int valor = 120000,
      int parcelas = 6,
      String? recorrencia,
      String? ocorrencia,
    }) => banco.customStatement(
      'INSERT INTO tbl_compra_faturada (uuid_compra_faturada, '
      'uuid_cartao_credito, uuid_recorrencia, ocorrencia, '
      'timestamp_compra_faturada, fuso_minutos, descricao, '
      'descricao_normalizada, valor_total, quant_parcela, mes_vencimento, '
      'ano_vencimento, id_subcategoria, criado_em, atualizado_em) '
      "VALUES (?, 'k1', ?, ?, '2026-11-08T10:00:00', -180, 'Passagem', "
      "'passagem', ?, ?, 12, 2026, 405, ?, ?)",
      [uuid, recorrencia, ocorrencia, valor, parcelas, _agora, _agora],
    );

    test('cartão: final com 4 dígitos e CNPJ com 14 dígitos', () async {
      await inserirCartao();
      await expectLater(
        inserirCartao(uuid: 'k2', nome: 'Outro', finalCartao: '98a7'),
        violaRestricao,
      );
      await expectLater(
        inserirCartao(uuid: 'k3', nome: 'Outro', cnpj: '60.872.504/0001-23'),
        violaRestricao,
      );
    });

    test('recorrência à vista exige forma de pagamento e não cartão', () async {
      await inserirCartao();
      await inserirRecorrencia(documento: '60872504000123');
      await expectLater(
        inserirRecorrencia(uuid: 'r2', pagamento: null),
        violaRestricao,
      );
      await expectLater(
        inserirRecorrencia(uuid: 'r3', cartao: 'k1'),
        violaRestricao,
      );
      await inserirRecorrencia(
        uuid: 'r4',
        tipo: 'faturado',
        cartao: 'k1',
        pagamento: null,
      );
    });

    test('documento do beneficiário é CPF ou CNPJ só com dígitos', () async {
      await expectLater(inserirRecorrencia(documento: '123'), violaRestricao);
      await inserirRecorrencia(documento: '12345678901');
    });

    test('compra faturada: sem parcela de zero centavo', () async {
      await inserirCartao();
      await expectLater(inserirCompraFaturada(valor: 5), violaRestricao);
      await inserirCompraFaturada();
    });

    test('lançamento de recorrência: uma vez por ocorrência', () async {
      await inserirCartao();
      await inserirRecorrencia(tipo: 'faturado', cartao: 'k1', pagamento: null);
      await inserirCompraFaturada(
        valor: 5500,
        parcelas: 1,
        recorrencia: 'r1',
        ocorrencia: '2026-11-25',
      );
      await expectLater(
        inserirCompraFaturada(
          uuid: 'f2',
          valor: 5500,
          parcelas: 1,
          recorrencia: 'r1',
          ocorrencia: '2026-11-25',
        ),
        violaRestricao,
      );
      await expectLater(
        inserirCompraFaturada(uuid: 'f3', recorrencia: 'r1'),
        violaRestricao,
        reason: 'recorrência sem ocorrência',
      );
    });

    test('cartão com compras não é excluído', () async {
      await inserirCartao();
      await inserirCompraFaturada();
      await expectLater(
        banco.customStatement(
          "DELETE FROM tbl_cartoes_credito WHERE uuid_cartao_credito = 'k1'",
        ),
        violaRestricao,
      );
    });

    test('parcelas somem junto com a compra', () async {
      await inserirCartao();
      await inserirCompraFaturada();
      await banco.customStatement(
        'INSERT INTO tbl_parcela VALUES '
        "('p1', 'f1', 1, 20000, 12, 2026), ('p2', 'f1', 2, 20000, 1, 2027)",
      );
      await banco.customStatement(
        "DELETE FROM tbl_compra_faturada WHERE uuid_compra_faturada = 'f1'",
      );
      final restantes = await banco.select(banco.tblParcela).get();
      expect(restantes, isEmpty);
    });

    test('renda: uma vigência por mês', () async {
      Future<void> inserirRenda(String uuid) => banco.customStatement(
        'INSERT INTO tbl_renda VALUES (?, 500000, 80000, 11, 2026, ?, ?)',
        [uuid, _agora, _agora],
      );
      await inserirRenda('n1');
      await expectLater(inserirRenda('n2'), violaRestricao);
    });
  });
}
