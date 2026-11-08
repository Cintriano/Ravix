import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/internal/versioned_schema.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:ravix/data/banco.steps.dart';
import 'package:ravix/data/carga_inicial.dart';
import 'package:sqlite3/sqlite3.dart';

part 'banco.g.dart';

/// Banco local (SQLite). Esquema em `banco.drift`.
@DriftDatabase(include: {'banco.drift'})
final class BancoRavix extends _$BancoRavix {
  /// Abre o banco sobre o executor [e]. No app, use [abrirBancoRavix]; nos
  /// testes, `NativeDatabase.memory(setup: configurarConexao)`.
  new(super.e);

  /// 1: v1 (à vista e tags). 2: v2 (faturado, recorrências, renda).
  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _carregarDominios();
    },
    onUpgrade: (m, from, to) async {
      // A reconstrução de tabelas exige as FKs desligadas, e o PRAGMA não
      // muda dentro de transação: desliga antes e confere depois.
      await customStatement('PRAGMA foreign_keys = OFF');
      await transaction(
        () => m.runMigrationSteps(from: from, to: to, steps: _passos),
      );
      final quebradas = await customSelect('PRAGMA foreign_key_check').get();
      if (quebradas.isNotEmpty) {
        throw StateError('Migração $from → $to deixou FKs inválidas.');
      }
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  /// Passos de migração, um por versão (`banco.steps.dart`, gerado).
  static final MigrationStepWithVersion _passos = migrationSteps(
    from1To2: (m, schema) async {
      // Tabelas novas antes da reconstrução, que referencia tbl_recorrencia.
      await m.create(schema.tblCartoesCredito);
      await m.create(schema.tblRecorrencia);
      await m.create(schema.tblRecorrenciaExcecao);
      await m.create(schema.tblCompraFaturada);
      await m.create(schema.tblParcela);
      await m.create(schema.tblPagamentoFatura);
      await m.create(schema.tblEstorno);
      await m.create(schema.tblRenda);

      // tbl_compra_avista: boleto no CHECK e colunas da recorrência. As
      // colunas novas são nulas nos registros da v1; nenhum valor muda.
      await m.alterTable(
        TableMigration(
          schema.tblCompraAvista,
          newColumns: [
            schema.tblCompraAvista.uuidRecorrencia,
            schema.tblCompraAvista.ocorrencia,
          ],
        ),
      );

      for (final indice in [
        schema.uxCompraAvistaOcorrencia,
        schema.idxCompraFaturadaCartao,
        schema.idxCompraFaturadaTimestamp,
        schema.idxCompraFaturadaSubcategoria,
        schema.idxCompraFaturadaTag,
        schema.uxCompraFaturadaOcorrencia,
        schema.idxParcelaVencimento,
        schema.idxPagamentoFaturaFatura,
        schema.idxEstornoFatura,
      ]) {
        await m.createIndex(indice);
      }
    },
  );

  Future<void> _carregarDominios() => batch((b) {
    b
      ..insertAll(tblCategoria, [
        for (final c in categoriasIniciais)
          TblCategoriaCompanion.insert(idCategoria: Value(c.id), nome: c.nome),
      ])
      ..insertAll(tblSubcategoria, [
        for (final s in subcategoriasIniciais)
          TblSubcategoriaCompanion.insert(
            idSubcategoria: Value(s.id),
            idCategoria: s.idCategoria,
            nome: s.nome,
          ),
      ]);
  });
}

/// PRAGMAs aplicados a toda conexão, antes das migrações (DP-36).
///
/// O SQLite vem com as FKs desligadas; elas precisam ser ligadas em cada
/// conexão.
void configurarConexao(Database db) {
  db
    ..execute('PRAGMA journal_mode = WAL')
    ..execute('PRAGMA synchronous = NORMAL')
    ..execute('PRAGMA foreign_keys = ON');
}

/// Abre o banco do app em `ravix.sqlite`, num isolate separado.
BancoRavix abrirBancoRavix() => BancoRavix(
  LazyDatabase(() async {
    final pasta = await getApplicationDocumentsDirectory();
    return NativeDatabase.createInBackground(
      File(p.join(pasta.path, 'ravix.sqlite')),
      setup: configurarConexao,
    );
  }),
);
