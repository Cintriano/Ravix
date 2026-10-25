// Mede, a cada execução (inclusive no CI), as consultas da v1 com a massa
// de ~20 mil gastos. Só registra os tempos: eles variam entre máquinas, então
// o teste nunca falha por lentidão. As metas valem no aparelho
// (integration_test/desempenho_test.dart).
// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:ravix/core/datas.dart';
import 'package:ravix/data/banco.dart';
import 'package:ravix/data/compra_avista_repository.dart';
import 'package:ravix/data/massa_de_teste.dart';

import '../helpers/ambiente_falso.dart';
import '../helpers/banco_de_teste.dart';

Future<Duration> medir(Future<void> Function() acao) async {
  final cronometro = Stopwatch()..start();
  await acao();
  return cronometro.elapsed;
}

void main() {
  test('consultas com 20 mil gastos (tempos registrados)', () async {
    final banco = bancoEmMemoria();
    addTearDown(banco.close);
    final compras = CompraAvistaRepository(
      banco,
      relogio: RelogioFixo(DateTime(2026, 10, 24, 15)),
      uuid: GeradorUuidSequencial(),
      fuso: FusoFixo(-180),
    );
    final ate = DateTime(2026, 10, 24);
    final outubro = Mes(2026, 10);

    final geracao = await medir(() => gerarMassaDeTeste(banco, ate: ate));
    final total = await banco
        .customSelect('SELECT COUNT(*) AS n FROM tbl_compra_avista')
        .getSingle();
    expect(total.read<int>('n'), 20000);

    late List<CompraDoMes> doMes;
    final mes = await medir(
      () async => doMes = await compras.observarMes(outubro).first,
    );
    final acumulado = await medir(
      () => compras.observarAcumulado(outubro).first,
    );
    int? sugestao;
    final sugerir = await medir(
      () async => sugestao = await compras.sugerirSubcategoria('padaria'),
    );
    final salvar = await medir(() async {
      final emitiu = compras
          .observarMes(outubro)
          .firstWhere((l) => l.length == doMes.length + 1);
      await compras.criar(gasto(momento: DateTime(2026, 10, 24, 10)));
      await emitiu;
    });

    expect(doMes, isNotEmpty);
    expect(sugestao, 101);

    print(
      'Desempenho (20 mil gastos, banco em memória):\n'
      '  gerar a massa ........ ${geracao.inMilliseconds} ms\n'
      '  tabela do mês ........ ${mes.inMilliseconds} ms '
      '(${doMes.length} gastos)\n'
      '  acumulado do mês ..... ${acumulado.inMilliseconds} ms\n'
      '  sugestão "padaria" ... ${sugerir.inMilliseconds} ms\n'
      '  salvar e ver na lista  ${salvar.inMilliseconds} ms',
    );
  });
}
