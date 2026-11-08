import 'package:flutter_test/flutter_test.dart';
import 'package:ravix/core/datas.dart';
import 'package:ravix/data/banco.dart';
import 'package:ravix/data/renda_repository.dart';

import '../helpers/ambiente_falso.dart';
import '../helpers/banco_de_teste.dart';

void main() {
  late BancoRavix banco;
  late RendaRepository repositorio;

  setUp(() {
    banco = bancoEmMemoria();
    repositorio = RendaRepository(
      banco,
      relogio: RelogioFixo(DateTime.utc(2026, 11, 8, 12)),
      uuid: GeradorUuidSequencial(),
    );
  });
  tearDown(() => banco.close());

  Future<void> definir(int salario, int voucher, Mes mes) =>
      repositorio.definir(
        salarioCentavos: salario,
        voucherCentavos: voucher,
        aPartirDe: mes,
      );

  test('sem renda cadastrada, nenhum mês tem renda', () async {
    expect(await repositorio.vigente(Mes(2026, 11)), isNull);
  });

  test('vale a partir do mês e até a próxima vigência (DP-6)', () async {
    await definir(500000, 80000, Mes(2026, 3));
    await definir(550000, 90000, Mes(2026, 9));

    expect(await repositorio.vigente(Mes(2026, 2)), isNull);
    expect((await repositorio.vigente(Mes(2026, 3)))!.salario, 500000);
    expect((await repositorio.vigente(Mes(2026, 8)))!.salario, 500000);
    expect((await repositorio.vigente(Mes(2026, 9)))!.salario, 550000);
    expect((await repositorio.vigente(Mes(2027, 1)))!.voucher, 90000);
  });

  test('mudar a renda de um mês não altera os anteriores', () async {
    await definir(500000, 80000, Mes(2026, 3));
    await definir(600000, 80000, Mes(2026, 11));
    expect((await repositorio.vigente(Mes(2026, 10)))!.salario, 500000);
  });

  test('definir de novo no mesmo mês substitui', () async {
    await definir(500000, 80000, Mes(2026, 11));
    await definir(520000, 0, Mes(2026, 11));
    final historico = await repositorio.observarHistorico().first;
    expect(historico, hasLength(1));
    expect(historico.single.salario, 520000);
    expect(historico.single.voucher, 0);
  });

  test('histórico do mais recente para o mais antigo', () async {
    await definir(500000, 0, Mes(2025, 12));
    await definir(550000, 0, Mes(2026, 5));
    final meses = (await repositorio.observarHistorico().first).map(
      (r) => r.aPartirDe,
    );
    expect(meses, [Mes(2026, 5), Mes(2025, 12)]);
  });

  test('remover uma vigência devolve os meses dela à anterior', () async {
    await definir(500000, 0, Mes(2026, 3));
    await definir(550000, 0, Mes(2026, 9));
    final recente = (await repositorio.observarHistorico().first).first;
    await repositorio.remover(recente.uuidRenda);
    expect((await repositorio.vigente(Mes(2026, 10)))!.salario, 500000);
  });

  test('valida salário e voucher', () async {
    try {
      await definir(0, -1, Mes(2026, 11));
      fail('esperava RendaInvalida');
    } on RendaInvalida catch (e) {
      expect(e.erros.keys, CampoRenda.values);
    }
  });
}
