import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:ravix/core/datas.dart';
import 'package:ravix/data/banco.dart';
import 'package:ravix/data/compra_avista_repository.dart';
import 'package:ravix/data/fatura_repository.dart';

/// Total à vista de um dia numa forma de pagamento.
typedef AvistaDoDia = ({DateTime dia, TipoPagamento forma, int total});

/// Leitura do à vista para a visão macro (E01-F06).
final class MacroRepository {
  /// Cria o repositório sobre o banco do app.
  new(this._banco);

  final BancoRavix _banco;

  /// Gastos à vista de [mes] somados por dia e forma de pagamento.
  Stream<List<AvistaDoDia>> observarAvistaPorDia(Mes mes) => _banco
      .customSelect(
        '''
        SELECT substr(timestamp_compra_avista, 1, 10) AS dia, tipo_pagamento,
          SUM(valor_compra_avista) AS total
        FROM tbl_compra_avista
        WHERE timestamp_compra_avista >= ?1 AND timestamp_compra_avista < ?2
        GROUP BY dia, tipo_pagamento
        ORDER BY dia
        ''',
        variables: [
          Variable.withString(mes.inicioIso),
          Variable.withString(mes.fimIso),
        ],
        readsFrom: {_banco.tblCompraAvista},
      )
      .watch()
      .map(
        (linhas) => [
          for (final l in linhas)
            (
              dia: deIsoData(l.read<String>('dia')),
              forma: TipoPagamento.deCodigo(l.read<String>('tipo_pagamento')),
              total: l.read<int>('total'),
            ),
        ],
      );
}

/// Base de comparação da visão macro (E01-F06-T02, DP-1).
enum BaseComparacao {
  /// Salário + voucher (+ ganhos extras na v3). Padrão.
  rendaTotal('Renda total'),

  /// Só o salário; o à vista pago com voucher sai do consumo.
  soSalario('Só salário');

  new(this.rotulo);

  /// Nome no seletor.
  final String rotulo;
}

/// Mês em relação a hoje.
enum PeriodoDoMes {
  /// Já fechado: resultado final, ritmo 100%.
  passado,

  /// Em andamento: parcial, farol pelo ritmo.
  atual,

  /// Ainda não começou: só o comprometido, sem farol.
  futuro,
}

/// Cor do farol (DP-10).
enum Farol {
  /// Consumo até o ritmo.
  verde,

  /// Até 10 pontos acima do ritmo.
  amarelo,

  /// Mais de 10 pontos acima do ritmo.
  vermelho,
}

/// Cor do farol para [porcento] consumido no [ritmo], ambos de 0 a 100+.
Farol farolDe(double porcento, double ritmo) {
  if (porcento <= ritmo) return Farol.verde;
  if (porcento <= ritmo + 10) return Farol.amarelo;
  return Farol.vermelho;
}

/// Fatura de um cartão no mês, com o dia em que entra no consumo.
typedef FaturaNaMacro = ({String nomeCartao, int valor, DateTime dia});

/// Resultado da visão macro de um mês (E01-F06).
typedef Macro = ({
  PeriodoDoMes periodo,

  /// Faturas que já entraram no consumo (venceram ou foram pagas).
  int faturado,

  /// Faturas do mês que ainda vão vencer (só no mês atual).
  int faturadoAVencer,

  /// À vista do mês, pela base: sem o voucher na base só salário.
  int avista,

  /// À vista por forma de pagamento, todas as formas.
  Map<TipoPagamento, int> avistaPorForma,

  /// Faturado + à vista que entram na base.
  int consumo,

  /// Valor da base, ou `null` sem renda cadastrada.
  int? base,

  /// Consumo ÷ base × 100, ou `null` sem base.
  double? porcento,

  /// Dia atual ÷ dias do mês × 100; 100 em mês fechado; `null` no futuro.
  double? ritmo,

  /// Cor do farol; `null` no futuro ou sem base.
  Farol? farol,

  /// Base − consumo; negativo quando o consumo passa da base.
  int? superavit,

  /// Consumo acumulado em cada dia do mês até hoje (índice 0 = dia 1).
  List<int> serie,
});

