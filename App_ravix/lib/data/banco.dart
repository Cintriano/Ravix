import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:ravix/data/carga_inicial.dart';
import 'package:sqlite3/sqlite3.dart';

part 'banco.g.dart';

/// Banco local da v1 (SQLite). Esquema em `banco.drift`.
@DriftDatabase(include: {'banco.drift'})
final class BancoRavix extends _$BancoRavix {
  /// Abre o banco sobre o executor [e]. No app, use [abrirBancoRavix]; nos
  /// testes, `NativeDatabase.memory(setup: configurarConexao)`.
  new(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _carregarDominios();
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
