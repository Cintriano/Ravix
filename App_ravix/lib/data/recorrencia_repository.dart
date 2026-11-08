import 'package:drift/drift.dart';
import 'package:ravix/core/ambiente.dart';
import 'package:ravix/core/datas.dart';
import 'package:ravix/core/texto.dart';
import 'package:ravix/data/banco.dart';
import 'package:ravix/data/compra_avista_repository.dart';
import 'package:ravix/data/faturado_repository.dart';

/// Periodicidade de uma cobrança recorrente.
enum Periodicidade {
  /// Uma vez por mês, no dia de cobrança.
  mensal('mensal'),

  /// Uma vez por ano, no mês de início e no dia de cobrança.
  anual('anual');

  new(this.codigo);

  /// Código gravado em `periodicidade`.
  final String codigo;

  /// Periodicidade pelo [codigo].
  static Periodicidade deCodigo(String codigo) =>
      values.firstWhere((p) => p.codigo == codigo);
}

/// Situação de uma recorrência (E01-F12-T01).
enum SituacaoRecorrencia {
  /// Gera previstos e lançamentos.
  ativa('ativa'),

  /// Parada por um tempo; não gera nada até ser retomada.
  pausada('pausada'),

  /// Encerrada; o histórico fica.
  cancelada('cancelada');

  new(this.codigo);

  /// Código gravado em `status`.
  final String codigo;

  /// Situação pelo [codigo].
  static SituacaoRecorrencia deCodigo(String codigo) =>
      values.firstWhere((s) => s.codigo == codigo);
}

/// Regra de uma cobrança recorrente (DP-13). No faturado, `uuidCartao` é
/// obrigatório e `tipoPagamento` nulo; no à vista, o contrário.
typedef DadosRecorrencia = ({
  String descricao,
  int valorCentavos,
  int idSubcategoria,
  Periodicidade periodicidade,
  int diaCobranca,
  DateTime inicio,
  DateTime? fim,
  String? uuidCartao,
  TipoPagamento? tipoPagamento,
  String? documentoBeneficiario,
});

/// Uma cobrança prevista: a `regra` na data `ocorrencia`.
typedef Prevista = ({Recorrencia regra, DateTime ocorrencia});

/// Datas em que [regra] cobra dentro de [mes], respeitando início, fim e
/// periodicidade. Dia 29 a 31 em mês mais curto cai no último dia. Uma
/// cobrança antes do dia de início não conta: a regra ainda não existia.
List<DateTime> ocorrenciasNoMes(Recorrencia regra, Mes mes) {
  final inicio = deIsoData(regra.dataInicio);
  if (regra.periodicidade == Periodicidade.anual.codigo &&
      mes.mes != inicio.month) {
    return const [];
  }
  final dia = regra.diaCobranca.clamp(1, ultimoDiaDo(mes));
  final data = DateTime(mes.ano, mes.mes, dia);
  final fim = regra.dataFim == null ? null : deIsoData(regra.dataFim!);
  if (data.isBefore(inicio) || (fim != null && data.isAfter(fim))) {
    return const [];
  }
  return [data];
}

/// Recorrências e seus lançamentos (DP-13, DP-25; E02-F04, E01-F12).
///
/// A regra fica em `tbl_recorrencia`; os previstos são calculados. No
/// faturado, cada cobrança vira lançamento sozinha no dia
/// ([materializarFaturadas]); no à vista, só quando o usuário registra o
/// pagamento ([registrarAvista]).
final class RecorrenciaRepository {
  /// Cria o repositório sobre o banco do app.
  new(
    this._banco, {
    required this._relogio,
    required this._uuid,
    required this._fuso,
  });

  final BancoRavix _banco;
  final Relogio _relogio;
  final GeradorUuid _uuid;
  final Fuso _fuso;

