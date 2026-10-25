// Metas do DP-36 no aparelho, com ~20 mil gastos (cinco anos de uso) num
// banco próprio em arquivo, separado do banco de uso. Rode em modo profile:
//
// flutter drive --profile --driver test_driver/integration_test.dart \
//   --target integration_test/desempenho_test.dart -d <aparelho>
//
// Os tempos saem no log e em build/integration_response_data.json.
// ignore_for_file: avoid_print

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:ravix/app.dart';
import 'package:ravix/app/dependencias.dart';
import 'package:ravix/core/datas.dart';
import 'package:ravix/data/banco.dart';
import 'package:ravix/data/compra_avista_repository.dart';
import 'package:ravix/data/massa_de_teste.dart';
import 'package:ravix/features/shell/bloqueio.dart';

import '../test/helpers/app_de_teste.dart';

/// Abertura até a aba à vista utilizável.
const metaAbertura = Duration(seconds: 2);

/// Salvar e ver a tabela atualizada.
const metaSalvar = Duration(milliseconds: 100);

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<Duration> esperarAte(WidgetTester tester, Finder alvo) async {
    final cronometro = Stopwatch()..start();
    while (alvo.evaluate().isEmpty) {
      if (cronometro.elapsed > const Duration(seconds: 15)) {
        fail('Não apareceu: $alvo');
      }
      await tester.pump(const Duration(milliseconds: 4));
    }
    return cronometro.elapsed;
  }

  testWidgets('metas do DP-36 com 20 mil gastos', (tester) async {
    final pasta = await getTemporaryDirectory();
    final arquivo = File(p.join(pasta.path, 'ravix_desempenho.sqlite'));
    Future<void> apagar() async {
      for (final sufixo in ['', '-wal', '-shm']) {
        final f = File('${arquivo.path}$sufixo');
        if (f.existsSync()) await f.delete();
      }
    }

    await apagar();
    final banco = BancoRavix(
      NativeDatabase.createInBackground(arquivo, setup: configurarConexao),
    );
    addTearDown(() async {
      await banco.close();
      await apagar();
    });

    final agora = DateTime.now();
    final geracao = Stopwatch()..start();
    await gerarMassaDeTeste(banco, ate: agora);
    geracao.stop();

    // Abertura: do runApp até a tabela do mês na tela (desbloqueio na hora).
    final abertura = Stopwatch()..start();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bancoProvider.overrideWithValue(banco),
          servicoBloqueioProvider.overrideWithValue(ServicoBloqueioFalso()),
        ],
        child: const RavixApp(),
      ),
    );
    await esperarAte(tester, find.byType(ListTile));
    abertura.stop();

    // Salvar e ver: da gravação até a linha nova na tabela.
    final compras = ProviderScope.containerOf(
      tester.element(find.byType(RavixApp)),
    ).read(compraAvistaRepositoryProvider);
    final salvar = Stopwatch()..start();
    await compras.criar((
      momento: agora,
      descricao: 'Medição de salvar',
      valorCentavos: 1,
      tipoPagamento: TipoPagamento.pix,
      idSubcategoria: 507,
      uuidTag: null,
    ));
    await esperarAte(tester, find.text('Medição de salvar'));
    salvar.stop();

    // Consultas isoladas.
    final mes = Mes.de(agora);
    final consultaMes = Stopwatch()..start();
    final doMes = await compras.observarMes(mes).first;
    consultaMes.stop();
    final sugestao = Stopwatch()..start();
    await compras.sugerirSubcategoria('padaria');
    sugestao.stop();

    final resultado = {
      'gastos': 20000,
      'gastos_no_mes': doMes.length,
      'gerar_massa_ms': geracao.elapsedMilliseconds,
      'abertura_ms': abertura.elapsedMilliseconds,
      'salvar_e_ver_ms': salvar.elapsedMilliseconds,
      'consulta_mes_ms': consultaMes.elapsedMilliseconds,
      'sugestao_ms': sugestao.elapsedMilliseconds,
    };
    binding.reportData = resultado;
    print('DESEMPENHO $resultado');

    expect(abertura.elapsed, lessThan(metaAbertura));
    expect(salvar.elapsed, lessThan(metaSalvar));
  });
}
