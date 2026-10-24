import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:ravix/data/banco.dart';
import 'package:ravix/data/compra_avista_repository.dart';

/// Banco novo em memória, com a carga inicial e as mesmas PRAGMAs do app.
BancoRavix bancoEmMemoria() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return BancoRavix(NativeDatabase.memory(setup: configurarConexao));
}

/// Dados de um gasto à vista com valores padrão para os testes.
DadosCompraAvista gasto({
  DateTime? momento,
  String descricao = 'Padaria do Zé',
  int valorCentavos = 1250,
  TipoPagamento tipoPagamento = TipoPagamento.pix,
  int idSubcategoria = 101,
  String? uuidTag,
}) => (
  momento: momento ?? DateTime(2026, 10, 15, 8, 30),
  descricao: descricao,
  valorCentavos: valorCentavos,
  tipoPagamento: tipoPagamento,
  idSubcategoria: idSubcategoria,
  uuidTag: uuidTag,
);