  /// Grava uma regra ativa e devolve o UUID.
  Future<String> criar(DadosRecorrencia dados) async {
    final uuid = _uuid.gerar();
    final agora = paraIsoUtc(_relogio.agora());
    await _banco
        .into(_banco.tblRecorrencia)
        .insert(
          TblRecorrenciaCompanion.insert(
            uuidRecorrencia: uuid,
            tipoRegistro: dados.uuidCartao == null ? 'avista' : 'faturado',
            uuidCartaoCredito: Value(dados.uuidCartao),
            tipoPagamento: Value(dados.tipoPagamento?.codigo),
            documentoBeneficiario: Value(dados.documentoBeneficiario),
            descricao: dados.descricao.trim(),
            descricaoNormalizada: normalizarTexto(dados.descricao),
            valorRecorrencia: dados.valorCentavos,
            idSubcategoria: dados.idSubcategoria,
            periodicidade: dados.periodicidade.codigo,
            diaCobranca: dados.diaCobranca,
            dataInicio: paraIsoData(dados.inicio),
            dataFim: Value(dados.fim == null ? null : paraIsoData(dados.fim!)),
            criadoEm: agora,
            atualizadoEm: agora,
          ),
        );
    return uuid;
  }

  /// Regra pelo UUID, ou `null`.
  Future<Recorrencia?> buscar(String uuid) => (_banco.select(
    _banco.tblRecorrencia,
  )..where((r) => r.uuidRecorrencia.equals(uuid))).getSingleOrNull();

  /// Todas as regras, ativas primeiro, em ordem alfabética (E01-F12-T01).
  Stream<List<Recorrencia>> observarTodas() =>
      (_banco.select(_banco.tblRecorrencia)..orderBy([
            (r) => OrderingTerm.asc(r.status),
            (r) =>
                OrderingTerm(expression: r.descricao.collate(Collate.noCase)),
          ]))
          .watch();

  /// Troca a situação da regra (pausar, retomar, cancelar). Cancelar grava
  /// a data de fim em hoje; o histórico fica (E01-F12-T02).
  Future<void> mudarSituacao(String uuid, SituacaoRecorrencia situacao) async {
    final agora = _relogio.agora();
    await (_banco.update(
      _banco.tblRecorrencia,
    )..where((r) => r.uuidRecorrencia.equals(uuid))).write(
      TblRecorrenciaCompanion(
        status: Value(situacao.codigo),
        dataFim: situacao == SituacaoRecorrencia.cancelada
            ? Value(paraIsoData(agora))
            : const Value.absent(),
        atualizadoEm: Value(paraIsoUtc(agora)),
      ),
    );
  }

  /// "Este e os próximos" (DP-25): encerra a regra [uuid] na véspera de
  /// [aPartirDe] e cria uma regra nova com [dados] começando nela. Os
  /// lançamentos anteriores não mudam. Devolve o UUID da regra que vale a
  /// partir de [aPartirDe].
  ///
  /// Se [aPartirDe] é o dia de início (ou antes), não há passado a
  /// preservar na regra: ela é atualizada no lugar, e os lançamentos já
  /// feitos continuam com os valores deles.
  Future<String> alterarDaqui(
    String uuid,
    DateTime aPartirDe,
    DadosRecorrencia dados,
  ) => _banco.transaction(() async {
    final atual = await buscar(uuid);
    if (atual == null) throw StateError('Recorrência $uuid não existe');
    final desdeOInicio = !DateTime(
      aPartirDe.year,
      aPartirDe.month,
      aPartirDe.day,
    ).isAfter(deIsoData(atual.dataInicio));
    if (desdeOInicio) {
      await (_banco.update(
        _banco.tblRecorrencia,
      )..where((r) => r.uuidRecorrencia.equals(uuid))).write(
        TblRecorrenciaCompanion(
          descricao: Value(dados.descricao.trim()),
          descricaoNormalizada: Value(normalizarTexto(dados.descricao)),
          valorRecorrencia: Value(dados.valorCentavos),
          idSubcategoria: Value(dados.idSubcategoria),
          periodicidade: Value(dados.periodicidade.codigo),
          diaCobranca: Value(dados.diaCobranca),
          dataFim: Value(dados.fim == null ? null : paraIsoData(dados.fim!)),
          atualizadoEm: Value(paraIsoUtc(_relogio.agora())),
        ),
      );
      return uuid;
    }
    await encerrarAntesDe(uuid, aPartirDe);
    return await criar((
      descricao: dados.descricao,
      valorCentavos: dados.valorCentavos,
      idSubcategoria: dados.idSubcategoria,
      periodicidade: dados.periodicidade,
      diaCobranca: dados.diaCobranca,
      inicio: aPartirDe,
      fim: dados.fim,
      uuidCartao: dados.uuidCartao,
      tipoPagamento: dados.tipoPagamento,
      documentoBeneficiario: dados.documentoBeneficiario,
    ));
  });

