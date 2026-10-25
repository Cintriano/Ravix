import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ravix/app.dart';
import 'package:ravix/app/dependencias.dart';
import 'package:ravix/core/datas.dart';
import 'package:ravix/core/tema/icones.dart';

import '../../helpers/app_de_teste.dart';
import '../../helpers/banco_de_teste.dart';

void main() {
  Future<ProviderContainer> abrirTags(WidgetTester tester) async {
    await montarApp(tester);
    await tester.tap(find.byIcon(Icones.settings));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tags'));
    await tester.pumpAndSettle();
    return ProviderScope.containerOf(tester.element(find.byType(RavixApp)));
  }

  Future<void> digitarESalvar(
    WidgetTester tester,
    String nome,
    String botao,
  ) async {
    await tester.enterText(find.byType(TextField), nome);
    await tester.tap(find.widgetWithText(FilledButton, botao));
    await tester.pumpAndSettle();
  }

  Future<void> criarPelaTela(WidgetTester tester, String nome) async {
    await tester.tap(find.text('Nova tag'));
    await tester.pumpAndSettle();
    await digitarESalvar(tester, nome, 'Criar');
  }

  testWidgets('sem tags mostra o estado vazio com ação', (tester) async {
    await abrirTags(tester);
    expect(find.text('Nenhuma tag'), findsOneWidget);

    await tester.tap(find.text('Criar tag'));
    await tester.pumpAndSettle();
    await digitarESalvar(tester, 'Viagem', 'Criar');

    expect(find.text('Viagem'), findsOneWidget);
    expect(find.text('Nenhuma tag'), findsNothing);
    await encerrarApp(tester);
  });

  testWidgets('cria tags e lista em ordem alfabética', (tester) async {
    await abrirTags(tester);
    await criarPelaTela(tester, 'Viagem');
    await criarPelaTela(tester, '  aniversário  ');

    final nomes = tester
        .widgetList<ListTile>(find.byType(ListTile))
        .map((t) => (t.title! as Text).data);
    expect(nomes, ['aniversário', 'Viagem']);
    await encerrarApp(tester);
  });

  testWidgets('nome repetido mostra a mensagem e mantém o diálogo', (
    tester,
  ) async {
    await abrirTags(tester);
    await criarPelaTela(tester, 'Viagem');
    await criarPelaTela(tester, 'VIAGEM');

    expect(find.text('Já existe uma tag chamada "VIAGEM".'), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);

    // Ao corrigir o texto, a mensagem some.
    await tester.enterText(find.byType(TextField), 'Viagem 2');
    await tester.pump();
    expect(find.textContaining('Já existe'), findsNothing);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Viagem 2'), findsNothing);
    await encerrarApp(tester);
  });

  testWidgets('nome vazio mostra a mensagem', (tester) async {
    await abrirTags(tester);
    await criarPelaTela(tester, '   ');
    expect(find.text('O nome da tag não pode ficar vazio.'), findsOneWidget);
    await encerrarApp(tester);
  });

  testWidgets('tocar na tag renomeia', (tester) async {
    await abrirTags(tester);
    await criarPelaTela(tester, 'Viajem');

    await tester.tap(find.text('Viajem'));
    await tester.pumpAndSettle();
    expect(find.text('Renomear tag'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Viajem',
    );
    await digitarESalvar(tester, 'Viagem', 'Salvar');

    expect(find.text('Viagem'), findsOneWidget);
    expect(find.text('Viajem'), findsNothing);
    await encerrarApp(tester);
  });

  testWidgets('sem gastos: confirma e exclui', (tester) async {
    await abrirTags(tester);
    await criarPelaTela(tester, 'Viagem');

    await tester.tap(find.byTooltip('Remover Viagem'));
    await tester.pumpAndSettle();
    expect(find.text('Excluir a tag?'), findsOneWidget);
    expect(find.textContaining('não está em nenhum gasto'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
    await tester.pumpAndSettle();
    expect(find.text('Tag "Viagem" excluída.'), findsOneWidget);
    expect(find.text('Nenhuma tag'), findsOneWidget);
    await encerrarApp(tester);
  });

  testWidgets('com gastos: arquiva e mantém nos gastos antigos', (
    tester,
  ) async {
    final container = await abrirTags(tester);
    final tags = container.read(tagRepositoryProvider);
    final compras = container.read(compraAvistaRepositoryProvider);
    // Chamadas diretas ao banco rodam fora do relógio falso do teste.
    final viagem = (await tester.runAsync(() => tags.criar('Viagem')))!;
    await tester.runAsync(() => compras.criar(gasto(uuidTag: viagem.uuidTag)));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Remover Viagem'));
    await tester.pumpAndSettle();
    expect(find.text('Arquivar a tag?'), findsOneWidget);
    expect(find.textContaining('está em 1 gasto.'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Arquivar'));
    await tester.pumpAndSettle();
    expect(find.text('Tag "Viagem" arquivada.'), findsOneWidget);
    expect(find.text('Nenhuma tag'), findsOneWidget);

    final arquivada = await tester.runAsync(() => tags.buscar(viagem.uuidTag));
    expect(arquivada!.status, 'arquivada');
    final linhas = await tester.runAsync(
      () => compras.observarMes(Mes(2026, 10)).first,
    );
    expect(linhas!.single.tag, 'Viagem');
    await encerrarApp(tester);
  });

  testWidgets('cancelar a remoção mantém a tag', (tester) async {
    await abrirTags(tester);
    await criarPelaTela(tester, 'Viagem');

    await tester.tap(find.byTooltip('Remover Viagem'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.text('Viagem'), findsOneWidget);
    await encerrarApp(tester);
  });

  testWidgets('deslizar para a esquerda remove', (tester) async {
    await abrirTags(tester);
    await criarPelaTela(tester, 'Viagem');

    await tester.drag(find.text('Viagem'), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(find.text('Excluir a tag?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
    await tester.pumpAndSettle();
    expect(find.text('Nenhuma tag'), findsOneWidget);
    await encerrarApp(tester);
  });

  testWidgets('deslizar e cancelar devolve a linha', (tester) async {
    await abrirTags(tester);
    await criarPelaTela(tester, 'Viagem');

    await tester.drag(find.text('Viagem'), const Offset(-600, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.text('Viagem'), findsOneWidget);
    await encerrarApp(tester);
  });
}