/// Calcula a visão macro de [mes] em [hoje] (E01-F06-T01 a T05).
///
/// A fatura entra como degrau no dia do vencimento (DP-9), ou no dia do
/// pagamento, se foi paga antes. Sem dia de vencimento conhecido, entra no
/// último dia do mês. No mês atual, as que ainda não venceram ficam em
/// `faturadoAVencer`, fora do consumo e do farol.
Macro calcularMacro({
  required Mes mes,
  required DateTime hoje,
  required BaseComparacao base,
  required Renda? renda,
  required List<AvistaDoDia> avista,
  required List<FaturaDoCartao> faturas,
}) {
  final mesDeHoje = Mes.de(hoje);
  final periodo = switch (mes.compareTo(mesDeHoje)) {
    < 0 => PeriodoDoMes.passado,
    0 => PeriodoDoMes.atual,
    _ => PeriodoDoMes.futuro,
  };
  final dias = ultimoDiaDo(mes);
  final diaDeHoje = switch (periodo) {
    PeriodoDoMes.passado => dias,
    PeriodoDoMes.atual => hoje.day,
    PeriodoDoMes.futuro => 0,
  };
  final semVoucher = base == BaseComparacao.soSalario;

  final porDia = List.filled(dias, 0);
  final porForma = <TipoPagamento, int>{};
  var totalAvista = 0;
  for (final a in avista) {
    porForma.update(a.forma, (v) => v + a.total, ifAbsent: () => a.total);
    if (semVoucher && a.forma == TipoPagamento.voucher) continue;
    totalAvista += a.total;
    porDia[a.dia.day - 1] += a.total;
  }

  var faturado = 0;
  var aVencer = 0;
  for (final f in faturas) {
    if (f.valor <= 0) continue;
    final dia = diaDaFatura(f, mes);
    final entrou = periodo != PeriodoDoMes.atual || dia.day <= diaDeHoje;
    if (entrou) {
      faturado += f.valor;
      porDia[dia.day - 1] += f.valor;
    } else {
      aVencer += f.valor;
    }
  }

  final serie = <int>[];
  var acumulado = 0;
  for (var d = 0; d < diaDeHoje; d++) {
    acumulado += porDia[d];
    serie.add(acumulado);
  }

  final consumo = faturado + totalAvista;
  final valorBase = switch (renda) {
    null => null,
    final r when semVoucher => r.salario,
    final r => r.salario + r.voucher,
  };
  final porcento = valorBase == null || valorBase == 0
      ? null
      : consumo * 100 / valorBase;
  final ritmo = switch (periodo) {
    PeriodoDoMes.passado => 100.0,
    PeriodoDoMes.atual => diaDeHoje * 100 / dias,
    PeriodoDoMes.futuro => null,
  };
  return (
    periodo: periodo,
    faturado: faturado,
    faturadoAVencer: aVencer,
    avista: totalAvista,
    avistaPorForma: porForma,
    consumo: consumo,
    base: valorBase,
    porcento: porcento,
    ritmo: ritmo,
    farol: porcento == null || ritmo == null ? null : farolDe(porcento, ritmo),
    superavit: valorBase == null ? null : valorBase - consumo,
    serie: serie,
  );
}

/// Dia em que a fatura de [mes] entra no consumo: o pagamento, se foi
/// antes do vencimento; senão, o vencimento; sem ele, o último dia.
DateTime diaDaFatura(FaturaDoCartao fatura, Mes mes) {
  final ultimo = ultimoDiaDo(mes);
  final vencimento = DateTime(
    mes.ano,
    mes.mes,
    math.min(fatura.cartao.diaVencimento ?? ultimo, ultimo),
  );
  final pago = fatura.pagoEm;
  if (pago != null && Mes.de(pago) == mes && pago.isBefore(vencimento)) {
    return DateTime(pago.year, pago.month, pago.day);
  }
  return vencimento;
}
