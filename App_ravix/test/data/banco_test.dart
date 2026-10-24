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
    'INSERT INTO tbl_compra_avista VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
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
    test('cria as 4 tabelas e liga as FKs', () async {
      final tabelas = await banco
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' "
            "AND name LIKE 'tbl_%' ORDER BY name",
          )
          .map((r) => r.read<String>('name'))
          .get();
      expect(tabelas, [
        'tbl_categoria',
        'tbl_compra_avista',
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
}