  /// Encerra a regra [uuid] na véspera de [data]: as cobranças a partir dela
  /// deixam de existir; as anteriores ficam. Se [data] é o início (ou
  /// antes), a regra é cancelada inteira.
  Future<void> encerrarAntesDe(String uuid, DateTime data) async {
    final atual = await buscar(uuid);
    if (atual == null) throw StateError('Recorrência $uuid não existe');
    final vespera = DateTime(data.year, data.month, data.day - 1);
    final agora = Value(paraIsoUtc(_relogio.agora()));
    final antesDoInicio = vespera.isBefore(deIsoData(atual.dataInicio));
    await (_banco.update(
      _banco.tblRecorrencia,
    )..where((r) => r.uuidRecorrencia.equals(uuid))).write(
      antesDoInicio
          ? TblRecorrenciaCompanion(
              status: const Value('cancelada'),
              dataFim: Value(atual.dataInicio),
              atualizadoEm: agora,
            )
          : TblRecorrenciaCompanion(
              dataFim: Value(paraIsoData(vespera)),
              atualizadoEm: agora,
            ),
    );
  }

  /// Muda a regra [uuid] a partir de hoje (E01-F12-T03): valor, dia de
  /// cobrança e subcategoria valem para as próximas cobranças; as já
  /// lançadas ficam como estão. Devolve o UUID da regra que vale agora.
  Future<String> editarDaquiPraFrente(
    String uuid, {
    required int valorCentavos,
    required int diaCobranca,
    required int idSubcategoria,
  }) async {
    final atual = await buscar(uuid);
    if (atual == null) throw StateError('Recorrência $uuid não existe');
    final agora = _relogio.agora();
    final hoje = DateTime(agora.year, agora.month, agora.day);
    return await alterarDaqui(uuid, hoje, (
      descricao: atual.descricao,
      valorCentavos: valorCentavos,
      idSubcategoria: idSubcategoria,
      periodicidade: Periodicidade.deCodigo(atual.periodicidade),
      diaCobranca: diaCobranca,
      inicio: hoje,
      fim: atual.dataFim == null ? null : deIsoData(atual.dataFim!),
      uuidCartao: atual.uuidCartaoCredito,
      tipoPagamento: atual.tipoPagamento == null
          ? null
          : TipoPagamento.deCodigo(atual.tipoPagamento!),
      documentoBeneficiario: atual.documentoBeneficiario,
    ));
  }

  /// "Este e os próximos" ao editar um lançamento (E01-F03-T12): as
  /// cobranças depois de [ocorrencia] passam a usar [valorCentavos] e
  /// [idSubcategoria]. O lançamento editado já tem os valores novos.
  Future<String> aplicarAosProximos(
    String uuid, {
    required DateTime ocorrencia,
    required int valorCentavos,
    required int idSubcategoria,
  }) async {
    final atual = await buscar(uuid);
    if (atual == null) throw StateError('Recorrência $uuid não existe');
    final seguinte = DateTime(
      ocorrencia.year,
      ocorrencia.month,
      ocorrencia.day + 1,
    );
    return await alterarDaqui(uuid, seguinte, (
      descricao: atual.descricao,
      valorCentavos: valorCentavos,
      idSubcategoria: idSubcategoria,
      periodicidade: Periodicidade.deCodigo(atual.periodicidade),
      diaCobranca: atual.diaCobranca,
      inicio: seguinte,
      fim: atual.dataFim == null ? null : deIsoData(atual.dataFim!),
      uuidCartao: atual.uuidCartaoCredito,
      tipoPagamento: atual.tipoPagamento == null
          ? null
          : TipoPagamento.deCodigo(atual.tipoPagamento!),
      documentoBeneficiario: atual.documentoBeneficiario,
    ));
  }

  /// "Este e os próximos" ao excluir (E01-F03-T12): apaga o lançamento de
  /// [ocorrencia] e encerra a regra antes dela.
  Future<void> excluirDaqui(String uuid, DateTime ocorrencia) =>
      _banco.transaction(() async {
        await pular(uuid, ocorrencia);
        await encerrarAntesDe(uuid, ocorrencia);
      });

