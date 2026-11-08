import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:ravix/app/compartilhar.dart';
import 'package:ravix/app/dependencias.dart';
import 'package:ravix/core/tema/icones.dart';
import 'package:ravix/data/backup.dart';
import 'package:ravix/data/banco.dart';

import '../../helpers/ambiente_falso.dart';
import '../../helpers/app_de_teste.dart';

final class CompartilhadorFalso implements Compartilhador {
  final compartilhados = <String>[];
  bool falhar = false;

  @override
  Future<void> compartilharArquivo(
    File arquivo, {
    required String assunto,
  }) async {
    if (falhar) throw const FileSystemException('sem compartilhamento');
    compartilhados.add(p.basename(arquivo.path));
  }
}

void main() {
  late Directory pasta;
  late CompartilhadorFalso compartilhador;

  setUp(() {
    pasta = Directory.systemTemp.createTempSync('ravix_export_');
    compartilhador = CompartilhadorFalso();
  });
  tearDown(() => pasta.deleteSync(recursive: true));

  Future<void> abrirConfiguracao(WidgetTester tester) async {
    await montarApp(
      tester,
      extras: [
        compartilhadorProvider.overrideWithValue(compartilhador),
        backupRepositoryProvider.overrideWith(
          (ref) => BackupRepository(
            ref.watch(bancoProvider),
            relogio: RelogioFixo(agoraDosTestes),
            pastaTemporaria: () async => pasta,
          ),
        ),
      ],
    );
    await tester.tap(find.byIcon(Icones.settings));
    await tester.pumpAndSettle();
  }

  testarApp('exportar backup compartilha o arquivo do banco', (tester) async {
    await abrirConfiguracao(tester);
    await tester.runAsync(() async {
      await tester.tap(find.text('Exportar backup'));
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();

    expect(compartilhador.compartilhados, [
      'ravix_v${BancoRavix.versaoAtual}_backup_20261024-1500.sqlite',
    ]);
  });

  testarApp('falha ao compartilhar mostra o aviso', (tester) async {
    compartilhador.falhar = true;
    await abrirConfiguracao(tester);
    await tester.runAsync(() async {
      await tester.tap(find.text('Exportar backup'));
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();

    expect(find.text('Não foi possível exportar o backup.'), findsOneWidget);
  });
}
