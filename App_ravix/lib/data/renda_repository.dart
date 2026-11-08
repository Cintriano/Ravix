import 'package:drift/drift.dart';
import 'package:ravix/core/ambiente.dart';
import 'package:ravix/core/datas.dart';
import 'package:ravix/data/banco.dart';

/// Campos validados da renda (E01-F07-T01, T02).
enum CampoRenda {
  /// Salário.
  salario,

  /// Voucher/benefícios.
  voucher,
}

/// Renda inválida, com a mensagem de cada campo.
final class RendaInvalida implements Exception {
  /// Cria o erro com [erros].
  new(this.erros);

  /// Mensagem por campo.
  final Map<CampoRenda, String> erros;

  @override
  String toString() => erros.values.join(' ');
}

/// O mês a que uma linha de renda se refere.
extension MesDaRenda on Renda {
  /// Mês a partir do qual a renda vale.
  Mes get aPartirDe => Mes(anoReferencia, mesReferencia);
}

/// Salário e voucher por vigência (DP-6): cada linha vale a partir do seu
/// mês até a próxima. Mudar a renda de um mês não altera os anteriores.
final class RendaRepository {
  /// Cria o repositório sobre o banco do app.
  new(this._banco, {required this._relogio, required this._uuid});

  final BancoRavix _banco;
  final Relogio _relogio;
  final GeradorUuid _uuid;

  /// Grava a renda que vale a partir de [aPartirDe]. Se já existe uma
  /// vigência nesse mês, ela é substituída.
  ///
  /// Lança [RendaInvalida].
  Future<void> definir({
    required int salarioCentavos,
    required int voucherCentavos,
    required Mes aPartirDe,
  }) => _banco.transaction(() async {
    final erros = <CampoRenda, String>{
      if (salarioCentavos <= 0)
        CampoRenda.salario: 'Informe um salário maior que zero.',
      if (voucherCentavos < 0)
        CampoRenda.voucher: 'O voucher não pode ser negativo.',
    };
    if (erros.isNotEmpty) throw RendaInvalida(erros);

    final agora = paraIsoUtc(_relogio.agora());
    final existente = await _naReferencia(aPartirDe);
    if (existente != null) {
      await (_banco.update(
        _banco.tblRenda,
      )..where((r) => r.uuidRenda.equals(existente.uuidRenda))).write(
        TblRendaCompanion(
          salario: Value(salarioCentavos),
          voucher: Value(voucherCentavos),
          atualizadoEm: Value(agora),
        ),
      );
      return;
    }
    await _banco
        .into(_banco.tblRenda)
        .insert(
          TblRendaCompanion.insert(
            uuidRenda: _uuid.gerar(),
            salario: salarioCentavos,
            voucher: voucherCentavos,
            mesReferencia: aPartirDe.mes,
            anoReferencia: aPartirDe.ano,
            criadoEm: agora,
            atualizadoEm: agora,
          ),
        );
  });

  /// Apaga a vigência [uuid]. Os meses dela passam a usar a anterior.
  Future<void> remover(String uuid) => (_banco.delete(
    _banco.tblRenda,
  )..where((r) => r.uuidRenda.equals(uuid))).go();

  /// Renda que vale em [mes]: a vigência mais recente até ele, ou `null`.
  Future<Renda?> vigente(Mes mes) => _consultaVigente(mes).getSingleOrNull();

  /// Igual a [vigente], observando mudanças.
  Stream<Renda?> observarVigente(Mes mes) =>
      _consultaVigente(mes).watchSingleOrNull();

  /// Todas as vigências, da mais recente para a mais antiga.
  Stream<List<Renda>> observarHistorico() =>
      (_banco.select(_banco.tblRenda)..orderBy([
            (r) => OrderingTerm.desc(r.anoReferencia),
            (r) => OrderingTerm.desc(r.mesReferencia),
          ]))
          .watch();

  Selectable<Renda> _consultaVigente(Mes mes) => (_banco.select(_banco.tblRenda)
    ..where(
      (r) =>
          r.anoReferencia.isSmallerThanValue(mes.ano) |
          (r.anoReferencia.equals(mes.ano) &
              r.mesReferencia.isSmallerOrEqualValue(mes.mes)),
    )
    ..orderBy([
      (r) => OrderingTerm.desc(r.anoReferencia),
      (r) => OrderingTerm.desc(r.mesReferencia),
    ])
    ..limit(1));

  Future<Renda?> _naReferencia(Mes mes) =>
      (_banco.select(_banco.tblRenda)..where(
            (r) =>
                r.anoReferencia.equals(mes.ano) &
                r.mesReferencia.equals(mes.mes),
          ))
          .getSingleOrNull();
}
