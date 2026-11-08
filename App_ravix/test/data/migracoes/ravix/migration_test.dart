// Testes das migrações do banco, sobre os schemas exportados em
// drift_schemas/ (gerados por `dart run drift_dev make-migrations`).
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ravix/data/banco.dart';

import 'generated/schema.dart';
import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verificador;

  setUpAll(() => verificador = SchemaVerifier(GeneratedHelper()));

  group('esquema migrado igual ao criado do zero', () {
    const versoes = GeneratedHelper.versions;
    for (final (i, de) in versoes.indexed) {
      for (final para in versoes.skip(i + 1)) {
        test('$de → $para', () async {
          final schema = await verificador.schemaAt(de);
          final db = BancoRavix(schema.newConnection());
          await verificador.migrateAndValidate(db, para);
          await db.close();
        });
      }
    }
  });

  test('1 → 2 preserva categorias, tags e gastos à vista', () async {
    const categorias = [
      v1.TblCategoriaData(idCategoria: 1, nome: 'Alimentação'),
    ];
    const subcategorias = [
      v1.TblSubcategoriaData(
        idSubcategoria: 101,
        idCategoria: 1,
        nome: 'Padaria',
      ),
      v1.TblSubcategoriaData(
        idSubcategoria: 104,
        idCategoria: 1,
        nome: 'Delivery',
      ),
    ];
    const tags = [
      v1.TblTagData(
        uuidTag: 'tag-1',
        nome: 'Viagem',
        status: 'arquivada',
        criadoEm: '2026-10-01T12:00:00Z',
        atualizadoEm: '2026-10-02T12:00:00Z',
      ),
    ];
    const gastos = [
      v1.TblCompraAvistaData(
        uuidCompraAvista: 'gasto-1',
        timestampCompraAvista: '2026-10-15T08:30:00',
        fusoMinutos: -180,
        descricao: 'Padaria do Zé',
        descricaoNormalizada: 'padaria do ze',
        valorCompraAvista: 1250,
        tipoPagamento: 'pix',
        idSubcategoria: 101,
        criadoEm: '2026-10-15T11:30:00Z',
        atualizadoEm: '2026-10-15T11:30:00Z',
      ),
      v1.TblCompraAvistaData(
        uuidCompraAvista: 'gasto-2',
        timestampCompraAvista: '2026-10-20T21:05:00',
        fusoMinutos: -180,
        descricao: 'iFood',
        descricaoNormalizada: 'ifood',
        valorCompraAvista: 5650,
        tipoPagamento: 'voucher',
        idSubcategoria: 104,
        uuidTag: 'tag-1',
        criadoEm: '2026-10-21T00:05:00Z',
        atualizadoEm: '2026-10-22T10:00:00Z',
      ),
    ];

    await verificador.testWithDataIntegrity(
      oldVersion: 1,
      newVersion: 2,
      createOld: v1.DatabaseAtV1.new,
      createNew: v2.DatabaseAtV2.new,
      openTestedDatabase: BancoRavix.new,
      createItems: (batch, antigo) {
        batch
          ..insertAll(antigo.tblCategoria, categorias)
          ..insertAll(antigo.tblSubcategoria, subcategorias)
          ..insertAll(antigo.tblTag, tags)
          ..insertAll(antigo.tblCompraAvista, gastos);
      },
      validateItems: (novo) async {
        expect(await novo.select(novo.tblCategoria).get(), [
          for (final c in categorias)
            v2.TblCategoriaData(idCategoria: c.idCategoria, nome: c.nome),
        ]);
        expect(await novo.select(novo.tblSubcategoria).get(), hasLength(2));
        expect(await novo.select(novo.tblTag).get(), [
          for (final t in tags)
            v2.TblTagData(
              uuidTag: t.uuidTag,
              nome: t.nome,
              status: t.status,
              criadoEm: t.criadoEm,
              atualizadoEm: t.atualizadoEm,
            ),
        ]);
        // Mesmos valores; as colunas da recorrência chegam nulas.
        expect(await novo.select(novo.tblCompraAvista).get(), [
          for (final g in gastos)
            v2.TblCompraAvistaData(
              uuidCompraAvista: g.uuidCompraAvista,
              timestampCompraAvista: g.timestampCompraAvista,
              fusoMinutos: g.fusoMinutos,
              descricao: g.descricao,
              descricaoNormalizada: g.descricaoNormalizada,
              valorCompraAvista: g.valorCompraAvista,
              tipoPagamento: g.tipoPagamento,
              idSubcategoria: g.idSubcategoria,
              uuidTag: g.uuidTag,
              criadoEm: g.criadoEm,
              atualizadoEm: g.atualizadoEm,
            ),
        ]);
      },
    );
  });

  test('2 aceita boleto no à vista depois da migração', () async {
    final schema = await verificador.schemaAt(1);
    final db = BancoRavix(schema.newConnection());
    await verificador.migrateAndValidate(db, 2);

    await db.customStatement(
      "INSERT INTO tbl_categoria VALUES (6, 'Contas a pagar')",
    );
    await db.customStatement(
      "INSERT INTO tbl_subcategoria VALUES (602, 6, 'Contas de Consumo')",
    );
    await db.customStatement('''
      INSERT INTO tbl_compra_avista (
        uuid_compra_avista, timestamp_compra_avista, fuso_minutos, descricao,
        descricao_normalizada, valor_compra_avista, tipo_pagamento,
        id_subcategoria, criado_em, atualizado_em
      ) VALUES (
        'gasto-boleto', '2026-11-05T10:00:00', -180, 'Internet', 'internet',
        11990, 'boleto', 602, '2026-11-05T13:00:00Z', '2026-11-05T13:00:00Z'
      )''');

    expect(await db.select(db.tblCompraAvista).get(), hasLength(1));
    await db.close();
  });
}
