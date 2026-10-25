import 'package:drift/drift.dart';
import 'package:ravix/core/ambiente.dart';
import 'package:ravix/core/datas.dart';
import 'package:ravix/data/banco.dart';

/// Nome de tag vazio.
final class NomeTagVazio implements Exception {
  @override
  String toString() => 'O nome da tag não pode ficar vazio.';
}

/// Já existe uma tag (ativa ou arquivada) com esse nome, ignorando
/// maiúsculas e minúsculas.
final class NomeTagRepetido implements Exception {
  /// Cria o erro para [nome].
  new(this.nome);

  /// Nome que já existe.
  final String nome;

  @override
  String toString() => 'Já existe uma tag chamada "$nome".';
}

/// O que aconteceu ao remover uma tag (E01-F07-T10).
enum RemocaoTag {
  /// Não tinha registros e foi apagada.
  excluida,

  /// Tinha registros e foi arquivada: some dos seletores e continua nos
  /// registros antigos.
  arquivada,
}

final _espacos = RegExp(r'\s+');

/// Tags de contexto (DP-32).
final class TagRepository {
  /// Cria o repositório sobre o banco do app.
  new(this._banco, {required this._relogio, required this._uuid});

  final BancoRavix _banco;
  final Relogio _relogio;
  final GeradorUuid _uuid;

  /// Cria uma tag ativa com [nome] e devolve a tag criada.
  ///
  /// Lança [NomeTagVazio] ou [NomeTagRepetido].
  Future<Tag> criar(String nome) => _banco.transaction(() async {
    final limpo = await _validarNome(nome);
    final agora = paraIsoUtc(_relogio.agora());
    return await _banco
        .into(_banco.tblTag)
        .insertReturning(
          TblTagCompanion.insert(
            uuidTag: _uuid.gerar(),
            nome: limpo,
            criadoEm: agora,
            atualizadoEm: agora,
          ),
        );
  });

  /// Troca o nome da tag [uuid]. Os registros guardam só o UUID e não mudam.
  ///
  /// Lança [NomeTagVazio] ou [NomeTagRepetido].
  Future<void> renomear(String uuid, String nome) =>
      _banco.transaction(() async {
        final limpo = await _validarNome(nome, ignorar: uuid);
        await (_banco.update(
          _banco.tblTag,
        )..where((t) => t.uuidTag.equals(uuid))).write(
          TblTagCompanion(
            nome: Value(limpo),
            atualizadoEm: Value(paraIsoUtc(_relogio.agora())),
          ),
        );
      });

  /// Exclui a tag [uuid] se nenhum registro a usa; senão, arquiva.
  Future<RemocaoTag> remover(String uuid) => _banco.transaction(() async {
    final emUso = await contarUsos(uuid);
    final filtro = _banco.tblTag.uuidTag.equals(uuid);
    if (emUso == 0) {
      await (_banco.delete(_banco.tblTag)..where((_) => filtro)).go();
      return RemocaoTag.excluida;
    }
    await (_banco.update(_banco.tblTag)..where((_) => filtro)).write(
      TblTagCompanion(
        status: const Value('arquivada'),
        atualizadoEm: Value(paraIsoUtc(_relogio.agora())),
      ),
    );
    return RemocaoTag.arquivada;
  });

  /// Quantos gastos usam a tag [uuid]. Decide entre excluir e arquivar.
  Future<int> contarUsos(String uuid) =>
      _banco.contarComprasDaTag(uuidTag: uuid).getSingle();

  /// Todas as tags, ativas e arquivadas, em ordem alfabética (filtro da
  /// tabela, que alcança gastos antigos).
  Stream<List<Tag>> observarTodas() =>
      (_banco.select(_banco.tblTag)..orderBy([
            (t) => OrderingTerm(expression: t.nome.collate(Collate.noCase)),
          ]))
          .watch();

  /// Tags ativas em ordem alfabética, para os seletores.
  Stream<List<Tag>> observarAtivas() => _banco.tagsAtivas().watch();

  /// Tag pelo UUID (ativa ou arquivada), ou `null`.
  Future<Tag?> buscar(String uuid) => (_banco.select(
    _banco.tblTag,
  )..where((t) => t.uuidTag.equals(uuid))).getSingleOrNull();

  // O COLLATE NOCASE do banco só ignora maiúsculas em ASCII ("Rolê" e
  // "ROLÊ" passariam); a comparação aqui cobre os acentuados.
  Future<String> _validarNome(String nome, {String? ignorar}) async {
    final limpo = nome.trim().replaceAll(_espacos, ' ');
    if (limpo.isEmpty) {
      throw NomeTagVazio();
    }
    final chave = limpo.toLowerCase();
    final existentes = await _banco.select(_banco.tblTag).get();
    final repetida = existentes.any(
      (t) => t.uuidTag != ignorar && t.nome.toLowerCase() == chave,
    );
    if (repetida) {
      throw NomeTagRepetido(limpo);
    }
    return limpo;
  }
}
