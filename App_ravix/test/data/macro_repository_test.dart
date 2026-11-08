import 'package:flutter_test/flutter_test.dart';
import 'package:ravix/core/datas.dart';
import 'package:ravix/data/banco.dart';
import 'package:ravix/data/compra_avista_repository.dart';
import 'package:ravix/data/fatura_repository.dart';
import 'package:ravix/data/macro_repository.dart';

import '../helpers/ambiente_falso.dart';
import '../helpers/banco_de_teste.dart';

void main() {
  const renda = Renda(
    uuidRenda: 'r',
    salario: 500000,
    voucher: 100000,
    mesReferencia: 1,
    anoReferencia: 2026,
    criadoEm: '',
    atualizadoEm: '',
  );

  CartaoCredito cartao({int? vencimento = 5}) => CartaoCredito(
    uuidCartaoCredito: 'c',
    nomeCartao: 'Itaú',
    limiteCartao: 590000,
    diaFechamento: 29,
    diaVencimento: vencimento,
    status: 'ativo',
    criadoEm: '',
    atualizadoEm: '',
  );

  FaturaDoCartao fatura(int valor, {int? vencimento = 5, DateTime? pagoEm}) => (
    cartao: cartao(vencimento: vencimento),
    valor: valor,
    pago: pagoEm == null ? 0 : valor,
    pagoEm: pagoEm,
    consumo: 0,
  );

  AvistaDoDia noDia(
    int dia,
    int total, [
    TipoPagamento f = TipoPagamento.pix,
  ]) => (dia: DateTime(2026, 11, dia), forma: f, total: total);

  Macro calcular({
    DateTime? hoje,
    BaseComparacao base = BaseComparacao.rendaTotal,
    Renda? comRenda,
    bool semRenda = false,
    List<AvistaDoDia> avista = const [],
    List<FaturaDoCartao> faturas = const [],
    Mes? mes,
  }) => calcularMacro(
    mes: mes ?? Mes(2026, 11),
    hoje: hoje ?? DateTime(2026, 11, 10, 12),
    base: base,
    renda: semRenda ? null : comRenda ?? renda,
    avista: avista,
    faturas: faturas,
  );

  group('farol pelo ritmo (DP-10)', () {
    test('verde até o ritmo, amarelo até 10 pontos acima', () {
      expect(farolDe(30, 33.3), Farol.verde);
      expect(farolDe(43, 33.3), Farol.amarelo);
      expect(farolDe(44, 33.3), Farol.vermelho);
    });

    test('no dia 10 de 30, o ritmo é 33%', () {
      final m = calcular(avista: [noDia(2, 150000)]);
      expect(m.ritmo, closeTo(33.3, 0.1));
      // 1.500 de 6.000 = 25%.
      expect(m.porcento, 25);
      expect(m.farol, Farol.verde);
      expect(m.superavit, 450000);
    });

    test('mês fechado compara com 100%', () {
      final m = calcular(
        mes: Mes(2026, 10),
        avista: [
          (dia: DateTime(2026, 10, 3), forma: TipoPagamento.pix, total: 650000),
        ],
      );
      expect(m.periodo, PeriodoDoMes.passado);
      expect(m.ritmo, 100);
      expect(m.farol, Farol.amarelo);
      expect(m.superavit, -50000);
    });

    test('mês futuro: só o comprometido, sem farol', () {
      final m = calcular(mes: Mes(2026, 12), faturas: [fatura(80000)]);
      expect(m.periodo, PeriodoDoMes.futuro);
      expect(m.consumo, 80000);
      expect(m.farol, isNull);
      expect(m.ritmo, isNull);
      expect(m.serie, isEmpty);
    });

    test('sem renda, sem base nem farol', () {
      final m = calcular(semRenda: true, avista: [noDia(1, 100)]);
      expect(m.consumo, 100);
      expect(m.base, isNull);
      expect(m.farol, isNull);
      expect(m.superavit, isNull);
    });
  });

  group('base de comparação (DP-1)', () {
    final avista = [noDia(1, 10000), noDia(2, 30000, TipoPagamento.voucher)];

    test('renda total soma o voucher na base e no consumo', () {
      final m = calcular(avista: avista, faturas: [fatura(20000)]);
      expect(m.base, 600000);
      expect(m.consumo, 60000);
      expect(m.avistaPorForma, {
        TipoPagamento.pix: 10000,
        TipoPagamento.voucher: 30000,
      });
    });

    test('só salário tira o voucher dos dois lados', () {
      final m = calcular(
        avista: avista,
        faturas: [fatura(20000)],
        base: BaseComparacao.soSalario,
      );
      expect(m.base, 500000);
      expect(m.avista, 10000);
      expect(m.consumo, 30000);
      // A divisão por forma continua mostrando o voucher.
      expect(m.avistaPorForma[TipoPagamento.voucher], 30000);
    });
  });

  group('fatura entra no dia do vencimento (DP-9)', () {
    test('antes do vencimento fica a vencer', () {
      final m = calcular(
        hoje: DateTime(2026, 11, 3),
        faturas: [fatura(100000)],
      );
      expect(m.faturado, 0);
      expect(m.faturadoAVencer, 100000);
      expect(m.consumo, 0);
    });

    test('vencida entra como degrau na série', () {
      final m = calcular(
        avista: [noDia(1, 1000), noDia(7, 500)],
        faturas: [fatura(100000)],
      );
      expect(m.faturado, 100000);
      expect(m.faturadoAVencer, 0);
      expect(m.serie, hasLength(10));
      expect(m.serie.sublist(0, 7), [
        1000,
        1000,
        1000,
        1000,
        101000,
        101000,
        101500,
      ]);
      expect(m.serie.last, 101500);
    });

    test('paga antes do vencimento entra no dia do pagamento', () {
      final m = calcular(
        hoje: DateTime(2026, 11, 3),
        faturas: [fatura(100000, pagoEm: DateTime(2026, 11, 2, 9))],
      );
      expect(m.faturado, 100000);
      expect(m.serie, [0, 100000, 100000]);
    });

    test('sem dia de vencimento, entra no último dia', () {
      final m = calcular(faturas: [fatura(100000, vencimento: null)]);
      expect(m.faturadoAVencer, 100000);
      final fechado = calcular(
        hoje: DateTime(2026, 12, 2),
        faturas: [fatura(100000, vencimento: null)],
      );
      expect(fechado.serie.last, 100000);
      expect(fechado.serie[28], 0);
    });

    test('vencimento 31 em mês de 30 dias cai no dia 30', () {
      expect(
        diaDaFatura(fatura(1, vencimento: 31), Mes(2026, 11)),
        DateTime(2026, 11, 30),
      );
    });
  });

  test('à vista por dia e forma no banco', () async {
    final banco = bancoEmMemoria();
    addTearDown(banco.close);
    final compras = CompraAvistaRepository(
      banco,
      relogio: RelogioFixo(DateTime(2026, 11, 10)),
      uuid: GeradorUuidSequencial(),
      fuso: FusoFixo(-180),
    );
    await compras.criar(gasto2(DateTime(2026, 11, 3, 9), 1000));
    await compras.criar(gasto2(DateTime(2026, 11, 3, 18), 500));
    await compras.criar(
      gasto2(DateTime(2026, 11, 4, 12), 700, TipoPagamento.voucher),
    );
    await compras.criar(gasto2(DateTime(2026, 10, 31, 23), 999));

    final linhas = await MacroRepository(banco)
        .observarAvistaPorDia(Mes(2026, 11))
        .first;
    expect(linhas.map((l) => (l.dia.day, l.forma, l.total)), [
      (3, TipoPagamento.pix, 1500),
      (4, TipoPagamento.voucher, 700),
    ]);
  });
}

DadosCompraAvista gasto2(
  DateTime momento,
  int valor, [
  TipoPagamento forma = TipoPagamento.pix,
]) => gasto(momento: momento, valorCentavos: valor, tipoPagamento: forma);
