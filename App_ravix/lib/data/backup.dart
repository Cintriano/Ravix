import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:ravix/core/ambiente.dart';
import 'package:ravix/data/banco.dart';
import 'package:sqlite3/sqlite3.dart';

/// Nome do arquivo de backup com data e hora, ex.:
/// `ravix_v1_backup_20261108-1530.sqlite`.
String nomeDoBackup(int versao, DateTime momento) {
  String dois(int n) => n.toString().padLeft(2, '0');
  final data = '${momento.year}${dois(momento.month)}${dois(momento.day)}';
  final hora = '${dois(momento.hour)}${dois(momento.minute)}';
  return 'ravix_v${versao}_backup_$data-$hora.sqlite';
}

/// Copia o banco em [arquivo] antes de uma migração para [versaoAlvo].
///
/// Só copia se o banco existe e está numa versão anterior; devolve a cópia
/// ou `null`. A cópia é feita com `VACUUM INTO`, que grava um arquivo único
/// e consistente, já com o que estava no WAL. Fica na mesma pasta do banco.
File? copiarAntesDeMigrar(
  File arquivo, {
  required int versaoAlvo,
  required DateTime momento,
}) {
  if (!arquivo.existsSync()) return null;
  final db = sqlite3.open(arquivo.path);
  try {
    final versao =
        db.select('PRAGMA user_version').single.values.single! as int;
    if (versao == 0 || versao >= versaoAlvo) return null;
    final copia = File(
      p.join(arquivo.parent.path, nomeDoBackup(versao, momento)),
    );
    if (copia.existsSync()) copia.deleteSync();
    db.execute('VACUUM INTO ?', [copia.path]);
    return copia;
  } finally {
    db.close();
  }
}

/// Exporta o banco do app para um arquivo avulso, para o usuário guardar
/// fora do aparelho (Configuração → Exportar backup).
final class BackupRepository {
  /// Cria o repositório. O arquivo exportado vai para a pasta devolvida por
  /// `pastaTemporaria`.
  new(this._banco, {required this._relogio, required this._pastaTemporaria});

  final BancoRavix _banco;
  final Relogio _relogio;
  final Future<Directory> Function() _pastaTemporaria;

  /// Grava uma cópia consistente do banco e devolve o arquivo.
  Future<File> exportar() async {
    final pasta = await _pastaTemporaria();
    final arquivo = File(
      p.join(pasta.path, nomeDoBackup(_banco.schemaVersion, _relogio.agora())),
    );
    if (arquivo.existsSync()) await arquivo.delete();
    await _banco.customStatement('VACUUM INTO ?', [arquivo.path]);
    return arquivo;
  }
}
