import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:ravix/data/backup.dart';
import 'package:ravix/data/banco.dart';
import 'package:sqlite3/sqlite3.dart';

import '../helpers/ambiente_falso.dart';
import '../helpers/banco_de_teste.dart';
import 'migracoes/ravix/generated/schema_v1.dart' as v1;

void main() {
  late Directory pasta;
  final momento = DateTime(2026, 11, 8, 15, 30);

  setUp(() => pasta = Directory.systemTemp.createTempSync('ravix_backup_'));
  tearDown(() => pasta.deleteSync(recursive: true));

  File banco() => File(p.join(pasta.path, 'ravix.sqlite'));

  void criarBanco(int versao, {int gastos = 0}) {
    final db = sqlite3.open(banco().path)
      ..execute('CREATE TABLE t (x INTEGER)')
      ..execute('PRAGMA user_version = $versao');
    for (var i = 0; i < gastos; i++) {
      db.execute('INSERT INTO t VALUES ($i)');
    }
    db.close();
  }

  int linhas(File arquivo) {
    final db = sqlite3.open(arquivo.path);
    final n = db.select('SELECT COUNT(*) AS n FROM t').single['n'] as int;
    db.close();
    return n;
  }

  test('nome do backup leva a versão, a data e a hora', () {
    expect(nomeDoBackup(1, momento), 'ravix_v1_backup_20261108-1530.sqlite');
  });

  group('cópia antes de migrar', () {
    test('banco antigo: copia com os dados e a versão de origem', () {
      criarBanco(1, gastos: 3);
      final copia = copiarAntesDeMigrar(
        banco(),
        versaoAlvo: 2,
        momento: momento,
      );

      expect(copia, isNotNull);
      expect(p.basename(copia!.path), 'ravix_v1_backup_20261108-1530.sqlite');
      expect(linhas(copia), 3);
      final db = sqlite3.open(copia.path);
      expect(db.select('PRAGMA user_version').single.values.single, 1);
      db.close();
    });

    test('banco já na versão atual, novo ou inexistente: não copia', () {
      expect(
        copiarAntesDeMigrar(banco(), versaoAlvo: 2, momento: momento),
        isNull,
      );
      criarBanco(2);
      expect(
        copiarAntesDeMigrar(banco(), versaoAlvo: 2, momento: momento),
        isNull,
      );
      banco().deleteSync();
      criarBanco(0);
      expect(
        copiarAntesDeMigrar(banco(), versaoAlvo: 2, momento: momento),
        isNull,
      );
      expect(pasta.listSync(), hasLength(1));
    });

    test(
      'banco real da v1: cópia fica na v1 e o banco migra para a 2',
      () async {
        final antigo = v1.DatabaseAtV1(NativeDatabase(banco()));
        await antigo.customStatement(
          "INSERT INTO tbl_categoria VALUES (1, 'Alimentação')",
        );
        await antigo.customStatement(
          "INSERT INTO tbl_subcategoria VALUES (101, 1, 'Padaria')",
        );
        await antigo.customStatement(
          'INSERT INTO tbl_compra_avista VALUES '
          "('g1', '2026-10-15T08:30:00', -180, 'Padaria', 'padaria', 1250, "
          "'pix', 101, NULL, '2026-10-15T11:30:00Z', '2026-10-15T11:30:00Z')",
        );
        await antigo.close();

        final copia = copiarAntesDeMigrar(
          banco(),
          versaoAlvo: BancoRavix.versaoAtual,
          momento: momento,
        )!;
        final atual = BancoRavix(
          NativeDatabase(banco(), setup: configurarConexao),
        );
        expect(await atual.select(atual.tblCompraAvista).get(), hasLength(1));
        await atual.close();

        final db = sqlite3.open(copia.path);
        expect(db.select('PRAGMA user_version').single.values.single, 1);
        expect(db.select('SELECT * FROM tbl_compra_avista'), hasLength(1));
        db.close();
      },
    );
  });

  test('exportar grava uma cópia com todos os registros', () async {
    final db = bancoEmMemoria();
    await db.customStatement(
      'INSERT INTO tbl_compra_avista (uuid_compra_avista, '
      'timestamp_compra_avista, fuso_minutos, descricao, '
      'descricao_normalizada, valor_compra_avista, tipo_pagamento, '
      'id_subcategoria, criado_em, atualizado_em) VALUES '
      "('g1', '2026-11-08T10:00:00', -180, 'Internet', 'internet', 11990, "
      "'boleto', 602, '2026-11-08T13:00:00Z', '2026-11-08T13:00:00Z')",
    );
    final repositorio = BackupRepository(
      db,
      relogio: RelogioFixo(momento),
      pastaTemporaria: () async => pasta,
    );

    final arquivo = await repositorio.exportar();
    await db.close();

    expect(p.basename(arquivo.path), 'ravix_v2_backup_20261108-1530.sqlite');
    final copia = sqlite3.open(arquivo.path);
    expect(copia.select('SELECT * FROM tbl_compra_avista'), hasLength(1));
    expect(copia.select('SELECT * FROM tbl_subcategoria'), hasLength(34));
    copia.close();
  });
}