  /// Exclui a regra se nenhum lançamento a usa; senão, cancela. Devolve
  /// `true` se excluiu.
  Future<bool> remover(String uuid) => _banco.transaction(() async {
    final usos = await _banco
        .customSelect(
          'SELECT (SELECT COUNT(*) FROM tbl_compra_avista '
          'WHERE uuid_recorrencia = ?1) + (SELECT COUNT(*) FROM '
          'tbl_compra_faturada WHERE uuid_recorrencia = ?1) AS n',
          variables: [Variable.withString(uuid)],
        )
        .getSingle();
    if (usos.read<int>('n') == 0) {
      await (_banco.delete(
        _banco.tblRecorrencia,
      )..where((r) => r.uuidRecorrencia.equals(uuid))).go();
      return true;
    }
    await mudarSituacao(uuid, SituacaoRecorrencia.cancelada);
    return false;
  });

  /// Cobranças à vista previstas em [mes] que ainda não foram registradas
  /// nem puladas, por data (E01-F04-T07).
  Future<List<Prevista>> previstasAvista(Mes mes) =>
      _previstas(mes, tipo: 'avista');

  /// Igual a [previstasAvista], observando mudanças nas regras, nos gastos
  /// e nas exceções.
  Stream<List<Prevista>> observarPrevistasAvista(Mes mes) async* {
    yield await previstasAvista(mes);
    await for (final _ in _banco.tableUpdates(
      TableUpdateQuery.onAllTables([
        _banco.tblRecorrencia,
        _banco.tblCompraAvista,
        _banco.tblRecorrenciaExcecao,
      ]),
    )) {
      yield await previstasAvista(mes);
    }
  }

  /// Igual a [previstasAvista], para as do cartão (aba faturada).
  Future<List<Prevista>> previstasFaturadas(Mes mes) =>
      _previstas(mes, tipo: 'faturado');

  /// Registra o pagamento de uma cobrança à vista prevista: grava o
  /// lançamento ligado à ocorrência, com [momento], [valorCentavos] e
  /// [tipoPagamento] (editáveis no formulário). Devolve o UUID do gasto.
  Future<String> registrarAvista(
    Prevista prevista, {
    required DateTime momento,
    required int valorCentavos,
    required TipoPagamento tipoPagamento,
  }) async {
    final uuid = _uuid.gerar();
    final agora = paraIsoUtc(_relogio.agora());
    final regra = prevista.regra;
    await _banco
        .into(_banco.tblCompraAvista)
        .insert(
          TblCompraAvistaCompanion.insert(
            uuidCompraAvista: uuid,
            timestampCompraAvista: paraIsoLocal(momento),
            fusoMinutos: _fuso.minutosAtuais(),
            descricao: regra.descricao,
            descricaoNormalizada: regra.descricaoNormalizada,
            valorCompraAvista: valorCentavos,
            tipoPagamento: tipoPagamento.codigo,
            idSubcategoria: regra.idSubcategoria,
            uuidRecorrencia: Value(regra.uuidRecorrencia),
            ocorrencia: Value(paraIsoData(prevista.ocorrencia)),
            criadoEm: agora,
            atualizadoEm: agora,
          ),
        );
    return uuid;
  }

  /// "Só este" ao excluir (DP-25): pula a ocorrência e apaga o lançamento
  /// dela, se existir.
  Future<void> pular(String uuidRecorrencia, DateTime ocorrencia) =>
      _banco.transaction(() async {
        final data = paraIsoData(ocorrencia);
        await _banco
            .into(_banco.tblRecorrenciaExcecao)
            .insertOnConflictUpdate(
              TblRecorrenciaExcecaoCompanion.insert(
                uuidRecorrencia: uuidRecorrencia,
                ocorrencia: data,
                criadoEm: paraIsoUtc(_relogio.agora()),
              ),
            );
        await (_banco.delete(_banco.tblCompraAvista)..where(
              (c) =>
                  c.uuidRecorrencia.equals(uuidRecorrencia) &
                  c.ocorrencia.equals(data),
            ))
            .go();
        await (_banco.delete(_banco.tblCompraFaturada)..where(
              (c) =>
                  c.uuidRecorrencia.equals(uuidRecorrencia) &
                  c.ocorrencia.equals(data),
            ))
            .go();
      });

  /// Grava como lançamento cada cobrança do cartão com data até hoje que
  /// ainda não existe (DP-25): o cartão cobra sozinho. Roda ao abrir o app;
  /// o índice único impede duplicar. Devolve quantos lançamentos criou.
  Future<int> materializarFaturadas() => _banco.transaction(() async {
    final hoje = _relogio.agora();
    final regras =
        await (_banco.select(_banco.tblRecorrencia)..where(
              (r) =>
                  r.tipoRegistro.equals('faturado') & r.status.equals('ativa'),
            ))
            .get();
    var criados = 0;
    for (final regra in regras) {
      final cartao =
          await (_banco.select(_banco.tblCartoesCredito)..where(
                (c) => c.uuidCartaoCredito.equals(regra.uuidCartaoCredito!),
              ))
              .getSingle();
      final ja = await _jaTratadas(regra.uuidRecorrencia);
      var mes = Mes.de(deIsoData(regra.dataInicio));
      final ate = Mes.de(hoje);
      while (mes.compareTo(ate) <= 0) {
        for (final data in ocorrenciasNoMes(regra, mes)) {
          if (data.isAfter(hoje) || ja.contains(paraIsoData(data))) continue;
          await _lancarFaturada(regra, cartao, data);
          criados++;
        }
        mes = mes.proximo;
      }
    }
    return criados;
  });

  Future<void> _lancarFaturada(
    Recorrencia regra,
    CartaoCredito cartao,
    DateTime data,
  ) async {
    final uuid = _uuid.gerar();
    final agora = paraIsoUtc(_relogio.agora());
    final vencimento = sugerirVencimento(
      data,
      diaFechamento: cartao.diaFechamento,
      diaVencimento: cartao.diaVencimento,
    );
    await _banco
        .into(_banco.tblCompraFaturada)
        .insert(
          TblCompraFaturadaCompanion.insert(
            uuidCompraFaturada: uuid,
            uuidCartaoCredito: cartao.uuidCartaoCredito,
            uuidRecorrencia: Value(regra.uuidRecorrencia),
            ocorrencia: Value(paraIsoData(data)),
            timestampCompraFaturada: paraIsoLocal(data),
            fusoMinutos: _fuso.minutosAtuais(),
            descricao: regra.descricao,
            descricaoNormalizada: regra.descricaoNormalizada,
            valorTotal: regra.valorRecorrencia,
            quantParcela: 1,
            mesVencimento: vencimento.mes,
            anoVencimento: vencimento.ano,
            idSubcategoria: regra.idSubcategoria,
            criadoEm: agora,
            atualizadoEm: agora,
          ),
        );
    await _banco
        .into(_banco.tblParcela)
        .insert(
          TblParcelaCompanion.insert(
            uuidParcela: _uuid.gerar(),
            uuidCompraFaturada: uuid,
            numeroParcela: 1,
            valorParcela: regra.valorRecorrencia,
            mesVencimento: vencimento.mes,
            anoVencimento: vencimento.ano,
          ),
        );
  }

  Future<List<Prevista>> _previstas(Mes mes, {required String tipo}) async {
    final regras =
        await (_banco.select(_banco.tblRecorrencia)..where(
              (r) => r.tipoRegistro.equals(tipo) & r.status.equals('ativa'),
            ))
            .get();
    final previstas = <Prevista>[];
    for (final regra in regras) {
      final ja = await _jaTratadas(regra.uuidRecorrencia);
      for (final data in ocorrenciasNoMes(regra, mes)) {
        if (!ja.contains(paraIsoData(data))) {
          previstas.add((regra: regra, ocorrencia: data));
        }
      }
    }
    previstas.sort((a, b) => a.ocorrencia.compareTo(b.ocorrencia));
    return previstas;
  }

  /// Ocorrências da regra já lançadas ou puladas.
  Future<Set<String>> _jaTratadas(String uuid) async {
    final linhas = await _banco
        .customSelect(
          'SELECT ocorrencia FROM tbl_compra_avista '
          'WHERE uuid_recorrencia = ?1 '
          'UNION SELECT ocorrencia FROM tbl_compra_faturada '
          'WHERE uuid_recorrencia = ?1 '
          'UNION SELECT ocorrencia FROM tbl_recorrencia_excecao '
          'WHERE uuid_recorrencia = ?1',
          variables: [Variable.withString(uuid)],
          readsFrom: {
            _banco.tblCompraAvista,
            _banco.tblCompraFaturada,
            _banco.tblRecorrenciaExcecao,
          },
        )
        .get();
    return {for (final l in linhas) l.read<String>('ocorrencia')};
  }
}
